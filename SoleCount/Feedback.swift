import MessageUI
import SwiftUI
import UIKit

/// Feedback by email. Nothing is sent unless you press Send in Mail.
/// The note only carries the app version, iOS version, and iPhone model.
enum FeedbackMail {
    static let address = "krishnaazure1975@gmail.com"

    enum Kind {
        case feedback
        case idea

        var subject: String {
            switch self {
            case .feedback: "SoleCount feedback"
            case .idea: "SoleCount idea"
            }
        }

        var prompt: String {
            switch self {
            case .feedback: "Hi! What do you love about SoleCount, and what could be better?"
            case .idea: "Hi! What would you love SoleCount to do next?"
            }
        }
    }

    static func body(_ kind: Kind, version: String, build: String, system: String, model: String) -> String {
        "\(kind.prompt)\n\n\n\n—\nApp version \(version) (build \(build)), iOS \(system), \(model)"
    }

    static func currentBody(_ kind: Kind) -> String {
        let info = Bundle.main.infoDictionary
        return body(
            kind,
            version: info?["CFBundleShortVersionString"] as? String ?? "1.0",
            build: info?["CFBundleVersion"] as? String ?? "1",
            system: UIDevice.current.systemVersion,
            model: modelIdentifier
        )
    }

    static func mailtoURL(_ kind: Kind, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        components.queryItems = [
            URLQueryItem(name: "subject", value: kind.subject),
            URLQueryItem(name: "body", value: body)
        ]
        // URLComponents leaves "+" alone, which some mail apps read as a space.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return components.url
    }

    /// For example "iPhone17,2". On the simulator, the simulated model.
    static var modelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulated }
        var info = utsname()
        uname(&info)
        let mirror = Mirror(reflecting: info.machine)
        let id = mirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(Character(UnicodeScalar(UInt8(value))))
        }
        return id.isEmpty ? UIDevice.current.model : id
    }
}

/// Opens the Mail composer when it can, then a mailto: link, then shows the address to copy.
struct FeedbackButton<Label: View>: View {
    var kind: FeedbackMail.Kind
    @ViewBuilder var label: () -> Label

    @Environment(\.openURL) private var openURL
    @State private var showingComposer = false
    @State private var showingAddress = false

    var body: some View {
        Button {
            if MFMailComposeViewController.canSendMail() {
                showingComposer = true
            } else if let url = FeedbackMail.mailtoURL(kind, body: FeedbackMail.currentBody(kind)) {
                openURL(url) { accepted in
                    if !accepted { showingAddress = true }
                }
            } else {
                showingAddress = true
            }
        } label: {
            label()
        }
        .sheet(isPresented: $showingComposer) {
            MailComposer(kind: kind)
                .ignoresSafeArea()
        }
        .alert("Email me any time", isPresented: $showingAddress) {
            Button("Copy address") { UIPasteboard.general.string = FeedbackMail.address }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Mail isn't set up on this iPhone. You can write to \(FeedbackMail.address) from any email app.")
        }
    }
}

private struct MailComposer: UIViewControllerRepresentable {
    var kind: FeedbackMail.Kind
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator
        mail.setToRecipients([FeedbackMail.address])
        mail.setSubject(kind.subject)
        mail.setMessageBody(FeedbackMail.currentBody(kind), isHTML: false)
        return mail
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}
