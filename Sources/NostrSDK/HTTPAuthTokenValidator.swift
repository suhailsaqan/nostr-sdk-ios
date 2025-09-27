//
//  HTTPAuthTokenValidator.swift
//
//
//  Created by Suhail Saqan on 03/08/25.
//

import Foundation

/// A utility class for validating HTTP authentication tokens using NIP-98.
///
/// See [NIP-98](https://github.com/nostr-protocol/nips/blob/master/98.md).
public final class HTTPAuthTokenValidator: EventVerifying {

    /// Validates an HTTP authentication token for the given URL and method.
    /// - Parameters:
    ///   - token: The base64-encoded token (with or without "Nostr " prefix).
    ///   - url: The absolute URL of the HTTP request.
    ///   - method: The HTTP method (e.g., GET, POST, PUT, DELETE).
    ///   - maxAge: The maximum age of the token in seconds (default: 60 seconds).
    /// - Returns: A validation result containing the public key and validation status.
    /// - Throws: An error if the token could not be validated.
    public static func validateToken(
        _ token: String,
        url: URL,
        method: String,
        maxAge: Int64 = 60
    ) throws -> HTTPAuthValidationResult {
        // Remove "Nostr " prefix if present
        let cleanToken = token.hasPrefix("Nostr ") ? String(token.dropFirst(6)) : token

        // Decode the base64 token
        guard let tokenData = Data(base64Encoded: cleanToken) else {
            throw HTTPAuthValidationError.invalidTokenFormat
        }

        // Decode the event
        let authEvent: HTTPAuthEvent
        do {
            authEvent = try JSONDecoder().decode(HTTPAuthEvent.self, from: tokenData)
        } catch {
            throw HTTPAuthValidationError.invalidEventFormat
        }

        // Validate the event kind
        guard authEvent.kind == .httpAuth else {
            throw HTTPAuthValidationError.invalidEventKind
        }

        // Validate the URL
        guard let eventURL = authEvent.url, eventURL.absoluteString == url.absoluteString else {
            throw HTTPAuthValidationError.urlMismatch
        }

        // Validate the method
        guard let eventMethod = authEvent.method, eventMethod.uppercased() == method.uppercased()
        else {
            throw HTTPAuthValidationError.methodMismatch
        }

        // Validate the timestamp (check if token is not too old)
        let currentTime = Int64(Date().timeIntervalSince1970)
        let tokenAge = currentTime - authEvent.createdAt
        guard tokenAge <= maxAge else {
            throw HTTPAuthValidationError.tokenExpired
        }

        // Validate the signature
        guard let signature = authEvent.signature else {
            throw HTTPAuthValidationError.missingSignature
        }

        // Verify the signature
        let validator = HTTPAuthTokenValidator()
        try validator.verifyEvent(authEvent)

        return HTTPAuthValidationResult(
            isValid: true,
            publicKey: authEvent.pubkey,
            createdAt: authEvent.createdAt,
            url: eventURL,
            method: eventMethod
        )
    }

    /// Validates an HTTP authentication token and returns the public key if valid.
    /// - Parameters:
    ///   - token: The base64-encoded token (with or without "Nostr " prefix).
    ///   - url: The absolute URL of the HTTP request.
    ///   - method: The HTTP method (e.g., GET, POST, PUT, DELETE).
    ///   - maxAge: The maximum age of the token in seconds (default: 60 seconds).
    /// - Returns: The public key of the token creator if valid.
    /// - Throws: An error if the token could not be validated.
    public static func extractPublicKey(
        from token: String,
        url: URL,
        method: String,
        maxAge: Int64 = 60
    ) throws -> String {
        let result = try validateToken(token, url: url, method: method, maxAge: maxAge)
        return result.publicKey
    }
}

/// The result of HTTP authentication token validation.
public struct HTTPAuthValidationResult {
    /// Whether the token is valid.
    public let isValid: Bool

    /// The public key of the token creator.
    public let publicKey: String

    /// The timestamp when the token was created.
    public let createdAt: Int64

    /// The URL the token was created for.
    public let url: URL

    /// The HTTP method the token was created for.
    public let method: String
}

/// Errors that can occur during HTTP authentication token validation.
public enum HTTPAuthValidationError: Error, LocalizedError {
    case invalidTokenFormat
    case invalidEventFormat
    case invalidEventKind
    case urlMismatch
    case methodMismatch
    case tokenExpired
    case missingSignature
    case invalidSignature

    public var errorDescription: String? {
        switch self {
        case .invalidTokenFormat:
            return "Invalid token format - token is not valid base64"
        case .invalidEventFormat:
            return "Invalid event format - token does not contain a valid Nostr event"
        case .invalidEventKind:
            return "Invalid event kind - token is not an HTTP auth event"
        case .urlMismatch:
            return "URL mismatch - token URL does not match request URL"
        case .methodMismatch:
            return "Method mismatch - token method does not match request method"
        case .tokenExpired:
            return "Token expired - token is too old"
        case .missingSignature:
            return "Missing signature - token event has no signature"
        case .invalidSignature:
            return "Invalid signature - token signature verification failed"
        }
    }
}
