//
//  NWCInfoEvent.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import Foundation

/// NWC Info Event (kind 13194)
///
/// Contains wallet service information for Nostr Wallet Connect.
/// This is a replaceable event that provides details about the wallet service capabilities.
/// - Note: See [NIP‑47 Nostr Wallet Connect](https://github.com/nostr-protocol/nips/blob/master/47.md) for details.
public final class NWCInfoEvent: NostrEvent {

    // MARK: - Unavailable Initializers

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        // Verify that the event kind is 13194 (nwc info).
        if kind != .nwcInfo {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid kind for NWCInfoEvent, expected 13194"))
        }
    }

    @available(
        *, unavailable, message: "This initializer is unavailable for NWCInfoEvent."
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
        *, unavailable, message: "This initializer is unavailable for NWCInfoEvent."
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

    /// Creates a new NWCInfoEvent.
    ///
    /// - Parameters:
    ///   - name: The name of the wallet service.
    ///   - description: Description of the wallet service.
    ///   - icon: URL to the wallet service icon.
    ///   - version: The NWC protocol version supported.
    ///   - supportedMethods: Array of supported wallet methods.
    ///   - createdAt: The creation timestamp.
    ///   - keypair: The wallet service's keypair for signing.
    public init(
        name: String,
        description: String,
        icon: String? = nil,
        version: String = "1.0",
        supportedMethods: [String],
        createdAt: Int64 = Int64(Date().timeIntervalSince1970),
        signedBy keypair: Keypair
    ) throws {
        let info = NWCWalletInfo(
            name: name,
            description: description,
            icon: icon,
            version: version,
            supportedMethods: supportedMethods
        )

        let content = try JSONEncoder().encode(info)
        let contentString = String(data: content, encoding: .utf8) ?? "{}"

        try super.init(
            kind: .nwcInfo,
            content: contentString,
            tags: [],
            createdAt: createdAt,
            signedBy: keypair
        )
    }

    // MARK: - Computed Properties

    /// Returns the wallet info from the content.
    public var walletInfo: NWCWalletInfo? {
        guard let data = content.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(NWCWalletInfo.self, from: data)
    }
}

/// NWC Wallet Information
///
/// Contains information about the wallet service capabilities.
public struct NWCWalletInfo: Codable {
    /// The name of the wallet service
    public let name: String

    /// Description of the wallet service
    public let description: String

    /// URL to the wallet service icon
    public let icon: String?

    /// The NWC protocol version supported
    public let version: String

    /// Array of supported wallet methods
    public let supportedMethods: [String]

    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case icon
        case version
        case supportedMethods = "supported_methods"
    }
}

// MARK: - EventCreating Extensions

extension EventCreating {

    /// Creates a NWC Info Event (kind 13194) as specified in NIP‑47.
    ///
    /// - Parameters:
    ///   - name: The name of the wallet service.
    ///   - description: Description of the wallet service.
    ///   - icon: URL to the wallet service icon.
    ///   - version: The NWC protocol version supported.
    ///   - supportedMethods: Array of supported wallet methods.
    ///   - keypair: The wallet service's keypair for signing.
    /// - Returns: The signed `NWCInfoEvent`.
    public func nwcInfoEvent(
        name: String,
        description: String,
        icon: String? = nil,
        version: String = "1.0",
        supportedMethods: [String],
        signedBy keypair: Keypair
    ) throws -> NWCInfoEvent {
        return try NWCInfoEvent(
            name: name,
            description: description,
            icon: icon,
            version: version,
            supportedMethods: supportedMethods,
            signedBy: keypair
        )
    }
}
