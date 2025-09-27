//
//  NWCResponseEventTests.swift
//  NostrSDKTests
//
//  Created by Suhail Saqan on 3/8/25.
//

import XCTest

@testable import NostrSDK

final class NWCResponseEventTests: XCTestCase, EventCreating, EventVerifying, FixtureLoading {

    func testCreateNWCResponseEvent() throws {
        let encryptedContent = "encrypted_response_content"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let requestEventId = "request_event_id_123"

        let nwcResponse = try NWCResponseEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            requestEventId: requestEventId,
            signedBy: Keypair()!
        )

        // Verify basic properties
        XCTAssertEqual(nwcResponse.kind, .nwcResponse)
        XCTAssertEqual(nwcResponse.content, encryptedContent)
        XCTAssertEqual(nwcResponse.pubkey, Keypair()!.publicKey.hex)

        // Verify tags
        XCTAssertEqual(nwcResponse.recipientPubkey, recipientPubkey)

        // Verify signature
        XCTAssertNotNil(nwcResponse.signature)
        try verifySignature(
            nwcResponse.signature!, for: nwcResponse.calculatedId,
            withPublicKey: Keypair()!.publicKey.hex)
    }

    func testNWCResponseEventDecoding() throws {
        let encryptedContent = "encrypted_response_content"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let requestEventId = "request_event_id_123"

        let originalNWCResponse = try NWCResponseEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            requestEventId: requestEventId,
            signedBy: Keypair()!
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(originalNWCResponse)

        // Decode from JSON
        let decoder = JSONDecoder()
        let decodedNWCResponse = try decoder.decode(NWCResponseEvent.self, from: jsonData)

        // Verify properties match
        XCTAssertEqual(decodedNWCResponse.id, originalNWCResponse.id)
        XCTAssertEqual(decodedNWCResponse.pubkey, originalNWCResponse.pubkey)
        XCTAssertEqual(decodedNWCResponse.createdAt, originalNWCResponse.createdAt)
        XCTAssertEqual(decodedNWCResponse.kind, originalNWCResponse.kind)
        XCTAssertEqual(decodedNWCResponse.content, originalNWCResponse.content)
        XCTAssertEqual(decodedNWCResponse.signature, originalNWCResponse.signature)

        // Verify computed properties
        XCTAssertEqual(decodedNWCResponse.recipientPubkey, originalNWCResponse.recipientPubkey)
    }

    func testNWCResponseEventViaEventCreating() throws {
        let encryptedContent = "encrypted_response_content"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let requestEventId = "request_event_id_123"

        let nwcResponse = try nwcResponseEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            requestEventId: requestEventId,
            signedBy: Keypair()!
        )

        XCTAssertEqual(nwcResponse.kind, .nwcResponse)
        XCTAssertEqual(nwcResponse.content, encryptedContent)
        XCTAssertEqual(nwcResponse.recipientPubkey, recipientPubkey)
    }
}
