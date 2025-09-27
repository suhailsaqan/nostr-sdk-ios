//
//  NWCManager.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import CommonCrypto
import CryptoKit
import Foundation
import secp256k1

/// NWC Manager
///
/// Handles the complete Nostr Wallet Connect flow as defined in NIP-47
public class NWCManager: NIP04Encryption {

    /// Request queue to ensure only one request is processed at a time
    private static let requestQueue = DispatchQueue(label: "nwc.request.queue", qos: .userInitiated)
    private static var isProcessingRequest = false

    /// NWC Connection
    public struct NWCConnection {
        public let uri: NWCConnectionURI
        public let clientKeypair: Keypair
        public let walletPubkey: PublicKey
        public let relayURL: URL

        public init(uri: NWCConnectionURI, clientKeypair: Keypair) throws {
            self.uri = uri
            self.clientKeypair = clientKeypair

            guard let walletPubkey = PublicKey(hex: uri.walletPubkey) else {
                throw NWCManagerError.invalidWalletPubkey
            }
            self.walletPubkey = walletPubkey

            guard let relayURL = URL(string: uri.relayURL) else {
                throw NWCManagerError.invalidRelayURL
            }
            self.relayURL = relayURL
        }
    }

    /// NWC Request Result
    public struct NWCRequestResult {
        public let request: NWCRequestEvent
        public let response: NWCResponse?
        public let error: Error?
    }

    /// Creates a NWC connection from a connection URI
    ///
    /// - Parameters:
    ///   - uriString: The NWC connection URI string
    ///   - clientKeypair: The client's keypair (ignored - derived from secret in URI)
    /// - Returns: The NWC connection
    /// - Throws: Error if the connection creation fails
    public static func createConnection(
        from uriString: String,
        clientKeypair: Keypair
    ) throws -> NWCConnection {
        let uri = try NWCConnectionURI(uriString: uriString)

        guard let secretData = Data(hexString: uri.secret) else {
            throw NWCManagerError.invalidSecret
        }

        guard let derivedPrivateKey = PrivateKey(dataRepresentation: secretData) else {
            throw NWCManagerError.invalidSecret
        }

        guard let derivedClientKeypair = Keypair(privateKey: derivedPrivateKey) else {
            throw NWCManagerError.invalidSecret
        }

        return try NWCConnection(uri: uri, clientKeypair: derivedClientKeypair)
    }

    /// Fetches wallet info from the NWC service
    ///
    /// - Parameter connection: The NWC connection
    /// - Returns: The wallet info
    /// - Throws: Error if fetching fails
    public static func fetchWalletInfo(from connection: NWCConnection) async throws -> NWCWalletInfo
    {
        // Create get_info request
        let request = NWCRequest(method: .getInfo)
        let requestJSON = try JSONEncoder().encode(request)
        let requestString = String(data: requestJSON, encoding: .utf8) ?? "{}"

        // Encrypt the request
        let encryptedContent = try encryptRequest(
            content: requestString,
            connection: connection
        )

        // Create NWC request event
        let nwcRequest = try NWCRequestEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: connection.walletPubkey.hex,
            signedBy: connection.clientKeypair
        )

        // Send request and wait for response
        let response = try await sendRequest(nwcRequest, connection: connection)

        // Decrypt and parse response
        let decryptedResponse = try decryptResponse(
            encryptedContent: response.content,
            connection: connection
        )

        let nwcResponse = try JSONDecoder().decode(
            NWCResponse.self, from: decryptedResponse.data(using: .utf8) ?? Data())

        if let error = nwcResponse.error {
            throw NWCManagerError.walletError(error)
        }

        guard let result = nwcResponse.result else {
            throw NWCManagerError.noResult
        }

        // Parse wallet info from result
        let resultData = try JSONEncoder().encode(result)
        return try JSONDecoder().decode(NWCWalletInfo.self, from: resultData)
    }

    /// Pays a Lightning invoice
    ///
    /// - Parameters:
    ///   - invoice: The Lightning invoice to pay
    ///   - connection: The NWC connection
    /// - Returns: The payment preimage
    /// - Throws: Error if payment fails
    public static func payInvoice(
        _ invoice: String,
        connection: NWCConnection
    ) async throws -> String {
        // Create pay_invoice request
        let request = NWCRequest(
            method: .payInvoice,
            params: ["invoice": AnyCodable(invoice)]
        )
        let requestJSON = try JSONEncoder().encode(request)
        let requestString = String(data: requestJSON, encoding: .utf8) ?? "{}"

        // Encrypt the request
        let encryptedContent = try encryptRequest(
            content: requestString,
            connection: connection
        )

        // Create NWC request event
        let nwcRequest = try NWCRequestEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: connection.walletPubkey.hex,
            signedBy: connection.clientKeypair
        )

        // Send request and wait for response
        let response = try await sendRequest(nwcRequest, connection: connection)

        // Decrypt and parse response
        let decryptedResponse = try decryptResponse(
            encryptedContent: response.content,
            connection: connection
        )

        let nwcResponse = try JSONDecoder().decode(
            NWCResponse.self, from: decryptedResponse.data(using: .utf8) ?? Data())

        if let error = nwcResponse.error {
            throw NWCManagerError.walletError(error)
        }

        guard let result = nwcResponse.result else {
            throw NWCManagerError.noResult
        }

        // Parse payment response from result
        let resultData = try JSONEncoder().encode(result)
        let paymentResponse = try JSONDecoder().decode(NWCPayInvoiceResponse.self, from: resultData)

        return paymentResponse.preimage
    }

    /// Gets wallet balance
    ///
    /// - Parameter connection: The NWC connection
    /// - Returns: The wallet balance in millisats
    /// - Throws: Error if getting balance fails
    public static func getBalance(connection: NWCConnection) async throws -> Int {
        // Use request queue to ensure only one request is processed at a time
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async {
                Task {
                    do {
                        // Small delay to avoid overwhelming the wallet
                        try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

                        // Create get_balance request
                        let request = NWCRequest(method: .getBalance)
                        let requestJSON = try JSONEncoder().encode(request)
                        let requestString = String(data: requestJSON, encoding: .utf8) ?? "{}"

                        // Encrypt the request
                        let encryptedContent = try encryptRequest(
                            content: requestString,
                            connection: connection
                        )

                        let nwcRequest = try NWCRequestEvent(
                            encryptedContent: encryptedContent,
                            recipientPubkey: connection.walletPubkey.hex,
                            signedBy: connection.clientKeypair
                        )

                        // Send request and wait for response
                        let response = try await sendRequest(nwcRequest, connection: connection)

                        // Decrypt and parse response
                        let decryptedResponse = try decryptResponse(
                            encryptedContent: response.content,
                            connection: connection
                        )

                        let nwcResponse = try JSONDecoder().decode(
                            NWCResponse.self, from: decryptedResponse.data(using: .utf8) ?? Data())

                        if let error = nwcResponse.error {
                            throw NWCManagerError.walletError(error)
                        }

                        guard let result = nwcResponse.result else {
                            throw NWCManagerError.noResult
                        }

                        // Parse balance from result
                        let resultData = try JSONEncoder().encode(result)
                        let balanceResponse = try JSONDecoder().decode(
                            NWCGetBalanceResponse.self, from: resultData)

                        continuation.resume(returning: balanceResponse.balance)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Creates a Lightning invoice
    ///
    /// - Parameters:
    ///   - amount: The invoice amount in millisats
    ///   - description: Optional invoice description
    ///   - connection: The NWC connection
    /// - Returns: The created invoice and payment hash
    /// - Throws: Error if invoice creation fails
    public static func makeInvoice(
        amount: Int,
        description: String? = nil,
        connection: NWCConnection
    ) async throws -> (invoice: String, paymentHash: String) {
        // Create make_invoice request
        let request = NWCRequest(
            method: .makeInvoice,
            params: [
                "amount": AnyCodable(amount),
                "description": AnyCodable(description as Any),
            ]
        )
        let requestJSON = try JSONEncoder().encode(request)
        let requestString = String(data: requestJSON, encoding: .utf8) ?? "{}"

        // Encrypt the request
        let encryptedContent = try encryptRequest(
            content: requestString,
            connection: connection
        )

        // Create NWC request event
        let nwcRequest = try NWCRequestEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: connection.walletPubkey.hex,
            signedBy: connection.clientKeypair
        )

        // Send request and wait for response
        let response = try await sendRequest(nwcRequest, connection: connection)

        // Decrypt and parse response
        let decryptedResponse = try decryptResponse(
            encryptedContent: response.content,
            connection: connection
        )

        let nwcResponse = try JSONDecoder().decode(
            NWCResponse.self, from: decryptedResponse.data(using: .utf8) ?? Data())

        if let error = nwcResponse.error {
            throw NWCManagerError.walletError(error)
        }

        guard let result = nwcResponse.result else {
            throw NWCManagerError.noResult
        }

        // Parse invoice response from result
        let resultData = try JSONEncoder().encode(result)
        let invoiceResponse = try JSONDecoder().decode(
            NWCMakeInvoiceResponse.self, from: resultData)

        return (invoiceResponse.invoice, invoiceResponse.paymentHash)
    }

    /// Looks up a Lightning invoice by payment hash
    ///
    /// - Parameters:
    ///   - paymentHash: The payment hash to look up
    ///   - connection: The NWC connection
    /// - Returns: The invoice lookup result
    /// - Throws: Error if lookup fails
    public static func lookupInvoice(
        paymentHash: String,
        connection: NWCConnection
    ) async throws -> NWCLookupInvoiceResponse {
        // Create lookup_invoice request
        let request = NWCRequest(
            method: .lookupInvoice,
            params: ["payment_hash": AnyCodable(paymentHash)]
        )
        let requestJSON = try JSONEncoder().encode(request)
        let requestString = String(data: requestJSON, encoding: .utf8) ?? "{}"

        // Encrypt the request
        let encryptedContent = try encryptRequest(
            content: requestString,
            connection: connection
        )

        // Create NWC request event
        let nwcRequest = try NWCRequestEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: connection.walletPubkey.hex,
            signedBy: connection.clientKeypair
        )

        // Send request and wait for response
        let response = try await sendRequest(nwcRequest, connection: connection)

        // Decrypt and parse response
        let decryptedResponse = try decryptResponse(
            encryptedContent: response.content,
            connection: connection
        )

        let nwcResponse = try JSONDecoder().decode(
            NWCResponse.self, from: decryptedResponse.data(using: .utf8) ?? Data())

        if let error = nwcResponse.error {
            throw NWCManagerError.walletError(error)
        }

        guard let result = nwcResponse.result else {
            throw NWCManagerError.noResult
        }

        // Parse lookup response from result
        let resultData = try JSONEncoder().encode(result)
        return try JSONDecoder().decode(NWCLookupInvoiceResponse.self, from: resultData)
    }

    /// Lists Lightning transactions
    ///
    /// - Parameters:
    ///   - from: Optional start timestamp
    ///   - until: Optional end timestamp
    ///   - limit: Optional limit on number of transactions
    ///   - offset: Optional offset for pagination
    ///   - unpaid: Optional filter for unpaid invoices
    ///   - type: Optional transaction type filter
    ///   - connection: The NWC connection
    /// - Returns: The list of transactions
    /// - Throws: Error if listing fails
    public static func listTransactions(
        from: Int? = nil,
        until: Int? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        unpaid: Bool? = nil,
        type: String? = nil,
        connection: NWCConnection
    ) async throws -> NWCListTransactionsResponse {
        var params: [String: AnyCodable] = [:]

        if let from = from { params["from"] = AnyCodable(from) }
        if let until = until { params["until"] = AnyCodable(until) }
        if let limit = limit { params["limit"] = AnyCodable(limit) }
        if let offset = offset { params["offset"] = AnyCodable(offset) }
        if let unpaid = unpaid { params["unpaid"] = AnyCodable(unpaid) }
        if let type = type { params["type"] = AnyCodable(type) }

        // Create list_transactions request
        let request = NWCRequest(
            method: .listTransactions,
            params: params
        )
        let requestJSON = try JSONEncoder().encode(request)
        let requestString = String(data: requestJSON, encoding: .utf8) ?? "{}"

        // Encrypt the request
        let encryptedContent = try encryptRequest(
            content: requestString,
            connection: connection
        )

        // Create NWC request event
        let nwcRequest = try NWCRequestEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: connection.walletPubkey.hex,
            signedBy: connection.clientKeypair
        )

        // Send request and wait for response
        let response = try await sendRequest(nwcRequest, connection: connection)

        // Decrypt and parse response
        let decryptedResponse = try decryptResponse(
            encryptedContent: response.content,
            connection: connection
        )

        let nwcResponse = try JSONDecoder().decode(
            NWCResponse.self, from: decryptedResponse.data(using: .utf8) ?? Data())

        if let error = nwcResponse.error {
            throw NWCManagerError.walletError(error)
        }

        guard let result = nwcResponse.result else {
            throw NWCManagerError.noResult
        }

        // Parse transactions response from result
        let resultData = try JSONEncoder().encode(result)
        return try JSONDecoder().decode(NWCListTransactionsResponse.self, from: resultData)
    }

    /// Sends a notification to a client
    ///
    /// - Parameters:
    ///   - notification: The notification data to send
    ///   - recipientPubkey: The recipient's public key
    ///   - connection: The NWC connection
    /// - Throws: Error if sending fails
    public static func sendNotification(
        notification: NWCNotificationData,
        recipientPubkey: String,
        connection: NWCConnection
    ) async throws {
        let notificationJSON = try JSONEncoder().encode(notification)
        let notificationString = String(data: notificationJSON, encoding: .utf8) ?? "{}"

        // Encrypt the notification
        let encryptedContent = try encryptRequest(
            content: notificationString,
            connection: connection
        )

        // Create NWC notification event
        let nwcNotification = try NWCNotificationEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            signedBy: connection.clientKeypair
        )

        // Send notification (no response expected)
        try await sendNotificationEvent(nwcNotification, connection: connection)
    }

    /// Sends a payment received notification
    ///
    /// - Parameters:
    ///   - paymentHash: The payment hash
    ///   - amount: The payment amount in millisats
    ///   - description: Optional payment description
    ///   - preimage: Optional payment preimage
    ///   - recipientPubkey: The recipient's public key
    ///   - connection: The NWC connection
    /// - Throws: Error if sending fails
    public static func sendPaymentReceivedNotification(
        paymentHash: String,
        amount: Int,
        description: String? = nil,
        preimage: String? = nil,
        recipientPubkey: String,
        connection: NWCConnection
    ) async throws {
        let paymentData = NWCPaymentReceivedData(
            paymentHash: paymentHash,
            amount: amount,
            description: description,
            preimage: preimage
        )

        let dataDict = try JSONEncoder().encode(paymentData)
        let dataObject = try JSONSerialization.jsonObject(with: dataDict) as? [String: Any] ?? [:]
        let anyCodableData = dataObject.mapValues { AnyCodable($0) }

        let notification = NWCNotificationData(
            type: .paymentReceived,
            data: anyCodableData
        )

        try await sendNotification(
            notification: notification,
            recipientPubkey: recipientPubkey,
            connection: connection
        )
    }

    /// Sends a payment sent notification
    ///
    /// - Parameters:
    ///   - paymentHash: The payment hash
    ///   - amount: The payment amount in millisats
    ///   - feesPaid: Optional fees paid
    ///   - description: Optional payment description
    ///   - preimage: Optional payment preimage
    ///   - recipientPubkey: The recipient's public key
    ///   - connection: The NWC connection
    /// - Throws: Error if sending fails
    public static func sendPaymentSentNotification(
        paymentHash: String,
        amount: Int,
        feesPaid: Int? = nil,
        description: String? = nil,
        preimage: String? = nil,
        recipientPubkey: String,
        connection: NWCConnection
    ) async throws {
        let paymentData = NWCPaymentSentData(
            paymentHash: paymentHash,
            amount: amount,
            feesPaid: feesPaid,
            description: description,
            preimage: preimage
        )

        let dataDict = try JSONEncoder().encode(paymentData)
        let dataObject = try JSONSerialization.jsonObject(with: dataDict) as? [String: Any] ?? [:]
        let anyCodableData = dataObject.mapValues { AnyCodable($0) }

        let notification = NWCNotificationData(
            type: .paymentSent,
            data: anyCodableData
        )

        try await sendNotification(
            notification: notification,
            recipientPubkey: recipientPubkey,
            connection: connection
        )
    }

    /// Sends a balance changed notification
    ///
    /// - Parameters:
    ///   - balance: The new balance in millisats
    ///   - previousBalance: Optional previous balance
    ///   - recipientPubkey: The recipient's public key
    ///   - connection: The NWC connection
    /// - Throws: Error if sending fails
    public static func sendBalanceChangedNotification(
        balance: Int,
        previousBalance: Int? = nil,
        recipientPubkey: String,
        connection: NWCConnection
    ) async throws {
        let balanceData = NWCBalanceChangedData(
            balance: balance,
            previousBalance: previousBalance
        )

        let dataDict = try JSONEncoder().encode(balanceData)
        let dataObject = try JSONSerialization.jsonObject(with: dataDict) as? [String: Any] ?? [:]
        let anyCodableData = dataObject.mapValues { AnyCodable($0) }

        let notification = NWCNotificationData(
            type: .balanceChanged,
            data: anyCodableData
        )

        try await sendNotification(
            notification: notification,
            recipientPubkey: recipientPubkey,
            connection: connection
        )
    }

    // MARK: - Private Methods

    private static func encryptRequest(
        content: String,
        connection: NWCConnection
    ) throws -> String {
        // Use the existing NIP-04 encryption implementation
        let nwcManager = NWCManager()
        let result = try nwcManager.encryptNIP04(
            message: content,
            recipientPublicKey: connection.walletPubkey,
            senderPrivateKey: connection.clientKeypair.privateKey
        )

        return result
    }

    private static func decryptResponse(
        encryptedContent: String,
        connection: NWCConnection
    ) throws -> String {
        print("🔍 NWC: Attempting to decrypt response")
        print("🔍 NWC: Encrypted content: \(encryptedContent)")
        print("🔍 NWC: Wallet pubkey: \(connection.walletPubkey.hex)")
        print("🔍 NWC: Client pubkey: \(connection.clientKeypair.publicKey.hex)")

        // Use the existing NIP-04 decryption implementation
        let nwcManager = NWCManager()
        let result = try nwcManager.decryptNIP04(
            encryptedMessage: encryptedContent,
            senderPublicKey: connection.walletPubkey,
            recipientPrivateKey: connection.clientKeypair.privateKey
        )

        print("🔍 NWC: Successfully decrypted response: \(result)")
        return result
    }

    private static func sendRequest(
        _ request: NWCRequestEvent,
        connection: NWCConnection
    ) async throws -> NWCResponseEvent {

        return try await withCheckedThrowingContinuation { continuation in
            let requestId = request.id

            // Create a relay connection
            guard let relay = try? Relay(url: connection.relayURL) else {
                print("❌ NWCManager: Failed to create relay connection")
                continuation.resume(throwing: NWCManagerError.invalidRelayURL)
                return
            }

            // Set up relay delegate to handle responses
            let delegate = NWCRelayDelegate(
                requestId: requestId,
                connection: connection,
                continuation: continuation
            )
            relay.delegate = delegate

            // Connect to relay
            relay.connect()

            // Set up timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
                if !delegate.isCompleted {
                    relay.disconnect()
                    continuation.resume(
                        throwing: NWCManagerError.networkError(
                            NWCError(code: -1, message: "Request timeout - wallet not responding")))
                }
            }

            // Wait for connection and send request with a longer delay to avoid overwhelming the wallet
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                if relay.state == .connected {
                    do {
                        try relay.publishEvent(request)

                        // Set up subscription for response
                        // NIP-47: Response events are published by the wallet (author)
                        // and tagged with the client's public key (p tag)
                        let filter = Filter(
                            authors: [connection.walletPubkey.hex],  // Wallet publishes the response
                            kinds: [23195],  // NWC response kind
                            tags: ["p": [connection.clientKeypair.publicKey.hex]],  // Tagged with client pubkey
                            since: Int(Date().timeIntervalSince1970) - 5  // Only look back 5 seconds to avoid old responses
                        )

                        if let filter = filter {
                            let subscriptionId = try relay.subscribe(with: filter)

                            // Let's also try a broader subscription to see if we get any events at all
                            if let broadFilter = Filter(
                                authors: [connection.walletPubkey.hex],
                                kinds: [23195],
                                since: Int(Date().timeIntervalSince1970) - 5  // Only look back 5 seconds to avoid old responses
                            ) {
                                let broadSubscriptionId = try relay.subscribe(with: broadFilter)
                            } else {
                                print("❌ NWCManager: Failed to create broad filter")
                            }

                            // Let's also try an even broader subscription to see ALL NWC events on the relay
                            if let allNWCFilter = Filter(
                                kinds: [23195, 23194],  // Both NWC request and response kinds
                                since: Int(Date().timeIntervalSince1970) - 10  // Look back 10 seconds
                            ) {
                                let allNWCSubscriptionId = try relay.subscribe(with: allNWCFilter)
                            } else {
                                print("❌ NWCManager: Failed to create ALL NWC filter")
                            }
                        } else {
                            print("❌ NWCManager: Failed to create filter")
                        }
                    } catch {
                        print("❌ NWCManager: Failed to publish request: \(error)")
                        continuation.resume(throwing: NWCManagerError.networkError(error))
                        return
                    }
                } else {
                    print("❌ NWCManager: Failed to connect to relay, state: \(relay.state)")
                    continuation.resume(
                        throwing: NWCManagerError.networkError(
                            NWCError(code: -1, message: "Failed to connect to relay")))
                }
            }
        }
    }

    private static func sendNotificationEvent(
        _ notification: NWCNotificationEvent,
        connection: NWCManager.NWCConnection
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // Create a relay connection
            guard let relay = try? Relay(url: connection.relayURL) else {
                print("❌ NWCManager: Failed to create relay connection")
                continuation.resume(throwing: NWCManagerError.invalidRelayURL)
                return
            }

            // Connect to relay
            relay.connect()

            // Wait for connection and send notification
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                if relay.state == .connected {
                    do {
                        try relay.publishEvent(notification)
                        relay.disconnect()
                        continuation.resume()
                    } catch {
                        print("❌ NWCManager: Failed to publish notification: \(error)")
                        relay.disconnect()
                        continuation.resume(throwing: NWCManagerError.networkError(error))
                        return
                    }
                } else {
                    print("❌ NWCManager: Failed to connect to relay, state: \(relay.state)")
                    relay.disconnect()
                    continuation.resume(
                        throwing: NWCManagerError.networkError(
                            NWCError(code: -1, message: "Failed to connect to relay")))
                }
            }
        }
    }
}

/// NWC Relay Delegate for handling NWC request/response communication
private class NWCRelayDelegate: RelayDelegate {
    private let requestId: String
    private let connection: NWCManager.NWCConnection
    private let continuation: CheckedContinuation<NWCResponseEvent, Error>
    private(set) var isCompleted = false

    init(
        requestId: String,
        connection: NWCManager.NWCConnection,
        continuation: CheckedContinuation<NWCResponseEvent, Error>
    ) {
        self.requestId = requestId
        self.connection = connection
        self.continuation = continuation
    }

    func relayStateDidChange(_ relay: Relay, state: Relay.State) {
        print("🔗 NWCRelayDelegate: Relay state changed to: \(state)")
    }

    func relay(_ relay: Relay, didReceive event: RelayEvent) {

        // Log all NWC events we receive for debugging
        if event.event.kind.rawValue == 23195 || event.event.kind.rawValue == 23194 {
            print("🔍 NWCRelayDelegate: NWC EVENT DETECTED!")
        }

        guard !isCompleted else {
            return
        }

        // Check if this is a NWC response event (kind 23195)
        if event.event.kind.rawValue == 23195 {

            // Try to cast to NWCResponseEvent
            if let responseEvent = event.event as? NWCResponseEvent {
                print("🔍 NWCRelayDelegate: Received NWC response")
                print("🔍 NWCRelayDelegate: Response event ID: \(responseEvent.id)")
                print("🔍 NWCRelayDelegate: Response from pubkey: \(responseEvent.pubkey)")
                print("🔍 NWCRelayDelegate: Expected wallet pubkey: \(connection.walletPubkey.hex)")
                print(
                    "🔍 NWCRelayDelegate: Referenced event ID: \(responseEvent.referencedEventId ?? "nil")"
                )
                print("🔍 NWCRelayDelegate: Expected request ID: \(requestId)")

                // Verify this response is from the correct wallet pubkey
                // guard responseEvent.pubkey == connection.walletPubkey.hex else {
                //     print("🔍 NWCRelayDelegate: Response is from wrong wallet pubkey, ignoring")
                //     return
                // }

                // Verify this response is for our request
                if responseEvent.referencedEventId == requestId {
                    print("🔍 NWCRelayDelegate: Response matches our request ID!")
                    isCompleted = true
                    relay.disconnect()
                    continuation.resume(returning: responseEvent)
                } else {
                    print("🔍 NWCRelayDelegate: Response is for different request, ignoring")
                    // CRITICAL: Check what client pubkey this response is for
                    if let pTag = responseEvent.tags.first(where: { $0.name == "p" }) {

                        if pTag.value != connection.clientKeypair.publicKey.hex {
                            return
                        }
                    }
                }
            } else {
                print("❌ NWCRelayDelegate: Failed to cast to NWCResponseEvent")

                // Let's try to create a NWCResponseEvent manually if the cast fails
                do {
                    let responseEvent = try NWCResponseEvent(
                        encryptedContent: event.event.content,
                        recipientPubkey: connection.clientKeypair.publicKey.hex,
                        requestEventId: requestId,
                        signedBy: connection.clientKeypair
                    )

                    if let pTag = responseEvent.tags.first(where: { $0.name == "p" }) {
                        if pTag.value != connection.clientKeypair.publicKey.hex {
                            return
                        }
                        print(
                            "✅ NWCRelayDelegate: Manually created response client pubkey matches our keypair"
                        )
                    }

                    if responseEvent.referencedEventId == requestId {
                        print(
                            "✅ NWCRelayDelegate: Found matching manually created response for request \(requestId)"
                        )
                        isCompleted = true
                        relay.disconnect()
                        continuation.resume(returning: responseEvent)
                    } else {
                        print("🔗 NWCRelayDelegate: Manually created response not for our request")
                    }
                } catch {
                    print(
                        "❌ NWCRelayDelegate: Failed to create NWCResponseEvent manually: \(error)")
                }
            }
        } else {
            print("🔗 NWCRelayDelegate: Received non-NWC event: \(event.event.kind)")
            print("🔗 NWCRelayDelegate: Expected kind 23195, got \(event.event.kind.rawValue)")
        }
    }

    func relay(_ relay: Relay, didReceive response: RelayResponse) {
        print("🔗 NWCRelayDelegate: Received relay response: \(response)")
    }
}

/// NWC Manager Error
public enum NWCManagerError: Error, LocalizedError {
    case invalidWalletPubkey
    case invalidRelayURL
    case invalidSecret
    case walletError(NWCError)
    case noResult
    case notImplemented(String)
    case networkError(Error)
    case encryptionError(Error)
    case decryptionError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidWalletPubkey:
            return "Invalid wallet public key"
        case .invalidRelayURL:
            return "Invalid relay URL"
        case .invalidSecret:
            return "Invalid secret in NWC URI"
        case .walletError(let error):
            return "Wallet error: \(error.message)"
        case .noResult:
            return "No result in response"
        case .notImplemented(let feature):
            return "Feature not implemented: \(feature)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .encryptionError(let error):
            return "Encryption error: \(error.localizedDescription)"
        case .decryptionError(let error):
            return "Decryption error: \(error.localizedDescription)"
        }
    }
}
