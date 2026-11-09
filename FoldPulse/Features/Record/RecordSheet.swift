import SwiftUI
import FoldPulseCore

/// Manual recording with Undo (F4, SCREEN_SPECIFICATIONS §3).
struct RecordSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var recorded: FoldEvent?
    @State private var recordCount = 0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: FPSpace.m) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hinge right now").font(FPFont.label).foregroundStyle(FPColor.text2)
                    Text(model.hinge.liveLabel).font(.title2.weight(.bold))
                    Text(model.hasSeenHinge ? "Automatic counting is on while FoldPulse is open." :
                            "Automatic counting needs iPhone Duo; you can record by hand.")
                        .font(FPFont.caption).foregroundStyle(FPColor.text2)
                }
                .fpCard(radius: FPRadius.tile)
                .accessibilityElement(children: .combine)

                Button { record(.fold) } label: { Text("Record Fold").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.extraLarge)
                    .sensoryFeedback(.increase, trigger: recordCount)
                Button { record(.unfold) } label: { Text("Record Unfold").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered)
                    .controlSize(.extraLarge)

                if let recorded {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(FPColor.positive)
                        Text("\(recorded.type == .fold ? "Fold" : "Unfold") recorded · Manual").font(.subheadline.weight(.semibold))
                        Spacer()
                        Button("Undo") {
                            Task { await model.undo(recorded) }
                            self.recorded = nil
                        }
                        .font(.subheadline.weight(.bold))
                    }
                    .fpCard(radius: FPRadius.tile)
                    .transition(.opacity)
                }

                Text("Use manual recording only for folds FoldPulse missed. Folds made while the app is open are already counted automatically.")
                    .font(FPFont.caption).foregroundStyle(FPColor.text2)
                Spacer(minLength: 0)
            }
            .padding()
            .background(FPColor.background)
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func record(_ type: EventType) {
        Task {
            guard let event = await model.record(type, source: .manual) else { return }
            recordCount += 1
            withAnimation { recorded = event }
            // Undo stays until the sheet closes or the next record: no timing barrier for
            // anyone, including Voice Control and Full Keyboard Access users (WCAG 2.2.1).
            AccessibilityNotification.Announcement("\(type == .fold ? "Fold" : "Unfold") recorded. Undo is available.").post()
        }
    }
}
