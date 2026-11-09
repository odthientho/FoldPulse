import SwiftUI

/// Placeholder until Phase 4 (Insights: D/W/M/Y charts, averages, busiest day).
struct InsightsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Insights", systemImage: "chart.bar.xaxis",
                                   description: Text("Trends and averages arrive in the next build."))
                .navigationTitle("Insights")
        }
    }
}
