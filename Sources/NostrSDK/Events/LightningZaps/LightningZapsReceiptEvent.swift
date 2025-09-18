//
//  LightningZapsReceiptEvent.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/9/25.
//

import Foundation

public final class LightningZapsReceiptEvent: NostrEvent {
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        // Verify that the event kind is 9735 (zap receipt).
        if kind != .zapReceipt {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid kind for LightningZapsReceiptEvent, expected 9735"))
        }
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

    /// Creates a zap receipt event (kind 9735) for a lightning payment.
    ///
    /// The zap receipt MUST include:
    /// - A `p` tag with the recipient’s hex-encoded pubkey.
    /// - A `bolt11` tag containing the bolt11 invoice.
    /// - A `description` tag with the JSON-encoded zap request.
    ///
    /// Optionally, it MAY include:
    /// - An `e` tag for a hex-encoded event id.
    /// - An `a` tag for an event coordinate.
    /// - A `P` tag with the zap sender’s hex-encoded pubkey.
    /// - A `preimage` tag matching the payment preimage.
    ///
    /// - Parameters:
    ///   - content: An optional message for the zap receipt (typically empty).
    ///   - tags: An array of tags containing the above requirements.
    ///   - createdAt: The creation timestamp, ideally matching the invoice's `paid_at` time.
    ///   - keypair: The keypair used for signing the event.
    public init(
        content: String,
        tags: [Tag] = [],
        createdAt: Int64 = Int64(Date.now.timeIntervalSince1970),
        signedBy keypair: Keypair
    ) throws {
        try super.init(
            kind: .zapReceipt,
            content: content,
            tags: tags,
            createdAt: createdAt,
            signedBy: keypair)
    }

    // MARK: - Computed properties for Zap Receipt Tags

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

    /// Optional event coordinate from the `a` tag for addressable events.
    public var eventCoordinate: String? {
        return firstValueForRawTagName("a")
    }

    /// The bolt11 invoice from the `bolt11` tag.
    public var bolt11: String? {
        return firstValueForRawTagName("bolt11")
    }

    /// Optional zap sender's hex-encoded public key from the `P` tag.
    public var zapSenderPubkey: String? {
        return firstValueForRawTagName("P")
    }

    /// Optional payment preimage from the `preimage` tag.
    public var preimage: String? {
        return firstValueForRawTagName("preimage")
    }

    /// Decodes the receipt's description (from the `description` tag) into a Lightning Zap Request.
    public var description: LightningZapsRequestEvent? {
        guard let descriptionString = firstValueForRawTagName("description")?.data(using: .utf8)
        else {
            return nil
        }
        return try? JSONDecoder().decode(LightningZapsRequestEvent.self, from: descriptionString)
    }

    public var descriptionString: String? {
        return firstValueForRawTagName("description")
    }
}
