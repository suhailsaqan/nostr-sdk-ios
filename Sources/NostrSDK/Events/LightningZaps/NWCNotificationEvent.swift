//
//  NWCNotificationEvent.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import Foundation

/// NWC Notification Event (kind 23196)
///
/// Contains encrypted wallet notifications for Nostr Wallet Connect.
/// These events notify clients about wallet events such as received payments.
/// - Note: See [NIP‑47 Nostr Wallet Connect](https://github.com/nostr-protocol/nips/blob/master/47.md) for details.
public final class NWCNotificationEvent: NostrEvent {

    // MARK: - Unavailable Initializers

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        // Verify that the event kind is 23196 (nwc notification).
        if kind != .nwcNotification {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid kind for NWCNotificationEvent, expected 23196"))
        }
    }

    @available(
        *, unavailable, message: "This initializer is unavailable for NWCNotificationEvent."
    )
    required init(
        kind: EventKind,
        content: String,
        tags: [Tag] = [],
        createdAt: Int64,
        signedBy keypair: Keypair
    ) throws {
        try super.init(
            kind: kind, content: content, tags: tags, createdAt: createdAt, signedBy: keypair)
    }

    @available(
        *, unavailable, message: "This initializer is unavailable for NWCNotificationEvent."
    )
    required init(
        kind: EventKind,
        content: String,
        tags: [Tag] = [],
        createdAt: Int64,
        pubkey: String
    ) {
        super.init(kind: kind, content: content, tags: tags, createdAt: createdAt, pubkey: pubkey)
    }

    // MARK: - Designated Initializer

    /// Creates a new NWCNotificationEvent.
    ///
    /// - Parameters:
    ///   - encryptedContent: The encrypted notification content.
    ///   - recipientPubkey: The recipient's public key (tag "p").
    ///   - createdAt: The creation timestamp.
    ///   - keypair: The wallet service's keypair for signing.
    public init(
        encryptedContent: String,
        recipientPubkey: String,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970),
        signedBy keypair: Keypair
    ) throws {
        var tags = [Tag]()

        // Required "p" tag (recipient's pubkey).
        tags.append(Tag(name: "p", value: recipientPubkey))

        try super.init(
            kind: .nwcNotification,
            content: encryptedContent,
            tags: tags,
            createdAt: createdAt,
            signedBy: keypair
        )
    }

    // MARK: - Computed Properties

    /// Returns the recipient's public key from the "p" tag.
    public var recipientPubkey: String? {
        return firstValue(forTag: "p")
    }
}

// MARK: - EventCreating Extensions

extension EventCreating {

    /// Creates a NWC Notification Event (kind 23196) as specified in NIP‑47.
    ///
    /// - Parameters:
    ///   - encryptedContent: The encrypted notification content.
    ///   - recipientPubkey: The recipient's public key.
    ///   - keypair: The wallet service's keypair for signing.
    /// - Returns: The signed `NWCNotificationEvent`.
    public func nwcNotificationEvent(
        encryptedContent: String,
        recipientPubkey: String,
        signedBy keypair: Keypair
    ) throws -> NWCNotificationEvent {
        return try NWCNotificationEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            signedBy: keypair
        )
    }
}
