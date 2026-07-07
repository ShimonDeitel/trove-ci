import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TroveHomeView()
                .tabItem {
                    Label("Pets", systemImage: "pawprint.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(TRTheme.mint)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(TRTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(TroveStore())
        .environmentObject(PurchaseManager())
}
