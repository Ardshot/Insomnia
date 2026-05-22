import IOKit.pwr_mgt
import Foundation

class PowerManager {
    private var systemAssertion: IOPMAssertionID = 0
    private var displayAssertion: IOPMAssertionID = 0
    private var hasSystem = false
    private var hasDisplay = false

    var displaySleepAllowed: Bool = false {
        didSet {
            if displaySleepAllowed {
                releaseDisplaySleep()
            } else {
                preventDisplaySleep()
            }
        }
    }

    @discardableResult
    func preventSleep(reason: String = "Insomnia is preventing sleep") -> Bool {
        guard !hasSystem else { return true }
        let r = reason as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            r,
            &systemAssertion
        )
        hasSystem = result == kIOReturnSuccess
        preventDisplaySleep()
        return hasSystem
    }

    @discardableResult
    func preventDisplaySleep() -> Bool {
        guard !hasDisplay else { return true }
        let r = "Insomnia is preventing display sleep" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            r,
            &displayAssertion
        )
        hasDisplay = result == kIOReturnSuccess
        return hasDisplay
    }

    func releaseDisplaySleep() {
        guard hasDisplay else { return }
        IOPMAssertionRelease(displayAssertion)
        displayAssertion = 0
        hasDisplay = false
    }

    func releaseSystemSleep() {
        guard hasSystem else { return }
        IOPMAssertionRelease(systemAssertion)
        systemAssertion = 0
        hasSystem = false
    }

    func releaseAll() {
        releaseDisplaySleep()
        releaseSystemSleep()
    }

    deinit { releaseAll() }
}
