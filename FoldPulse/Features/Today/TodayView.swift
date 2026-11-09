import SwiftUI
import FoldPulseCore

/// Today dashboard (SCREEN_SPECIFICATIONS §2) using real data from the store.
/// Recording and live hinge counting are wired up in Phase 4.
struct TodayView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FPSpace.m) {
                    let stats = TodayStats(events: model.events, now: .now, timeZone: .current)
                    HeroCounter(label: "Folds since install", value: stats.total)
                    MilestoneBar(total: stats.total)
                    if stats.total == 0 {
                        emptyCard
                    } else {
                        HStack(spacing: FPSpace.m) {
                            StatTile(label: "Today", value: stats.todayFolds, caption: "\(stats.todayUnfolds) unfolds")
                            StatTile(label: "Daily average", value: stats.dailyAverage, caption: "last 7 full days")
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

/// Derived dashboard numbers (pure; computed from the event log).
struct TodayStats {
    let total: Int
    let todayFolds: Int
    let todayUnfolds: Int
    let dailyAverage: Int?
    let coverage: Coverage
    let lastSevenDays: [DayCount]

    init(events: [FoldEvent], now: Date, timeZone: TimeZone) {
        let snapshot = WidgetSnapshot.make(from: events, now: now, timeZone: timeZone)
        let today = snapshot.localDay
        let week = LocalDay.range(from: today.adding(days: -6), through: today)
        total = snapshot.totalSinceInstall
        todayFolds = snapshot.todayFolds
        todayUnfolds = snapshot.todayUnfolds
        dailyAverage = snapshot.dailyAverage7d
        coverage = Statistics.coverage(events, days: Set(week))
        lastSevenDays = Statistics.series(events, days: week)
    }
}
