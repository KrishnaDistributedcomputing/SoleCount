import Foundation

/// One row of the CSV file the share sheet sends.
struct ExportRow: Equatable {
    var name: String
    var brand: String
    var type: String
    var size: String
    var colorway: String
    var condition: String
    var price: Double
    var purchaseDate: Date
    var wears: Int
    var meters: Double
    var steps: Double
    var retired: Bool
    var notes: String
}

enum CollectionExport {
    static let header = "Name,Brand,Type,Size,Colorway,Condition,Price,Purchased,Wears,Distance km,Steps,Retired,Notes"

    static func csv(rows: [ExportRow], calendar: Calendar = .current) -> String {
        var lines = [header]
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        for row in rows {
            let fields = [
                row.name,
                row.brand,
                row.type,
                row.size,
                row.colorway,
                row.condition,
                String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), row.price),
                formatter.string(from: row.purchaseDate),
                String(row.wears),
                String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), row.meters / 1000),
                String(Int(row.steps.rounded())),
                row.retired ? "yes" : "no",
                row.notes
            ]
            lines.append(fields.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
