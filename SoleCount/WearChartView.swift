import SwiftUI
import Charts

// Bar chart: how many times you wore the pair in each of the last 6 months.
struct WearChartView: View {
    let wearDates: [Date]

    private struct MonthCount: Identifiable {
        let month: Date
        let count: Int
        var id: Date { month }
    }

    private var data: [MonthCount] {
        let calendar = Calendar.current
        let thisMonth = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        var result: [MonthCount] = []
        for offset in stride(from: 5, through: 0, by: -1) {
            guard let start = calendar.date(byAdding: .month, value: -offset, to: thisMonth) else { continue }
            let count = wearDates.filter {
                calendar.isDate($0, equalTo: start, toGranularity: .month)
            }.count
            result.append(MonthCount(month: start, count: count))
        }
        return result
    }

    private var maxCount: Int {
        data.map(\.count).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if data.allSatisfy({ $0.count == 0 }) {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No wears in the last 6 months")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Wears", item.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(8)
                    .annotation(position: .top) {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...max(maxCount + 1, 5))
                .frame(height: 220)
            }
        }
        .accessibilityLabel("Wear history chart showing wears per month for the last 6 months")
    }
}
