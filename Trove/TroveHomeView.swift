import SwiftUI

struct TroveHomeView: View {
    @EnvironmentObject private var store: TroveStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("trove_weight_unit") private var unitRaw: String = WeightUnit.lbs.rawValue
    @State private var activeSheet: TroveSheet?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .lbs }

    var body: some View {
        NavigationStack {
            ZStack {
                TRTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Trove")
                                .font(TRTheme.titleFont)
                                .foregroundStyle(TRTheme.ink)
                            Spacer()
                            Button {
                                if store.canAddPet(isPro: purchases.isPro) {
                                    activeSheet = .addPet
                                } else {
                                    activeSheet = .paywall
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(TRTheme.mint)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("addPetButton")
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                        if store.pets.isEmpty {
                            emptyState
                        } else {
                            ForEach(store.pets) { pet in
                                petCard(pet)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addPet:
                    PetFormView(existing: nil)
                case .editPet(let pet):
                    PetFormView(existing: pet)
                case .addEntry(let pet):
                    EntryFormView(pet: pet)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    private func petCard(_ pet: Pet) -> some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    activeSheet = .editPet(pet)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pet.name)
                            .font(TRTheme.headlineFont)
                            .foregroundStyle(TRTheme.ink)
                        Text(pet.species)
                            .font(.caption)
                            .foregroundStyle(TRTheme.inkFaded)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("petNameLabel_\(pet.name)")

                Spacer()

                Button {
                    activeSheet = .addEntry(pet)
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(TRTheme.mint)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("logWeightButton_\(pet.name)")
            }

            /// Quirky signature feature: a literal vet-scale needle dial that
            /// swings live to point at the pet's trend direction (gaining
            /// right / losing left / stable center), driven by trendMagnitude.
            // Note: no accessibilityIdentifier is applied here at the call site —
            // TrendNeedleDial's internal HStack already carries its own
            // "trendLabel_<name>" identifier via .accessibilityElement(children: .combine).
            // Applying a second identifier ("trendDial_<name>") to the whole view from
            // outside competed with/shadowed that inner identifier in the accessibility
            // tree, making "trendLabel_<name>" unreliable to query from XCUITest.
            TrendNeedleDial(pet: pet, unit: unit)

            if pet.entries.isEmpty {
                Text("No weigh-ins yet. Tap + to log the first one.")
                    .font(.caption)
                    .foregroundStyle(TRTheme.inkFaded)
                    .padding(.vertical, 8)
            } else {
                entryHistory(pet)
            }
        }
        .padding(18)
        .background(TRTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(TRTheme.rule, lineWidth: 1))
        .padding(.horizontal, 18)
    }

    private func entryHistory(_ pet: Pet) -> some View {
        VStack(spacing: 8) {
            ForEach(pet.sortedEntries.reversed().prefix(5)) { entry in
                HStack {
                    Text(entry.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(TRTheme.inkFaded)
                    Spacer()
                    Text(String(format: "%.1f %@", LbKgConverter.display(entry.weight, unit: unit), unit.rawValue))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TRTheme.ink)
                    Menu {
                        Button("Delete", role: .destructive) {
                            store.deleteEntry(petID: pet.id, entryID: entry.id)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(TRTheme.inkFaded)
                    }
                    .accessibilityIdentifier("entryMenu_\(pet.name)_\(entry.id)")
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(TRTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint")
                .font(.system(size: 48))
                .foregroundStyle(TRTheme.inkFaded)
            Text("No pets tracked yet")
                .font(TRTheme.headlineFont)
                .foregroundStyle(TRTheme.ink)
            Text("Add a pet to start logging weigh-ins.")
                .font(.subheadline)
                .foregroundStyle(TRTheme.inkFaded)
        }
        .padding(.top, 40)
        .padding(.horizontal, 18)
    }
}

/// A literal physical scale-needle dial: an arc gauge with a needle that
/// visibly rotates to point left (losing), center (stable), or right
/// (gaining) based on the pet's computed trend magnitude, animating on
/// every appearance/update like a real analog vet scale settling.
struct TrendNeedleDial: View {
    let pet: Pet
    let unit: WeightUnit
    @State private var animatedAngle: Double = 0

    private var targetAngle: Double {
        // -1...1 maps to -60...60 degrees
        pet.trendMagnitude * 60
    }

    private var trendColor: Color {
        switch pet.trend {
        case .gaining: return TRTheme.danger
        case .losing: return TRTheme.taupe
        case .stable: return TRTheme.mint
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .trim(from: 0.0, to: 1.0)
                    .stroke(TRTheme.surfaceRaised, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0.28, to: 0.72)
                    .stroke(TRTheme.rule, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .frame(width: 140, height: 140)

                // Needle
                RoundedRectangle(cornerRadius: 2)
                    .fill(trendColor)
                    .frame(width: 4, height: 58)
                    .offset(y: -29)
                    .rotationEffect(.degrees(animatedAngle))

                Circle()
                    .fill(trendColor)
                    .frame(width: 14, height: 14)

                Text(pet.latestWeight.map { String(format: "%.1f", LbKgConverter.display($0, unit: unit)) } ?? "--")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(TRTheme.ink)
                    .offset(y: 30)
            }
            .frame(width: 140, height: 90)
            .clipped()

            HStack(spacing: 6) {
                Image(systemName: pet.trend.systemImage)
                    .foregroundStyle(trendColor)
                Text(pet.trend.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(trendColor)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("trendLabel_\(pet.name)")
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.55)) {
                animatedAngle = targetAngle
            }
        }
        .onChange(of: targetAngle) { _, newValue in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.55)) {
                animatedAngle = newValue
            }
        }
    }
}

#Preview {
    TroveHomeView()
        .environmentObject(TroveStore())
        .environmentObject(PurchaseManager())
}
