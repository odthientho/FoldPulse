import SwiftUI
import Charts
import FoldPulseCore

/// Last-7-days bar chart; the final bar (today) is highlighted.
struct WeekChart: View {
    let series: [DayCount]

    var body: some View {
        Chart(Array(series.enumerated()), id: \.offset) { index, item in
            BarMark(x: .value("Day", item.day.description), y: .value("Folds", item.count))
                .foregroundStyle(index == series.count - 1 ? FPColor.accent : FPColor.accent.opacity(0.45))
                .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let raw = value.as(String.self), let day = LocalDay(string: raw) { Text(Self.weekdayInitial(day)) }
                }
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 120)
        .accessibilityLabel("Folds over the last 7 days")
    }

    static func weekdayInitial(_ day: LocalDay) -> String {
        let date = day.start(in: .current)
        return date.formatted(.dateTime.weekday(.narrow))
    }
}
