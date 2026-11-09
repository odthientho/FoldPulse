import SwiftUI
import FoldPulseCore

/// Coverage detail (SCREEN_SPECIFICATIONS §7, US-12).
struct CoverageView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let coverage = model.dashboard.coverage
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Counted for you · this week").font(FPFont.label).foregroundStyle(FPColor.text2)
                    if let share = coverage.countedForYouShare {
                        Text(share, format: .percent.precision(.fractionLength(0))).font(.system(.largeTitle, design: .rounded).weight(.bold))
                        Text("of \(coverage.recordedFolds.formatted()) recorded folds").font(FPFont.caption).foregroundStyle(FPColor.text2)
                    } else {
                        Text("No folds recorded this week yet").font(.headline)
                    }
                }
                .accessibilityElement(children: .combine)
                .listRowBackground(Color.clear)
            }
            Section("By source") {
                row(.hinge, coverage.hinge, coverage.recordedFolds)
                row(.shortcut, coverage.shortcut, coverage.recordedFolds)
                row(.manual, coverage.manual, coverage.recordedFolds)
                LabeledContent { Text("\(coverage.gaps) · not counted") } label: { SourceBadge(source: .inferred) }
            }
            Section("Background counting") {
                NavigationLink { SetupView() } label: { BackgroundStatusRow() }
            }
            Section {
                Text("\"Counted for you\" is the share of recorded folds that FoldPulse or your automation captured without you tapping. Folds that were missed entirely can't be included; gaps show where FoldPulse knows something was missed.")
                    .font(.footnote).foregroundStyle(FPColor.text2)
            }
        }
        .navigationTitle("Coverage")
    }

    private func row(_ source: DetectionSource, _ count: Int, _ total: Int) -> some View {
        LabeledContent {
            Text(total == 0 ? "\(count)" : "\(count) · \(Double(count) / Double(total), format: .percent.precision(.fractionLength(0)))")
        } label: {
            SourceBadge(source: source)
        }
    }
}

/// One-line background-counting status used in Coverage and Settings.
struct BackgroundStatusRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.selfTestVersion
        VStack(alignment: .leading, spacing: 2) {
            Text("Shortcuts automation").font(.body)
            Text(status).font(.footnote).foregroundStyle(FPColor.text2)
        }
    }

    private var status: String {
        let lastRun = model.lastAutomationRun
        switch model.selfTestState {
        case .passed(let date):
            if let lastRun, Date.now.timeIntervalSince(lastRun) > 24 * 3600 {
                return "No automation run in 24 h — check the automations"
            }
            if let lastRun { return "Working · last run \(lastRun.formatted(.relative(presentation: .named)))" }
            return "Self-test passed \(date.formatted(date: .abbreviated, time: .omitted))"
        case .waiting:
            return "Self-test in progress"
        case .failed:
            return "Self-test failed — tap for details"
        case .notRun:
            return lastRun == nil ? "Not set up — optional" : "Runs seen · self-test not run"
        }
    }
}
