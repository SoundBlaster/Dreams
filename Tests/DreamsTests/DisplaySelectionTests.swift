import Foundation
import Testing
@testable import Dreams

struct DisplaySelectionTests {
    private let laptop = RainDisplay(id: "laptop", name: "Built-in", builtIn: true, isMain: false, excluded: false)
    private let external = RainDisplay(id: "external", name: "External", builtIn: false, isMain: true, excluded: false)
    private let agent = RainDisplay(id: "agent", name: "Agent", builtIn: false, isMain: false, excluded: true)

    @Test func automaticPrefersInternalEvenWithExternalMain() {
        #expect(RainDisplaySelection().targets(in: [external, laptop, agent]) == [laptop])
    }

    @Test func closedLidUsesMainExternal() {
        let second = RainDisplay(id: "second", name: "Second", builtIn: false, isMain: false, excluded: false)
        #expect(RainDisplaySelection().targets(in: [second, external, agent]) == [external])
    }

    @Test func allCoversBothAndExcludesAgent() {
        #expect(RainDisplaySelection(mode: .all).targets(in: [laptop, agent, external]) == [laptop, external])
    }

    @Test func selectedSubsetSurvivesDisconnectAndReconnect() {
        let choice = RainDisplaySelection(mode: .selected, selectedIDs: [external.id])
        #expect(choice.targets(in: [laptop, external, agent]) == [external])
        #expect(choice.targets(in: [laptop, agent]) == [laptop])
        #expect(choice.targets(in: [laptop, external, agent]) == [external])
        #expect(choice.selectedIDs == [external.id])
    }

    @Test func remainingSelectedScreenWinsOverAutomaticFallback() {
        let choice = RainDisplaySelection(mode: .selected, selectedIDs: [external.id, "disconnected"])
        #expect(choice.targets(in: [laptop, external]) == [external])
    }

    @Test(arguments: RainDisplaySelection.Mode.allCases)
    func noModeCanCoverAgentWorkspace(_ mode: RainDisplaySelection.Mode) {
        let choice = RainDisplaySelection(mode: mode, selectedIDs: [agent.id])
        #expect(choice.targets(in: [agent]).isEmpty)
        #expect(choice.targets(in: [agent, external]) == [external])
    }

    @Test func noDisplayIsSafeAndMissingMainUsesFirstEligible() {
        #expect(RainDisplaySelection().targets(in: []).isEmpty)
        #expect(RainDisplaySelection().targets(in: [agent, laptop]) == [laptop])
    }

    @Test func stableChoicePersistsAndInvalidModeFallsBack() throws {
        let name = "Dreams.DisplayTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let choice = RainDisplaySelection(mode: .selected, selectedIDs: [external.id, laptop.id])
        choice.save(to: defaults)
        #expect(RainDisplaySelection.load(from: defaults) == choice)
        defaults.set("invalid", forKey: "rainDisplayMode")
        #expect(RainDisplaySelection.load(from: defaults).mode == .automatic)
        #expect(RainDisplaySelection.load(from: defaults).selectedIDs == choice.selectedIDs)
    }
}
