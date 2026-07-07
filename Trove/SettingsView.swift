import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TroveStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("trove_weight_unit") private var unitRaw: String = WeightUnit.lbs.rawValue
    @AppStorage("trove_reminders_enabled") private var remindersEnabled: Bool = false
    @State private var activeSheet: TroveSheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .lbs }

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Weight Unit", selection: $unitRaw) {
                        ForEach(WeightUnit.allCases) { u in
                            Text(u.rawValue).tag(u.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("weightUnitPicker")
                }

                Section("Reminders") {
                    Toggle("Weekly weigh-in reminder", isOn: $remindersEnabled)
                        .accessibilityIdentifier("remindersToggle")
                }

                Section("Stats") {
                    HStack {
                        Text("Total Logged")
                        Spacer()
                        Text("\(store.stats.totalLogged)")
                            .foregroundStyle(TRTheme.inkFaded)
                    }
                    HStack {
                        Text("Current Streak")
                        Spacer()
                        Text("\(store.stats.currentStreak) days")
                            .foregroundStyle(TRTheme.inkFaded)
                    }
                    HStack {
                        Text("Best Streak")
                        Spacer()
                        Text("\(store.stats.bestStreak) days")
                            .foregroundStyle(TRTheme.inkFaded)
                    }
                }

                Section("Trove Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(TRTheme.mint)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(TRTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/trove-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(TRTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all pets and history?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TroveStore())
        .environmentObject(PurchaseManager())
}
