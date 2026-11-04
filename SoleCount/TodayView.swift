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
    @State private var showingAdd = false
    @State private var gameBurst = 0
    @State private var cheer: String?
    @AppStorage("feedbackNudgeDismissed") private var feedbackNudgeDismissed = false
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
                    if sneakers.isEmpty {
                        welcomeCard
                    }
                    if let cheer {
                        cheerCard(cheer)
                            .transition(.scale.combined(with: .opacity))
                    }
                    if !motivation.starterQuestDone && !quest.isComplete {
                        questCard
                    }
                    if !sneakers.isEmpty {
                        levelCard
                        challengeCard
                    }
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
                        AchievementGrid(badges: Array(badges.prefix(4)), celebrate: motivation.celebration)
                    }
                    stepChart
                    if showFeedbackNudge {
                        feedbackNudge
                    }
                }
                .padding()
            }
            .background(ShoeTheme.canvas)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                ConfettiBurst(trigger: motivation.celebration)
                    .padding(.top, 40)
            }
            .overlay(alignment: .top) {
                ConfettiBurst(trigger: gameBurst)
                    .padding(.top, 120)
            }
            .task(id: gameKey) { checkGame() }
            .sheet(isPresented: $showingAdd) { AddSneakerView() }
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
                tint: ShoeTheme.coralTint,
                label: DistanceFormat.steps(steps),
                caption: "Steps"
            )
            ProgressRing(
                progress: motivation.weeklyKilometers > 0 ? week.thisWeek / (motivation.weeklyKilometers * 1_000) : 0,
                tint: ShoeTheme.mintTint,
                label: DistanceFormat.string(meters: week.thisWeek),
                caption: "This week"
            )
            ProgressRing(
                progress: min(1, Double(motivation.streak()) / 7),
                tint: ShoeTheme.goldTint,
                label: "\(motivation.streak())",
                caption: "Day streak"
            )
        }
        .padding()
        .warmCard()
    }

    /// After 10 logged wears, a gentle ask for ideas. Hidden forever once closed.
    private var showFeedbackNudge: Bool {
        !feedbackNudgeDismissed && !LaunchFlags.screenshots && sneakers.reduce(0) { $0 + $1.wearDates.count } >= 10
    }

    private var feedbackNudge: some View {
        HStack(spacing: 12) {
            FeedbackButton(kind: .idea) {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(ShoeTheme.goldTint)
                        .accessibilityHidden(true)
                    Text("Enjoying SoleCount? Tell me what to build next")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("feedbackNudge")
            Button {
                feedbackNudgeDismissed = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(ShoeTheme.softText)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Hide this")
            .accessibilityIdentifier("dismissFeedbackNudge")
        }
        .padding(.leading)
        .padding(.vertical, 4)
        .padding(.trailing, 4)
        .warmCard()
    }

    private var streakCard: some View {

        VStack(alignment: .leading, spacing: 8) {
            Text(streakTitle)
                .font(.headline)
            Text("Best is \(motivation.bestStreak()) days. Changing the step goal does not erase it.")
                .font(.subheadline)
                .foregroundStyle(ShoeTheme.softText)
                .fixedSize(horizontal: false, vertical: true)
            Text(motivation.bankedRestDays() > 0
                 ? "\(motivation.bankedRestDays()) rest day saved. Use it when you need a break."
                 : "A rest day is saved after every 6 days you show up, up to 2.")
                .font(.footnote)
                .foregroundStyle(ShoeTheme.softText)
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
        .warmCard()
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
                .symbolEffect(.bounce, value: trend == .up && !reduceMotion && !LaunchFlags.screenshots)
            VStack(alignment: .leading, spacing: 4) {
                Text("This week")
                    .font(.headline)
                Text(line)
                    .font(.subheadline)
                    .foregroundStyle(ShoeTheme.softText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .warmCard()
        .accessibilityElement(children: .combine)
    }

    private var streakTitle: String {
        if motivation.pause() != .none { return "Paused. Your streak is safe and waiting." }
        let days = motivation.streak()
        if days == 0 { return "Your streak starts with your next walk." }
        return "\(days)-day streak. Look at you."
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("A good thought", systemImage: "sun.horizon.fill")
                .font(.headline)
            Text(MotivationEngine.affirmation(on: .now, calendar: .current))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Label("Today's tip", systemImage: "quote.opening")
                .font(.headline)
                .padding(.top, 4)
            Text(MotivationEngine.tip(on: .now, calendar: .current))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Text("Kind words and a walking idea. Not medical advice.")
                .font(.caption)
                .foregroundStyle(ShoeTheme.softText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
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
                        .foregroundStyle(ShoeTheme.softText)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "figure.walk.motion")
                    .font(.title)
                    .symbolEffect(.pulse, isActive: !reduceMotion && !LaunchFlags.screenshots)
            }
            .padding()
            .background(ShoeTheme.cardFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(ShoeTheme.today[0].opacity(0.16))
            )
            .shadow(color: ShoeTheme.shadow.opacity(0.22), radius: 12, y: 6)
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
        .warmCard()
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
                .foregroundStyle(ShoeTheme.coralTint)
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
            .warmCard()
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
        case .up: ShoeTheme.mintTint
        case .down: ShoeTheme.goldTint
        case .flat: ShoeTheme.softText
        }
    }

    // MARK: - Welcome, quest, level, and weekly challenge

    private var gameLevel: SoleLevel {
        let wears = sneakers.reduce(0) { $0 + $1.wearCount }
        let meters = sneakers.reduce(0) { $0 + $1.totalMeters }
        let earned = badges.filter(\.unlocked).count
        return SoleGame.level(xp: SoleGame.xp(wears: wears, meters: meters, badges: earned))
    }

    private var quest: StarterQuest {
        SoleGame.starterQuest(
            pairCount: sneakers.count,
            loggedWears: sneakers.reduce(0) { $0 + $1.wearDates.count },
            wearsThisWeek: wearWeek.thisWeek
        )
    }

    private var usesMiles: Bool { DistanceFormat.usesMiles(forceMetric: LaunchFlags.screenshots) }

    private var activeWearDates: [[Date]] {
        sneakers.filter { !$0.isRetired }.map(\.wearDates)
    }

    private var challenge: WeeklyChallenge {
        SoleGame.challenge(
            for: .now,
            calendar: .current,
            activePairs: activeWearDates.count,
            hasDistance: health.access == .ready || week.thisWeek > 0 || week.lastWeek > 0,
            usesMiles: usesMiles
        )
    }

    private var gameKey: String {
        "\(gameLevel.number)-\(quest.doneCount)-\(sneakers.count)"
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Every great walk starts with one pair 👟")
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
            Text("Add your sneakers and watch every step count.")
                .font(.body)
                .foregroundStyle(ShoeTheme.softText)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                if StoreManager.canAddPair(currentCount: sneakers.count, isPro: store.isPro) {
                    showingAdd = true
                }
            } label: {
                Label("Add my first pair", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SunriseButtonStyle())
            .accessibilityIdentifier("addFirstPairToday")
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(ShoeTheme.glow.opacity(0.6), lineWidth: 1.5)
        )
    }

    private var questCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Starter quest", systemImage: "map.fill")
                    .font(.headline)
                Spacer()
                Text("\(quest.doneCount) of 3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ShoeTheme.softText)
            }
            questRow("Add your first pair", done: quest.addedPair)
            questRow("Log your first wear", done: quest.loggedWear)
            questRow("Log 3 wears this week", done: quest.threeWearsThisWeek)
            Text("Finish all three to earn the Quest complete badge.")
                .font(.footnote)
                .foregroundStyle(ShoeTheme.softText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
        .accessibilityIdentifier("starterQuestCard")
    }

    private func questRow(_ title: String, done: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(done ? ShoeTheme.mintTint : ShoeTheme.softText)
                .accessibilityHidden(true)
            Text(title)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(done ? "\(title), done" : "\(title), not done yet")
    }

    private var levelCard: some View {
        let level = gameLevel
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text("\(level.number)")
                    .font(.title3.bold())
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(ShoeTheme.goldTint.opacity(0.22)))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sole Level \(level.number)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ShoeTheme.softText)
                    Text(level.name)
                        .font(.headline)
                }
                Spacer(minLength: 8)
                Text("\(level.xp.formatted()) XP")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            SunriseBar(fraction: level.progress, tint: ShoeTheme.goldTint)
            Text(levelLine(level))
                .font(.subheadline)
                .foregroundStyle(ShoeTheme.softText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("soleLevelCard")
    }

    private func levelLine(_ level: SoleLevel) -> String {
        guard let next = level.nextName, let left = level.xpToNext else {
            return "Top level. Every walk still counts."
        }
        return "\(left.formatted()) XP to \(next). Wears, distance, and badges all add XP."
    }

    private var challengeCard: some View {
        let challenge = challenge
        let progress = SoleGame.progress(
            of: challenge,
            pairWearDates: activeWearDates,
            weekMeters: week.thisWeek,
            now: .now,
            calendar: .current
        )
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: progress.isDone ? "checkmark.seal.fill" : challenge.symbol)
                .font(.title2)
                .foregroundStyle(progress.isDone ? ShoeTheme.mintTint : ShoeTheme.coralTint)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text("This week's challenge")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ShoeTheme.softText)
                Text(challenge.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                SunriseBar(fraction: progress.fraction, tint: progress.isDone ? ShoeTheme.mintTint : ShoeTheme.coralTint)
                Text(SoleGame.challengeLine(challenge, progress: progress, usesMiles: usesMiles))
                    .font(.subheadline)
                    .foregroundStyle(ShoeTheme.softText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("weeklyChallengeCard")
    }

    private func cheerCard(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(ShoeTheme.goldTint)
                .accessibilityHidden(true)
            Text(text)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                cheer = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(ShoeTheme.softText)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Close")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(ShoeTheme.goldTint.opacity(0.7), lineWidth: 1.5)
        )
    }

    /// Marks the quest done and celebrates a new level once. The first look stays quiet.
    private func checkGame() {
        var message: String?
        if quest.isComplete && !motivation.starterQuestDone {
            motivation.markStarterQuestDone()
            message = "Starter quest complete. You earned the Quest complete badge."
        }
        let level = gameLevel
        if let up = SoleGame.levelToCelebrate(current: level.number, lastCelebrated: motivation.celebratedLevel) {
            message = "Level up! You're a \(level.name) now. Lovely walking."
            motivation.setCelebratedLevel(up)
        } else if level.number > (motivation.celebratedLevel ?? 0) {
            motivation.setCelebratedLevel(level.number)
        }
        guard let message, !LaunchFlags.screenshots else { return }
        if reduceMotion {
            cheer = message
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { cheer = message }
        }
        gameBurst += 1
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
                    .foregroundStyle(ShoeTheme.softText)
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
                .buttonStyle(SunriseButtonStyle())
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
