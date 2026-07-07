import SwiftUI

/// Trove's identity: a clinical-mint / warm-taupe vet-chart palette —
/// calm and medical-record-like, distinct from every sibling app's colors.
enum TRTheme {
    static let backdrop = Color(red: 0.961, green: 0.969, blue: 0.961)   // pale clinical mint-white
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.925, green: 0.945, blue: 0.933)
    static let ink = Color(red: 0.157, green: 0.176, blue: 0.165)        // near-black chart ink
    static let inkFaded = Color(red: 0.157, green: 0.176, blue: 0.165).opacity(0.55)
    static let rule = Color.black.opacity(0.08)

    static let mint = Color(red: 0.290, green: 0.573, blue: 0.494)       // clinical mint
    static let mintBright = Color(red: 0.361, green: 0.678, blue: 0.588)
    static let taupe = Color(red: 0.694, green: 0.596, blue: 0.502)      // warm taupe accent
    static let danger = Color(red: 0.749, green: 0.353, blue: 0.298)     // gaining-too-fast alert
    static let success = Color(red: 0.290, green: 0.573, blue: 0.494)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
