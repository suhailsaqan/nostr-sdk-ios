//
//  LightningZapRequestEvent.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import Foundation

/// Lightning Zap Request Event (kind 9734)
///
/// A zap request represents a payer’s request to a recipient’s lightning wallet
/// for an invoice. The event is *not* published to relays but is sent via HTTP GET to the recipient’s
/// lnurl-pay callback URL.
/// - Note: See [NIP‑57 Lightning Zaps](https://github.com/nostr-protocol/nips/blob/master/57.md) for details.
public final class LightningZapRequestEvent: NostrEvent {

    // MARK: - Unavailable Initializers

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    @available(
        *, unavailable, message: "This initializer is unavailable for LightningZapRequestEvent."
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
        *, unavailable, message: "This initializer is unavailable for LightningZapRequestEvent."
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

    /// Creates a new LightningZapRequestEvent.
    ///
    /// - Parameters:
    ///   - content: An optional message (e.g. "Zap!").
    ///   - relays: A list of relay URLs where the zap receipt should be published.
    ///   - amount: The zap amount in millisats, as a string value (optional).
    ///   - lnurl: The recipient’s lnurl pay URL (encoded in bech32, optional).
    ///   - recipientPubkey: The hex-encoded public key of the recipient (tag "p").
    ///   - eventId: (Optional) Hex-encoded event id if zapping a specific event (tag "e").
    ///   - eventCoordinate: (Optional) An event coordinate for addressable events (tag "a").
    ///   - createdAt: The event timestamp.
    ///   - keypair: The sender’s keypair for signing the event.
    public init(
        content: String = "",
        relays: [String],
        amount: Int? = nil,
        lnurl: String? = nil,
        recipientPubkey: String,
        eventId: String? = nil,
        eventCoordinate: String? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970),
        signedBy keypair: Keypair
    ) throws {
        var tags = [Tag]()

        // The "relays" tag: contains relay URLs as other parameters
        if !relays.isEmpty {
            tags.append(
                Tag(
                    name: "relays",
                    value: relays.first ?? "",
                    otherParameters: Array(relays.dropFirst())))
        }

        // The "amount" tag (if provided)
        if let amount = amount {
            tags.append(Tag(name: "amount", value: String(amount)))
        }

        // The "lnurl" tag (if provided)
        if let lnurl = lnurl {
            tags.append(Tag(name: "lnurl", value: lnurl))
        }

        // The "p" tag (recipient’s pubkey) is required.
        tags.append(Tag(name: "p", value: recipientPubkey))

        // Optional "e" tag.
        if let eventId = eventId {
            tags.append(Tag(name: "e", value: eventId))
        }

        // Optional "a" tag.
        if let eventCoordinate = eventCoordinate {
            tags.append(Tag(name: "a", value: eventCoordinate))
        }

        try super.init(
            kind: .zapRequest,  // .zapRequest should correspond to 9734 in your EventKind enum.
            content: content,
            tags: tags,
            createdAt: createdAt,
            signedBy: keypair
        )
    }

    // MARK: - Computed Properties

    /// Returns the relay URLs from the "relays" tag.
    public var relayURLs: [String] {
        guard let relayTag = tags.first(where: { $0.name == "relays" }) else { return [] }
        var urls = [relayTag.value]
        urls.append(contentsOf: relayTag.otherParameters)
        return urls.filter { !$0.isEmpty }
    }

    /// Returns the zap amount in millisats, if provided.
    public var amount: Int? {
        guard let amountString = firstValue(forTag: "amount") else { return nil }
        return Int(amountString)
    }

    /// Returns the lnurl (if provided).
    public var lnurl: String? {
        return firstValue(forTag: "lnurl")
    }

    /// Returns the recipient’s public key (from the "p" tag).
    public var recipientPubkey: String? {
        return firstValue(forTag: "p")
    }

    /// Returns the event id (from the "e" tag) if present.
    public var eventId: String? {
        return firstValue(forTag: "e")
    }

    /// Returns the event coordinate (from the "a" tag) if present.
    public var eventCoordinate: String? {
        return firstValue(forTag: "a")
    }
}

// MARK: - EventCreating Extensions

extension EventCreating {

    /// Creates a Lightning Zap Request Event (kind 9734) for initiating a zap.
    ///
    /// - Parameters:
    ///   - content: An optional message to send with the zap.
    ///   - relays: The relay URLs for publishing the zap receipt.
    ///   - amount: The zap amount in millisats (optional).
    ///   - lnurl: The recipient’s lnurl pay URL (optional).
    ///   - recipientPubkey: The recipient’s hex-encoded public key.
    ///   - eventId: (Optional) The event id if zapping a specific event.
    ///   - eventCoordinate: (Optional) The event coordinate.
    ///   - keypair: The sender’s keypair to sign the event.
    /// - Returns: A signed LightningZapRequestEvent.
    public func lightningZapRequestEvent(
        content: String = "",
        relays: [String],
        amount: Int? = nil,
        lnurl: String? = nil,
        recipientPubkey: String,
        eventId: String? = nil,
        eventCoordinate: String? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970),
        signedBy keypair: Keypair
    ) throws -> LightningZapRequestEvent {
        return try LightningZapRequestEvent(
            content: content,
            relays: relays,
            amount: amount,
            lnurl: lnurl,
            recipientPubkey: recipientPubkey,
            eventId: eventId,
            eventCoordinate: eventCoordinate,
            createdAt: createdAt,
            signedBy: keypair
        )
    }

}
