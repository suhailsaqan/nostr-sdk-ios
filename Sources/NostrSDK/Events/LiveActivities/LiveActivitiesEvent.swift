//
//  LiveActivitiesEvent.swift
//
//
//  Created by Suhail Saqan on 11/6/24.
//

import Foundation

/// A live activities event (kind 9000) is for real-time content updates, generally referred to as "live updates" or "live activities".
///
/// > Note: [NIP-53 Specification](https://github.com/nostr-protocol/nips/blob/master/53.md)
public final class LiveActivitiesEvent: NostrEvent, ParameterizedReplaceableEvent {
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    @available(*, unavailable, message: "This initializer is unavailable for this class.")
    required init(kind: EventKind, content: String, tags: [Tag] = [], createdAt: Int64 = Int64(Date.now.timeIntervalSince1970), signedBy keypair: Keypair) throws {
        try super.init(kind: kind, content: content, tags: tags, createdAt: createdAt, signedBy: keypair)
    }

    @available(*, unavailable, message: "This initializer is unavailable for this class.")
    required init(kind: EventKind, content: String, tags: [Tag] = [], createdAt: Int64 = Int64(Date.now.timeIntervalSince1970), pubkey: String) {
        super.init(kind: kind, content: content, tags: tags, createdAt: createdAt, pubkey: pubkey)
    }

    @available(*, unavailable, message: "This initializer is unavailable for this class.")
    override init(id: String, pubkey: String, createdAt: Int64, kind: EventKind, tags: [Tag], content: String, signature: String?) {
        super.init(id: id, pubkey: pubkey, createdAt: createdAt, kind: kind, tags: tags, content: content, signature: signature)
    }

    public init(content: String, tags: [Tag] = [], createdAt: Int64 = Int64(Date.now.timeIntervalSince1970), signedBy keypair: Keypair) throws {
        try super.init(kind: .liveActivities, content: content, tags: tags, createdAt: createdAt, signedBy: keypair)
    }
    
    /// Inclusive start timestamp.
    /// The start timestamp is represented by ``Date``.
    /// `nil` is returned if the backing `start` tag is malformed.
    public var startsAt: Date? {
        guard let startString = firstValueForRawTagName("start"), let startSeconds = Int(startString) else {
            return nil
        }

        return Date(timeIntervalSince1970: TimeInterval(startSeconds))
    }

    /// Exclusive end timestamp.
    /// End timestamp represented by ``Date``.
    /// `nil` is returned if the backing `end` tag is malformed or if the live activity event ends instantaneously.
    public var endsAt: Date? {
        guard let endString = firstValueForRawTagName("end"), let endSeconds = Int(endString) else {
            return nil
        }

        return Date(timeIntervalSince1970: TimeInterval(endSeconds))
    }
}

public enum LiveActivityStatus: String {
    case planned = "Planned"
    case live = "Live"
    case ended = "Ended"
}

public extension EventCreating {

    /// Creates a ``LiveActivitiesEvent`` (kind 9000) for live activities content, generally referred to as "live updates" or "live activities".
    /// - Parameters:
    ///   - identifier: A unique identifier for the content. Can be reused in the future for replacing the event. If an identifier is not provided, a ``UUID`` string is used.
    ///   - content: The content of the live activity.
    ///   - startsAt: The date when the live activity starts.
    ///   - endsAt: The date when the live activity ends.
    ///   - keypair: The ``Keypair`` to sign with.
    /// - Returns: The signed ``LiveActivitiesEvent``.
    func liveActivitiesEvent(withIdentifier identifier: String = UUID().uuidString,
                             title: String? = nil,
                             summary: String? = nil,
                             image: String? = nil,
                             hashtags: [String]? = nil,
                             streaming: String? = nil,
                             recording: String? = nil,
                             startsAt: Date? = nil,
                             endsAt: Date? = nil,
                             status: LiveActivityStatus? = nil,
                             participants: [LiveActivitiesEventParticipant]? = nil,
                             signedBy keypair: Keypair) throws -> LiveActivitiesEvent {

        var tags = [Tag]()

        tags.append(Tag(name: .identifier, value: identifier))

        if let title, !title.isEmpty {
            tags.append(Tag(name: "title", value: title))
        }
        
        if let summary, !summary.isEmpty {
            tags.append(Tag(name: "summary", value: summary))
        }

        if let image, !image.isEmpty {
            tags.append(Tag(name: "image", value: image))
        }

        if let hashtags, !hashtags.isEmpty {
            tags += hashtags.map { .hashtag($0) }
        }

        if let streaming, !streaming.isEmpty {
            tags.append(Tag(name: "streaming", value: streaming))
        }

        if let recording, !recording.isEmpty {
            tags.append(Tag(name: "recording", value: recording))
        }

        if let startsAt {
            tags.append(Tag(name: "startsAt", value: String(Int64(startsAt.timeIntervalSince1970))))
        }

        if let endsAt {
            tags.append(Tag(name: "endsAt", value: String(Int64(endsAt.timeIntervalSince1970))))
        }

        if let status {
            tags.append(Tag(name: "status", value: status.rawValue))
        }
        
        if let participants, !participants.isEmpty {
            tags += participants.map { $0.tag }
        }

        return try LiveActivitiesEvent(content: title ?? "", tags: tags, signedBy: keypair)
    }
}
