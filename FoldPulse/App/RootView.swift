import SwiftUI

/// Four tabs (SCREEN_SPECIFICATIONS §0). The system decides whether bars are
/// horizontal, vertical (outer display) or a sidebar — never custom-drawn.
struct RootView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "waveform.path.ecg") { TodayView() }
            Tab("History", systemImage: "list.bullet.rectangle") { HistoryView() }
            Tab("Insights", systemImage: "chart.bar.xaxis") { InsightsView() }
            Tab("Settings", systemImage: "gearshape") { SettingsView() }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
