//
//  NWCRequestEvent.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import Foundation

/// NWC Request Event (kind 23194)
///
/// Contains encrypted wallet requests for Nostr Wallet Connect.
/// These events contain encrypted JSON-RPC requests to the wallet service.
/// - Note: See [NIP‑47 Nostr Wallet Connect](https://github.com/nostr-protocol/nips/blob/master/47.md) for details.
public final class NWCRequestEvent: NostrEvent {

    // MARK: - Unavailable Initializers

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        // Verify that the event kind is 23194 (nwc request).
        if kind != .nwcRequest {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid kind for NWCRequestEvent, expected 23194"))
        }
    }

    @available(
        *, unavailable, message: "This initializer is unavailable for NWCRequestEvent."
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
        *, unavailable, message: "This initializer is unavailable for NWCRequestEvent."
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

    /// Creates a new NWCRequestEvent.
    ///
    /// - Parameters:
    ///   - encryptedContent: The encrypted request content.
    ///   - recipientPubkey: The recipient's public key (tag "p").
    ///   - createdAt: The creation timestamp.
    ///   - keypair: The client's keypair for signing.
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
            kind: .nwcRequest,
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

    /// Creates a NWC Request Event (kind 23194) as specified in NIP‑47.
    ///
    /// - Parameters:
    ///   - encryptedContent: The encrypted request content.
    ///   - recipientPubkey: The recipient's public key.
    ///   - keypair: The client's keypair for signing.
    /// - Returns: The signed `NWCRequestEvent`.
    public func nwcRequestEvent(
        encryptedContent: String,
        recipientPubkey: String,
        signedBy keypair: Keypair
    ) throws -> NWCRequestEvent {
        return try NWCRequestEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            signedBy: keypair
        )
    }
}
