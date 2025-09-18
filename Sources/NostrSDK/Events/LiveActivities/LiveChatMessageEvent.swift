//
//  LiveChatMessageEvent.swift
//
//
//  Created by Suhail Saqan on 02/06/25.
//

import Foundation

/// A live chat message event (kind 1311) for live streaming chat messages as described in NIP‑53.
/// This event MUST include an "a" tag referencing the associated live event in the following format:
/// ["a", "30311:<liveEventPubKey>:<d‑identifier>", "<optional relay URL>", "root"].
public final class LiveChatMessageEvent: NostrEvent {

    // MARK: - Decoding

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        // Optionally, verify that the event kind is 1311.
        if kind != .liveChatMessage {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid kind for LiveChatMessageEvent"))
        }
    }

    // MARK: - Unavailable Initializers

    @available(
        *, unavailable,
        message:
            "This initializer is unavailable for LiveChatMessageEvent. Use init(content:tags:createdAt:signedBy:) instead."
    )
    required init(
        kind: EventKind, content: String, tags: [Tag], createdAt: Int64, signedBy keypair: Keypair
    ) throws {
        fatalError("Unavailable")
    }

    @available(
        *, unavailable,
        message:
            "This initializer is unavailable for LiveChatMessageEvent. Use init(content:tags:createdAt:pubkey:) instead."
    )
    required init(kind: EventKind, content: String, tags: [Tag], createdAt: Int64, pubkey: String) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, message: "This initializer is unavailable for LiveChatMessageEvent.")
    override init(
        id: String, pubkey: String, createdAt: Int64, kind: EventKind, tags: [Tag], content: String,
        signature: String?
    ) {
        fatalError("Unavailable")
    }

    // MARK: - Designated Initializer

    /// Creates a new Live Chat Message event.
    /// - Parameters:
    ///   - content: The chat message content.
    ///   - tags: The event tags. (Should include the required "a" tag per NIP‑53.)
    ///   - createdAt: The creation timestamp (in seconds since 1970).
    ///   - keypair: The signing keypair.
    public init(
        content: String,
        tags: [Tag] = [],
        createdAt: Int64 = Int64(Date.now.timeIntervalSince1970),
        signedBy keypair: Keypair
    ) throws {
        try super.init(
            kind: .liveChatMessage, content: content, tags: tags, createdAt: createdAt,
            signedBy: keypair)
    }

    // MARK: - Live Event Reference

    /// Parses and returns the live event reference from the "a" tag (if available).
    ///
    /// The expected format for the "a" tag is:
    /// ```swift
    /// ["a", "30311:<liveEventPubKey>:<d‑identifier>", "<optional relay URL>", "root"]
    /// ```
    ///
    /// - Returns: A tuple containing:
    ///   - `liveEventKind`: The live event’s kind (should be "30311").
    ///   - `pubkey`: The public key of the live event’s creator.
    ///   - `d`: The unique d‑identifier for the live event.
    ///   - `relay`: An optional relay URL (if provided).
    ///   - `marker`: The marker (e.g. "root").
    public var liveEventReference:
        (liveEventKind: String, pubkey: String, d: String, relay: String?, marker: String)?
    {
        // Look for an "a" tag whose values array contains at least three elements
        // (which will serialize as a 4-item JSON array including the tag name).
        // Here we expect:
        //   values[0] -> "30311:<liveEventPubKey>:<d‑identifier>"
        //   values[1] -> relay (can be an empty string)
        //   values[2] -> marker (should be "root")
        let aTag = tags.first { tag in
            guard tag.name == "a" else { return false }
            let combined = [tag.value] + tag.otherParameters
            guard combined.count >= 3 else { return false }
            return combined[2].lowercased() == "root"
        }
        // First, try to find the "a" tag with the correct format.
        guard
            let aTag = tags.first(where: { (tag: Tag) -> Bool in
                let combined = [tag.value] + tag.otherParameters
                return tag.name == "a" && combined.count >= 3 && combined[2].lowercased() == "root"
            })
        else {
            return nil
        }

        // Now that aTag is unwrapped, combine its main value and other parameters.
        let combined = [aTag.value] + aTag.otherParameters

        // Ensure there are at least 3 elements.
        guard combined.count >= 3 else { return nil }

        // The first element should be in the format "30311:<liveEventPubKey>:<d>".
        let referenceComponents = combined[0].split(separator: ":")
        guard referenceComponents.count == 3 else { return nil }

        let liveEventKind = String(referenceComponents[0])
        let pubkey = String(referenceComponents[1])
        let d = String(referenceComponents[2])

        // The second element is the relay URL. If it's empty, we treat it as nil.
        let relay = combined[1].isEmpty ? nil : combined[1]

        // The third element is the marker (e.g. "root").
        let marker = combined[2]

        return (liveEventKind: liveEventKind, pubkey: pubkey, d: d, relay: relay, marker: marker)
    }
}

extension EventCreating {

    /// Creates a Live Chat Message event (kind 1311) as specified in NIP‑53.
    ///
    /// The required "a" tag will be created using the provided parameters.
    ///
    /// - Parameters:
    ///   - content: The live chat message.
    ///   - liveEventPubKey: The public key of the associated live event’s creator.
    ///   - d: The unique identifier (`d` tag) for the live event.
    ///   - liveEventKind: The kind of the live event reference. Defaults to `"30311"`.
    ///   - relay: An optional relay URL for the live event.
    ///   - marker: The tag marker. Defaults to `"root"`.
    ///   - keypair: The keypair to sign the event.
    /// - Returns: The signed `LiveChatMessageEvent`.
    public func liveChatMessageEvent(
        content: String,
        liveEventPubKey: String,
        d: String,
        liveEventKind: String = "30311",
        relay: String? = nil,
        marker: String = "root",
        signedBy keypair: Keypair
    ) throws -> LiveChatMessageEvent {

        var tags = [Tag]()
        // Construct the "a" tag value in the format "liveEventKind:liveEventPubKey:d"
        let aValue = "\(liveEventKind):\(liveEventPubKey):\(d)"
        // Use an empty string if no relay is provided.
        let relayValue = relay ?? ""
        // The values array below produces the JSON: ["a", aValue, relayValue, marker]
        let aTag = Tag(name: "a", value: aValue, otherParameters: [relayValue, marker])
        tags.append(aTag)

        return try LiveChatMessageEvent(content: content, tags: tags, signedBy: keypair)
    }
}
