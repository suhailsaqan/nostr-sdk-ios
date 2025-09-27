//
//  HTTPAuthEvent.swift
//
//
//  Created by Suhail Saqan on 03/08/25.
//

import Foundation

/// An event that provides HTTP authentication using Nostr events.
/// The content should be empty and the event should contain 'u' and 'method' tags.
///
/// See [NIP-98](https://github.com/nostr-protocol/nips/blob/master/98.md).
public final class HTTPAuthEvent: NostrEvent {
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

    /// The absolute URL of the HTTP request.
    public var url: URL? {
        guard let urlString = firstValueForRawTagName("u") else {
            return nil
        }
        return URL(string: urlString)
    }

    /// The HTTP method of the request (e.g., GET, POST, PUT, DELETE).
    public var method: String? {
        firstValueForRawTagName("method")
    }
}

extension EventCreating {
    /// Creates an HTTP authentication event for the given URL and method.
    /// - Parameters:
    ///   - url: The absolute URL of the HTTP request.
    ///   - method: The HTTP method (e.g., GET, POST, PUT, DELETE).
    ///   - keypair: The keypair to sign the event with.
    /// - Returns: A signed HTTPAuthEvent.
    /// - Throws: An error if the event could not be created or signed.
    public func createHTTPAuthEvent(url: URL, method: String, signedBy keypair: Keypair) throws
        -> HTTPAuthEvent
    {
        try HTTPAuthEvent.Builder()
            .url(url)
            .method(method)
            .build(signedBy: keypair)
    }
}

extension HTTPAuthEvent {
    /// Builder of a ``HTTPAuthEvent``.
    public final class Builder: NostrEvent.Builder<HTTPAuthEvent> {
        public init() {
            super.init(kind: .httpAuth)
        }

        /// The absolute URL of the HTTP request.
        @discardableResult
        public final func url(_ url: URL) -> Self {
            appendTags(Tag(name: "u", value: url.absoluteString))
        }

        /// The HTTP method of the request (e.g., GET, POST, PUT, DELETE).
        @discardableResult
        public final func method(_ method: String) -> Self {
            appendTags(Tag(name: "method", value: method.uppercased()))
        }
    }
}

