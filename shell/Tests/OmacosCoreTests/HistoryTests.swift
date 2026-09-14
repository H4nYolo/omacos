import Testing
@testable import OmacosCore

@Suite struct HistoryTests {
    @Test func parsesAndBumps() {
        var h = LaunchHistory(text: "3 Zen\n1 Activity Monitor\nbroken line\n")
        #expect(h.count("Zen") == 3)
        #expect(h.count("Activity Monitor") == 1)
        #expect(h.count("Mail") == 0)
        h.bump("Mail"); h.bump("Zen")
        #expect(h.text == "1 Activity Monitor\n1 Mail\n4 Zen\n")
    }
}
