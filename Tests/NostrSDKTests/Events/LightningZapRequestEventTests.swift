//
//  LightningZapRequestEventTests.swift
//  NostrSDKTests
//
//  Created by Suhail Saqan on 3/8/25.
//

import XCTest

@testable import NostrSDK

final class LightningZapRequestEventTests: XCTestCase, EventCreating, EventVerifying, FixtureLoading
{

    func testCreateLightningZapRequestEvent() throws {
        let relays = ["wss://relay1.example.com", "wss://relay2.example.com"]
        let amount = 1000  // 1000 millisats
        let lnurl =
            "lnurl1dp68gurn8ghj7um9wfmxjcm99e3k7mf0v9cxj0m385ekkcenxc6r2c35xvukxefcv5mkvv34x5ekzd3ev56nyd3hxqurzepexejxxepnxscrvwfnv9nxzcn9xq6xyefhvgcxxcmyxymnserxq6xycth8y6n2vpyu3jrdj"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let eventId = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        let content = "Great post! ⚡"

        let zapRequest = try LightningZapRequestEvent(
            content: content,
            relays: relays,
            amount: amount,
            lnurl: lnurl,
            recipientPubkey: recipientPubkey,
            eventId: eventId,
            signedBy: Keypair.test
        )

        // Verify basic properties
        XCTAssertEqual(zapRequest.kind, .zapRequest)
        XCTAssertEqual(zapRequest.content, content)
        XCTAssertEqual(zapRequest.pubkey, Keypair.test.publicKey.hex)

        // Verify tags
        XCTAssertEqual(zapRequest.relayURLs, relays)
        XCTAssertEqual(zapRequest.amount, amount)
        XCTAssertEqual(zapRequest.lnurl, lnurl)
        XCTAssertEqual(zapRequest.recipientPubkey, recipientPubkey)
        XCTAssertEqual(zapRequest.eventId, eventId)

        // Verify signature
        XCTAssertNotNil(zapRequest.signature)
        try verifySignature(
            zapRequest.signature!, for: zapRequest.calculatedId,
            withPublicKey: Keypair.test.publicKey.hex)
    }

    func testCreateLightningZapRequestEventMinimal() throws {
        let relays = ["wss://relay.example.com"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        let zapRequest = try LightningZapRequestEvent(
            relays: relays,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair.test
        )

        // Verify basic properties
        XCTAssertEqual(zapRequest.kind, .zapRequest)
        XCTAssertEqual(zapRequest.content, "")
        XCTAssertEqual(zapRequest.pubkey, Keypair.test.publicKey.hex)

        // Verify required tags
        XCTAssertEqual(zapRequest.relayURLs, relays)
        XCTAssertEqual(zapRequest.recipientPubkey, recipientPubkey)

        // Optional fields should be nil
        XCTAssertNil(zapRequest.amount)
        XCTAssertNil(zapRequest.lnurl)
        XCTAssertNil(zapRequest.eventId)
        XCTAssertNil(zapRequest.eventCoordinate)

        // Verify signature
        XCTAssertNotNil(zapRequest.signature)
        try verifySignature(
            zapRequest.signature!, for: zapRequest.calculatedId,
            withPublicKey: Keypair.test.publicKey.hex)
    }

    func testCreateLightningZapRequestEventWithEventCoordinate() throws {
        let relays = ["wss://relay.example.com"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let eventCoordinate =
            "30023:d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62:relay"

        let zapRequest = try LightningZapRequestEvent(
            relays: relays,
            recipientPubkey: recipientPubkey,
            eventCoordinate: eventCoordinate,
            signedBy: Keypair.test
        )

        XCTAssertEqual(zapRequest.eventCoordinate, eventCoordinate)
    }

    func testLightningZapRequestEventComputedProperties() throws {
        let relays = [
            "wss://relay1.example.com", "wss://relay2.example.com", "wss://relay3.example.com",
        ]
        let amount = 5000
        let lnurl =
            "lnurl1dp68gurn8ghj7um9wfmxjcm99e3k7mf0v9cxj0m385ekkcenxc6r2c35xvukxefcv5mkvv34x5ekzd3ev56nyd3hxqurzepexejxxepnxscrvwfnv9nxzcn9xq6xyefhvgcxxcmyxymnserxq6xycth8y6n2vpyu3jrdj"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let eventId = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

        let zapRequest = try LightningZapRequestEvent(
            relays: relays,
            amount: amount,
            lnurl: lnurl,
            recipientPubkey: recipientPubkey,
            eventId: eventId,
            signedBy: Keypair.test
        )

        // Test relay URLs extraction
        XCTAssertEqual(zapRequest.relayURLs.count, 3)
        XCTAssertEqual(zapRequest.relayURLs, relays)

        // Test amount extraction
        XCTAssertEqual(zapRequest.amount, amount)

        // Test lnurl extraction
        XCTAssertEqual(zapRequest.lnurl, lnurl)

        // Test recipient pubkey extraction
        XCTAssertEqual(zapRequest.recipientPubkey, recipientPubkey)

        // Test event ID extraction
        XCTAssertEqual(zapRequest.eventId, eventId)
    }

    func testLightningZapRequestEventEmptyRelays() throws {
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        let zapRequest = try LightningZapRequestEvent(
            relays: [],
            recipientPubkey: recipientPubkey,
            signedBy: Keypair.test
        )

        XCTAssertEqual(zapRequest.relayURLs.count, 0)
    }

    func testLightningZapRequestEventDecoding() throws {
        // Create a zap request event
        let relays = ["wss://relay.example.com"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        let originalZapRequest = try LightningZapRequestEvent(
            relays: relays,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair.test
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(originalZapRequest)

        // Decode from JSON
        let decoder = JSONDecoder()
        let decodedZapRequest = try decoder.decode(LightningZapRequestEvent.self, from: jsonData)

        // Verify properties match
        XCTAssertEqual(decodedZapRequest.id, originalZapRequest.id)
        XCTAssertEqual(decodedZapRequest.pubkey, originalZapRequest.pubkey)
        XCTAssertEqual(decodedZapRequest.createdAt, originalZapRequest.createdAt)
        XCTAssertEqual(decodedZapRequest.kind, originalZapRequest.kind)
        XCTAssertEqual(decodedZapRequest.content, originalZapRequest.content)
        XCTAssertEqual(decodedZapRequest.signature, originalZapRequest.signature)
        XCTAssertEqual(decodedZapRequest.tags.count, originalZapRequest.tags.count)

        // Verify computed properties
        XCTAssertEqual(decodedZapRequest.relayURLs, originalZapRequest.relayURLs)
        XCTAssertEqual(decodedZapRequest.recipientPubkey, originalZapRequest.recipientPubkey)
    }

    func testLightningZapRequestEventViaEventCreating() throws {
        let relays = ["wss://relay.example.com"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        let zapRequest = try lightningZapRequestEvent(
            relays: relays,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair.test
        )

        XCTAssertEqual(zapRequest.kind, .zapRequest)
        XCTAssertEqual(zapRequest.relayURLs, relays)
        XCTAssertEqual(zapRequest.recipientPubkey, recipientPubkey)
    }

    func testLightningZapRequestEventWithAllParameters() throws {
        let relays = ["wss://relay1.example.com", "wss://relay2.example.com"]
        let amount = 21000  // 21 sats
        let lnurl =
            "lnurl1dp68gurn8ghj7um9wfmxjcm99e3k7mf0v9cxj0m385ekkcenxc6r2c35xvukxefcv5mkvv34x5ekzd3ev56nyd3hxqurzepexejxxepnxscrvwfnv9nxzcn9xq6xyefhvgcxxcmyxymnserxq6xycth8y6n2vpyu3jrdj"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let eventId = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        let eventCoordinate =
            "30023:d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62:relay"
        let content = "Amazing content! ⚡"

        let zapRequest = try LightningZapRequestEvent(
            content: content,
            relays: relays,
            amount: amount,
            lnurl: lnurl,
            recipientPubkey: recipientPubkey,
            eventId: eventId,
            eventCoordinate: eventCoordinate,
            signedBy: Keypair.test
        )

        // Verify all properties
        XCTAssertEqual(zapRequest.content, content)
        XCTAssertEqual(zapRequest.relayURLs, relays)
        XCTAssertEqual(zapRequest.amount, amount)
        XCTAssertEqual(zapRequest.lnurl, lnurl)
        XCTAssertEqual(zapRequest.recipientPubkey, recipientPubkey)
        XCTAssertEqual(zapRequest.eventId, eventId)
        XCTAssertEqual(zapRequest.eventCoordinate, eventCoordinate)

        // Verify signature
        XCTAssertNotNil(zapRequest.signature)
        try verifySignature(
            zapRequest.signature!, for: zapRequest.calculatedId,
            withPublicKey: Keypair.test.publicKey.hex)
    }
}
