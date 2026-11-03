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

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Month", item.month, unit: .month),
                y: .value("Wears", item.count)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .frame(height: 200)
        .accessibilityLabel("Wear history chart")
    }
}
