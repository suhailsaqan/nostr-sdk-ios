//
//  HTTPAuthTokenGenerator.swift
//
//
//  Created by Suhail Saqan on 03/08/25.
//

import Foundation

/// A utility class for generating HTTP authentication tokens using NIP-98.
///
/// See [NIP-98](https://github.com/nostr-protocol/nips/blob/master/98.md).
public final class HTTPAuthTokenGenerator {

    /// Generates a base64-encoded HTTP authentication token for the given URL and method.
    /// - Parameters:
    ///   - url: The absolute URL of the HTTP request.
    ///   - method: The HTTP method (e.g., GET, POST, PUT, DELETE).
    ///   - keypair: The keypair to sign the event with.
    ///   - includeAuthorizationScheme: Whether to include the "Nostr " prefix in the token.
    /// - Returns: A base64-encoded token that can be used in the Authorization header.
    /// - Throws: An error if the token could not be generated.
    public static func generateToken(
        url: URL,
        method: String,
        signedBy keypair: Keypair,
        includeAuthorizationScheme: Bool = false
    ) throws -> String {
        let authEvent = try HTTPAuthEvent.Builder()
            .url(url)
            .method(method)
            .build(signedBy: keypair)

        let eventData = try JSONEncoder().encode(authEvent)
        let base64Token = eventData.base64EncodedString()

        if includeAuthorizationScheme {
            return "Nostr \(base64Token)"
        } else {
            return base64Token
        }
    }

    /// Generates a base64-encoded HTTP authentication token for the given URL and method with a custom timestamp.
    /// - Parameters:
    ///   - url: The absolute URL of the HTTP request.
    ///   - method: The HTTP method (e.g., GET, POST, PUT, DELETE).
    ///   - keypair: The keypair to sign the event with.
    ///   - createdAt: The timestamp to use for the event creation.
    ///   - includeAuthorizationScheme: Whether to include the "Nostr " prefix in the token.
    /// - Returns: A base64-encoded token that can be used in the Authorization header.
    /// - Throws: An error if the token could not be generated.
    public static func generateToken(
        url: URL,
        method: String,
        signedBy keypair: Keypair,
        createdAt: Int64,
        includeAuthorizationScheme: Bool = false
    ) throws -> String {
        let authEvent = try HTTPAuthEvent.Builder()
            .url(url)
            .method(method)
            .createdAt(createdAt)
            .build(signedBy: keypair)

        let eventData = try JSONEncoder().encode(authEvent)
        let base64Token = eventData.base64EncodedString()

        if includeAuthorizationScheme {
            return "Nostr \(base64Token)"
        } else {
            return base64Token
        }
    }
}

