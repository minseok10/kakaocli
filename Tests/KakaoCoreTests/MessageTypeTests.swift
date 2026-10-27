import Testing
@testable import KakaoCore

@Test func testMessageTypeNames() {
    #expect(Message.MessageType(code: 1) == .text)
    #expect(Message.MessageType(code: 6) == .emoticon)
    #expect(Message.MessageType(code: 18) == .file)
    #expect(Message.MessageType(code: 26) == .reply)
    #expect(Message.MessageType(code: 27) == .multiPhoto)
    #expect(Message.MessageType(code: 1999) == .unknown)
}

@Test func testDeletedFlagKeepsBaseType() {
    #expect(Message.MessageType(code: 16385) == .text)
    #expect(Message.MessageType.isDeleted(code: 16385))
    #expect(!Message.MessageType.isDeleted(code: 1))
    #expect(!Message.MessageType.isDeleted(code: -1))
}

@Test func testMessageCursorRoundTrip() {
    let cursor = MessageCursor(sentAt: 1790400000, logId: 4567)
    #expect(MessageCursor(string: cursor.string) == cursor)
    #expect(MessageCursor(string: "1790400000") == nil)
    #expect(MessageCursor(string: "a.b") == nil)
}

@Test func testChatTypeCodes() {
    #expect(Chat.ChatType.from(rawInt: 0) == .direct)
    #expect(Chat.ChatType.from(rawInt: 1) == .group)
    #expect(Chat.ChatType.from(rawInt: 2) == .channel)
    #expect(Chat.ChatType.from(rawInt: 4) == .openChat)
    #expect(Chat.ChatType.from(rawInt: 5) == .selfChat)
    #expect(Chat.ChatType.from(rawInt: 9999) == .system)
    #expect(Chat.ChatType.from(rawInt: 3, isOpenLink: true) == .openChat)
    #expect(Chat.ChatType.from(rawInt: 3) == .unknown)
}
