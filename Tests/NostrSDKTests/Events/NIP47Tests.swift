//
//  NIP47Tests.swift
//  NostrSDKTests
//
//  Created by Suhail Saqan on 3/8/25.
//

import XCTest

@testable import NostrSDK

final class NIP47Tests: XCTestCase {

    func testNWCConnectionURIParsing() throws {
        let uriString =
            "nostr+walletconnect://0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef?relay=wss://relay.example.com&secret=abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"

        let uri = try NWCConnectionURI(uriString: uriString)

        XCTAssertEqual(
            uri.walletPubkey, "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")
        XCTAssertEqual(uri.relayURL, "wss://relay.example.com")
        XCTAssertEqual(
            uri.secret, "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789")
    }

    func testNWCConnectionURIInvalidScheme() {
        let uriString =
            "https://example.com?relay=wss://relay.example.com&secret=abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"

        XCTAssertThrowsError(try NWCConnectionURI(uriString: uriString)) { error in
            XCTAssertTrue(error is NWCConnectionURIError)
            if let nwcError = error as? NWCConnectionURIError {
                XCTAssertEqual(nwcError, .invalidScheme)
            }
        }
    }

    func testNWCConnectionURIMissingSecret() {
        let uriString =
            "nostr+walletconnect://0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef?relay=wss://relay.example.com"

        XCTAssertThrowsError(try NWCConnectionURI(uriString: uriString)) { error in
            XCTAssertTrue(error is NWCConnectionURIError)
            if let nwcError = error as? NWCConnectionURIError {
                XCTAssertEqual(nwcError, .missingSecret)
            }
        }
    }

    func testNWCRequestEventCreation() throws {
        let keypair = Keypair.test
        let recipientPubkey = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        let encryptedContent = "encrypted_request_content"

        let request = try NWCRequestEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            signedBy: keypair
        )

        XCTAssertEqual(request.kind, .nwcRequest)
        XCTAssertEqual(request.content, encryptedContent)
        XCTAssertEqual(request.recipientPubkey, recipientPubkey)
        XCTAssertEqual(request.tags.count, 1)
        XCTAssertEqual(request.tags.first?.name, "p")
        XCTAssertEqual(request.tags.first?.value, recipientPubkey)
    }

    func testNWCResponseEventCreation() throws {
        let keypair = Keypair.test
        let recipientPubkey = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        let requestEventId = "request_event_id_123"
        let encryptedContent = "encrypted_response_content"

        let response = try NWCResponseEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            requestEventId: requestEventId,
            signedBy: keypair
        )

        XCTAssertEqual(response.kind, .nwcResponse)
        XCTAssertEqual(response.content, encryptedContent)
        XCTAssertEqual(response.recipientPubkey, recipientPubkey)
        XCTAssertEqual(response.referencedEventId, requestEventId)
        XCTAssertEqual(response.tags.count, 2)

        let pTag = response.tags.first { $0.name == "p" }
        let eTag = response.tags.first { $0.name == "e" }

        XCTAssertNotNil(pTag)
        XCTAssertNotNil(eTag)
        XCTAssertEqual(pTag?.value, recipientPubkey)
        XCTAssertEqual(eTag?.value, requestEventId)
    }

    func testNWCNotificationEventCreation() throws {
        let keypair = Keypair.test
        let recipientPubkey = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        let encryptedContent = "encrypted_notification_content"

        let notification = try NWCNotificationEvent(
            encryptedContent: encryptedContent,
            recipientPubkey: recipientPubkey,
            signedBy: keypair
        )

        XCTAssertEqual(notification.kind, .nwcNotification)
        XCTAssertEqual(notification.content, encryptedContent)
        XCTAssertEqual(notification.recipientPubkey, recipientPubkey)
        XCTAssertEqual(notification.tags.count, 1)
        XCTAssertEqual(notification.tags.first?.name, "p")
        XCTAssertEqual(notification.tags.first?.value, recipientPubkey)
    }

    func testNWCInfoEventCreation() throws {
        let keypair = Keypair.test
        let name = "Test Wallet"
        let description = "A test wallet for NWC"
        let icon = "https://example.com/icon.png"
        let version = "1.0"
        let supportedMethods = ["get_info", "pay_invoice", "get_balance", "make_invoice"]

        let infoEvent = try NWCInfoEvent(
            name: name,
            description: description,
            icon: icon,
            version: version,
            supportedMethods: supportedMethods,
            signedBy: keypair
        )

        XCTAssertEqual(infoEvent.kind, .nwcInfo)
        XCTAssertNotNil(infoEvent.walletInfo)

        let walletInfo = infoEvent.walletInfo!
        XCTAssertEqual(walletInfo.name, name)
        XCTAssertEqual(walletInfo.description, description)
        XCTAssertEqual(walletInfo.icon, icon)
        XCTAssertEqual(walletInfo.version, version)
        XCTAssertEqual(walletInfo.supportedMethods, supportedMethods)
    }

    func testNWCRequestMethods() throws {
        // Test get_info request
        let getInfoRequest = NWCRequest(method: .getInfo)
        XCTAssertEqual(getInfoRequest.method, .getInfo)
        XCTAssertTrue(getInfoRequest.params.isEmpty)

        // Test pay_invoice request
        let invoice = "lnbc100n1p0example..."
        let payInvoiceRequest = NWCRequest(
            method: .payInvoice,
            params: ["invoice": AnyCodable(invoice)]
        )
        XCTAssertEqual(payInvoiceRequest.method, .payInvoice)
        XCTAssertEqual(payInvoiceRequest.params.count, 1)
        XCTAssertEqual(payInvoiceRequest.params["invoice"]?.value as? String, invoice)

        // Test make_invoice request
        let makeInvoiceRequest = NWCRequest(
            method: .makeInvoice,
            params: [
                "amount": AnyCodable(100000),
                "description": AnyCodable("Test invoice"),
            ]
        )
        XCTAssertEqual(makeInvoiceRequest.method, .makeInvoice)
        XCTAssertEqual(makeInvoiceRequest.params.count, 2)
        XCTAssertEqual(makeInvoiceRequest.params["amount"]?.value as? Int, 100000)
        XCTAssertEqual(makeInvoiceRequest.params["description"]?.value as? String, "Test invoice")
    }

    func testNWCResponseStructures() throws {
        // Test get_info response
        let getInfoResponse = NWCGetInfoResponse(
            alias: "Test Wallet",
            color: "#FF0000",
            pubkey: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
            network: "bitcoin",
            blockHeight: 800000,
            blockHash: "0000000000000000000000000000000000000000000000000000000000000000",
            methods: ["get_info", "pay_invoice", "get_balance", "make_invoice"]
        )

        XCTAssertEqual(getInfoResponse.alias, "Test Wallet")
        XCTAssertEqual(getInfoResponse.color, "#FF0000")
        XCTAssertEqual(getInfoResponse.network, "bitcoin")
        XCTAssertEqual(getInfoResponse.blockHeight, 800000)
        XCTAssertEqual(getInfoResponse.methods.count, 4)

        // Test pay_invoice response
        let payInvoiceResponse = NWCPayInvoiceResponse(preimage: "preimage123")
        XCTAssertEqual(payInvoiceResponse.preimage, "preimage123")

        // Test get_balance response
        let getBalanceResponse = NWCGetBalanceResponse(balance: 1_000_000)
        XCTAssertEqual(getBalanceResponse.balance, 1_000_000)

        // Test make_invoice response
        let makeInvoiceResponse = NWCMakeInvoiceResponse(
            invoice: "lnbc100n1p0example...",
            paymentHash: "payment_hash_123"
        )
        XCTAssertEqual(makeInvoiceResponse.invoice, "lnbc100n1p0example...")
        XCTAssertEqual(makeInvoiceResponse.paymentHash, "payment_hash_123")
    }

    func testNWCErrorCodes() {
        // Test standard JSON-RPC error codes
        XCTAssertEqual(NWCErrorCode.invalidMethod.rawValue, -32601)
        XCTAssertEqual(NWCErrorCode.invalidParams.rawValue, -32602)
        XCTAssertEqual(NWCErrorCode.internalError.rawValue, -32603)
        XCTAssertEqual(NWCErrorCode.parseError.rawValue, -32700)

        // Test NWC specific error codes
        XCTAssertEqual(NWCErrorCode.rateLimited.rawValue, -32000)
        XCTAssertEqual(NWCErrorCode.notFound.rawValue, -32001)
        XCTAssertEqual(NWCErrorCode.insufficientBalance.rawValue, -32002)
        XCTAssertEqual(NWCErrorCode.quotaExceeded.rawValue, -32003)
        XCTAssertEqual(NWCErrorCode.restricted.rawValue, -32004)
        XCTAssertEqual(NWCErrorCode.rejected.rawValue, -32005)
        XCTAssertEqual(NWCErrorCode.unsupportedMethod.rawValue, -32006)
        XCTAssertEqual(NWCErrorCode.expired.rawValue, -32007)
        XCTAssertEqual(NWCErrorCode.unauthorized.rawValue, -32008)
        XCTAssertEqual(NWCErrorCode.invalidInvoice.rawValue, -32009)
        XCTAssertEqual(NWCErrorCode.paymentFailed.rawValue, -32010)
        XCTAssertEqual(NWCErrorCode.paymentTimeout.rawValue, -32011)
        XCTAssertEqual(NWCErrorCode.paymentRouteNotFound.rawValue, -32012)
        XCTAssertEqual(NWCErrorCode.paymentIncorrectDetails.rawValue, -32013)
        XCTAssertEqual(NWCErrorCode.paymentInsufficientBalance.rawValue, -32014)
        XCTAssertEqual(NWCErrorCode.paymentServiceUnavailable.rawValue, -32015)
        XCTAssertEqual(NWCErrorCode.paymentUnknown.rawValue, -32016)

        // Test error messages
        XCTAssertEqual(NWCErrorCode.invalidMethod.message, "Method not found")
        XCTAssertEqual(NWCErrorCode.insufficientBalance.message, "Insufficient balance")
        XCTAssertEqual(NWCErrorCode.paymentFailed.message, "Payment failed")
    }

    func testNWCNotificationData() throws {
        // Test payment received notification
        let paymentReceivedData = NWCPaymentReceivedData(
            paymentHash: "payment_hash_123",
            amount: 100000,
            description: "Test payment",
            preimage: "preimage_123"
        )

        XCTAssertEqual(paymentReceivedData.paymentHash, "payment_hash_123")
        XCTAssertEqual(paymentReceivedData.amount, 100000)
        XCTAssertEqual(paymentReceivedData.description, "Test payment")
        XCTAssertEqual(paymentReceivedData.preimage, "preimage_123")

        // Test payment sent notification
        let paymentSentData = NWCPaymentSentData(
            paymentHash: "payment_hash_456",
            amount: 50000,
            feesPaid: 1000,
            description: "Test payment sent",
            preimage: "preimage_456"
        )

        XCTAssertEqual(paymentSentData.paymentHash, "payment_hash_456")
        XCTAssertEqual(paymentSentData.amount, 50000)
        XCTAssertEqual(paymentSentData.feesPaid, 1000)
        XCTAssertEqual(paymentSentData.description, "Test payment sent")
        XCTAssertEqual(paymentSentData.preimage, "preimage_456")

        // Test balance changed notification
        let balanceChangedData = NWCBalanceChangedData(
            balance: 1_000_000,
            previousBalance: 900000
        )

        XCTAssertEqual(balanceChangedData.balance, 1_000_000)
        XCTAssertEqual(balanceChangedData.previousBalance, 900000)

        // Test notification data wrapper
        let notificationData = NWCNotificationData(
            type: .paymentReceived,
            data: [
                "payment_hash": AnyCodable("payment_hash_123"),
                "amount": AnyCodable(100000),
            ]
        )

        XCTAssertEqual(notificationData.type, .paymentReceived)
        XCTAssertEqual(notificationData.data.count, 2)
        XCTAssertEqual(notificationData.data["payment_hash"]?.value as? String, "payment_hash_123")
        XCTAssertEqual(notificationData.data["amount"]?.value as? Int, 100000)
    }

    func testNWCTransactionStructure() throws {
        let transaction = NWCTransaction(
            type: "incoming",
            invoice: "lnbc100n1p0example...",
            paymentHash: "payment_hash_123",
            preimage: "preimage_123",
            description: "Test transaction",
            descriptionHash: "description_hash_123",
            paid: true,
            amount: 100000,
            feesPaid: 1000,
            createdAt: 1_640_995_200,
            expiresAt: 1_640_998_800,
            metadata: [
                "source": AnyCodable("test"),
                "category": AnyCodable("payment"),
            ]
        )

        XCTAssertEqual(transaction.type, "incoming")
        XCTAssertEqual(transaction.invoice, "lnbc100n1p0example...")
        XCTAssertEqual(transaction.paymentHash, "payment_hash_123")
        XCTAssertEqual(transaction.preimage, "preimage_123")
        XCTAssertEqual(transaction.description, "Test transaction")
        XCTAssertEqual(transaction.descriptionHash, "description_hash_123")
        XCTAssertTrue(transaction.paid)
        XCTAssertEqual(transaction.amount, 100000)
        XCTAssertEqual(transaction.feesPaid, 1000)
        XCTAssertEqual(transaction.createdAt, 1_640_995_200)
        XCTAssertEqual(transaction.expiresAt, 1_640_998_800)
        XCTAssertEqual(transaction.metadata?.count, 2)
        XCTAssertEqual(transaction.metadata?["source"]?.value as? String, "test")
        XCTAssertEqual(transaction.metadata?["category"]?.value as? String, "payment")
    }

    func testAnyCodableSerialization() throws {
        // Test string
        let stringValue = AnyCodable("test_string")
        let stringData = try JSONEncoder().encode(stringValue)
        let stringDecoded = try JSONDecoder().decode(AnyCodable.self, from: stringData)
        XCTAssertEqual(stringDecoded.value as? String, "test_string")

        // Test integer
        let intValue = AnyCodable(123)
        let intData = try JSONEncoder().encode(intValue)
        let intDecoded = try JSONDecoder().decode(AnyCodable.self, from: intData)
        XCTAssertEqual(intDecoded.value as? Int, 123)

        // Test boolean
        let boolValue = AnyCodable(true)
        let boolData = try JSONEncoder().encode(boolValue)
        let boolDecoded = try JSONDecoder().decode(AnyCodable.self, from: boolData)
        XCTAssertEqual(boolDecoded.value as? Bool, true)

        // Test array
        let arrayValue = AnyCodable([1, 2, 3])
        let arrayData = try JSONEncoder().encode(arrayValue)
        let arrayDecoded = try JSONDecoder().decode(AnyCodable.self, from: arrayData)
        XCTAssertEqual(arrayDecoded.value as? [Int], [1, 2, 3])

        // Test dictionary
        let dictValue = AnyCodable(["key1": "value1", "key2": 42])
        let dictData = try JSONEncoder().encode(dictValue)
        let dictDecoded = try JSONDecoder().decode(AnyCodable.self, from: dictData)
        let decodedDict = dictDecoded.value as? [String: Any]
        XCTAssertEqual(decodedDict?["key1"] as? String, "value1")
        XCTAssertEqual(decodedDict?["key2"] as? Int, 42)
    }
}
