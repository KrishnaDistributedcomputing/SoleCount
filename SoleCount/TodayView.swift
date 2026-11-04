import Charts
import SwiftData
import SwiftUI

/// The home tab: today's steps, a short walk, and a reason to head out.
struct TodayView: View {
    @Environment(HealthSync.self) private var health
    @Environment(MotivationStore.self) private var motivation
    @Environment(StoreManager.self) private var store
    @Query(sort: \Sneaker.createdAt, order: .reverse) private var sneakers: [Sneaker]

    @State private var showingWalk = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var steps: Double { motivation.todaySteps() }
    private var week: (thisWeek: Double, lastWeek: Double) {
        MotionMath.weekMeters(days: motivation.days, now: .now, calendar: .current)
    }
    private var wearWeek: (thisWeek: Int, lastWeek: Int) {
        MotionMath.wearCounts(dates: sneakers.flatMap(\.wearDates), now: .now, calendar: .current)
    }
    private var badges: [Badge] {
        HealthCoordinator.badges(motivation: motivation, sneakers: sneakers)
    }
    private var hints: [RotationHint] {
        CollectionMath.forgotten(
            pairs: sneakers.map { ($0.name, $0.lastWorn, $0.isRetired) },
            now: .now,
            calendar: .current
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeroHeader(
                        title: "Today",
                        subtitle: heroSubtitle,
                        symbol: "figure.walk",
                        colors: ShoeTheme.today
                    )
                    rings
                    streakCard
                    weekCard
                    tipCard
                    walkCard
                    if !hints.isEmpty {
                        rotationCard
                    }
                    HealthConnectCard(onConnect: connect, onRefresh: refresh)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Badges")
                            .font(.title3.bold())
                        AchievementGrid(badges: Array(badges.prefix(4)))
                    }
                    stepChart
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                ConfettiBurst(trigger: motivation.celebration)
                    .padding(.top, 40)
            }
            .sheet(isPresented: $showingWalk) {
                WalkNowSheet(
                    plan: MotionMath.walkPlan(
                        stepsToday: Int(steps.rounded()),
                        goal: motivation.stepGoal,
                        healthConnected: health.access == .ready || motivation.days.contains { Calendar.current.isDateInToday($0.day) }
                    )
                )
            }
        }
    }

    private var heroSubtitle: String {
        if health.access == .ready || !motivation.days.isEmpty {
            let left = MotionMath.stepsRemaining(stepsToday: Int(steps.rounded()), goal: motivation.stepGoal)
            if let left {
                return "\(DistanceFormat.steps(Double(left.stepsLeft))) steps to today's goal."
            }
            return "Today's step goal is done. A little extra still feels good."
        }
        return "Log what you wear. Connect Apple Health when you want the steps."
    }

    private var rings: some View {
        HStack(alignment: .top, spacing: 12) {
            ProgressRing(
                progress: motivation.stepGoal > 0 ? steps / Double(motivation.stepGoal) : 0,
                tint: ShoeTheme.today[0],
                label: DistanceFormat.steps(steps),
                caption: "Steps"
            )
            ProgressRing(
                progress: motivation.weeklyKilometers > 0 ? week.thisWeek / (motivation.weeklyKilometers * 1_000) : 0,
                tint: .mint,
                label: DistanceFormat.string(meters: week.thisWeek),
                caption: "This week"
            )
            ProgressRing(
                progress: min(1, Double(motivation.streak()) / 7),
                tint: .orange,
                label: "\(motivation.streak())",
                caption: "Day streak"
            )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var streakCard: some View {
        let paused = motivation.pause() != .none
        return VStack(alignment: .leading, spacing: 8) {
            Text(paused ? "Paused. Your streak is waiting." : "\(motivation.streak())-day streak")
                .font(.headline)
            Text("Best is \(motivation.bestStreak()) days. Changing the step goal does not erase it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(motivation.bankedRestDays() > 0
                 ? "\(motivation.bankedRestDays()) rest day saved. Use it when you need a break."
                 : "A rest day is saved after every 6 days you show up, up to 2.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Menu {
                ForEach(StreakPause.allCases) { pause in
                    Button(pause.title) { motivation.setPause(pause) }
                }
            } label: {
                Label(motivation.pause() == .none ? "Pause for sick, travel, or rest" : "Paused: \(motivation.pause().title)", systemImage: "pause.circle")
            }
            .accessibilityIdentifier("streakPauseMenu")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var weekCard: some View {
        let distanceTrend = MotionMath.trend(current: week.thisWeek, previous: week.lastWeek)
        let wearTrend = MotionMath.trend(current: Double(wearWeek.thisWeek), previous: Double(wearWeek.lastWeek))
        let trend = (health.access == .ready || week.thisWeek > 0 || week.lastWeek > 0) ? distanceTrend : wearTrend
        let line: String = {
            if health.access == .ready || week.thisWeek > 0 || week.lastWeek > 0 {
                return "\(DistanceFormat.string(meters: week.thisWeek)) this week, \(DistanceFormat.string(meters: week.lastWeek)) last week"
            }
            return "\(wearWeek.thisWeek) wears this week, \(wearWeek.lastWeek) last week"
        }()
        return HStack(spacing: 12) {
            Image(systemName: arrow(trend))
                .font(.title2)
                .foregroundStyle(tint(trend))
                .symbolEffect(.bounce, value: trend == .up && !reduceMotion)
            VStack(alignment: .leading, spacing: 4) {
                Text("This week")
                    .font(.headline)
                Text(line)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today's tip", systemImage: "quote.opening")
                .font(.headline)
            Text(MotivationEngine.tip(on: .now, calendar: .current))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Text("Tips are encouragement, not medical advice.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var walkCard: some View {
        Button {
            showingWalk = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Walk now")
                        .font(.headline)
                    Text("A short walk sized to what's left today.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "figure.walk.motion")
                    .font(.title)
                    .symbolEffect(.pulse, isActive: !reduceMotion)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ShoeTheme.today[0].gradient.opacity(0.18))
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens a short walk you can start")
    }

    private var rotationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wear your forgotten pairs")
                .font(.headline)
                .accessibilityIdentifier("forgottenPairsCard")
            ForEach(hints.prefix(3), id: \.name) { hint in
                Text(CollectionMath.hintLine(hint))
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var stepChart: some View {
        let points = MotionMath.lastDays(7, from: motivation.days, now: .now, calendar: .current)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 days")
                .font(.title3.bold())
            Chart(points) { point in
                AreaMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value("Steps", point.steps)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [ShoeTheme.today[0].opacity(0.45), ShoeTheme.today[0].opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                LineMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value("Steps", point.steps)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(ShoeTheme.today[0])
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .frame(height: 160)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Steps for the last 7 days")
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func arrow(_ trend: WeekTrend) -> String {
        switch trend {
        case .up: "arrow.up.circle.fill"
        case .down: "arrow.down.circle.fill"
        case .flat: "equal.circle.fill"
        }
    }

    private func tint(_ trend: WeekTrend) -> Color {
        switch trend {
        case .up: .green
        case .down: .orange
        case .flat: .secondary
        }
    }

    private func connect() {
        Task { await HealthCoordinator.connect(health: health, motivation: motivation, sneakers: sneakers) }
    }

    private func refresh() {
        Task { await HealthCoordinator.refresh(health: health, motivation: motivation, sneakers: sneakers) }
    }
}

/// A simple timer for the suggested walk. It does not use location.
private struct WalkNowSheet: View {
    var plan: MotionMath.WalkPlan
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var running = false
    @State private var elapsed = 0
    @State private var finished = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 56))
                    .foregroundStyle(ShoeTheme.today[0].gradient)
                    .symbolEffect(.bounce, value: running && !reduceMotion)
                    .accessibilityHidden(true)
                Text(headline)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text(timeLabel)
                    .font(.largeTitle.bold())
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Button(running ? "Pause" : (elapsed > 0 && !finished ? "Resume" : "Start")) {
                    running.toggle()
                    if finished {
                        elapsed = 0
                        finished = false
                        running = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .sensoryFeedback(.impact, trigger: running)
            }
            .padding()
            .navigationTitle("Walk now")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task(id: running) {
                guard running else { return }
                while running && elapsed < plan.minutes * 60 {
                    try? await Task.sleep(for: .seconds(1))
                    guard running else { return }
                    elapsed += 1
                }
                if elapsed >= plan.minutes * 60 {
                    running = false
                    finished = true
                }
            }
        }
    }

    private var headline: String {
        if finished { return "Nice walk" }
        if plan.alreadyDone { return "Goal's done. This one is extra." }
        return "\(plan.minutes) minutes"
    }

    private var detail: String {
        if plan.alreadyDone {
            return "About \(plan.steps.formatted()) steps at an easy pace. Stop whenever you like."
        }
        return "About \(plan.steps.formatted()) steps. This is a nudge, not a workout plan."
    }

    private var timeLabel: String {
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
