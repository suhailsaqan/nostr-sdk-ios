//
//  NWCConnectionURI.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import Foundation

/// NWC Connection URI
///
/// Represents a Nostr Wallet Connect connection URI.
/// Format: `nostr+walletconnect://<wallet-pubkey>?relay=<relay-url>&secret=<secret>`
public struct NWCConnectionURI {
    /// The wallet service's public key
    public let walletPubkey: String

    /// The relay URL for communication
    public let relayURL: String

    /// The shared secret for encryption
    public let secret: String

    /// The original URI string
    public let uriString: String

    /// Creates a NWC Connection URI from a string
    ///
    /// - Parameter uriString: The connection URI string
    /// - Throws: NWCConnectionURIError if the URI is invalid
    public init(uriString: String) throws {
        self.uriString = uriString

        // Parse the URI
        guard let url = URL(string: uriString) else {
            throw NWCConnectionURIError.invalidURI
        }

        // Check scheme
        guard url.scheme == "nostr+walletconnect" else {
            throw NWCConnectionURIError.invalidScheme
        }

        // Extract wallet pubkey from host
        guard let host = url.host, !host.isEmpty else {
            throw NWCConnectionURIError.missingWalletPubkey
        }

        // Validate wallet pubkey format (64 hex characters)
        guard host.count == 64, host.allSatisfy({ $0.isHexDigit }) else {
            throw NWCConnectionURIError.invalidWalletPubkey
        }

        self.walletPubkey = host

        // Extract query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems
        else {
            throw NWCConnectionURIError.missingQueryParameters
        }

        // Extract relay URL
        guard let relayItem = queryItems.first(where: { $0.name == "relay" }),
            let relayURL = relayItem.value, !relayURL.isEmpty
        else {
            throw NWCConnectionURIError.missingRelayURL
        }

        // Validate relay URL
        guard URL(string: relayURL) != nil else {
            throw NWCConnectionURIError.invalidRelayURL
        }

        self.relayURL = relayURL

        // Extract secret
        guard let secretItem = queryItems.first(where: { $0.name == "secret" }),
            let secret = secretItem.value, !secret.isEmpty
        else {
            throw NWCConnectionURIError.missingSecret
        }

        self.secret = secret
    }

    /// Creates a NWC Connection URI from components
    ///
    /// - Parameters:
    ///   - walletPubkey: The wallet service's public key
    ///   - relayURL: The relay URL for communication
    ///   - secret: The shared secret for encryption
    public init(walletPubkey: String, relayURL: String, secret: String) {
        self.walletPubkey = walletPubkey
        self.relayURL = relayURL
        self.secret = secret
        self.uriString = "nostr+walletconnect://\(walletPubkey)?relay=\(relayURL)&secret=\(secret)"
    }

    /// Returns the URI as a URL
    public var url: URL? {
        return URL(string: uriString)
    }
}

/// NWC Connection URI Error
public enum NWCConnectionURIError: Error, LocalizedError {
    case invalidURI
    case invalidScheme
    case missingWalletPubkey
    case invalidWalletPubkey
    case missingQueryParameters
    case missingRelayURL
    case invalidRelayURL
    case missingSecret

    public var errorDescription: String? {
        switch self {
        case .invalidURI:
            return "Invalid NWC connection URI"
        case .invalidScheme:
            return "Invalid URI scheme, expected 'nostr+walletconnect'"
        case .missingWalletPubkey:
            return "Missing wallet public key in URI"
        case .invalidWalletPubkey:
            return "Invalid wallet public key format"
        case .missingQueryParameters:
            return "Missing query parameters in URI"
        case .missingRelayURL:
            return "Missing relay URL parameter"
        case .invalidRelayURL:
            return "Invalid relay URL format"
        case .missingSecret:
            return "Missing secret parameter"
        }
    }
}

// MARK: - Character Extensions

extension Character {
    fileprivate var isHexDigit: Bool {
        return ("0"..."9").contains(self) || ("a"..."f").contains(self)
            || ("A"..."F").contains(self)
    }
}
