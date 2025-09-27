//
//  NWCExample.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import Foundation

/// Example usage of Nostr Wallet Connect functionality
///
/// This file demonstrates how to use the NWC implementation
/// following the NIP-47 specification.
public class NWCExample {

    /// Example: Create a NWC connection
    public static func createNWCConnection() throws -> NWCManager.NWCConnection {
        let uriString =
            "nostr+walletconnect://d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62?relay=wss://relay.example.com&secret=abcdef1234567890"
        let clientKeypair = Keypair()!

        return try NWCManager.createConnection(from: uriString, clientKeypair: clientKeypair)
    }

    /// Example: Create a NWC Info Event
    public static func createNWCInfoEvent() throws -> NWCInfoEvent {
        let name = "Example Wallet"
        let description = "An example wallet service"
        let icon = "https://example.com/wallet-icon.png"
        let version = "1.0"
        let supportedMethods = [
            "get_info",
            "pay_invoice",
            "get_balance",
            "make_invoice",
            "lookup_invoice",
            "list_transactions",
        ]

        return try NWCInfoEvent(
            name: name,
            description: description,
            icon: icon,
            version: version,
            supportedMethods: supportedMethods,
            signedBy: Keypair()!
        )
    }

    /// Example: Create a NWC Request Event
    public static func createNWCRequestEvent() throws -> NWCRequestEvent {
        let encryptedContent = "encrypted_request_content"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        return try NWCRequestEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair()!
        )
    }

    /// Example: Create a NWC Response Event
    public static func createNWCResponseEvent() throws -> NWCResponseEvent {
        let encryptedContent = "encrypted_response_content"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let requestEventId = "request_event_id_123"

        return try NWCResponseEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            requestEventId: requestEventId,
            signedBy: Keypair()!
        )
    }

    /// Example: Create a NWC Notification Event
    public static func createNWCNotificationEvent() throws -> NWCNotificationEvent {
        let encryptedContent = "encrypted_notification_content"
        let recipientPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"

        return try NWCNotificationEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            signedBy: Keypair()!
        )
    }

    /// Example: Parse NWC Connection URI
    public static func parseNWCConnectionURI() throws -> NWCConnectionURI {
        let uriString =
            "nostr+walletconnect://d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62?relay=wss://relay.example.com&secret=abcdef1234567890"

        return try NWCConnectionURI(uriString: uriString)
    }

    /// Example: Create NWC Request
    public static func createNWCRequest() throws -> NWCRequest {
        let method = NWCRequestMethod.payInvoice
        let params = ["invoice": AnyCodable("lnbc1000n1p0example...")]

        return NWCRequest(method: method, params: params)
    }

    /// Example: Create NWC Response
    public static func createNWCResponse() throws -> NWCResponse {
        let result = AnyCodable(["preimage": "payment_preimage_here"])

        return NWCResponse(result: result)
    }

    /// Example: Create NWC Error Response
    public static func createNWCErrorResponse() throws -> NWCResponse {
        let error = NWCError(code: -32601, message: "Method not found")

        return NWCResponse(error: error)
    }
}

/// Extension to demonstrate NIP-04 encryption usage
extension NWCExample {

    /// Example: Encrypt a message using NIP-04
    public static func encryptMessage() throws -> String {
        let message = "Hello, this is a test message!"
        let recipientPublicKey = PublicKey(
            hex: "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62")!
        let senderPrivateKey = Keypair()!.privateKey

        let manager = NWCManager()
        return try manager.encryptNIP04(
            message: message,
            recipientPublicKey: recipientPublicKey,
            senderPrivateKey: senderPrivateKey
        )
    }

    /// Example: Decrypt a message using NIP-04
    public static func decryptMessage() throws -> String {
        let encryptedMessage = "encrypted_message_base64"
        let senderPublicKey = PublicKey(
            hex: "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62")!
        let recipientPrivateKey = Keypair()!.privateKey

        let manager = NWCManager()
        return try manager.decryptNIP04(
            encryptedMessage: encryptedMessage,
            senderPublicKey: senderPublicKey,
            recipientPrivateKey: recipientPrivateKey
        )
    }
}

/// Extension to demonstrate NWC Models usage
extension NWCExample {

    /// Example: Create NWC Get Info Response
    public static func createNWCGetInfoResponse() -> NWCGetInfoResponse {
        return NWCGetInfoResponse(
            alias: "Example Wallet",
            color: "#FF6B35",
            pubkey: "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62",
            network: "bitcoin",
            blockHeight: 800000,
            blockHash: "0000000000000000000000000000000000000000000000000000000000000000",
            methods: ["get_info", "pay_invoice", "get_balance"]
        )
    }

    /// Example: Create NWC Pay Invoice Request
    public static func createNWCPayInvoiceRequest() -> NWCPayInvoiceRequest {
        return NWCPayInvoiceRequest(invoice: "lnbc1000n1p0example...")
    }

    /// Example: Create NWC Pay Invoice Response
    public static func createNWCPayInvoiceResponse() -> NWCPayInvoiceResponse {
        return NWCPayInvoiceResponse(preimage: "payment_preimage_here")
    }

    /// Example: Create NWC Get Balance Response
    public static func createNWCGetBalanceResponse() -> NWCGetBalanceResponse {
        return NWCGetBalanceResponse(balance: 1_000_000)  // 1000 sats
    }

    /// Example: Create NWC Make Invoice Request
    public static func createNWCMakeInvoiceRequest() -> NWCMakeInvoiceRequest {
        return NWCMakeInvoiceRequest(
            amount: 1000,  // 1 sat
            description: "Test invoice",
            expiry: 3600  // 1 hour
        )
    }

    /// Example: Create NWC Make Invoice Response
    public static func createNWCMakeInvoiceResponse() -> NWCMakeInvoiceResponse {
        return NWCMakeInvoiceResponse(
            invoice: "lnbc1000n1p0example...",
            paymentHash: "payment_hash_here"
        )
    }
}
