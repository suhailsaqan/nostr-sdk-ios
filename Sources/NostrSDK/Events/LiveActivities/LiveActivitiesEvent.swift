//
//  LiveActivitiesEvent.swift
//
//
//  Created by Suhail Saqan on 11/6/24.
//

import Foundation

/// A live streaming event (kind 30311) as specified by NIP-53. This is a parameterized
/// replaceable event advertising the content and participants of a live stream.
///
/// > Note: [NIP-53 Specification](https://github.com/nostr-protocol/nips/blob/master/53.md)
public final class LiveActivitiesEvent: NostrEvent, ParameterizedReplaceableEvent,
    TitleTagInterpreting, HashtagInterpreting
{
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

    public init(
        content: String, tags: [Tag] = [], createdAt: Int64 = Int64(Date.now.timeIntervalSince1970),
        signedBy keypair: Keypair
    ) throws {
        try super.init(
            kind: .liveActivities, content: content, tags: tags, createdAt: createdAt,
            signedBy: keypair)
    }

    public var liveActivitiesEventCoordinateList: [EventCoordinates] {
        referencedEventCoordinates
            .filter { $0.kind == .liveActivities }
    }

    /// Identifier string.
    /// Returns the identifier associated with the live activity if available, otherwise `nil`.
    public var identifier: String? {
        guard let identifierString: String = firstValueForRawTagName("d") else {
            return nil
        }
        return identifierString
    }

    /// Inclusive start timestamp.
    /// The start timestamp is represented by ``Date``.
    /// `nil` is returned if the backing `start` tag is malformed.
    public var startsAt: Date? {
        guard let startString: String = firstValueForRawTagName("starts"),
            let startSeconds = Int(startString)
        else {
            return nil
        }

        return Date(timeIntervalSince1970: TimeInterval(startSeconds))
    }

    /// Exclusive end timestamp.
    /// End timestamp represented by ``Date``.
    /// `nil` is returned if the backing `end` tag is malformed or if the live activity event ends instantaneously.
    public var endsAt: Date? {
        guard let endString: String = firstValueForRawTagName("ends"),
            let endSeconds = Int(endString)
        else {
            return nil
        }

        return Date(timeIntervalSince1970: TimeInterval(endSeconds))
    }

    /// Streaming URL string.
    /// Returns the streaming URL of the the live activity if available, otherwise `nil`.
    public var streaming: URL? {
        guard let streamingString: String = firstValueForRawTagName("streaming") else {
            return nil
        }
        return URL(string: streamingString)
    }

    /// Recording URL string.
    /// Returns the recording URL of the the live activity if available, otherwise `nil`.
    public var recording: URL? {
        guard let recordingString: String = firstValueForRawTagName("recording") else {
            return nil
        }
        return URL(string: recordingString)
    }

    /// Status string.
    /// Returns the status associated with the live activity if available, otherwise `nil`.
    public var status: LiveActivityStatus? {
        guard let statusString: String = firstValueForRawTagName("status"),
            let status = LiveActivityStatus(rawValue: statusString)
        else {
            return nil
        }
        return status
    }

    /// Image URL string.
    /// Returns the URL of the image associated with the live activity if available, otherwise `nil`.
    public var image: URL? {
        guard let imageString: String = firstValueForRawTagName("image") else {
            return nil
        }
        return URL(string: imageString)
    }

    /// Title string.
    /// Returns the title associated with the live activity if available, otherwise `nil`.
    public var title: String? {
        guard let titleString: String = firstValueForRawTagName("title") else {
            return nil
        }
        return titleString
    }

    /// Summary string.
    /// Returns the summary associated with the live activity if available, otherwise `nil`.
    public var summary: String? {
        guard let summaryString: String = firstValueForRawTagName("summary") else {
            return nil
        }
        return summaryString
    }

    public var currentParticipants: Int? {
        guard
            let currentParticipantsString: String = firstValueForRawTagName("current_participants"),
            let currentParticipants = Int(currentParticipantsString)
        else {
            return nil
        }

        return currentParticipants
    }

    public var totalParticipants: Int? {
        guard let totalParticipantsString: String = firstValueForRawTagName("total_participants"),
            let totalParticipants = Int(totalParticipantsString)
        else {
            return nil
        }

        return totalParticipants
    }

    /// Preferred relays advertised by the live activity, if present.
    /// The `relays` tag has the form ["relays", "wss://one", "wss://two", ...].
    public var relays: [URL] {
        guard let relaysTag = tags.first(where: { $0.name == "relays" }) else { return [] }
        let values = [relaysTag.value] + relaysTag.otherParameters
        return values.compactMap { URL(string: $0) }
    }

    /// Pinned live chat messages associated with this live event, if any.
    /// The `pinned` tag is ["pinned", "<event id>"] and may appear multiple times.
    public var pinnedEventIds: [String] {
        tags.filter { $0.name == "pinned" }.map { $0.value }
    }

    /// Participants string.
    /// Returns the participants associated with the live activity if available, otherwise `nil`.
    /// Participants list.
    /// Returns an array of participants associated with the live activity, parsed from the "p" tags.
    public var participants: [LiveActivitiesEventParticipant] {
        return tags.filter { $0.name == "p" }
            .compactMap { LiveActivitiesEventParticipant(pubkeyTag: $0) }
    }
}

public enum LiveActivityStatus: String {
    case planned = "planned"
    case live = "live"
    case ended = "ended"
}

extension EventCreating {

    /// Creates a ``LiveActivitiesEvent`` (kind 30311) per NIP-53.
    /// - Parameters:
    ///   - identifier: A unique identifier for the content. Can be reused in the future for replacing the event. If an identifier is not provided, a ``UUID`` string is used.
    ///   - content: The content of the live activity.
    ///   - startsAt: The date when the live activity starts.
    ///   - endsAt: The date when the live activity ends.
    ///   - keypair: The ``Keypair`` to sign with.
    /// - Returns: The signed ``LiveActivitiesEvent``.
    public func liveActivitiesEvent(
        withIdentifier identifier: String = UUID().uuidString,
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
        relays: [String]? = nil,
        pinnedEventIds: [String]? = nil,
        signedBy keypair: Keypair
    ) throws -> LiveActivitiesEvent {

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
            tags.append(Tag(name: "starts", value: String(Int64(startsAt.timeIntervalSince1970))))
        }

        if let endsAt {
            tags.append(Tag(name: "ends", value: String(Int64(endsAt.timeIntervalSince1970))))
        }

        if let status {
            tags.append(Tag(name: "status", value: status.rawValue))
        }

        if let participants: [LiveActivitiesEventParticipant], !participants.isEmpty {
            tags += participants.map { $0.tag }
        }

        if let relays, !relays.isEmpty {
            // First item goes in `value`, subsequent in `otherParameters`
            let first = relays.first!
            let rest = Array(relays.dropFirst())
            tags.append(Tag(name: "relays", value: first, otherParameters: rest))
        }

        if let pinnedEventIds, !pinnedEventIds.isEmpty {
            for id in pinnedEventIds {
                tags.append(Tag(name: "pinned", value: id))
            }
        }

        return try LiveActivitiesEvent(
            content: "", tags: tags, signedBy: keypair)
    }
}
