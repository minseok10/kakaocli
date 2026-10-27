import ArgumentParser
import Foundation
import KakaoCore

struct SendCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send a message via UI automation",
        discussion: """
            After pressing Return, waits for the message to appear in the local database.
            Exit status 0 means it was confirmed there; 2 means Return was pressed but the
            message was not seen in time. Check KakaoTalk before retrying, or it may be sent twice.
            """
    )

    @Argument(help: "Chat name to send to (exact name, or a substring matching only one chat), or any value with --me")
    var chat: String

    @Argument(help: "Message text to send")
    var message: String

    @Flag(name: [.customLong("me")], help: "Send to self-chat (나와의 채팅) regardless of chat argument")
    var selfChat = false

    @Flag(name: .long, help: "Show what would happen without actually sending")
    var dryRun = false

    @Option(name: .long, help: "Seconds to wait for the message to appear in the database")
    var confirmTimeout: Double = 10

    func run() throws {
        let automator = KakaoAutomator()
        let target = selfChat ? "self-chat" : chat
        if dryRun {
            print("DRY RUN: Would send to '\(target)': \(message)")
            print("Steps: activate KakaoTalk → find chat '\(target)' → type message → press Enter → confirm in DB")
            return
        }

        // Take the baseline before touching the UI, so only a message written by this send can match.
        let reader = try openDatabase(dbPath: nil, key: nil)
        defer { reader.close() }
        let myUserId = try reader.myUserId()
        let baseline = try reader.maxLogId()

        try automator.sendMessage(to: chat, message: message, selfChat: selfChat)

        let deadline = Date().addingTimeInterval(confirmTimeout)
        while true {
            let found = try reader.outgoingMessages(text: message, authorId: myUserId, afterLogId: baseline)
            // Prefer a row the server has acked; a pending one may still be rewritten.
            if let sent = found.first(where: { $0.logId != DatabaseReader.pendingLogId }) {
                print("Message sent to '\(target)' and confirmed in the database (chat \(chatLabel(reader, sent.chatId)), log_id \(sent.logId)).")
                return
            }
            if Date() >= deadline {
                if let pending = found.first {
                    print("Message sent to '\(target)' (chat \(chatLabel(reader, pending.chatId))); KakaoTalk has not received the server ack yet.")
                    return
                }
                fputs("Return was pressed for '\(target)', but the message did not appear in the database within \(Int(confirmTimeout))s. Check KakaoTalk before retrying.\n", stderr)
                throw ExitCode(2)
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    private func chatLabel(_ reader: DatabaseReader, _ chatId: Int64) -> String {
        let name = MetadataStore().name(for: chatId)
            ?? (try? reader.chats(limit: 999999))?.first(where: { $0.id == chatId })?.displayName
        return name.map { "\($0), id \(chatId)" } ?? "id \(chatId)"
    }
}
