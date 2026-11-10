import SwiftUI
import FoldPulseCore

/// Event detail: source, time zone, de-duplication info, note; Edit and Delete.
struct EventDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State var event: FoldEvent
    @State private var editing = false
    @State private var confirmDelete = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.type == .fold ? "Fold" : "Unfold").font(.largeTitle.weight(.bold))
                    Text(timeDescription).font(.subheadline).foregroundStyle(FPColor.text2)
                }
                .listRowBackground(Color.clear)
            }
            Section {
                LabeledContent("Source") { SourceBadge(source: event.source) }
                if event.isEdited {
                    LabeledContent("Edited", value: "Yes — the original source is kept")
                        .accessibilityIdentifier("editedRow")
                }
                if let start = event.inferredIntervalStart, let end = event.inferredIntervalEnd {
                    LabeledContent("Missed between", value: "\(start.formatted(date: .abbreviated, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))")
                }
                LabeledContent("Note", value: event.note ?? "—")
            }
            if event.source != .inferred {
                Section {
                    Button("Edit") { editing = true }
                    Button("Delete event", role: .destructive) { confirmDelete = true }
                }
            }
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editing) {
            EditEventSheet(event: event) { updated in
                event = updated
                Task { await model.edit(updated) }
            }
        }
        .confirmationDialog("Delete this event?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await model.delete(event); dismiss() }
            }
        }
    }

    private var timeDescription: String {
        let time = event.timestamp.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: event.timeZone))
        return "\(time) · \(event.timeZoneID)"
    }
}

/// Edit type, time and note (SCREEN_SPECIFICATIONS §5).
struct EditEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: FoldEvent
    @State private var time: Date
    @State private var note: String
    let onSave: (FoldEvent) -> Void

    init(event: FoldEvent, onSave: @escaping (FoldEvent) -> Void) {
        _draft = State(initialValue: event)
        _time = State(initialValue: event.timestamp)
        _note = State(initialValue: event.note ?? "")
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $draft.type) {
                    Text("Fold").tag(EventType.fold)
                    Text("Unfold").tag(EventType.unfold)
                }
                .pickerStyle(.segmented)
                DatePicker("Time", selection: $time, in: ...Date.now)
                    .environment(\.timeZone, draft.timeZone)
                LabeledContent("Source") { SourceBadge(source: draft.source) }
                TextField("Note", text: $note, axis: .vertical)
                    .onChange(of: note) { _, value in if value.count > 500 { note = String(value.prefix(500)) } }
                Text("The original source is kept and the event is marked \"edited\", so totals stay transparent.")
                    .font(.footnote).foregroundStyle(FPColor.text2)
            }
            .navigationTitle("Edit event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = draft
                        updated.setTimestamp(time)
                        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        updated.note = trimmed.isEmpty ? nil : trimmed
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}
