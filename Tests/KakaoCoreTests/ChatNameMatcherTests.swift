import Testing
@testable import KakaoCore

@Test func testExactMatchWinsOverSubstrings() {
    let names: [String?] = ["민수 가족방", "민수", "민수 친구들"]
    #expect(ChatNameMatcher.match("민수", in: names) == .found(1))
}

@Test func testUniqueSubstringMatches() {
    let names: [String?] = ["회사 공지", "민수 가족방", nil]
    #expect(ChatNameMatcher.match("가족", in: names) == .found(1))
}

@Test func testAmbiguousSubstringIsRefused() {
    let names: [String?] = ["민수 가족방", "민수 친구들", "회사"]
    #expect(ChatNameMatcher.match("민수", in: names) == .ambiguous(["민수 가족방", "민수 친구들"]))
}

@Test func testDuplicateExactNamesAreRefused() {
    let names: [String?] = ["민수", "민수"]
    #expect(ChatNameMatcher.match("민수", in: names) == .ambiguous(["민수", "민수"]))
}

@Test func testNoMatch() {
    let names: [String?] = ["회사", nil]
    #expect(ChatNameMatcher.match("민수", in: names) == .notFound)
}
