import Foundation

@Observable
final class OnboardingState {
    enum Step: Int, CaseIterable {
        case welcome
        case inputMonitoring
        case importLayout
        case complete
    }

    var currentStep: Step {
        didSet {
            UserDefaults.standard.set(currentStep.rawValue, forKey: "onboardingStep")
        }
    }

    init() {
        let saved = UserDefaults.standard.integer(forKey: "onboardingStep")
        currentStep = Step(rawValue: saved) ?? .welcome
    }

    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    static func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "onboardingStep")
    }

    func advance() {
        let cases = Step.allCases
        if let index = cases.firstIndex(of: currentStep), index + 1 < cases.count {
            currentStep = cases[index + 1]
        }
    }

    func skip() {
        currentStep = .complete
    }
}
