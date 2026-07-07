import SwiftUI

@main
struct TroveApp: App {
    @StateObject private var store = TroveStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
        }
    }
}
