import SwiftData
import SwiftUI

/// The whole collection in one place: wears, distance, value, and badges.
struct StatsDashboardView: View {
    @Environment(MotivationStore.self) private var motivation
    @Query(sort: \Sneaker.createdAt, order: .reverse) private var sneakers: [Sneaker]

    private var logging: LoggingConsistency {
        LoggingConsistencyMath.evaluate(
            wearDates: sneakers.flatMap(\.wearDates),
            now: .now,
            calendar: .current
        )
    }

    private var summary: CollectionSummary {
        CollectionMath.summarize(
            pairs: sneakers.map { $0.asPairStats() },
            wearDays: logging.qualifyingDays,
            now: .now,
            calendar: .current
        )
    }

    private var badges: [Badge] {
        HealthCoordinator.badges(motivation: motivation, sneakers: sneakers)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if sneakers.isEmpty {
                        ContentUnavailableView {
                            Label("Stats will bloom here", systemImage: "chart.bar")
                        } description: {
                            Text("Add a pair and log a wear. The good numbers show up after that.")
                        }
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            stat("Pairs", value: "\(summary.pairCount)", symbol: "shoe.2.fill")
                            stat("Wears", value: "\(summary.totalWears)", symbol: "figure.walk")
                            stat("Distance", value: DistanceFormat.string(meters: summary.totalMeters), symbol: "point.bottomleft.forward.to.point.topright.scurvepath")
                            stat("Steps", value: DistanceFormat.steps(summary.totalSteps), symbol: "shoe.fill")
                            stat("Value", value: summary.collectionValue.asCurrency, symbol: "tag.fill")
                            stat("Per wear", value: summary.averageCostPerWear?.asCurrency ?? "–", symbol: "divide")
                        }
                        highlight("Most worn", name: summary.mostWorn, symbol: "star.fill")
                        highlight("Ready for another day", name: summary.leastWorn, symbol: "sun.max.fill")
                        LoggingStreakCard(consistency: logging)

                        let facts = MotivationEngine.facts(meters: summary.totalMeters)
                        if !facts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How far is that?")
                                    .font(.title3.bold())
                                ForEach(facts, id: \.text) { fact in
                                    Text(fact.text)
                                        .font(.body)
                                }
                                Text("Distances are approximate.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .warmCard()
                        }

                        HStack {
                            Text("Badges")
                                .font(.title3.bold())
                            Spacer()
                            NavigationLink {
                                BadgesView(badges: badges)
                            } label: {
                                Text("All badges")
                            }
                            .accessibilityIdentifier("allBadgesButton")
                        }
                        AchievementGrid(badges: Array(badges.prefix(4)), celebrate: motivation.celebration)
                        shareLinks
                    }
                }
                .padding()
            }
            .background(ShoeTheme.canvas)
            .navigationTitle("Stats")
        }
    }

    private var shareLinks: some View {
        let best = motivation.bestStreak()
        let collection = ReviewMath.summarize(
            title: "Your collection",
            pairs: sneakers.map { (name: $0.name, wears: $0.wearCount, meters: $0.totalMeters) },
            bestStreak: best
        )
        let calendar = Calendar.current
        let monthPairs: [(name: String, wears: Int, meters: Double)] = sneakers.map { sneaker in
            let wears = sneaker.wearDates.filter { calendar.isDate($0, equalTo: .now, toGranularity: .month) }.count
            let meters = sneaker.monthlyMeters.last ?? 0
            return (name: sneaker.name, wears: wears, meters: meters)
        }
        let month = ReviewMath.summarize(title: "This month", pairs: monthPairs, bestStreak: best)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Share")
                .font(.title3.bold())
            if let data = CardRenderer.png(content: { ShareCardBody(summary: collection) }) {
                ShareLink(item: PNGShare(data: data), preview: SharePreview("Collection")) {
                    Label("Share collection card", systemImage: "square.and.arrow.up")
                }
                .accessibilityIdentifier("shareCollectionButton")
            }
            if let data = CardRenderer.png(content: { ShareCardBody(summary: month) }) {
                ShareLink(item: PNGShare(data: data), preview: SharePreview("This month")) {
                    Label("Share this month", systemImage: "calendar")
                }
                .accessibilityIdentifier("shareMonthButton")
            }
            Text("Pictures are made on this iPhone. Nothing is uploaded.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func stat(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(ShoeTheme.today[0])
            Text(value)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
    }

    private func highlight(_ title: String, name: String?, symbol: String) -> some View {
        HStack {
            Image(systemName: symbol)
                .foregroundStyle(.orange)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(name ?? "–")
                    .font(.headline)
            }
            Spacer()
        }
        .padding()
        .warmCard()
        .accessibilityElement(children: .combine)
    }
}
