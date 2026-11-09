import SwiftUI
import WidgetKit
import FoldPulseCore

/// Lean-v1 widget set (WIDGET_DESIGN §1): Home small (also StandBy),
/// Lock Screen circular and rectangular. Reads the App Group snapshot only.
struct TodayWidget: Widget {
    static let kind = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SnapshotProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) { FPColor.surface }
        }
        .configurationDisplayName("Today's folds")
        .description("Today's folds and your total since install.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: WidgetSnapshot(generatedAt: .now, localDay: LocalDay(date: .now, timeZone: .current),
                                                           todayFolds: 64, todayUnfolds: 62, totalSinceInstall: 1_284,
                                                           dailyAverage7d: 72, nextMilestone: 5_000))
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : currentEntry(at: .now))
    }

    /// Entries: now; when the data turns stale (to show "as of"); and the next
    /// local midnight (so "today" resets without a reload). The widget re-reads the
    /// snapshot every 30 minutes, so a reload the app throttled is never lost.
    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let now = Date.now
        let midnight = WidgetSnapshot.nextMidnight(after: now, timeZone: .current)
        let snapshot = SnapshotFile.read() ?? .empty(now: now, timeZone: .current)
        var dates = [now]
        let staleAt = snapshot.generatedAt.addingTimeInterval(WidgetSnapshot.staleAfter + 1)
        if staleAt > now && staleAt < midnight { dates.append(staleAt) }
        dates.append(midnight)
        let entries = dates.map { SnapshotEntry(date: $0, snapshot: snapshot) }
        let refresh = min(midnight.addingTimeInterval(60), now.addingTimeInterval(30 * 60))
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    private func currentEntry(at date: Date) -> SnapshotEntry {
        SnapshotEntry(date: date, snapshot: SnapshotFile.read() ?? .empty(now: date, timeZone: .current))
    }
}

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    private var display: WidgetSnapshot.Display { entry.snapshot.display(at: entry.date, timeZone: .current) }
    private var todayText: String { display.todayFolds.map { $0.formatted() } ?? "—" }

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Today").font(.caption.weight(.semibold)).foregroundStyle(FPColor.text2)
                Spacer()
                PulseLine().stroke(FPColor.accent, lineWidth: 1.6).frame(width: 40, height: 10).widgetAccentable()
            }
            Text(todayText)
                .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                .minimumScaleFactor(0.6)
                .widgetAccentable()
                .privacySensitive()
            Text("folds").font(.caption).foregroundStyle(FPColor.text2)
            Spacer(minLength: 0)
            Text("\(display.totalSinceInstall.formatted()) since install")
                .font(.caption2.weight(.semibold))
                .privacySensitive()
            if display.isStale {
                Text("as of \(display.generatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2).foregroundStyle(FPColor.text2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("FoldPulse. \(todayText) folds today. \(display.totalSinceInstall.formatted()) since install.")
    }

    private var circular: some View {
        let average = max(entry.snapshot.dailyAverage7d ?? 0, 1)
        let today = display.todayFolds ?? 0
        return Gauge(value: Double(min(today, average)), in: 0...Double(average)) {
            Text("Folds")
        } currentValueLabel: {
            Text(todayText).privacySensitive()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel("\(todayText) folds today, daily average \(entry.snapshot.dailyAverage7d.map(String.init) ?? "not available yet")")
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("FoldPulse").font(.caption2.weight(.semibold)).opacity(0.8)
            Text("\(todayText) folds today").font(.headline).privacySensitive()
            Text("\(display.totalSinceInstall.formatted()) since install").font(.caption).privacySensitive()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
