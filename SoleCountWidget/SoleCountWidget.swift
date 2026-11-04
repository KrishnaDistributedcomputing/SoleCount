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
                        .foregroundStyle(.orange)
                }
            }
            ZStack {
                Circle().stroke(Color.white.opacity(0.25), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(entry.snapshot.todaySteps)")
                    .font(.title2.bold())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            Text("of \(entry.snapshot.stepGoal) steps")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.40, blue: 0.92), Color(red: 0.36, green: 0.22, blue: 0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .foregroundStyle(.white)
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
