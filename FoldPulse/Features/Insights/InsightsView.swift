import SwiftUI
import Charts
import FoldPulseCore

/// Insights (SCREEN_SPECIFICATIONS §6): day / week / month / year.
struct InsightsView: View {
    @Environment(AppModel.self) private var model
    @State private var period: InsightPeriod = .week
    @State private var summary: PeriodSummary?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FPSpace.m) {
                    Picker("Period", selection: $period) {
                        Text("Day").tag(InsightPeriod.day)
                        Text("Week").tag(InsightPeriod.week)
                        Text("Month").tag(InsightPeriod.month)
                        Text("Year").tag(InsightPeriod.year)
                    }
                    .pickerStyle(.segmented)

                    if let summary {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(periodTitle(summary)).font(FPFont.label).foregroundStyle(FPColor.text2)
                            HStack(alignment: .firstTextBaseline) {
                                Text(summary.total, format: .number).font(.system(.largeTitle, design: .rounded).weight(.bold))
                                Text(summary.total == 1 ? "fold" : "folds").font(.headline).foregroundStyle(FPColor.text2)
                            }
                            if let previous = summary.previousTotal {
                                Text("Previous \(previousName): \(previous.formatted())").font(FPFont.caption).foregroundStyle(FPColor.text2)
                            }
                        }
                        .accessibilityElement(children: .combine)

                        chart(summary).fpCard()

                        HStack(spacing: FPSpace.m) {
                            if summary.period != .day {
                                StatTile(label: "Busiest day", value: summary.busiestDay?.count,
                                         caption: summary.busiestDay.map { $0.day.start(in: .current).formatted(.dateTime.weekday(.abbreviated).month().day()) } ?? "—")
                                StatTile(label: "Avg per day", value: summary.averagePerFullDay.map { Int($0.rounded()) }, caption: "full days only")
                            } else {
                                StatTile(label: "Today", value: summary.total, caption: "so far")
                                StatTile(label: "Daily average", value: model.dashboard.snapshot.dailyAverage7d, caption: "last 7 full days")
                            }
                        }
                        CoverageTile(coverage: model.dashboard.coverage)
                        Text("Averages use full days only, from the first day you tracked. Gaps are not counted.")
                            .font(FPFont.caption).foregroundStyle(FPColor.text2)
                    } else {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
            }
            .background(FPColor.background)
            .navigationTitle("Insights")
            .task(id: TaskKey(period: period, version: model.dashboard.snapshot.generatedAt)) {
                summary = await model.summary(period)
            }
        }
    }

    private struct TaskKey: Equatable {
        let period: InsightPeriod
        let version: Date
    }

    private var previousName: String {
        switch period {
        case .day: return "day"
        case .week: return "7 days"
        case .month: return "month"
        case .year: return "year"
        }
    }

    private func periodTitle(_ s: PeriodSummary) -> String {
        switch s.period {
        case .day: return "Today so far"
        case .week: return "Last 7 days (incl. today so far)"
        case .month: return "This month"
        case .year: return "This year"
        }
    }

    private func chart(_ s: PeriodSummary) -> some View {
        Chart(Array(s.buckets.enumerated()), id: \.offset) { _, bucket in
            BarMark(x: .value("Period", label(bucket.key)), y: .value("Folds", bucket.count))
                .foregroundStyle(bucket.isCurrent ? FPColor.accent : FPColor.accent.opacity(0.45))
                .cornerRadius(3)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: s.period == .day ? 6 : 7)) { _ in AxisValueLabel() }
        }
        .frame(height: 180)
        .accessibilityLabel("Folds per \(s.period == .day ? "hour" : s.period == .year ? "month" : "day")")
    }

    private func label(_ key: PeriodBucket.Key) -> String {
        switch key {
        case .hour(let h): return String(h)
        // Labels must be unique per bar: 7 consecutive weekdays, day numbers and month names all are.
        case .day(let d): return period == .week ? d.start(in: .current).formatted(.dateTime.weekday(.abbreviated)) : String(d.day)
        case .month(_, let m): return Calendar.current.shortMonthSymbols[m - 1]
        }
    }
}
