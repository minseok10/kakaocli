import Foundation

/// Picks the chat-list row a `send` target refers to.
///
/// An exact name wins; otherwise a substring match is accepted only when it is
/// the only one. Anything else is refused rather than guessed, because a message
/// sent to the wrong chat cannot be taken back.
public enum ChatNameMatcher {
    public enum Match: Equatable {
        case found(Int)
        case notFound
        case ambiguous([String])
    }

    /// Match `query` against row names (nil = row whose name could not be read).
    public static func match(_ query: String, in names: [String?]) -> Match {
        let exact = names.indices.filter { names[$0] == query }
        let candidates = exact.isEmpty
            ? names.indices.filter { names[$0]?.localizedCaseInsensitiveContains(query) == true }
            : exact
        switch candidates.count {
        case 0: return .notFound
        case 1: return .found(candidates[0])
        default: return .ambiguous(candidates.compactMap { names[$0] })
        }
    }
}
