import Foundation

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case lbs = "lbs"
    case kg = "kg"

    var id: String { rawValue }
}

/// A single weigh-in for a pet, from a vet visit or a home scale check.
struct WeightEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var weight: Double   // always stored in lbs internally
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), weight: Double, note: String = "") {
        self.id = id
        self.date = date
        self.weight = weight
        self.note = note
    }
}

/// A tracked pet with its full weight history.
struct Pet: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var species: String
    var entries: [WeightEntry]

    init(id: UUID = UUID(), name: String, species: String = "Dog", entries: [WeightEntry] = []) {
        self.id = id
        self.name = name
        self.species = species
        self.entries = entries
    }

    var sortedEntries: [WeightEntry] {
        entries.sorted { $0.date < $1.date }
    }

    var latestWeight: Double? {
        sortedEntries.last?.weight
    }

    /// The quirky signature feature's data source: trend direction computed
    /// from the slope between the earliest and latest entry within the
    /// trailing window (falls back to all entries if fewer than 2 exist).
    var trend: WeightTrend {
        let sorted = sortedEntries
        guard sorted.count >= 2 else { return .stable }
        let first = sorted.first!
        let last = sorted.last!
        let deltaWeight = last.weight - first.weight
        let percentChange = first.weight > 0 ? (deltaWeight / first.weight) * 100 : 0
        if percentChange > 3 { return .gaining }
        if percentChange < -3 { return .losing }
        return .stable
    }

    /// Normalized -1...1 value driving the plumping/slimming silhouette and
    /// the needle-dial swing: 0 = stable, positive = gaining, negative = losing.
    var trendMagnitude: Double {
        let sorted = sortedEntries
        guard sorted.count >= 2, let first = sorted.first, let last = sorted.last, first.weight > 0 else { return 0 }
        let percentChange = (last.weight - first.weight) / first.weight
        return max(-1, min(1, percentChange * 6)) // scale so ~17% change hits full swing
    }
}

enum WeightTrend: String, Codable {
    case gaining = "Gaining"
    case losing = "Losing"
    case stable = "Stable"

    var systemImage: String {
        switch self {
        case .gaining: return "arrow.up.right"
        case .losing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
}

/// Lifetime stats for the streak/habit-loop feature.
struct TroveStats: Codable, Equatable {
    var totalLogged: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var lastLogDate: Date?

    mutating func recordLog(on date: Date = Date()) {
        totalLogged += 1
        let calendar = Calendar.current
        if let last = lastLogDate {
            let daysSince = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: date)).day ?? 0
            if daysSince == 0 {
                // same-day log, streak unchanged
            } else if daysSince == 1 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        bestStreak = max(bestStreak, currentStreak)
        lastLogDate = date
    }
}

enum LbKgConverter {
    static func lbsToKg(_ lbs: Double) -> Double { lbs * 0.453592 }
    static func kgToLbs(_ kg: Double) -> Double { kg / 0.453592 }

    static func display(_ lbs: Double, unit: WeightUnit) -> Double {
        unit == .lbs ? lbs : lbsToKg(lbs)
    }

    static func toStorage(_ value: Double, unit: WeightUnit) -> Double {
        unit == .lbs ? value : kgToLbs(value)
    }
}
