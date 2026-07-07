import XCTest
@testable import Trove

final class TroveTests: XCTestCase {
    var store: TroveStore!

    @MainActor
    override func setUp() {
        super.setUp()
        store = TroveStore()
        store.deleteAllData()
        for p in store.pets { store.deletePet(p.id) }
    }

    @MainActor
    func testAddPet() {
        let added = store.addPet(name: "Milo", species: "Cat", isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.pets.count, 1)
        XCTAssertEqual(store.pets[0].name, "Milo")
    }

    @MainActor
    func testAddPetRejectsEmptyName() {
        let added = store.addPet(name: "   ", species: "Dog", isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testFreeLimitBlocksSecondPet() {
        _ = store.addPet(name: "Milo", species: "Cat", isPro: false)
        XCTAssertFalse(store.canAddPet(isPro: false))
        let second = store.addPet(name: "Rex", species: "Dog", isPro: false)
        XCTAssertFalse(second)
        XCTAssertEqual(store.pets.count, 1)
    }

    @MainActor
    func testProAllowsMultiplePets() {
        _ = store.addPet(name: "Milo", species: "Cat", isPro: true)
        _ = store.addPet(name: "Rex", species: "Dog", isPro: true)
        let third = store.addPet(name: "Zoe", species: "Rabbit", isPro: true)
        XCTAssertTrue(third)
        XCTAssertEqual(store.pets.count, 3)
    }

    @MainActor
    func testUpdatePet() {
        _ = store.addPet(name: "Milo", species: "Cat", isPro: false)
        let id = store.pets[0].id
        store.updatePet(id, name: "Milo Jr", species: "Cat")
        XCTAssertEqual(store.pets[0].name, "Milo Jr")
    }

    @MainActor
    func testDeletePet() {
        _ = store.addPet(name: "Milo", species: "Cat", isPro: false)
        let id = store.pets[0].id
        store.deletePet(id)
        XCTAssertTrue(store.pets.isEmpty)
    }

    @MainActor
    func testAddEntry() {
        _ = store.addPet(name: "Milo", species: "Cat", isPro: false)
        let id = store.pets[0].id
        let added = store.addEntry(petID: id, weight: 10.5, date: Date(), note: "Vet")
        XCTAssertTrue(added)
        XCTAssertEqual(store.pets[0].entries.count, 1)
    }

    @MainActor
    func testAddEntryRejectsNonPositiveWeight() {
        _ = store.addPet(name: "Milo", species: "Cat", isPro: false)
        let id = store.pets[0].id
        let added = store.addEntry(petID: id, weight: 0, date: Date(), note: "")
        XCTAssertFalse(added)
    }

    @MainActor
    func testDeleteEntry() {
        _ = store.addPet(name: "Milo", species: "Cat", isPro: false)
        let id = store.pets[0].id
        store.addEntry(petID: id, weight: 10.5, date: Date(), note: "")
        let entryID = store.pets[0].entries[0].id
        store.deleteEntry(petID: id, entryID: entryID)
        XCTAssertTrue(store.pets[0].entries.isEmpty)
    }

    // MARK: - Trend calculation

    func testTrendGainingWhenWeightIncreasesSignificantly() {
        let calendar = Calendar.current
        let now = Date()
        let entries = [
            WeightEntry(date: calendar.date(byAdding: .day, value: -30, to: now)!, weight: 40),
            WeightEntry(date: now, weight: 45)
        ]
        let pet = Pet(name: "Test", entries: entries)
        XCTAssertEqual(pet.trend, .gaining)
    }

    func testTrendLosingWhenWeightDecreasesSignificantly() {
        let calendar = Calendar.current
        let now = Date()
        let entries = [
            WeightEntry(date: calendar.date(byAdding: .day, value: -30, to: now)!, weight: 45),
            WeightEntry(date: now, weight: 40)
        ]
        let pet = Pet(name: "Test", entries: entries)
        XCTAssertEqual(pet.trend, .losing)
    }

    func testTrendStableWhenWeightBarelyChanges() {
        let calendar = Calendar.current
        let now = Date()
        let entries = [
            WeightEntry(date: calendar.date(byAdding: .day, value: -30, to: now)!, weight: 40),
            WeightEntry(date: now, weight: 40.3)
        ]
        let pet = Pet(name: "Test", entries: entries)
        XCTAssertEqual(pet.trend, .stable)
    }

    func testTrendStableWithFewerThanTwoEntries() {
        let pet = Pet(name: "Test", entries: [WeightEntry(weight: 40)])
        XCTAssertEqual(pet.trend, .stable)
    }

    func testTrendMagnitudeSignMatchesDirection() {
        let calendar = Calendar.current
        let now = Date()
        let gaining = Pet(name: "G", entries: [
            WeightEntry(date: calendar.date(byAdding: .day, value: -30, to: now)!, weight: 40),
            WeightEntry(date: now, weight: 45)
        ])
        XCTAssertGreaterThan(gaining.trendMagnitude, 0)

        let losing = Pet(name: "L", entries: [
            WeightEntry(date: calendar.date(byAdding: .day, value: -30, to: now)!, weight: 45),
            WeightEntry(date: now, weight: 40)
        ])
        XCTAssertLessThan(losing.trendMagnitude, 0)
    }

    // MARK: - Unit conversion

    func testLbsToKgConversion() {
        XCTAssertEqual(LbKgConverter.lbsToKg(10), 4.53592, accuracy: 0.001)
    }

    func testKgToLbsConversion() {
        XCTAssertEqual(LbKgConverter.kgToLbs(10), 22.0462, accuracy: 0.01)
    }

    func testDisplayAndStorageRoundTrip() {
        let lbsValue = 50.0
        let kgDisplay = LbKgConverter.display(lbsValue, unit: .kg)
        let backToLbs = LbKgConverter.toStorage(kgDisplay, unit: .kg)
        XCTAssertEqual(backToLbs, lbsValue, accuracy: 0.001)
    }

    // MARK: - Stats / streak

    func testStatsRecordLogFirstTimeSetsStreakToOne() {
        var stats = TroveStats()
        stats.recordLog(on: Date())
        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.totalLogged, 1)
    }

    func testStatsRecordLogConsecutiveDaysIncrementsStreak() {
        var stats = TroveStats()
        let calendar = Calendar.current
        let day1 = Date()
        let day2 = calendar.date(byAdding: .day, value: 1, to: day1)!
        stats.recordLog(on: day1)
        stats.recordLog(on: day2)
        XCTAssertEqual(stats.currentStreak, 2)
        XCTAssertEqual(stats.bestStreak, 2)
    }

    func testStatsRecordLogGapResetsStreak() {
        var stats = TroveStats()
        let calendar = Calendar.current
        let day1 = Date()
        let day5 = calendar.date(byAdding: .day, value: 5, to: day1)!
        stats.recordLog(on: day1)
        stats.recordLog(on: day5)
        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.bestStreak, 1)
    }

    @MainActor
    func testAddEntryUpdatesStreak() {
        _ = store.addPet(name: "Milo", species: "Cat", isPro: false)
        let id = store.pets[0].id
        store.addEntry(petID: id, weight: 10, date: Date(), note: "")
        XCTAssertEqual(store.stats.totalLogged, 1)
        XCTAssertEqual(store.stats.currentStreak, 1)
    }
}
