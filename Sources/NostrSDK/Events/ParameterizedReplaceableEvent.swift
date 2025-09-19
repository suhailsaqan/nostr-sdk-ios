//
//  ParameterizedReplaceableEvent.swift
//
//
//  Created by Terry Yiu on 12/23/23.
//

import Foundation

public protocol ParameterizedReplaceableEvent: ReplaceableEvent, MetadataCoding {}
extension ParameterizedReplaceableEvent {
    /// The identifier of the event. For parameterized replaceable events, this identifier remains stable across replacements.
    /// This identifier is represented by the "d" tag, which is distinctly different from the `id` field on ``NostrEvent``.
    public var identifier: String? {
        firstValueForTagName(.identifier)
    }

    public func replaceableEventCoordinates(relayURL: URL? = nil) -> EventCoordinates? {
        guard kind.isParameterizedReplaceable else {
            print("DEBUG: Kind is not parameterized replaceable")
            return nil
        }

        guard let identifier = identifier else {
            print("DEBUG: Identifier is nil")
            return nil
        }

        guard let publicKey = PublicKey(hex: pubkey) else {
            print("DEBUG: Failed to create PublicKey from pubkey: \(pubkey)")
            return nil
        }

        do {
            let coordinates = try EventCoordinates(
                kind: kind, pubkey: publicKey, identifier: identifier, relayURL: relayURL)
            return coordinates
        } catch {
            print("DEBUG: Failed to create EventCoordinates: \(error)")
            return nil
        }
    }

    public func shareableEventCoordinates(
        relayURLStrings: [String]? = nil, includeAuthor: Bool = true, includeKind: Bool = true
    ) throws -> String {
        try shareableEventCoordinates(
            relayURLStrings: relayURLStrings, includeAuthor: includeAuthor,
            includeKind: includeKind, identifier: identifier ?? "")
    }
}
