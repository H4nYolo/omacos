import Testing
@testable import OmacosCore

@Suite struct NotesEditingTests {
    @Test func slashCommandsOnlyAtTheLineStart() {
        #expect(NotesEditing.expandSlash("/t") == "- [ ] ")
        #expect(NotesEditing.expandSlash("  /t") == "  - [ ] ")
        #expect(NotesEditing.expandSlash("/h") == "## ")
        #expect(NotesEditing.expandSlash("/d", timestamp: { "## NOW" }) == "## NOW")
        #expect(NotesEditing.expandSlash("and/t") == nil)
        #expect(NotesEditing.expandSlash("/tx") == nil)
        #expect(NotesEditing.expandSlash("") == nil)
    }

    @Test func enterContinuesLists() {
        #expect(NotesEditing.continuation("- [ ] call INC1") == .insert("- [ ] "))
        #expect(NotesEditing.continuation("  - [x] done") == .insert("  - [ ] "))   // the next one is open again
        #expect(NotesEditing.continuation("* item") == .insert("* "))
        #expect(NotesEditing.continuation("9. nine") == .insert("10. "))
        #expect(NotesEditing.continuation("1) one") == .insert("2) "))
        #expect(NotesEditing.continuation("plain text") == .none)
        #expect(NotesEditing.continuation("**bold**") == .none)
    }

    @Test func enterOnAnEmptyMarkerEndsTheList() {
        #expect(NotesEditing.continuation("- [ ] ") == .clear)
        #expect(NotesEditing.continuation("  - ") == .clear)
        #expect(NotesEditing.continuation("3. ") == .clear)
    }

    @Test func toggleTask() {
        #expect(NotesEditing.toggleTask("- [ ] a") == "- [x] a")
        #expect(NotesEditing.toggleTask("  - [X] a") == "  - [ ] a")
        #expect(NotesEditing.toggleTask("- a [ ] b") == "- [ ] a [ ] b")   // a bullet becomes a task
        #expect(NotesEditing.toggleTask("  call back") == "  - [ ] call back")
        #expect(NotesEditing.toggleTask("") == "- [ ] ")
    }
}
