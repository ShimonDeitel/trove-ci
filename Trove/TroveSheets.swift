import SwiftUI

enum TroveSheet: Identifiable {
    case addPet
    case editPet(Pet)
    case addEntry(Pet)
    case paywall

    var id: String {
        switch self {
        case .addPet: return "addPet"
        case .editPet(let p): return "edit-\(p.id)"
        case .addEntry(let p): return "entry-\(p.id)"
        case .paywall: return "paywall"
        }
    }
}

private let speciesOptions = ["Dog", "Cat", "Rabbit", "Bird", "Other"]

struct PetFormView: View {
    @EnvironmentObject private var store: TroveStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let existing: Pet?

    @State private var name: String
    @State private var species: String

    init(existing: Pet?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _species = State(initialValue: existing?.species ?? "Dog")
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("petNameField")
                    Picker("Species", selection: $species) {
                        ForEach(speciesOptions, id: \.self) { Text($0).tag($0) }
                    }
                    .accessibilityIdentifier("petSpeciesPicker")
                }

                if isEditing {
                    Section {
                        Button("Delete Pet", role: .destructive) {
                            if let existing {
                                store.deletePet(existing.id)
                            }
                            dismiss()
                        }
                        .accessibilityIdentifier("deletePetButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Pet" : "New Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        if isEditing, let existing {
                            store.updatePet(existing.id, name: name, species: species)
                        } else {
                            store.addPet(name: name, species: species, isPro: purchases.isPro)
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("savePetButton")
                }
            }
        }
    }
}

struct EntryFormView: View {
    @EnvironmentObject private var store: TroveStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("trove_weight_unit") private var unitRaw: String = WeightUnit.lbs.rawValue

    let pet: Pet

    @State private var weightText: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .lbs }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weigh-in") {
                    TextField("Weight (\(unit.rawValue))", text: $weightText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("entryWeightField")
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("entryDatePicker")
                    TextField("Note (vet visit, home scale...)", text: $note)
                        .accessibilityIdentifier("entryNoteField")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Double(weightText) else { return }
                        let lbs = LbKgConverter.toStorage(value, unit: unit)
                        store.addEntry(petID: pet.id, weight: lbs, date: date, note: note)
                        dismiss()
                    }
                    .disabled(Double(weightText) == nil)
                    .accessibilityIdentifier("saveEntryButton")
                }
            }
        }
    }
}
