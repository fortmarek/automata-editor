import SwiftUI
import ComposableArchitecture
import Foundation

@main
struct AutomataEditorApp: App {
    init() {
        let coloredAppearance = UINavigationBarAppearance()

        coloredAppearance.configureWithOpaqueBackground()
        coloredAppearance.backgroundColor = .black

        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            OverviewView(
                store: Store(
                    initialState: OverviewFeature.State(),
                    reducer: OverviewFeature()
                )
            )
        }
    }
}
