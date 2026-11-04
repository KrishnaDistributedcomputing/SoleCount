import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// The CSV file handed to the system share sheet.
struct CSVShare: Transferable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("SoleCount.csv")
            try Data(file.text.utf8).write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}
