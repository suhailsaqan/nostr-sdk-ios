//
//  ZapManager.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import Foundation

/// Zap Manager
///
/// Handles the complete Lightning Zap flow as defined in NIP-57
public class ZapManager {

    /// Zap request result
    public struct ZapRequestResult {
        /// The zap request event
        public let zapRequest: LightningZapRequestEvent

        /// The LNURL pay request response
        public let payRequest: LNURLPayRequest

        /// The callback URL for the zap request
        public let callbackURL: URL

        /// The bolt11 invoice (if available)
        public let bolt11Invoice: String?
    }

    /// Zap receipt result
    public struct ZapReceiptResult {
        /// The zap receipt event
        public let zapReceipt: LightningZapReceiptEvent

        /// The bolt11 invoice
        public let bolt11Invoice: String

        /// The payment preimage (if available)
        public let preimage: String?
    }

    /// Creates a zap request and fetches the LNURL pay request
    ///
    /// - Parameters:
    ///   - content: Optional message for the zap
    ///   - amount: The zap amount in millisats
    ///   - lnurl: The recipient's LNURL (bech32 encoded or HTTP URL)
    ///   - recipientPubkey: The recipient's Nostr public key
    ///   - eventId: Optional event ID being zapped
    ///   - eventCoordinate: Optional event coordinate being zapped
    ///   - relays: Relay URLs for publishing the zap receipt
    ///   - keypair: The sender's keypair
    /// - Returns: The zap request result
    /// - Throws: Error if the zap request creation fails
    public static func createZapRequest(
        content: String = "",
        amount: Int64,
        lnurl: String,
        recipientPubkey: String,
        eventId: String? = nil,
        eventCoordinate: String? = nil,
        relays: [String],
        signedBy keypair: Keypair
    ) async throws -> ZapRequestResult {

        // Fetch LNURL pay request
        let payRequest = try await LNURLPayRequestManager.fetchPayRequest(from: lnurl)

        // Validate Nostr support (without pubkey validation for custodial wallets)
        // For custodial wallets like Alby, the LNURL service handles pubkey validation
        try LNURLPayRequestManager.validateNostrSupport(payRequest)

        // Validate amount
        try LNURLPayRequestManager.validateAmount(amount, against: payRequest)

        // Create zap request event
        let zapRequest = try LightningZapRequestEvent(
            content: content,
            relays: relays,
            amount: Int(amount),
            lnurl: lnurl,
            recipientPubkey: recipientPubkey,
            eventId: eventId,
            eventCoordinate: eventCoordinate,
            signedBy: keypair
        )

        // Encode zap request as JSON
        let zapRequestJSONString = try zapRequest.toJSONString()

        // Create callback URL
        guard
            let callbackURL = LNURLPayRequestManager.createCallbackURL(
                from: payRequest,
                amount: amount,
                zapRequestJSON: zapRequestJSONString,
                comment: content.isEmpty ? nil : content
            )
        else {
            throw ZapError.invalidCallbackURL
        }

        return ZapRequestResult(
            zapRequest: zapRequest,
            payRequest: payRequest,
            callbackURL: callbackURL,
            bolt11Invoice: nil
        )
    }

    /// Sends a zap request and gets the bolt11 invoice
    ///
    /// - Parameter zapRequestResult: The zap request result
    /// - Returns: The updated zap request result with bolt11 invoice
    /// - Throws: Error if sending the zap request fails
    public static func sendZapRequest(_ zapRequestResult: ZapRequestResult) async throws
        -> ZapRequestResult
    {
        let payResponse = try await LNURLPayRequestManager.sendZapRequest(
            to: zapRequestResult.callbackURL)

        guard let bolt11Invoice = payResponse.pr else {
            throw ZapError.noInvoiceReceived
        }

        return ZapRequestResult(
            zapRequest: zapRequestResult.zapRequest,
            payRequest: zapRequestResult.payRequest,
            callbackURL: zapRequestResult.callbackURL,
            bolt11Invoice: bolt11Invoice
        )
    }

    /// Creates a zap receipt event
    ///
    /// - Parameters:
    ///   - zapRequestResult: The zap request result
    ///   - bolt11Invoice: The bolt11 invoice
    ///   - preimage: Optional payment preimage
    ///   - createdAt: The timestamp when the invoice was paid
    ///   - keypair: The keypair to sign the zap receipt
    ///   - additionalRelays: Optional additional relay URLs
    /// - Returns: The zap receipt result
    /// - Throws: Error if creating the zap receipt fails
    public static func createZapReceipt(
        from zapRequestResult: ZapRequestResult,
        bolt11Invoice: String,
        preimage: String? = nil,
        createdAt: Int64,
        signedBy keypair: Keypair,
        additionalRelays: [String] = []
    ) throws -> ZapReceiptResult {

        // Encode the original zap request as JSON
        let zapRequestJSONString = try zapRequestResult.zapRequest.toJSONString()

        // Create zap receipt event
        let zapReceipt = try LightningZapReceiptEvent(
            recipientPubkey: zapRequestResult.zapRequest.recipientPubkey ?? "",
            senderPubkey: zapRequestResult.zapRequest.pubkey,
            eventId: zapRequestResult.zapRequest.eventId,
            eventCoordinate: zapRequestResult.zapRequest.eventCoordinate,
            bolt11: bolt11Invoice,
            zapRequestJSON: zapRequestJSONString,
            preimage: preimage,
            createdAt: createdAt,
            signedBy: keypair,
            additionalRelays: additionalRelays
        )

        return ZapReceiptResult(
            zapReceipt: zapReceipt,
            bolt11Invoice: bolt11Invoice,
            preimage: preimage
        )
    }

    /// Validates a zap receipt against its corresponding zap request
    ///
    /// - Parameters:
    ///   - zapReceipt: The zap receipt to validate
    ///   - zapRequest: The corresponding zap request
    /// - Returns: True if the zap receipt is valid
    public static func validateZapReceipt(
        _ zapReceipt: LightningZapReceiptEvent,
        against zapRequest: LightningZapRequestEvent
    ) -> Bool {
        // Check that the recipient pubkeys match
        guard zapReceipt.recipientPubkey == zapRequest.recipientPubkey else {
            return false
        }

        // Check that the event IDs match (if present)
        if let receiptEventId = zapReceipt.eventId,
            let requestEventId = zapRequest.eventId,
            receiptEventId != requestEventId
        {
            return false
        }

        // Check that the event coordinates match (if present)
        if let receiptCoordinate = zapReceipt.eventCoordinate,
            let requestCoordinate = zapRequest.eventCoordinate,
            receiptCoordinate != requestCoordinate
        {
            return false
        }

        // Check that the sender pubkey matches (if present in receipt)
        if let receiptSenderPubkey = zapReceipt.senderPubkey,
            receiptSenderPubkey != zapRequest.pubkey
        {
            return false
        }

        // Verify the zap request in the description matches
        guard let embeddedZapRequest = zapReceipt.zapRequest else {
            return false
        }

        return embeddedZapRequest.id == zapRequest.id
    }

    /// Extracts zap information from a user's metadata
    ///
    /// - Parameter metadata: The user's metadata
    /// - Returns: Tuple containing LNURL and Lightning address (if available)
    public static func extractZapInfo(from metadata: UserMetadata) -> (
        lnurl: String?, lightningAddress: String?
    ) {
        return (metadata.lightningURLString, metadata.lightningAddress)
    }
}

/// Zap-related errors
public enum ZapError: Error, LocalizedError {
    case invalidCallbackURL
    case noInvoiceReceived
    case invalidZapRequest
    case invalidZapReceipt
    case amountValidationFailed
    case nostrValidationFailed
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidCallbackURL:
            return "Invalid callback URL"
        case .noInvoiceReceived:
            return "No bolt11 invoice received"
        case .invalidZapRequest:
            return "Invalid zap request"
        case .invalidZapReceipt:
            return "Invalid zap receipt"
        case .amountValidationFailed:
            return "Amount validation failed"
        case .nostrValidationFailed:
            return "Nostr validation failed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// Extension to LightningZapRequestEvent for JSON encoding
extension LightningZapRequestEvent {
    /// Encodes the zap request to JSON data
    public func toJSONData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    /// Encodes the zap request to JSON string
    public func toJSONString() throws -> String {
        let data = try toJSONData()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
