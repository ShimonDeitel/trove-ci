import Foundation
import Combine

@MainActor
final class TroveStore: ObservableObject {
    @Published private(set) var pets: [Pet] = []
    @Published private(set) var stats = TroveStats()

    static let freePetLimit = 1

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("trove_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if pets.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        let now = Date()
        let calendar = Calendar.current
        let entries = [
            WeightEntry(date: calendar.date(byAdding: .day, value: -60, to: now) ?? now, weight: 42.0, note: "Vet checkup"),
            WeightEntry(date: calendar.date(byAdding: .day, value: -30, to: now) ?? now, weight: 43.5, note: "Home scale"),
            WeightEntry(date: now, weight: 45.0, note: "Home scale")
        ]
        pets = [Pet(name: "Buddy", species: "Dog", entries: entries)]
        save()
    }

    func canAddPet(isPro: Bool) -> Bool {
        isPro || pets.count < Self.freePetLimit
    }

    @discardableResult
    func addPet(name: String, species: String, isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddPet(isPro: isPro) else { return false }
        pets.append(Pet(name: trimmed, species: species))
        save()
        return true
    }

    func updatePet(_ id: UUID, name: String, species: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = pets.firstIndex(where: { $0.id == id }) else { return }
        pets[idx].name = trimmed
        pets[idx].species = species
        save()
    }

    func deletePet(_ id: UUID) {
        pets.removeAll { $0.id == id }
        save()
    }

    @discardableResult
    func addEntry(petID: UUID, weight: Double, date: Date, note: String) -> Bool {
        guard weight > 0, let idx = pets.firstIndex(where: { $0.id == petID }) else { return false }
        pets[idx].entries.append(WeightEntry(date: date, weight: weight, note: note))
        stats.recordLog(on: date)
        save()
        return true
    }

    func deleteEntry(petID: UUID, entryID: UUID) {
        guard let idx = pets.firstIndex(where: { $0.id == petID }) else { return }
        pets[idx].entries.removeAll { $0.id == entryID }
        save()
    }

    func deleteAllData() {
        pets = []
        stats = TroveStats()
        seedDefaults()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var pets: [Pet]
        var stats: TroveStats
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            pets = decoded.pets
            stats = decoded.stats
        }
    }

    private func save() {
        let snapshot = Snapshot(pets: pets, stats: stats)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
