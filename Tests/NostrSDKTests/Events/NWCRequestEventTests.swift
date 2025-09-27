//
//  NWCRequestEventTests.swift
//  NostrSDKTests
//
//  Created by Suhail Saqan on 3/8/25.
//

import XCTest

@testable import NostrSDK

final class NWCRequestEventTests: XCTestCase, EventCreating, EventVerifying, FixtureLoading {

    func testCreateNWCRequestEvent() throws {
        let encryptedContent = "encrypted_request_content"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        let nwcRequest = try NWCRequestEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair()!
        )

        // Verify basic properties
        XCTAssertEqual(nwcRequest.kind, .nwcRequest)
        XCTAssertEqual(nwcRequest.content, encryptedContent)
        XCTAssertEqual(nwcRequest.pubkey, Keypair()!.publicKey.hex)

        // Verify tags
        XCTAssertEqual(nwcRequest.recipientPubkey, recipientPubkey)

        // Verify signature
        XCTAssertNotNil(nwcRequest.signature)
        try verifySignature(
            nwcRequest.signature!, for: nwcRequest.calculatedId,
            withPublicKey: Keypair()!.publicKey.hex)
    }

    func testNWCRequestEventDecoding() throws {
        let encryptedContent = "encrypted_request_content"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        let originalNWCRequest = try NWCRequestEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair()!
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(originalNWCRequest)

        // Decode from JSON
        let decoder = JSONDecoder()
        let decodedNWCRequest = try decoder.decode(NWCRequestEvent.self, from: jsonData)

        // Verify properties match
        XCTAssertEqual(decodedNWCRequest.id, originalNWCRequest.id)
        XCTAssertEqual(decodedNWCRequest.pubkey, originalNWCRequest.pubkey)
        XCTAssertEqual(decodedNWCRequest.createdAt, originalNWCRequest.createdAt)
        XCTAssertEqual(decodedNWCRequest.kind, originalNWCRequest.kind)
        XCTAssertEqual(decodedNWCRequest.content, originalNWCRequest.content)
        XCTAssertEqual(decodedNWCRequest.signature, originalNWCRequest.signature)

        // Verify computed properties
        XCTAssertEqual(decodedNWCRequest.recipientPubkey, originalNWCRequest.recipientPubkey)
    }

    func testNWCRequestEventViaEventCreating() throws {
        let encryptedContent = "encrypted_request_content"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        let nwcRequest = try nwcRequestEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair()!
        )

        XCTAssertEqual(nwcRequest.kind, .nwcRequest)
        XCTAssertEqual(nwcRequest.content, encryptedContent)
        XCTAssertEqual(nwcRequest.recipientPubkey, recipientPubkey)
    }
}
