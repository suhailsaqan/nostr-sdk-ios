//
//  LightningZapRequestEvent.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

//
//  LightningZapsEvent.swift
//
//  Created by Your Name on [Date].
//
//  Implementation for Lightning Zaps as defined in NIP-57.
//  This file defines two event types:
//    - LightningZapRequestEvent (kind 9734)
//    - LightningZapReceiptEvent (kind 9735)
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

        // The "relays" tag: first element is "relays", followed by relay URLs.
        var relayTagValues = ["relays"]
        relayTagValues.append(contentsOf: relays)
        tags.append(
            Tag(
                name: "relays", value: relays.first ?? "",
                otherParameters: Array(relays.dropFirst())))

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
        return tags.first(where: { $0.name == "relays" })?.otherParameters ?? []
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

/// Lightning Zap Receipt Event (kind 9735)
///
/// A zap receipt is generated by a lightning node when the invoice from a zap request has been paid.
/// It confirms the zap payment and contains the bolt11 invoice details along with the original zap request.
/// - Note: See [NIP‑57 Lightning Zaps](https://github.com/nostr-protocol/nips/blob/master/57.md) for details.
public final class LightningZapReceiptEvent: NostrEvent {

    // MARK: - Unavailable Initializers

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    @available(
        *, unavailable, message: "This initializer is unavailable for LightningZapReceiptEvent."
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
        *, unavailable, message: "This initializer is unavailable for LightningZapReceiptEvent."
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

    /// Creates a new LightningZapReceiptEvent.
    ///
    /// - Parameters:
    ///   - recipientPubkey: The recipient’s public key (tag "p").
    ///   - senderPubkey: (Optional) The sender’s public key (tag "P") from the zap request.
    ///   - eventId: (Optional) The event id from the zap request (tag "e").
    ///   - eventCoordinate: (Optional) The event coordinate from the zap request (tag "a").
    ///   - bolt11: The bolt11 invoice string (tag "bolt11").
    ///   - zapRequestJSON: The JSON-encoded zap request (tag "description").
    ///   - preimage: (Optional) The preimage matching the bolt11 invoice (tag "preimage").
    ///   - createdAt: The timestamp corresponding to when the invoice was paid.
    ///   - keypair: The keypair to sign the zap receipt.
    ///   - additionalRelays: (Optional) A list of relay URLs where the receipt should be published.
    public init(
        recipientPubkey: String,
        senderPubkey: String? = nil,
        eventId: String? = nil,
        eventCoordinate: String? = nil,
        bolt11: String,
        zapRequestJSON: String,
        preimage: String? = nil,
        createdAt: Int64,
        signedBy keypair: Keypair,
        additionalRelays: [String] = []
    ) throws {
        var tags = [Tag]()

        // Required "p" tag (recipient’s pubkey).
        tags.append(Tag(name: "p", value: recipientPubkey))

        // Optional "P" tag (zap sender’s pubkey).
        if let senderPubkey = senderPubkey {
            tags.append(Tag(name: "P", value: senderPubkey))
        }

        // Optional "e" tag.
        if let eventId = eventId {
            tags.append(Tag(name: "e", value: eventId))
        }

        // Optional "a" tag.
        if let eventCoordinate = eventCoordinate {
            tags.append(Tag(name: "a", value: eventCoordinate))
        }

        // The bolt11 invoice tag.
        tags.append(Tag(name: "bolt11", value: bolt11))

        // The description tag contains the JSON-encoded zap request.
        tags.append(Tag(name: "description", value: zapRequestJSON))

        // Optional preimage tag.
        if let preimage = preimage {
            tags.append(Tag(name: "preimage", value: preimage))
        }

        // Optionally include a "relays" tag if additional relay URLs are provided.
        if !additionalRelays.isEmpty {
            var relayTagValues = ["relays"]
            relayTagValues.append(contentsOf: additionalRelays)
            tags.append(
                Tag(
                    name: "relays", value: additionalRelays.first ?? "",
                    otherParameters: Array(additionalRelays.dropFirst())))
        }

        try super.init(
            kind: .zapReceipt,  // .zapReceipt should correspond to 9735 in your EventKind enum.
            content: "",
            tags: tags,
            createdAt: createdAt,
            signedBy: keypair
        )
    }

    // MARK: - Computed Properties

    /// Returns the recipient’s public key from the "p" tag.
    public var recipientPubkey: String? {
        return firstValue(forTag: "p")
    }

    /// Returns the sender’s public key from the "P" tag, if available.
    public var senderPubkey: String? {
        return firstValue(forTag: "P")
    }

    /// Returns the event id from the "e" tag if present.
    public var eventId: String? {
        return firstValue(forTag: "e")
    }

    /// Returns the event coordinate from the "a" tag if present.
    public var eventCoordinate: String? {
        return firstValue(forTag: "a")
    }

    /// Returns the bolt11 invoice string.
    public var bolt11: String? {
        return firstValue(forTag: "bolt11")
    }

    /// Returns the JSON-encoded zap request from the "description" tag.
    public var zapRequestJSON: String? {
        return firstValue(forTag: "description")
    }

    /// Returns the preimage if provided.
    public var preimage: String? {
        return firstValue(forTag: "preimage")
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

    /// Creates a Lightning Zap Receipt Event (kind 9735) for confirming a zap payment.
    ///
    /// - Parameters:
    ///   - recipientPubkey: The recipient’s hex-encoded public key.
    ///   - senderPubkey: (Optional) The sender’s pubkey from the zap request.
    ///   - eventId: (Optional) The event id from the zap request.
    ///   - eventCoordinate: (Optional) The event coordinate from the zap request.
    ///   - bolt11: The bolt11 invoice string.
    ///   - zapRequestJSON: The JSON-encoded zap request event.
    ///   - preimage: (Optional) A preimage matching the bolt11 invoice.
    ///   - createdAt: The invoice paid timestamp.
    ///   - keypair: The keypair to sign the zap receipt.
    ///   - additionalRelays: (Optional) Relay URLs where the zap receipt should be published.
    /// - Returns: A signed LightningZapReceiptEvent.
    public func lightningZapReceiptEvent(
        recipientPubkey: String,
        senderPubkey: String? = nil,
        eventId: String? = nil,
        eventCoordinate: String? = nil,
        bolt11: String,
        zapRequestJSON: String,
        preimage: String? = nil,
        createdAt: Int64,
        signedBy keypair: Keypair,
        additionalRelays: [String] = []
    ) throws -> LightningZapReceiptEvent {
        return try LightningZapReceiptEvent(
            recipientPubkey: recipientPubkey,
            senderPubkey: senderPubkey,
            eventId: eventId,
            eventCoordinate: eventCoordinate,
            bolt11: bolt11,
            zapRequestJSON: zapRequestJSON,
            preimage: preimage,
            createdAt: createdAt,
            signedBy: keypair,
            additionalRelays: additionalRelays
        )
    }
}

