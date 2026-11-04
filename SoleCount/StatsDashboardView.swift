import SwiftUI

/// The whole collection in one place: wears, distance, value, and badges.
struct StatsDashboardView: View {
    @Environment(MotivationStore.self) private var motivation
    @Query(sort: \Sneaker.createdAt, order: .reverse) private var sneakers: [Sneaker]

    private var summary: CollectionSummary {
        let days = Set(sneakers.flatMap(\.wearDates).map { Calendar.current.startOfDay(for: $0) })
        return CollectionMath.summarize(
            pairs: sneakers.map { $0.asPairStats() },
            wearDays: days,
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
                            Label("No stats yet", systemImage: "chart.bar")
                        } description: {
                            Text("Add a pair and log a wear. The numbers will show up here.")
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
                        highlight("Forgotten lately", name: summary.leastWorn, symbol: "moon.zzz.fill")
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text(summary.wearStreak > 0 ? "\(summary.wearStreak)-day wear streak" : "No wear streak yet")
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

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
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }

                        Text("Badges")
                            .font(.title3.bold())
                        AchievementGrid(badges: badges)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stats")
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}
