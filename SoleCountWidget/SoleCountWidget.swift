import SwiftUI
import WidgetKit

/// Today's steps and the step-goal streak. The app fills in the numbers.
struct SoleCountWidgetEntry: TimelineEntry {
    var date: Date
    var snapshot: WidgetSnapshot
}

struct SoleCountWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SoleCountWidgetEntry {
        SoleCountWidgetEntry(date: .now, snapshot: WidgetSnapshot(todaySteps: 6_400, stepGoal: 8_000, streak: 4, updatedAt: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (SoleCountWidgetEntry) -> Void) {
        completion(SoleCountWidgetEntry(date: .now, snapshot: WidgetStore.load() ?? .empty))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SoleCountWidgetEntry>) -> Void) {
        let entry = SoleCountWidgetEntry(date: .now, snapshot: WidgetStore.load() ?? .empty)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct SoleCountWidgetView: View {
    var entry: SoleCountWidgetEntry

    /// Dark brown on the sunrise fill, so the widget stays easy to read.
    private static let ink = Color(red: 0.24, green: 0.12, blue: 0.08)

    private var progress: Double {
        guard entry.snapshot.stepGoal > 0 else { return 0 }
        return min(1, Double(entry.snapshot.todaySteps) / Double(entry.snapshot.stepGoal))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "shoe.fill")
                Text("Today")
                    .font(.headline)
                Spacer()
                if entry.snapshot.streak > 0 {
                    Label("\(entry.snapshot.streak)", systemImage: "flame.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Self.ink)
                }
            }
            ZStack {
                Circle().stroke(Self.ink.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Self.ink, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(red: 0.95, green: 0.62, blue: 0.32).opacity(0.6), radius: 4)
                Text("\(entry.snapshot.todaySteps)")
                    .font(.title2.bold())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            Text("of \(entry.snapshot.stepGoal) steps")
                .font(.caption2)
                .foregroundStyle(Self.ink.opacity(0.85))
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.55, blue: 0.42),
                    Color(red: 0.98, green: 0.75, blue: 0.45),
                    Color(red: 0.62, green: 0.82, blue: 0.70)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .foregroundStyle(Self.ink)
    }
}

struct SoleCountStepsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SoleCountSteps", provider: SoleCountWidgetProvider()) { entry in
            SoleCountWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's steps")
        .description("Your step ring and streak.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct SoleCountWidgetBundle: WidgetBundle {
    var body: some Widget {
        SoleCountStepsWidget()
    }
}
