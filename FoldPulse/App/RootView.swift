import SwiftUI

/// Four tabs (SCREEN_SPECIFICATIONS §0). The system decides whether bars are
/// horizontal, vertical (outer display) or a sidebar — never custom-drawn.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @AppStorage(AppSettings.Key.theme, store: AppServices.sharedDefaults) private var theme = AppTheme.system.rawValue
    @AppStorage(AppSettings.Key.onboarding, store: AppServices.sharedDefaults) private var onboarded = false

    var body: some View {
        TabView {
            Tab("Today", systemImage: "waveform.path.ecg") { TodayView() }
            Tab("History", systemImage: "list.bullet.rectangle") { HistoryView() }
            Tab("Insights", systemImage: "chart.bar.xaxis") { InsightsView() }
            Tab("Settings", systemImage: "gearshape") { SettingsView() }
        }
        .tabViewStyle(.sidebarAdaptable)
        .preferredColorScheme(AppTheme(rawValue: theme)?.colorScheme)
        .fullScreenCover(isPresented: Binding(get: { !onboarded && !model.services.isUITesting },
                                              set: { if !$0 { onboarded = true } })) {
            OnboardingView { onboarded = true }
        }
    }
}
