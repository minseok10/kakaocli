import Foundation

/// A KakaoTalk chat room.
public struct Chat: Sendable {
    public let id: Int64
    public let type: ChatType
    /// Raw `NTChatRoom.type`.
    public let typeCode: Int
    public let displayName: String
    public let memberCount: Int
    public let lastMessageId: Int64?
    public let lastMessageAt: Date?
    public let unreadCount: Int

    public enum ChatType: String, Sendable {
        case direct = "direct"
        case group = "group"
        case channel = "channel"   // KakaoTalk Channel (business/service account) chat
        case openChat = "open"
        case selfChat = "self"
        case system = "system"
        case unknown = "unknown"
    }
}
