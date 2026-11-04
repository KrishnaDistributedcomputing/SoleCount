import SwiftData
import SwiftUI

/// A month of wears. Tap a day to see which pairs were on your feet.
struct WearCalendarView: View {
    @Query(sort: \Sneaker.name) private var sneakers: [Sneaker]
    @State private var month = Date.now
    @State private var selected = Calendar.current.startOfDay(for: .now)

    private var calendar: Calendar { .current }

    private var days: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        let count = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<count {
            cells.append(calendar.date(byAdding: .day, value: offset, to: interval.start))
        }
        return cells
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button {
                            shift(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .accessibilityLabel("Previous month")
                        Spacer()
                        Text(month, format: .dateTime.month(.wide).year())
                            .font(.title3.bold())
                        Spacer()
                        Button {
                            shift(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .accessibilityLabel("Next month")
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                            if let day {
                                dayCell(day)
                            } else {
                                Color.clear.frame(height: 36)
                            }
                        }
                    }
                    .padding()
                    .warmCard()

                    let names = pairs(on: selected)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selected, format: .dateTime.weekday(.wide).month().day())
                            .font(.headline)
                        if names.isEmpty {
                            Text("No pairs logged.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(names, id: \.self) { name in
                                Label(name, systemImage: "shoe.fill")
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .warmCard()
                }
                .padding()
            }
            .background(ShoeTheme.canvas)
            .navigationTitle("Calendar")
        }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    private func dayCell(_ day: Date) -> some View {
        let count = pairs(on: day).count
        let isSelected = calendar.isDate(day, inSameDayAs: selected)
        return Button {
            selected = day
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.caption.weight(.semibold))
                Circle()
                    .fill(count > 0 ? ShoeTheme.today[0] : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                Circle().fill(isSelected ? ShoeTheme.today[0].opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)), \(count) pairs")
    }

    private func pairs(on day: Date) -> [String] {
        sneakers.compactMap { sneaker in
            sneaker.wearDates.contains { calendar.isDate($0, inSameDayAs: day) } ? sneaker.name : nil
        }
    }

    private func shift(by value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: month) {
            month = next
        }
    }
}
