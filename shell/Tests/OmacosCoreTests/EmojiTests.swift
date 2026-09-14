import Testing
@testable import OmacosCore

@Suite struct EmojiTests {
    @Test func parsesTsvAndSearchesNameAndKeywords() {
        let table = EmojiTable.parse("🚀\trocket\trocket ship launch\n😀\tgrinning face\tgrinning smile happy\nbroken\n")
        #expect(table.count == 2)
        #expect(table[0].emoji == "🚀")
        let hits = Matcher.rank(table, query: "launch", label: { $0.searchText })
        #expect(hits.map(\.emoji) == ["🚀"])
        #expect(Matcher.rank(table, query: "happy", label: { $0.searchText }).map(\.emoji) == ["😀"])
    }
}
