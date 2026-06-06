import Testing
@testable import Koban_Agent

// MARK: - OnboardingModelTests

@MainActor
struct OnboardingModelTests {
    @Test
    func advanceWalksTheStepsAndStops() {
        let model = OnboardingModel()
        #expect(model.step == .welcome)

        model.advance()
        #expect(model.step == .surfaces)
        model.advance()
        #expect(model.step == .indexing)

        // The last step has no successor.
        model.advance()
        #expect(model.step == .indexing)
    }

    @Test
    func goBackStopsAtWelcome() {
        let model = OnboardingModel()
        model.advance()

        model.goBack()
        #expect(model.step == .welcome)

        model.goBack()
        #expect(model.step == .welcome)
    }

    @Test
    func beginIndexingStartsEverySurfacePending() {
        let model = OnboardingModel()

        model.beginIndexing([.homebrew, .claudeConfig])

        #expect(model.state(for: .homebrew) == .pending)
        #expect(model.state(for: .claudeConfig) == .pending)
        #expect(model.progress == 0)
        #expect(model.isIndexingComplete == false)
    }

    @Test
    func progressTracksIndexedSurfaces() {
        let model = OnboardingModel()
        model.beginIndexing([.homebrew, .claudeConfig])

        model.markIndexing(.homebrew)
        #expect(model.state(for: .homebrew) == .indexing)
        #expect(model.progress == 0)

        model.markIndexed(.homebrew)
        #expect(model.state(for: .homebrew) == .indexed)
        #expect(model.progress == 0.5)
    }

    @Test
    func completeIndexingMarksEverySurfaceDone() {
        let model = OnboardingModel()
        model.beginIndexing([.homebrew, .claudeConfig])
        model.markIndexing(.homebrew)

        model.completeIndexing()

        #expect(model.state(for: .homebrew) == .indexed)
        #expect(model.state(for: .claudeConfig) == .indexed)
        #expect(model.progress == 1)
        #expect(model.isIndexingComplete)
    }
}
