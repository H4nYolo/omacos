import Testing
@testable import OmacosCore

@Suite struct MatcherTests {
    @Test func everyWordMustMatchAsSubstring() {
        #expect(Matcher.score(query: "act mon", label: "Activity Monitor") != nil)
        #expect(Matcher.score(query: "actmon", label: "Activity Monitor") == nil)   // no fuzzy
        #expect(Matcher.score(query: "act zzz", label: "Activity Monitor") == nil)
        #expect(Matcher.score(query: "", label: "Anything") == 0)
    }

    @Test func wordStartsBeatMiddleMatches() {
        let start = Matcher.score(query: "mon", label: "Monitor")!
        let wordStart = Matcher.score(query: "mon", label: "Activity Monitor")!
        let middle = Matcher.score(query: "mon", label: "Lemonade")!
        #expect(start > wordStart)
        #expect(wordStart > middle)
    }

    @Test func rankUsesScoreThenHistoryThenName() {
        let items = ["Safari", "Sol", "Slack", "Mail"]
        let history = ["Slack": 5, "Safari": 1]
        #expect(Matcher.rank(items, query: "s", label: { $0 }, rank: { history[$0] ?? 0 }) == ["Slack", "Safari", "Sol"])
        #expect(Matcher.rank(items, query: "", label: { $0 }, rank: { history[$0] ?? 0 }) == ["Slack", "Safari", "Mail", "Sol"])
    }
}
