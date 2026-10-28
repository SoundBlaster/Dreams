import XCTest
@testable import DreamsTV

final class RemoteAdjustmentTests: XCTestCase {
    @MainActor
    func testFailedPendingHoldReleasesSwipeSuppressionOnReset() {
        let view = RemoteHoldAdjustment.HoldView()
        var active = false
        var steps: [Int] = []
        view.holdChanged = { active = $0 }
        view.adjust = { steps.append($0) }
        let hold = view.recognizers.compactMap { $0 as? DirectionalHoldRecognizer }.first!
        hold.trackPress()
        XCTAssertTrue(active)
        hold.reset()
        XCTAssertFalse(active)
        XCTAssertTrue(steps.isEmpty)
    }

    @MainActor
    func testHoldRepeatsTenStepsAndDetachingStopsPendingWork() async throws {
        let view = RemoteHoldAdjustment.HoldView()
        var steps: [Int] = []
        let repeated = expectation(description: "A held direction repeats")
        var active = false
        view.holdChanged = { active = $0 }
        view.adjust = {
            steps.append($0)
            if steps.count == 2 { repeated.fulfill() }
        }
        view.beginRepeating(direction: -10)
        XCTAssertTrue(active)
        XCTAssertEqual(steps, [-10])
        await fulfillment(of: [repeated], timeout: 2)
        XCTAssertEqual(steps[1], -10)
        view.detach()
        XCTAssertFalse(active)
        let count = steps.count
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(steps.count, count, "Closing the menu must cancel pending repeats")
        XCTAssertTrue(view.recognizers.allSatisfy { $0.allowedTouchTypes.isEmpty })
    }

    func testCoarseStepsUseEachFieldsUnitsAndClampAtBounds() {
        var tuning = RainTuning()
        SettingsField.columns.adjust(&tuning, by: 10)
        XCTAssertEqual(tuning.columns, 100)
        SettingsField.columns.adjust(&tuning, by: -10)
        XCTAssertEqual(tuning.columns, 90)
        SettingsField.density.adjust(&tuning, by: 10)
        XCTAssertEqual(tuning.density, 0.92, accuracy: 0.00001)
        SettingsField.speed.adjust(&tuning, by: 10)
        XCTAssertEqual(tuning.speed, 0.53, accuracy: 0.00001)
        SettingsField.fade.adjust(&tuning, by: 10)
        XCTAssertEqual(tuning.fade, 13)
        SettingsField.fade.adjust(&tuning, by: 10)
        XCTAssertEqual(tuning.fade, 16)
        tuning.columns = 239
        SettingsField.columns.adjust(&tuning, by: 10)
        XCTAssertEqual(tuning.columns, 240)
        tuning.columns = 25
        SettingsField.columns.adjust(&tuning, by: -10)
        XCTAssertEqual(tuning.columns, 24)
    }

    func testDisabledAndNonNumericFieldsIgnoreCoarseAdjustment() {
        var tuning = RainTuning()
        tuning.automaticColumns = true
        tuning.decelerationEnabled = false
        tuning.showsClock = false
        let original = tuning
        for field in [SettingsField.columns, .acceleration, .size, .typeface, .clock, .glyphs, .automatic] {
            field.adjust(&tuning, by: 10)
        }
        XCTAssertEqual(tuning, original)
        tuning.showsClock = true
        SettingsField.typeface.adjust(&tuning, by: 10)
        XCTAssertEqual(tuning.clockTypeface, .system)
        SettingsField.typeface.adjust(&tuning, by: 1)
        XCTAssertEqual(tuning.clockTypeface, .rounded)
    }
}
