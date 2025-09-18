//
//  NWCResponseEvent.swift
//  nostr-sdk-ios
//
//  Created by Suhail Saqan on 4/19/25.
//

import Foundation

public final class NWCResponseEvent: NostrEvent {
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    @available(*, unavailable, message: "This initializer is unavailable for this class.")
    required init(
        kind: EventKind, content: String, tags: [Tag] = [],
        createdAt: Int64 = Int64(Date.now.timeIntervalSince1970), signedBy keypair: Keypair
    ) throws {
        try super.init(
            kind: kind, content: content, tags: tags, createdAt: createdAt, signedBy: keypair)
    }

    @available(*, unavailable, message: "This initializer is unavailable for this class.")
    required init(
        kind: EventKind, content: String, tags: [Tag] = [],
        createdAt: Int64 = Int64(Date.now.timeIntervalSince1970), pubkey: String
    ) {
        super.init(kind: kind, content: content, tags: tags, createdAt: createdAt, pubkey: pubkey)
    }

    @available(*, unavailable, message: "This initializer is unavailable for this class.")
    override init(
        id: String, pubkey: String, createdAt: Int64, kind: EventKind, tags: [Tag], content: String,
        signature: String?
    ) {
        super.init(
            id: id, pubkey: pubkey, createdAt: createdAt, kind: kind, tags: tags, content: content,
            signature: signature)
    }

    /// Creates a zap response event (kind 23195) for a lightning payment.
    ///
    /// - Parameters:
    ///   - content: Optional message to include with the zap response.
    ///   - tags: An array of tags. Must include:
    ///       - A `p` tag with the recipient’s hex-encoded pubkey.
    ///   - createdAt: The creation timestamp.
    ///   - keypair: The sender's keypair for signing.
    public init(
        content: String, tags: [Tag] = [],
        createdAt: Int64 = Int64(Date.now.timeIntervalSince1970),
        signedBy keypair: Keypair
    ) throws {
        try super.init(
            kind: .nwcResponse, content: content, tags: tags, createdAt: createdAt,
            signedBy: keypair)
    }

    // MARK: - Computed properties for NWC Response Tags

    /// The recipient's hex-encoded public key from the `p` tag.
    public var recipientPubkey: String? {
        return firstValueForRawTagName("p")
    }
}

extension EventCreating {

    /// Creates a NWC Response event (kind 23195) as specified in NIP‑47.
    ///
    /// The following tags will be automatically created:
    /// - `p`: The recipient’s hex-encoded public key.
    ///
    /// - Parameters:
    ///   - content: An optional message to include with the zap response.
    ///   - recipientPubkey: The recipient's hex-encoded public key.
    ///   - keypair: The signing keypair.
    /// - Returns: The signed `NWCResponseEvent`.
    public func nwcResponseEvent(
        content: String,
        recipientPubkey: String,
        signedBy keypair: Keypair
    ) throws -> NWCResponseEvent {
        var tags: [Tag] = [Tag]()

        // "p" tag: the recipient's hex-encoded public key.
        let pTag = Tag(name: "p", value: recipientPubkey)
        tags.append(pTag)

        // Create and return the signed LightningZapsResponseEvent.
        return try NWCResponseEvent(content: content, tags: tags, signedBy: keypair)
    }
}
