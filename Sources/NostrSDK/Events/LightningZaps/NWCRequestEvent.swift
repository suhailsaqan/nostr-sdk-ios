//
//  NWCRequestEvent.swift
//  nostr-sdk-ios
//
//  Created by Suhail Saqan on 3/31/25.
//

import Foundation

public final class NWCRequestEvent: NostrEvent {
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

    /// Creates a zap request event (kind 23194) for a lightning payment.
    ///
    /// - Parameters:
    ///   - content: Optional message to include with the zap request.
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
            kind: .nwcRequest, content: content, tags: tags, createdAt: createdAt,
            signedBy: keypair)
    }

    // MARK: - Computed properties for NWC Request Tags

    /// The recipient's hex-encoded public key from the `p` tag.
    public var recipientPubkey: String? {
        return firstValueForRawTagName("p")
    }
}

extension EventCreating {

    /// Creates a NWC Request event (kind 23194) as specified in NIP‑47.
    ///
    /// The following tags will be automatically created:
    /// - `p`: The recipient’s hex-encoded public key.
    ///
    /// - Parameters:
    ///   - content: An optional message to include with the zap request.
    ///   - recipientPubkey: The recipient's hex-encoded public key.
    ///   - keypair: The signing keypair.
    /// - Returns: The signed `NWCRequestEvent`.
    public func nwcRequestEvent(
        content: String,
        recipientPubkey: String,
        signedBy keypair: Keypair
    ) throws -> NWCRequestEvent {
        var tags: [Tag] = [Tag]()

        // "p" tag: the recipient's hex-encoded public key.
        let pTag = Tag(name: "p", value: recipientPubkey)
        tags.append(pTag)

        // Create and return the signed LightningZapsRequestEvent.
        return try NWCRequestEvent(content: content, tags: tags, signedBy: keypair)
    }
}
