//
//  LightningZapReceiptEventTests.swift
//  NostrSDKTests
//
//  Created by Suhail Saqan on 3/8/25.
//

import XCTest

@testable import NostrSDK

final class LightningZapReceiptEventTests: XCTestCase, EventCreating, EventVerifying, FixtureLoading
{

    func testCreateLightningZapReceiptEvent() throws {
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let senderPubkey = "a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890"
        let eventId = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        let bolt11 = "lnbc1000n1p0example..."
        let zapRequestJSON =
            "{\"id\":\"test\",\"pubkey\":\"sender\",\"created_at\":1234567890,\"kind\":9734,\"tags\":[],\"content\":\"\",\"sig\":\"signature\"}"
        let preimage = "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
        let createdAt = Int64(Date().timeIntervalSince1970)

        let zapReceipt = try LightningZapReceiptEvent(
            recipientPubkey: recipientPubkey,
            senderPubkey: senderPubkey,
            eventId: eventId,
            bolt11: bolt11,
            zapRequestJSON: zapRequestJSON,
            preimage: preimage,
            createdAt: createdAt,
            signedBy: Keypair.test
        )

        // Verify basic properties
        XCTAssertEqual(zapReceipt.kind, .zapReceipt)
        XCTAssertEqual(zapReceipt.content, "")
        XCTAssertEqual(zapReceipt.pubkey, Keypair.test.publicKey.hex)
        XCTAssertEqual(zapReceipt.createdAt, createdAt)

        // Verify tags
        XCTAssertEqual(zapReceipt.recipientPubkey, recipientPubkey)
        XCTAssertEqual(zapReceipt.senderPubkey, senderPubkey)
        XCTAssertEqual(zapReceipt.eventId, eventId)
        XCTAssertEqual(zapReceipt.bolt11, bolt11)
        XCTAssertEqual(zapReceipt.zapRequestJSON, zapRequestJSON)
        XCTAssertEqual(zapReceipt.preimage, preimage)

        // Verify signature
        XCTAssertNotNil(zapReceipt.signature)
        try verifySignature(
            zapReceipt.signature!, for: zapReceipt.calculatedId,
            withPublicKey: Keypair.test.publicKey.hex)
    }

    func testCreateLightningZapReceiptEventMinimal() throws {
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let bolt11 = "lnbc1000n1p0example..."
        let zapRequestJSON =
            "{\"id\":\"test\",\"pubkey\":\"sender\",\"created_at\":1234567890,\"kind\":9734,\"tags\":[],\"content\":\"\",\"sig\":\"signature\"}"
        let createdAt = Int64(Date().timeIntervalSince1970)

        let zapReceipt = try LightningZapReceiptEvent(
            recipientPubkey: recipientPubkey,
            bolt11: bolt11,
            zapRequestJSON: zapRequestJSON,
            createdAt: createdAt,
            signedBy: Keypair.test
        )

        // Verify basic properties
        XCTAssertEqual(zapReceipt.kind, .zapReceipt)
        XCTAssertEqual(zapReceipt.content, "")
        XCTAssertEqual(zapReceipt.pubkey, Keypair.test.publicKey.hex)

        // Verify required tags
        XCTAssertEqual(zapReceipt.recipientPubkey, recipientPubkey)
        XCTAssertEqual(zapReceipt.bolt11, bolt11)
        XCTAssertEqual(zapReceipt.zapRequestJSON, zapRequestJSON)

        // Optional fields should be nil
        XCTAssertNil(zapReceipt.senderPubkey)
        XCTAssertNil(zapReceipt.eventId)
        XCTAssertNil(zapReceipt.eventCoordinate)
        XCTAssertNil(zapReceipt.preimage)

        // Verify signature
        XCTAssertNotNil(zapReceipt.signature)
        try verifySignature(
            zapReceipt.signature!, for: zapReceipt.calculatedId,
            withPublicKey: Keypair.test.publicKey.hex)
    }

    func testLightningZapReceiptEventDecoding() throws {
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let bolt11 = "lnbc1000n1p0example..."
        let zapRequestJSON =
            "{\"id\":\"test\",\"pubkey\":\"sender\",\"created_at\":1234567890,\"kind\":9734,\"tags\":[],\"content\":\"\",\"sig\":\"signature\"}"
        let createdAt = Int64(Date().timeIntervalSince1970)

        let originalZapReceipt = try LightningZapReceiptEvent(
            recipientPubkey: recipientPubkey,
            bolt11: bolt11,
            zapRequestJSON: zapRequestJSON,
            createdAt: createdAt,
            signedBy: Keypair.test
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(originalZapReceipt)

        // Decode from JSON
        let decoder = JSONDecoder()
        let decodedZapReceipt = try decoder.decode(LightningZapReceiptEvent.self, from: jsonData)

        // Verify properties match
        XCTAssertEqual(decodedZapReceipt.id, originalZapReceipt.id)
        XCTAssertEqual(decodedZapReceipt.pubkey, originalZapReceipt.pubkey)
        XCTAssertEqual(decodedZapReceipt.createdAt, originalZapReceipt.createdAt)
        XCTAssertEqual(decodedZapReceipt.kind, originalZapReceipt.kind)
        XCTAssertEqual(decodedZapReceipt.content, originalZapReceipt.content)
        XCTAssertEqual(decodedZapReceipt.signature, originalZapReceipt.signature)

        // Verify computed properties
        XCTAssertEqual(decodedZapReceipt.recipientPubkey, originalZapReceipt.recipientPubkey)
        XCTAssertEqual(decodedZapReceipt.bolt11, originalZapReceipt.bolt11)
        XCTAssertEqual(decodedZapReceipt.zapRequestJSON, originalZapReceipt.zapRequestJSON)
    }

    func testLightningZapReceiptEventViaEventCreating() throws {
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let bolt11 = "lnbc1000n1p0example..."
        let zapRequestJSON =
            "{\"id\":\"test\",\"pubkey\":\"sender\",\"created_at\":1234567890,\"kind\":9734,\"tags\":[],\"content\":\"\",\"sig\":\"signature\"}"
        let createdAt = Int64(Date().timeIntervalSince1970)

        let zapReceipt = try lightningZapReceiptEvent(
            recipientPubkey: recipientPubkey,
            bolt11: bolt11,
            zapRequestJSON: zapRequestJSON,
            createdAt: createdAt,
            signedBy: Keypair.test
        )

        XCTAssertEqual(zapReceipt.kind, .zapReceipt)
        XCTAssertEqual(zapReceipt.recipientPubkey, recipientPubkey)
        XCTAssertEqual(zapReceipt.bolt11, bolt11)
    }
}
