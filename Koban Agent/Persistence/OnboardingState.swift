import Foundation

/// The persisted record that first-run onboarding has finished. Its presence is the flag: a single
/// row exists once the user completes onboarding, carrying when they did. Stored in the app
/// database so the menu-bar agent shows its first-run flow exactly once, on the genuine first run.
struct OnboardingState: Codable {
    var completedAt: Date
}
