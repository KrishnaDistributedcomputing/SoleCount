import Charts
import SwiftUI

/// Kilometres (or miles) per month for one pair. Same six-month window as the wear chart.
struct DistanceChartView: View {
    var monthlyMeters: [Double]
    var tint: Color

    private struct MonthDistance: Identifiable {
        var month: Date
        var amount: Double
        var id: Date { month }
    }

    private var data: [MonthDistance] {
        let months = HealthAttribution.monthWindow(calendar: .current, now: .now)
        return months.enumerated().map { index, month in
            let meters = index < monthlyMeters.count ? monthlyMeters[index] : 0
            let shown = DistanceFormat.usesMiles() ? meters / DistanceFormat.metersPerMile : meters / 1_000
            return MonthDistance(month: month, amount: shown)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if data.allSatisfy({ $0.amount < 0.05 }) {
                Text("No distance in the last 6 months yet")
                    .font(.subheadline)
                    .foregroundStyle(ShoeTheme.softText)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(data) { item in
                    AreaMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Distance", item.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tint.opacity(0.45), tint.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    LineMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Distance", item.amount)
                    )
                    .foregroundStyle(tint)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
            }
        }
        .accessibilityLabel("Distance per month for the last 6 months")
    }
}
