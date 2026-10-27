import Foundation

/// A KakaoTalk message.
public struct Message: Sendable {
    public let id: Int64
    public let chatId: Int64
    public let senderId: Int64
    public let senderName: String?
    public let text: String?
    /// Raw `NTChatMessage.type`.
    public let typeCode: Int
    public let createdAt: Date
    public let isFromMe: Bool

    public var type: MessageType { MessageType(code: typeCode) }
    public var isDeleted: Bool { MessageType.isDeleted(code: typeCode) }

    /// Message kinds by `NTChatMessage.type`. Codes follow KakaoTalk's LOCO chat
    /// types and were checked against a real database's attachments.
    public enum MessageType: String, Sendable {
        case system       // 0: join/leave/kick feed events (JSON in `message`)
        case text
        case photo
        case video
        case contact
        case audio
        case emoticon     // 6, 8, 12, 20, 22, 25: static, animated and GIF emoticons
        case gift
        case kakaolink
        case avatar
        case schedule
        case vote
        case lottery
        case location
        case profile
        case file
        case nudge
        case search       // 23: shared #search card
        case post         // 24: notices and posts
        case reply
        case multiPhoto = "multi_photo"
        case call         // 51, 52: voice/video call start and end
        case custom       // 71: rich cards such as money-transfer envelopes
        case notification // 72: AlimTalk messages from businesses
        case plusFriend = "plus_friend"
        case unknown

        /// Added to a message's type when it is deleted for everyone. The original
        /// content usually stays in the local database.
        static let deletedFlag = 0x4000

        public init(code: Int) {
            switch code & ~Self.deletedFlag {
            case 0: self = .system
            case 1: self = .text
            case 2: self = .photo
            case 3: self = .video
            case 4: self = .contact
            case 5: self = .audio
            case 6, 8, 12, 20, 22, 25: self = .emoticon
            case 7: self = .gift
            case 9: self = .kakaolink
            case 11: self = .avatar
            case 13, 96: self = .schedule
            case 14, 97: self = .vote
            case 15: self = .lottery
            case 16: self = .location
            case 17: self = .profile
            case 18: self = .file
            case 21: self = .nudge
            case 23: self = .search
            case 24, 98: self = .post
            case 26: self = .reply
            case 27: self = .multiPhoto
            case 51, 52: self = .call
            case 71: self = .custom
            case 72: self = .notification
            case 81, 82, 83: self = .plusFriend
            default: self = .unknown
            }
        }

        public static func isDeleted(code: Int) -> Bool {
            code > 0 && code & deletedFlag != 0
        }
    }
}
