import SwiftUI
import FoldPulseCore

/// Today dashboard (SCREEN_SPECIFICATIONS §2) using real data from the store.
/// Numbers are computed off the main thread by `EventStore.loadState`.
/// Recording and live hinge counting are wired up in Phase 4.
struct TodayView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let stats = model.dashboard
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FPSpace.m) {
                    HeroCounter(label: "Folds since install", value: stats.snapshot.totalSinceInstall)
                    MilestoneBar(total: stats.snapshot.totalSinceInstall)
                    if stats.snapshot.totalSinceInstall == 0 {
                        emptyCard
                    } else {
                        HStack(spacing: FPSpace.m) {
                            StatTile(label: "Today", value: stats.snapshot.todayFolds,
                                     caption: "\(stats.snapshot.todayUnfolds) unfolds")
                            StatTile(label: "Daily average", value: stats.snapshot.dailyAverage7d, caption: "last 7 full days")
                        }
                        CoverageTile(coverage: stats.coverage)
                        VStack(alignment: .leading) {
                            Text("Last 7 days").font(.headline)
                            WeekChart(series: stats.lastSevenDays)
                        }
                        .fpCard()
                    }
                    if let error = model.lastError {
                        Text(error).font(.footnote).foregroundStyle(FPColor.destructive)
                    }
                }
                .padding(.horizontal)
            }
            .background(FPColor.background)
            .navigationTitle("Today")
        }
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ready when you are").font(.headline)
            Text("Close and open your iPhone while FoldPulse is open, and watch the count start.")
                .font(.subheadline).foregroundStyle(FPColor.text2)
        }
        .fpCard()
    }
}
