//
//  ZapManagerTests.swift
//  NostrSDKTests
//
//  Created by Suhail Saqan on 3/8/25.
//

import XCTest

@testable import NostrSDK

final class ZapManagerTests: XCTestCase, EventCreating, EventVerifying, FixtureLoading {

    func testExtractZapInfoFromMetadata() throws {
        let metadata = UserMetadata(
            name: "Test User",
            displayName: "Test Display Name",
            about: "Test user",
            website: URL(string: "https://example.com"),
            nostrAddress: "test@example.com",
            pictureURL: URL(string: "https://example.com/picture.png"),
            bannerPictureURL: URL(string: "https://example.com/banner.png"),
            isBot: false,
            lightningURLString:
                "lnurl1dp68gurn8ghj7um9wfmxjcm99e3k7mf0v9cxj0m385ekkcenxc6r2c35xvukxefcv5mkvv34x5ekzd3ev56nyd3hxqurzepexejxxepnxscrvwfnv9nxzcn9xq6xyefhvgcxxcmyxymnserxq6xycth8y6n2vpyu3jrdj",
            lightningAddress: "test@example.com"
        )

        let zapInfo = ZapManager.extractZapInfo(from: metadata)

        XCTAssertEqual(zapInfo.lnurl, metadata.lightningURLString)
        XCTAssertEqual(zapInfo.lightningAddress, metadata.lightningAddress)
    }

    func testValidateZapReceipt() throws {
        // Create a zap request
        let relays = ["wss://relay.example.com"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        let zapRequest = try LightningZapRequestEvent(
            relays: relays,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair.test
        )

        // Create a corresponding zap receipt
        let bolt11 = "lnbc1000n1p0example..."
        let zapRequestJSON = try JSONEncoder().encode(zapRequest)
        let zapRequestJSONString = String(data: zapRequestJSON, encoding: .utf8) ?? ""

        let zapReceipt = try LightningZapReceiptEvent(
            recipientPubkey: recipientPubkey,
            senderPubkey: zapRequest.pubkey,
            bolt11: bolt11,
            zapRequestJSON: zapRequestJSONString,
            createdAt: Int64(Date().timeIntervalSince1970),
            signedBy: Keypair.test
        )

        // Validate the zap receipt
        let isValid = ZapManager.validateZapReceipt(zapReceipt, against: zapRequest)
        XCTAssertTrue(isValid)
    }

    func testValidateZapReceiptWithMismatchedRecipient() throws {
        // Create a zap request
        let relays = ["wss://relay.example.com"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        let zapRequest = try LightningZapRequestEvent(
            relays: relays,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair.test
        )

        // Create a zap receipt with different recipient
        let differentRecipientPubkey =
            "a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890"
        let bolt11 = "lnbc1000n1p0example..."
        let zapRequestJSON = try JSONEncoder().encode(zapRequest)
        let zapRequestJSONString = String(data: zapRequestJSON, encoding: .utf8) ?? ""

        let zapReceipt = try LightningZapReceiptEvent(
            recipientPubkey: differentRecipientPubkey,
            senderPubkey: zapRequest.pubkey,
            bolt11: bolt11,
            zapRequestJSON: zapRequestJSONString,
            createdAt: Int64(Date().timeIntervalSince1970),
            signedBy: Keypair.test
        )

        // Validate the zap receipt - should fail
        let isValid = ZapManager.validateZapReceipt(zapReceipt, against: zapRequest)
        XCTAssertFalse(isValid)
    }

    func testValidateZapReceiptWithEventId() throws {
        // Create a zap request with event ID
        let relays = ["wss://relay.example.com"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let eventId = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

        let zapRequest = try LightningZapRequestEvent(
            relays: relays,
            recipientPubkey: recipientPubkey,
            eventId: eventId,
            signedBy: Keypair.test
        )

        // Create a corresponding zap receipt
        let bolt11 = "lnbc1000n1p0example..."
        let zapRequestJSON = try JSONEncoder().encode(zapRequest)
        let zapRequestJSONString = String(data: zapRequestJSON, encoding: .utf8) ?? ""

        let zapReceipt = try LightningZapReceiptEvent(
            recipientPubkey: recipientPubkey,
            senderPubkey: zapRequest.pubkey,
            eventId: eventId,
            bolt11: bolt11,
            zapRequestJSON: zapRequestJSONString,
            createdAt: Int64(Date().timeIntervalSince1970),
            signedBy: Keypair.test
        )

        // Validate the zap receipt
        let isValid = ZapManager.validateZapReceipt(zapReceipt, against: zapRequest)
        XCTAssertTrue(isValid)
    }

    func testCreateZapReceiptFromZapRequest() throws {
        // Create a zap request
        let relays = ["wss://relay.example.com"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let amount = 1000

        let zapRequest = try LightningZapRequestEvent(
            relays: relays,
            amount: amount,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair.test
        )

        // Create zap request result
        let zapRequestResult = ZapManager.ZapRequestResult(
            zapRequest: zapRequest,
            payRequest: LNURLPayRequest(
                callback: "https://example.com/callback",
                maxSendable: 1_000_000,
                minSendable: 1000,
                metadata: "test metadata",
                tag: "payRequest",
                commentAllowed: 200,
                payerData: nil,
                nostrPubkey: recipientPubkey,
                allowsNostr: true
            ),
            callbackURL: URL(string: "https://example.com/callback")!,
            bolt11Invoice: nil
        )

        // Create zap receipt
        let bolt11 = "lnbc1000n1p0example..."
        let preimage = "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
        let createdAt = Int64(Date().timeIntervalSince1970)

        let zapReceiptResult = try ZapManager.createZapReceipt(
            from: zapRequestResult,
            bolt11Invoice: bolt11,
            preimage: preimage,
            createdAt: createdAt,
            signedBy: Keypair.test
        )

        // Verify zap receipt
        XCTAssertEqual(zapReceiptResult.bolt11Invoice, bolt11)
        XCTAssertEqual(zapReceiptResult.preimage, preimage)
        XCTAssertEqual(zapReceiptResult.zapReceipt.recipientPubkey, recipientPubkey)
        XCTAssertEqual(zapReceiptResult.zapReceipt.senderPubkey, zapRequest.pubkey)
        XCTAssertEqual(zapReceiptResult.zapReceipt.bolt11, bolt11)
        XCTAssertEqual(zapReceiptResult.zapReceipt.preimage, preimage)

        // Verify signature
        XCTAssertNotNil(zapReceiptResult.zapReceipt.signature)
        try verifySignature(
            zapReceiptResult.zapReceipt.signature!,
            for: zapReceiptResult.zapReceipt.calculatedId,
            withPublicKey: Keypair.test.publicKey.hex
        )
    }
}
