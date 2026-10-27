import CSQLCipher
import Foundation

/// Watches the KakaoTalk database for new messages by polling.
///
/// Uses `lastLogId` to track the high-water mark — only messages with
/// `logId > lastLogId` are emitted. Polling interval is configurable.
public final class DatabaseWatcher: @unchecked Sendable {
    private let databasePath: String
    private let key: String?
    private let pollInterval: TimeInterval
    private var lastLogId: Int64
    private var running = false

    public init(databasePath: String, key: String?, pollInterval: TimeInterval = 2.0, startFromLogId: Int64? = nil) {
        self.databasePath = databasePath
        self.key = key
        self.pollInterval = pollInterval
        self.lastLogId = startFromLogId ?? 0
    }

    /// Start watching. Calls `onMessages` with each batch of new messages.
    /// Calls `onError` if a poll fails. Blocks the calling thread until `stop()` is called.
    public func watch(onMessages: @escaping ([SyncMessage]) -> Void, onError: @escaping (Error) -> Void) {
        running = true

        // If no starting logId, seed from the current max
        if lastLogId == 0 {
            do {
                lastLogId = try fetchMaxLogId()
            } catch {
                onError(error)
                return
            }
        }

        while running {
            do {
                let messages = try fetchNewMessages()
                if !messages.isEmpty {
                    if let maxId = messages.map(\.logId).max() {
                        lastLogId = maxId
                    }
                    onMessages(messages)
                }
            } catch {
                onError(error)
            }
            Thread.sleep(forTimeInterval: pollInterval)
        }
    }

    public func stop() {
        running = false
    }

    // MARK: - Private

    private func fetchMaxLogId() throws -> Int64 {
        let reader = DatabaseReader(databasePath: databasePath)
        try reader.open(key: key)
        defer { reader.close() }
        return try reader.maxLogId()
    }

    private func fetchNewMessages() throws -> [SyncMessage] {
        let reader = DatabaseReader(databasePath: databasePath)
        try reader.open(key: key)
        defer { reader.close() }
        let myUserId = try reader.myUserId()
        return try reader.messagesSince(logId: lastLogId, myUserId: myUserId)
    }
}

/// A message event emitted by the watcher, designed for JSON serialization.
public struct SyncMessage: Sendable, Encodable {
    public let type: String
    public let logId: Int64
    public let chatId: Int64
    public let chatName: String?
    public let senderId: Int64
    public let senderName: String?
    public let text: String?
    public let messageType: Int
    public let messageTypeName: String
    public let isDeleted: Bool
    public let timestamp: String
    public let isFromMe: Bool

    public init(type: String, logId: Int64, chatId: Int64, chatName: String?, senderId: Int64,
                senderName: String?, text: String?, messageType: Int, timestamp: String, isFromMe: Bool) {
        self.type = type
        self.logId = logId
        self.chatId = chatId
        self.chatName = chatName
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.messageType = messageType
        self.messageTypeName = Message.MessageType(code: messageType).rawValue
        self.isDeleted = Message.MessageType.isDeleted(code: messageType)
        self.timestamp = timestamp
        self.isFromMe = isFromMe
    }

    enum CodingKeys: String, CodingKey {
        case type
        case logId = "log_id"
        case chatId = "chat_id"
        case chatName = "chat_name"
        case senderId = "sender_id"
        case senderName = "sender"
        case text
        case messageType = "message_type"
        case messageTypeName = "message_type_name"
        case isDeleted = "deleted"
        case timestamp
        case isFromMe = "is_from_me"
    }
}
