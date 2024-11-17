//
//  LiveActivitiesEventParticipant.swift
//
//
//  Created by Suhail Saqan on 11/16/23.
//

import Foundation

/// A participant in a live activity event.
public struct LiveActivitiesEventParticipant: PubkeyProviding, RelayProviding, RelayURLValidating, Equatable, Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.tag == rhs.tag
    }

    /// The tag representation of this live activity event participant.
    public let tag: Tag

    /// The public key of the participant.
    public var pubkey: PublicKey? {
        PublicKey(hex: tag.value)
    }

    /// A relay in which the participant can be found. nil is returned if the relay URL is malformed.
    public var relayURL: URL? {
        guard let relayString = tag.otherParameters.first else {
            return nil
        }

        return try? validateRelayURLString(relayString)
    }

    /// The role of the participant in the meeting.
    public var role: String? {
        guard tag.otherParameters.count >= 2 else {
            return nil
        }

        return tag.otherParameters[1]
    }

    /// Initializes a live activity event participant from a ``Tag``.
    /// `nil` is returned if the tag is not a pubkey tag.
    public init?(pubkeyTag: Tag) {
        guard pubkeyTag.name == TagName.pubkey.rawValue else {
            return nil
        }

        self.tag = pubkeyTag
    }

    /// Initializes a live activity event participant.
    /// - Parameters:
    ///   - pubkey: The public key of the participant.
    ///   - relayURL: A relay in which the participant can be found.
    ///   - role: The role of the participant in the meeting.
    public init(pubkey: PublicKey, relayURL: URL? = nil, role: String? = nil) {
        var otherParameters: [String] = [relayURL?.absoluteString ?? ""]
        if let role, !role.isEmpty {
            otherParameters.append(role)
        }
        
        tag = Tag.pubkey(pubkey.hex, otherParameters: otherParameters)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(tag)
    }
}

/// Interprets calendar event participant tags.
public protocol LiveActivitiesEventParticipantInterpreting: NostrEvent {}
public extension LiveActivitiesEventParticipantInterpreting {
    var participants: [LiveActivitiesEventParticipant] {
        tags.filter { $0.name == TagName.pubkey.rawValue }.compactMap { LiveActivitiesEventParticipant(pubkeyTag: $0) }
    }
}
