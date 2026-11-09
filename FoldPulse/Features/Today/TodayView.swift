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
                    // Without verified background counting the total covers folds made with the
                    // app open only — say so (SCREEN_SPECIFICATIONS §2, Phase 2 review).
                    HeroCounter(label: model.backgroundCountingVerified ? "Folds since install" : "Folds counted since install",
                                value: stats.snapshot.totalSinceInstall)
                    MilestoneBar(total: stats.snapshot.totalSinceInstall)
                    if !model.hasSeenHinge {
                        manualOnlyCard
                    }
                    if stats.snapshot.totalSinceInstall == 0 {
                        emptyCard
                    } else {
                        HStack(spacing: FPSpace.m) {
                            StatTile(label: "Today", value: stats.snapshot.todayFolds,
                                     caption: "\(stats.snapshot.todayUnfolds) unfolds")
                            StatTile(label: "Daily average", value: stats.snapshot.dailyAverage7d, caption: "last 7 full days")
                        }
                        if model.hasSeenHinge {
                            if model.backgroundCountingVerified {
                                NavigationLink { CoverageView() } label: { CoverageTile(coverage: stats.coverage) }
                                    .buttonStyle(.plain)
                            } else {
                                foregroundOnlyCard
                            }
                        }
                        VStack(alignment: .leading) {
                            Text("Last 7 days").font(.headline)
                            WeekChart(series: stats.lastSevenDays)
                        }
                        .fpCard()
                        if let last = model.lastEvent {
                            HStack(spacing: 6) {
                                Text("Last: \(last.type == .fold ? "Fold" : "Unfold") · \(last.timestamp, format: .relative(presentation: .named))")
                                    .font(FPFont.caption).foregroundStyle(FPColor.text2)
                                SourceBadge(source: last.source)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    if let error = model.lastError {
                        Text(error).font(.footnote).foregroundStyle(FPColor.destructive)
                    }
                }
                .padding(.horizontal)
            }
            .background(FPColor.background)
            .navigationTitle("Today")
            .toolbar {
                // Icon + title: the outer display shows bars vertically (SCREEN_SPECIFICATIONS §0).
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Record", systemImage: "plus") { showingRecord = true }
                }
            }
            .sheet(isPresented: $showingRecord) { RecordSheet() }
            .sheet(isPresented: milestoneBinding) {
                if let milestone = model.pendingMilestone {
                    MilestoneSheet(milestone: milestone) { model.dismissMilestone() }
                }
            }
        }
    }

    @State private var showingRecord = false

    private var milestoneBinding: Binding<Bool> {
        Binding(get: { model.pendingMilestone != nil && !showingRecord },
                set: { if !$0 { model.dismissMilestone() } })
    }

    /// Background counting not set up (the likely default): explain what's missed.
    private var foregroundOnlyCard: some View {
        NavigationLink { SetupView() } label: {
            HStack(alignment: .top, spacing: FPSpace.m) {
                Image(systemName: "exclamationmark.triangle").foregroundStyle(FPColor.warning)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Counting only while FoldPulse is open").font(.headline).foregroundStyle(FPColor.text)
                    Text("Folds made with the app closed aren't counted yet. Add the optional Shortcuts automation to count them too.")
                        .font(.subheadline).foregroundStyle(FPColor.text2)
                    Text("Set up background counting").font(.subheadline.weight(.semibold)).foregroundStyle(FPColor.accentText)
                }
            }
            .fpCard()
        }
        .buttonStyle(.plain)
    }

    /// Shown until a hinge reading has ever been received (non-Duo devices, D-4).
    private var manualOnlyCard: some View {
        HStack(alignment: .top, spacing: FPSpace.m) {
            Image(systemName: "hand.tap").foregroundStyle(FPColor.accentText)
            VStack(alignment: .leading, spacing: 4) {
                Text("Waiting for the hinge").font(.headline)
                Text("Automatic counting needs iPhone Duo. On other iPhones you can record folds by hand with Record.")
                    .font(.subheadline).foregroundStyle(FPColor.text2)
            }
        }
        .fpCard()
        .accessibilityElement(children: .combine)
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
