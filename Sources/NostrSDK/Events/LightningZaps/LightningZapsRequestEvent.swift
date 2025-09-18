//
//  LightningZapsRequestEvent.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/9/25.
//

import Foundation

public final class LightningZapsRequestEvent: NostrEvent {
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

    /// Creates a zap request event (kind 9734) for a lightning payment.
    ///
    /// - Parameters:
    ///   - content: Optional message to include with the zap request.
    ///   - tags: An array of tags. Must include:
    ///       - A `relays` tag listing the relay URLs for publishing the zap receipt.
    ///       - An `amount` tag (amount in millisats as a string).
    ///       - An `lnurl` tag with the recipient's lnurl pay url.
    ///       - A `p` tag with the recipient’s hex-encoded pubkey.
    ///     Optionally, the event MAY include:
    ///       - An `e` tag for a hex-encoded event id.
    ///       - An `a` tag for an event coordinate.
    ///   - createdAt: The creation timestamp.
    ///   - keypair: The sender's keypair for signing.
    public init(
        content: String, tags: [Tag] = [],
        createdAt: Int64 = Int64(Date.now.timeIntervalSince1970),
        signedBy keypair: Keypair
    ) throws {
        try super.init(
            kind: .zapRequest, content: content, tags: tags, createdAt: createdAt,
            signedBy: keypair)
    }

    // MARK: - Computed properties for Zap Request Tags

    /// Relay URLs where the recipient's wallet should publish its zap receipt.
    /// The first element of the `relays` tag is the tag name itself, so this returns all subsequent values.
    //    public var relayUrls: [String]? {
    //        guard let relayTag = tag(withName: "relays") else {
    //            return nil
    //        }
    //        return Array(relayTag.dropFirst())
    //    }

    /// The amount in millisats as specified in the `amount` tag.
    public var amount: Int? {
        guard let amountString: String = firstValueForRawTagName("amount"),
            let amount = Int(amountString)
        else {
            return nil
        }
        return amount
    }

    /// The lnurl pay request url (bech32-encoded with the prefix `lnurl`) from the `lnurl` tag.
    public var lnurl: String? {
        return firstValueForRawTagName("lnurl")
    }

    /// The recipient's hex-encoded public key from the `p` tag.
    public var recipientPubkey: String? {
        return firstValueForRawTagName("p")
    }

    /// Optional hex-encoded event id from the `e` tag if zapping an event.
    public var eventId: String? {
        return firstValueForRawTagName("e")
    }
}

/// An error type to indicate invalid parameters during event creation.
enum LightningZapEventCreationError: Error {
    case emptyRelays
}

extension EventCreating {

    /// Creates a Lightning Zap Request event (kind 9734) as specified in NIP‑57.
    ///
    /// The following tags will be automatically created:
    /// - `relays`: A tag listing the relay URLs where the zap receipt should be published.
    /// - `amount`: The amount (in millisats) as a string.
    /// - `lnurl`: The recipient's lnurl pay request URL.
    /// - `p`: The recipient’s hex-encoded public key.
    /// - Optionally, if an event id is provided, an `e` tag will be added.
    ///
    /// - Parameters:
    ///   - content: An optional message to include with the zap request.
    ///   - relays: An array of relay URLs. Must contain at least one URL.
    ///   - amount: The amount in millisats.
    ///   - lnurl: The recipient's lnurl pay URL (bech32-encoded with the prefix `lnurl`).
    ///   - recipientPubkey: The recipient's hex-encoded public key.
    ///   - eventId: An optional event id if zapping an event.
    ///   - keypair: The signing keypair.
    /// - Returns: The signed `LightningZapsRequestEvent`.
    public func lightningZapsRequestEvent(
        content: String,
        relays: [String],
        amount: Int? = nil,
        lnurl: String? = nil,
        isAnon: Bool? = nil,
        anonReq: String? = nil,
        recipientPubkey: String,
        eventId: String? = nil,
        signedBy keypair: Keypair
    ) throws -> LightningZapsRequestEvent {

        // Ensure there is at least one relay URL.
        guard let firstRelay = relays.first else {
            throw LightningZapEventCreationError.emptyRelays
        }

        var tags: [Tag] = [Tag]()

        // "relays" tag: first element is the tag value; subsequent elements are additional relays.
        let relaysTag = Tag(name: "relays", value: firstRelay)
        tags.append(relaysTag)

        // "amount" tag: the amount is encoded as a string.
        if let amountTag = amount {
            tags.append(Tag(name: "amount", value: String(amountTag)))
        }
        
        // "lnurl" tag: the recipient's lnurl pay request URL.
        if let lnurlTag = lnurl {
            tags.append(Tag(name: "lnurl", value: lnurlTag))
        }

        // "p" tag: the recipient's hex-encoded public key.
        let pTag = Tag(name: "p", value: recipientPubkey)
        tags.append(pTag)

        if isAnon! {
            tags.append(Tag(name: "anon", value: ""))
        } else if let anonVal = anonReq {
            let anonTag = Tag(name: "anon", value: anonVal)
            tags.append(anonTag)
        }

        // Optionally, add the "e" tag if an event id is provided.
        if let eventId = eventId {
            let eTag = Tag(name: "e", value: eventId)
            tags.append(eTag)
        }

        // Create and return the signed LightningZapsRequestEvent.
        return try LightningZapsRequestEvent(content: content, tags: tags, signedBy: keypair)
    }
}
