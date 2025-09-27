//
//  LightningZapsExample.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import Foundation

/// Example usage of Lightning Zaps functionality
///
/// This file demonstrates how to use the Lightning Zaps implementation
/// following the NIP-57 specification.
public class LightningZapsExample {

    /// Example: Create a simple zap request
    public static func createSimpleZapRequest() throws -> LightningZapRequestEvent {
        let relays = ["wss://relay.damus.io", "wss://relay.snort.social"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let amount = 1000  // 1000 millisats (1 satoshi)
        let content = "Great post! ⚡"

        return try LightningZapRequestEvent(
            content: content,
            relays: relays,
            amount: amount,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair()!
        )
    }

    /// Example: Create a zap request for a specific event
    public static func createZapRequestForEvent() throws -> LightningZapRequestEvent {
        let relays = ["wss://relay.damus.io"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let eventId = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        let amount = 21000  // 21 satoshis
        let content = "Amazing insight! ⚡"

        return try LightningZapRequestEvent(
            content: content,
            relays: relays,
            amount: amount,
            recipientPubkey: recipientPubkey,
            eventId: eventId,
            signedBy: Keypair()!
        )
    }

    /// Example: Create a zap request with LNURL
    public static func createZapRequestWithLNURL() throws -> LightningZapRequestEvent {
        let relays = ["wss://relay.damus.io"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let lnurl =
            "lnurl1dp68gurn8ghj7um9wfmxjcm99e3k7mf0v9cxj0m385ekkcenxc6r2c35xvukxefcv5mkvv34x5ekzd3ev56nyd3hxqurzepexejxxepnxscrvwfnv9nxzcn9xq6xyefhvgcxxcmyxymnserxq6xycth8y6n2vpyu3jrdj"
        let amount = 5000  // 5 satoshis
        let content = "Thanks for the great content! ⚡"

        return try LightningZapRequestEvent(
            content: content,
            relays: relays,
            amount: amount,
            lnurl: lnurl,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair()!
        )
    }

    /// Example: Create a zap receipt
    public static func createZapReceipt() throws -> LightningZapReceiptEvent {
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let senderPubkey = "a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890"
        let bolt11 = "lnbc1000n1p0example..."
        let zapRequestJSON =
            "{\"id\":\"test\",\"pubkey\":\"sender\",\"created_at\":1234567890,\"kind\":9734,\"tags\":[],\"content\":\"\",\"sig\":\"signature\"}"
        let preimage = "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
        let createdAt = Int64(Date().timeIntervalSince1970)

        return try LightningZapReceiptEvent(
            recipientPubkey: recipientPubkey,
            senderPubkey: senderPubkey,
            bolt11: bolt11,
            zapRequestJSON: zapRequestJSON,
            preimage: preimage,
            createdAt: createdAt,
            signedBy: Keypair()!
        )
    }

    /// Example: Complete zap flow using ZapManager
    public static func completeZapFlow() async throws {
        // Step 1: Create zap request
        let relays = ["wss://relay.damus.io"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let lnurl =
            "lnurl1dp68gurn8ghj7um9wfmxjcm99e3k7mf0v9cxj0m385ekkcenxc6r2c35xvukxefcv5mkvv34x5ekzd3ev56nyd3hxqurzepexejxxepnxscrvwfnv9nxzcn9xq6xyefhvgcxxcmyxymnserxq6xycth8y6n2vpyu3jrdj"
        let amount: Int64 = 1000
        let content = "Great post! ⚡"

        // Create zap request and fetch LNURL pay request
        let zapRequestResult = try await ZapManager.createZapRequest(
            content: content,
            amount: amount,
            lnurl: lnurl,
            recipientPubkey: recipientPubkey,
            relays: relays,
            signedBy: Keypair()!
        )

        print("Zap request created: \(zapRequestResult.zapRequest.id)")
        print("Callback URL: \(zapRequestResult.callbackURL)")

        // Step 2: Send zap request to get bolt11 invoice
        let zapRequestWithInvoice = try await ZapManager.sendZapRequest(zapRequestResult)

        if let bolt11Invoice = zapRequestWithInvoice.bolt11Invoice {
            print("Bolt11 invoice received: \(bolt11Invoice)")

            // Step 3: Create zap receipt (after payment is made)
            let zapReceiptResult = try ZapManager.createZapReceipt(
                from: zapRequestWithInvoice,
                bolt11Invoice: bolt11Invoice,
                preimage: "payment_preimage_here",
                createdAt: Int64(Date().timeIntervalSince1970),
                signedBy: Keypair()!
            )

            print("Zap receipt created: \(zapReceiptResult.zapReceipt.id)")
        }
    }

    /// Example: Validate zap receipt
    public static func validateZapReceipt() throws -> Bool {
        // Create a zap request
        let relays = ["wss://relay.damus.io"]
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        let zapRequest = try LightningZapRequestEvent(
            relays: relays,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair()!
        )

        // Create a corresponding zap receipt
        let bolt11 = "lnbc1000n1p0example..."
        let zapRequestJSON = try zapRequest.toJSONString()

        let zapReceipt = try LightningZapReceiptEvent(
            recipientPubkey: recipientPubkey,
            senderPubkey: zapRequest.pubkey,
            bolt11: bolt11,
            zapRequestJSON: zapRequestJSON,
            createdAt: Int64(Date().timeIntervalSince1970),
            signedBy: Keypair()!
        )

        // Validate the zap receipt
        return ZapManager.validateZapReceipt(zapReceipt, against: zapRequest)
    }

    /// Example: Extract zap info from user metadata
    public static func extractZapInfoFromUser() -> (lnurl: String?, lightningAddress: String?) {
        let metadata = UserMetadata(
            name: "Alice",
            displayName: "Alice",
            about: "Lightning enthusiast",
            website: URL(string: "https://alice.example.com"),
            nostrAddress: "alice@example.com",
            pictureURL: URL(string: "https://alice.example.com/picture.png"),
            bannerPictureURL: nil,
            isBot: false,
            lightningURLString:
                "lnurl1dp68gurn8ghj7um9wfmxjcm99e3k7mf0v9cxj0m385ekkcenxc6r2c35xvukxefcv5mkvv34x5ekzd3ev56nyd3hxqurzepexejxxepnxscrvwfnv9nxzcn9xq6xyefhvgcxxcmyxymnserxq6xycth8y6n2vpyu3jrdj",
            lightningAddress: "alice@example.com"
        )

        return ZapManager.extractZapInfo(from: metadata)
    }
}

/// Extension to demonstrate LNURL pay request usage
extension LightningZapsExample {

    /// Example: Handle LNURL pay request flow
    public static func handleLNURLPayRequest() async throws {
        let lnurl =
            "lnurl1dp68gurn8ghj7um9wfmxjcm99e3k7mf0v9cxj0m385ekkcenxc6r2c35xvukxefcv5mkvv34x5ekzd3ev56nyd3hxqurzepexejxxepnxscrvwfnv9nxzcn9xq6xyefhvgcxxcmyxymnserxq6xycth8y6n2vpyu3jrdj"

        // Fetch LNURL pay request
        let payRequest = try await LNURLPayRequestManager.fetchPayRequest(from: lnurl)

        print("LNURL Pay Request:")
        print("  Callback: \(payRequest.callback)")
        print("  Min Sendable: \(payRequest.minSendable) msats")
        print("  Max Sendable: \(payRequest.maxSendable) msats")
        print("  Allows Nostr: \(payRequest.allowsNostr ?? false)")
        print("  Nostr Pubkey: \(payRequest.nostrPubkey ?? "None")")

        // Validate Nostr support
        try LNURLPayRequestManager.validateNostrSupport(payRequest)

        // Validate amount
        let amount: Int64 = 1000
        try LNURLPayRequestManager.validateAmount(amount, against: payRequest)

        print("LNURL validation successful!")
    }
}
