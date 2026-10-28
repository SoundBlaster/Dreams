import SwiftUI
import UIKit
// UIGestureRecognizer subclass overrides are declared in this UIKit submodule.
// swiftlint:disable:next duplicate_imports
import UIKit.UIGestureRecognizerSubclass

@MainActor
final class RemoteHoldState {
    var active = false
}

/// Native directional clicks/holds coexist with the List's touch-surface focus handling.
struct RemoteHoldAdjustment: UIViewRepresentable {
    let enabled: Bool
    let field: String
    let holdChanged: (Bool) -> Void
    let adjust: (Int) -> Void

    func makeUIView(context: Context) -> HoldView { HoldView() }

    func updateUIView(_ view: HoldView, context: Context) {
        if view.field != field || !enabled { view.stop() }
        view.field = field
        view.holdChanged = holdChanged
        view.adjust = adjust
        view.recognizers.forEach { $0.isEnabled = enabled }
    }

    static func dismantleUIView(_ view: HoldView, coordinator: ()) { view.detach() }

    final class HoldView: UIView, UIGestureRecognizerDelegate {
        var field = ""
        var holdChanged: (Bool) -> Void = { _ in }
        var adjust: (Int) -> Void = { _ in }
        private var repeating: Task<Void, Never>?
        private weak var attachedWindow: UIWindow?
        lazy var recognizers: [UIGestureRecognizer] = [UIPress.PressType.leftArrow, .rightArrow].flatMap { type in
            let hold = DirectionalHoldRecognizer(target: self, action: #selector(held(_:)))
            hold.pressStarted = { [weak self] in self?.holdChanged(true) }
            hold.pressFinished = { [weak self] in self?.stop() }
            hold.minimumPressDuration = 0.5
            let double = UITapGestureRecognizer(target: self, action: #selector(clicked(_:)))
            double.numberOfTapsRequired = 2
            let single = UITapGestureRecognizer(target: self, action: #selector(clicked(_:)))
            single.require(toFail: double)
            single.require(toFail: hold)
            double.require(toFail: hold)
            let group: [UIGestureRecognizer] = [hold, double, single]
            for recognizer in group {
                recognizer.allowedPressTypes = [NSNumber(value: type.rawValue)]
                recognizer.allowedTouchTypes = []
                recognizer.cancelsTouchesInView = false
                recognizer.delegate = self
            }
            return group
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            detach()
            attachedWindow = window
            recognizers.forEach { window?.addGestureRecognizer($0) }
        }

        func detach() {
            stop()
            recognizers.forEach { attachedWindow?.removeGestureRecognizer($0) }
            attachedWindow = nil
        }

        func stop() {
            repeating?.cancel()
            repeating = nil
            holdChanged(false)
        }

        func beginRepeating(direction: Int) {
            stop()
            holdChanged(true)
            adjust(direction)
            repeating = Task { @MainActor [weak self] in
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
                    guard !Task.isCancelled, let self else { return }
                    self.adjust(direction)
                }
            }
        }

        @objc private func held(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                let direction = direction(of: recognizer) * 10
                beginRepeating(direction: direction)
            case .ended, .cancelled: stop()
            default: break
            }
        }

        @objc private func clicked(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            stop()
            adjust(direction(of: recognizer) * (recognizer.numberOfTapsRequired == 2 ? 10 : 1))
        }

        private func direction(of recognizer: UIGestureRecognizer) -> Int {
            recognizer.allowedPressTypes.first?.intValue == UIPress.PressType.leftArrow.rawValue ? -1 : 1
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
            guard gestureRecognizer.allowedPressTypes.contains(NSNumber(value: press.type.rawValue)) else { return false }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            !recognizers.contains { $0 === otherGestureRecognizer }
        }
    }
}

/// A failed recognizer does not invoke its action, so release suppression on reset too.
final class DirectionalHoldRecognizer: UILongPressGestureRecognizer {
    var pressStarted: () -> Void = {}
    var pressFinished: () -> Void = {}
    private var receivedPress = false

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        trackPress()
        super.pressesBegan(presses, with: event)
    }

    func trackPress() {
        receivedPress = true
        pressStarted()
    }

    override func reset() {
        super.reset()
        if receivedPress {
            receivedPress = false
            pressFinished()
        }
    }
}
