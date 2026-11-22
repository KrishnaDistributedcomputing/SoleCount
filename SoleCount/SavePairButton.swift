import SwiftUI
import UIKit

/// The Save control on the add-a-pair form.
/// A SwiftUI toolbar button can spend its first tap only closing the keyboard.
/// This button still runs Save on that tap.
struct SavePairButton: UIViewRepresentable {
    var enabled: Bool
    var action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> FirstTapUIButton {
        let button = FirstTapUIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        button.onCancelledTap = { [weak coordinator = context.coordinator] in
            coordinator?.tapped()
        }
        button.accessibilityIdentifier = "saveSneakerButton"
        button.accessibilityLabel = "Save"
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        return button
    }

    func updateUIView(_ button: FirstTapUIButton, context: Context) {
        context.coordinator.action = action
        button.isEnabled = enabled
        let metrics = UIFontMetrics(forTextStyle: .body)
        button.titleLabel?.font = metrics.scaledFont(for: UIFont.systemFont(ofSize: 17, weight: .semibold))
        button.setTitleColor(.tintColor, for: .normal)
        button.setTitleColor(UIColor.tintColor.withAlphaComponent(0.35), for: .disabled)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: FirstTapUIButton, context: Context) -> CGSize? {
        let fitted = uiView.intrinsicContentSize
        return CGSize(width: max(fitted.width, 44), height: max(fitted.height, 44))
    }

    final class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func tapped() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
            action()
        }
    }
}

/// A Save button that still fires when the system cancels the touch to close the keyboard.
private final class FirstTapUIButton: UIButton {
    var onCancelledTap: (() -> Void)?

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        let inside = touches.contains { bounds.contains($0.location(in: self)) }
        super.touchesCancelled(touches, with: event)
        if inside, isEnabled {
            onCancelledTap?()
        }
    }
}
