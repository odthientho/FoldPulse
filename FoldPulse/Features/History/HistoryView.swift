import SwiftUI
import FoldPulseCore

/// History (SCREEN_SPECIFICATIONS §4): filters, day sections, edit and delete.
struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @State private var filter: SourceFilter = .all
    @State private var range: DateRange = .sevenDays
    @State private var events: [FoldEvent] = []
    @State private var pendingDelete: FoldEvent?

    enum SourceFilter: String, CaseIterable, Identifiable {
        case all = "All", automatic = "Auto", shortcut = "Shortcut", manual = "Manual", gaps = "Gaps"
        var id: String { rawValue }
        var sources: Set<DetectionSource>? {
            switch self {
            case .all: return nil
            case .automatic: return [.hinge]
            case .shortcut: return [.shortcut]
            case .manual: return [.manual]
            case .gaps: return [.inferred]
            }
        }
    }

    enum DateRange: String, CaseIterable, Identifiable {
        case today = "Today", sevenDays = "Last 7 days", thirtyDays = "Last 30 days", all = "All time"
        var id: String { rawValue }
        var since: Date? {
            let today = LocalDay(date: .now, timeZone: .current)
            switch self {
            case .today: return today.start(in: .current)
            case .sevenDays: return today.adding(days: -6).start(in: .current)
            case .thirtyDays: return today.adding(days: -29).start(in: .current)
            case .all: return nil
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Source", selection: $filter) {
                        ForEach(SourceFilter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }
                if events.isEmpty {
                    ContentUnavailableView("No events", systemImage: "list.bullet.rectangle",
                                           description: Text("Nothing recorded for this filter and range."))
                        .listRowBackground(Color.clear)
                }
                ForEach(groupedDays) { group in
                    Section {
                        ForEach(group.events) { event in
                            NavigationLink(value: event) { EventRow(event: event) }
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", role: .destructive) { requestDelete(event) }
                                }
                        }
                    } header: {
                        Text(header(for: group.day, folds: group.events.filter { $0.type == .fold && $0.source != .inferred }.count))
                    }
                }
                if filter == .all || filter == .gaps, events.contains(where: { $0.source == .inferred }) {
                    Text("A gap marks an event FoldPulse knows was missed (two folds in a row mean an unfold was missed). Gaps are not counted in totals.")
                        .font(.footnote).foregroundStyle(FPColor.text2)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: FoldEvent.self) { EventDetailView(event: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Range", selection: $range) {
                            ForEach(DateRange.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label(range.rawValue, systemImage: "calendar")
                    }
                }
            }
            .confirmationDialog("Delete this event?", isPresented: deleteBinding, titleVisibility: .visible, presenting: pendingDelete) { event in
                Button("Delete", role: .destructive) { Task { await model.delete(event); await load() } }
            } message: { event in
                Text("This \(event.source.label.lowercased()) event was recorded automatically. Delete it only if it's wrong.")
            }
            .task(id: TaskKey(filter: filter, range: range, version: model.dashboard.snapshot.generatedAt)) { await load() }
        }
    }

    private struct TaskKey: Equatable {
        let filter: SourceFilter
        let range: DateRange
        let version: Date
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    private func requestDelete(_ event: FoldEvent) {
        if event.source == .hinge || event.source == .shortcut {
            pendingDelete = event
        } else {
            Task { await model.delete(event); await load() }
        }
    }

    private func load() async {
        events = await model.history(since: range.since, sources: filter.sources)
    }

    private struct DayGroup: Identifiable {
        let day: LocalDay
        let events: [FoldEvent]
        var id: LocalDay { day }
    }

    private var groupedDays: [DayGroup] {
        var order: [LocalDay] = []
        var groups: [LocalDay: [FoldEvent]] = [:]
        for event in events {
            if groups[event.localDay] == nil { order.append(event.localDay) }
            groups[event.localDay, default: []].append(event)
        }
        return order.map { DayGroup(day: $0, events: groups[$0] ?? []) }
    }

    private func header(for day: LocalDay, folds: Int) -> String {
        let today = LocalDay(date: .now, timeZone: .current)
        let name: String
        if day == today { name = "Today" } else if day == today.adding(days: -1) { name = "Yesterday" } else {
            name = day.start(in: .current).formatted(.dateTime.weekday(.abbreviated).month().day())
        }
        return "\(name) · \(folds) \(folds == 1 ? "fold" : "folds")"
    }
}

struct EventRow: View {
    let event: FoldEvent

    var body: some View {
        HStack {
            Text(event.source == .inferred ? "—" : event.timestamp.formatted(.dateTime.hour().minute()))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(FPColor.text2)
                .frame(width: 56, alignment: .leading)
            Text(title).font(.body.weight(.medium))
            if event.note != nil || event.isEdited {
                Image(systemName: "pencil").font(.caption).foregroundStyle(FPColor.text2)
                    .accessibilityLabel(event.isEdited ? "Edited" : "Has a note")
            }
            Spacer()
            SourceBadge(source: event.source, compact: true)
        }
        .opacity(event.source == .inferred ? 0.75 : 1)
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        let base = event.type == .fold ? "Fold" : "Unfold"
        return event.source == .inferred ? "\(base) (gap)" : base
    }
}
