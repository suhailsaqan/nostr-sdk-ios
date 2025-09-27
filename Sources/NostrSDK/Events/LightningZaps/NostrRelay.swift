//
//  NostrRelay.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import Foundation

/// Dummy implementation of relay URL validation.
/// In your project, replace this with your actual validation logic.
public func validateRelayURLString(_ urlString: String) throws -> URL {
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    return url
}

/// Represents a relay in a Nostr event.
/// Conforms to RelayProviding by exposing a primary relay URL.
public struct NostrRelay: RelayProviding, Equatable, Hashable, RelayURLValidating {
    /// The underlying tag representing the relay.
    public let tag: Tag
    
    /// Returns the primary relay URL from the tag’s additional parameters.
    /// Conforms to the RelayProviding protocol.
    public var relayURL: URL? {
        guard let firstRelay = tag.otherParameters.first, !firstRelay.isEmpty else {
            return nil
        }
        return try? validateRelayURLString(firstRelay)
    }
    
    /// An array of all relay URLs extracted from the tag.
    public var allRelayURLs: [URL] {
        tag.otherParameters.compactMap { relayString in
            return try? validateRelayURLString(relayString)
        }
    }
    
    /// Initializes a NostrRelay from a relay tag.
    /// Returns nil if the tag is not a valid relay tag.
    ///
    /// - Parameter relayTag: A tag with the name "relays" and at least one relay URL in its other parameters.
    public init?(relayTag: Tag) {
        guard relayTag.name == "relays", !relayTag.otherParameters.isEmpty else {
            return nil
        }
        self.tag = relayTag
    }
    
    /// Initializes a NostrRelay with a single relay URL.
    ///
    /// - Parameter relayURL: The relay URL.
    public init(relayURL: URL) {
        // Here, the tag is constructed with "relays" as both the name and a placeholder value,
        // and the relay URL stored as the sole element in otherParameters.
        self.tag = Tag(name: "relays", value: "relays", otherParameters: [relayURL.absoluteString])
    }
}
