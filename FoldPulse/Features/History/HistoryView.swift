import SwiftUI
import FoldPulseCore

/// Basic chronological list (filters, edit and delete arrive in Phase 4).
struct HistoryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                if model.recentEvents.isEmpty {
                    ContentUnavailableView("No folds yet", systemImage: "list.bullet.rectangle",
                                           description: Text("Your folds and unfolds will appear here."))
                } else {
                    List(model.recentEvents) { event in
                        EventRow(event: event)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct EventRow: View {
    let event: FoldEvent

    var body: some View {
        HStack {
            Text(event.timestamp, format: .dateTime.hour().minute())
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(FPColor.text2)
                .frame(width: 56, alignment: .leading)
            Text(event.type == .fold ? "Fold" : "Unfold").font(.body.weight(.medium))
            Spacer()
            SourceBadge(source: event.source, compact: true)
        }
        .accessibilityElement(children: .combine)
    }
}
