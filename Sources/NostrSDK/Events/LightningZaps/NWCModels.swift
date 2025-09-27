//
//  NWCModels.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import Foundation

/// NWC Request Method
public enum NWCRequestMethod: String, Codable, CaseIterable {
    case getInfo = "get_info"
    case payInvoice = "pay_invoice"
    case getBalance = "get_balance"
    case makeInvoice = "make_invoice"
    case lookupInvoice = "lookup_invoice"
    case listTransactions = "list_transactions"
}

/// NWC Request
public struct NWCRequest: Codable {
    public let method: NWCRequestMethod
    public let params: [String: AnyCodable]

    public init(method: NWCRequestMethod, params: [String: AnyCodable] = [:]) {
        self.method = method
        self.params = params
    }
}

/// NWC Response
public struct NWCResponse: Codable {
    public let result: AnyCodable?
    public let error: NWCError?

    public init(result: AnyCodable? = nil, error: NWCError? = nil) {
        self.result = result
        self.error = error
    }
}

/// NWC Error
public struct NWCError: Codable, Error {
    public let code: Int
    public let message: String

    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}

/// NWC Error Codes as defined in NIP-47
public enum NWCErrorCode: Int, CaseIterable {
    case invalidMethod = -32601
    case invalidParams = -32602
    case internalError = -32603
    case parseError = -32700

    // NWC specific errors
    case rateLimited = -32000
    case notFound = -32001
    case insufficientBalance = -32002
    case quotaExceeded = -32003
    case restricted = -32004
    case rejected = -32005
    case unsupportedMethod = -32006
    case expired = -32007
    case unauthorized = -32008
    case invalidInvoice = -32009
    case paymentFailed = -32010
    case paymentTimeout = -32011
    case paymentRouteNotFound = -32012
    case paymentIncorrectDetails = -32013
    case paymentInsufficientBalance = -32014
    case paymentServiceUnavailable = -32015
    case paymentUnknown = -32016

    public var message: String {
        switch self {
        case .invalidMethod:
            return "Method not found"
        case .invalidParams:
            return "Invalid params"
        case .internalError:
            return "Internal error"
        case .parseError:
            return "Parse error"
        case .rateLimited:
            return "Rate limited"
        case .notFound:
            return "Not found"
        case .insufficientBalance:
            return "Insufficient balance"
        case .quotaExceeded:
            return "Quota exceeded"
        case .restricted:
            return "Restricted"
        case .rejected:
            return "Rejected"
        case .unsupportedMethod:
            return "Unsupported method"
        case .expired:
            return "Expired"
        case .unauthorized:
            return "Unauthorized"
        case .invalidInvoice:
            return "Invalid invoice"
        case .paymentFailed:
            return "Payment failed"
        case .paymentTimeout:
            return "Payment timeout"
        case .paymentRouteNotFound:
            return "Payment route not found"
        case .paymentIncorrectDetails:
            return "Payment incorrect details"
        case .paymentInsufficientBalance:
            return "Payment insufficient balance"
        case .paymentServiceUnavailable:
            return "Payment service unavailable"
        case .paymentUnknown:
            return "Payment unknown"
        }
    }

    public static func error(for code: Int) -> NWCError {
        if let errorCode = NWCErrorCode(rawValue: code) {
            return NWCError(code: code, message: errorCode.message)
        } else {
            return NWCError(code: code, message: "Unknown error")
        }
    }
}

/// Any Codable wrapper for dynamic JSON values
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(
                AnyCodable.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

/// NWC Get Info Response
public struct NWCGetInfoResponse: Codable {
    public let alias: String
    public let color: String?
    public let pubkey: String
    public let network: String?
    public let blockHeight: Int?
    public let blockHash: String?
    public let methods: [String]

    private enum CodingKeys: String, CodingKey {
        case alias, color, pubkey, network
        case blockHeight = "block_height"
        case blockHash = "block_hash"
        case methods
    }
}

/// NWC Pay Invoice Request
public struct NWCPayInvoiceRequest: Codable {
    public let invoice: String

    public init(invoice: String) {
        self.invoice = invoice
    }
}

/// NWC Pay Invoice Response
public struct NWCPayInvoiceResponse: Codable {
    public let preimage: String

    public init(preimage: String) {
        self.preimage = preimage
    }
}

/// NWC Get Balance Response
public struct NWCGetBalanceResponse: Codable {
    public let balance: Int

    public init(balance: Int) {
        self.balance = balance
    }
}

/// NWC Make Invoice Request
public struct NWCMakeInvoiceRequest: Codable {
    public let amount: Int
    public let description: String?
    public let descriptionHash: String?
    public let expiry: Int?

    private enum CodingKeys: String, CodingKey {
        case amount, description
        case descriptionHash = "description_hash"
        case expiry
    }

    public init(
        amount: Int, description: String? = nil, descriptionHash: String? = nil, expiry: Int? = nil
    ) {
        self.amount = amount
        self.description = description
        self.descriptionHash = descriptionHash
        self.expiry = expiry
    }
}

/// NWC Make Invoice Response
public struct NWCMakeInvoiceResponse: Codable {
    public let invoice: String
    public let paymentHash: String

    private enum CodingKeys: String, CodingKey {
        case invoice
        case paymentHash = "payment_hash"
    }

    public init(invoice: String, paymentHash: String) {
        self.invoice = invoice
        self.paymentHash = paymentHash
    }
}

/// NWC Lookup Invoice Request
public struct NWCLookupInvoiceRequest: Codable {
    public let paymentHash: String

    private enum CodingKeys: String, CodingKey {
        case paymentHash = "payment_hash"
    }

    public init(paymentHash: String) {
        self.paymentHash = paymentHash
    }
}

/// NWC Lookup Invoice Response
public struct NWCLookupInvoiceResponse: Codable {
    public let paid: Bool
    public let preimage: String?
    public let bolt11: String?

    public init(paid: Bool, preimage: String? = nil, bolt11: String? = nil) {
        self.paid = paid
        self.preimage = preimage
        self.bolt11 = bolt11
    }
}

/// NWC List Transactions Request
public struct NWCListTransactionsRequest: Codable {
    public let from: Int?
    public let until: Int?
    public let limit: Int?
    public let offset: Int?
    public let unpaid: Bool?
    public let type: String?

    public init(
        from: Int? = nil, until: Int? = nil, limit: Int? = nil, offset: Int? = nil,
        unpaid: Bool? = nil, type: String? = nil
    ) {
        self.from = from
        self.until = until
        self.limit = limit
        self.offset = offset
        self.unpaid = unpaid
        self.type = type
    }
}

/// NWC Transaction
public struct NWCTransaction: Codable {
    public let type: String
    public let invoice: String?
    public let paymentHash: String?
    public let preimage: String?
    public let description: String?
    public let descriptionHash: String?
    public let paid: Bool
    public let amount: Int?
    public let feesPaid: Int?
    public let createdAt: Int
    public let expiresAt: Int?
    public let metadata: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case type, invoice, description, paid, amount, metadata, preimage
        case paymentHash = "payment_hash"
        case descriptionHash = "description_hash"
        case feesPaid = "fees_paid"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }

    public init(
        type: String,
        invoice: String? = nil,
        paymentHash: String? = nil,
        preimage: String? = nil,
        description: String? = nil,
        descriptionHash: String? = nil,
        paid: Bool = false,
        amount: Int? = nil,
        feesPaid: Int? = nil,
        createdAt: Int,
        expiresAt: Int? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.type = type
        self.invoice = invoice
        self.paymentHash = paymentHash
        self.preimage = preimage
        self.description = description
        self.descriptionHash = descriptionHash
        self.paid = paid
        self.amount = amount
        self.feesPaid = feesPaid
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.metadata = metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "unknown"
        invoice = try container.decodeIfPresent(String.self, forKey: .invoice)
        paymentHash = try container.decodeIfPresent(String.self, forKey: .paymentHash)
        preimage = try container.decodeIfPresent(String.self, forKey: .preimage)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        descriptionHash = try container.decodeIfPresent(String.self, forKey: .descriptionHash)
        paid = try container.decodeIfPresent(Bool.self, forKey: .paid) ?? false
        amount = try container.decodeIfPresent(Int.self, forKey: .amount) ?? 0
        feesPaid = try container.decodeIfPresent(Int.self, forKey: .feesPaid)
        createdAt = try container.decode(Int.self, forKey: .createdAt)
        expiresAt = try container.decodeIfPresent(Int.self, forKey: .expiresAt)
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(invoice, forKey: .invoice)
        try container.encodeIfPresent(paymentHash, forKey: .paymentHash)
        try container.encodeIfPresent(preimage, forKey: .preimage)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(descriptionHash, forKey: .descriptionHash)
        try container.encode(paid, forKey: .paid)
        try container.encodeIfPresent(amount, forKey: .amount)
        try container.encodeIfPresent(feesPaid, forKey: .feesPaid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
}

/// NWC List Transactions Response
public struct NWCListTransactionsResponse: Codable {
    public let transactions: [NWCTransaction]

    public init(transactions: [NWCTransaction]) {
        self.transactions = transactions
    }
}

/// NWC Notification Types
public enum NWCNotificationType: String, Codable, CaseIterable {
    case paymentReceived = "payment_received"
    case paymentSent = "payment_sent"
    case invoicePaid = "invoice_paid"
    case invoiceExpired = "invoice_expired"
    case balanceChanged = "balance_changed"
}

/// NWC Notification Data
public struct NWCNotificationData: Codable {
    public let type: NWCNotificationType
    public let data: [String: AnyCodable]

    public init(type: NWCNotificationType, data: [String: AnyCodable] = [:]) {
        self.type = type
        self.data = data
    }
}

/// NWC Payment Received Notification Data
public struct NWCPaymentReceivedData: Codable {
    public let paymentHash: String
    public let amount: Int
    public let description: String?
    public let preimage: String?

    private enum CodingKeys: String, CodingKey {
        case paymentHash = "payment_hash"
        case amount, description, preimage
    }

    public init(
        paymentHash: String, amount: Int, description: String? = nil, preimage: String? = nil
    ) {
        self.paymentHash = paymentHash
        self.amount = amount
        self.description = description
        self.preimage = preimage
    }
}

/// NWC Payment Sent Notification Data
public struct NWCPaymentSentData: Codable {
    public let paymentHash: String
    public let amount: Int
    public let feesPaid: Int?
    public let description: String?
    public let preimage: String?

    private enum CodingKeys: String, CodingKey {
        case paymentHash = "payment_hash"
        case amount, description, preimage
        case feesPaid = "fees_paid"
    }

    public init(
        paymentHash: String, amount: Int, feesPaid: Int? = nil, description: String? = nil,
        preimage: String? = nil
    ) {
        self.paymentHash = paymentHash
        self.amount = amount
        self.feesPaid = feesPaid
        self.description = description
        self.preimage = preimage
    }
}

/// NWC Invoice Paid Notification Data
public struct NWCInvoicePaidData: Codable {
    public let paymentHash: String
    public let amount: Int
    public let description: String?
    public let preimage: String?

    private enum CodingKeys: String, CodingKey {
        case paymentHash = "payment_hash"
        case amount, description, preimage
    }

    public init(
        paymentHash: String, amount: Int, description: String? = nil, preimage: String? = nil
    ) {
        self.paymentHash = paymentHash
        self.amount = amount
        self.description = description
        self.preimage = preimage
    }
}

/// NWC Invoice Expired Notification Data
public struct NWCInvoiceExpiredData: Codable {
    public let paymentHash: String
    public let amount: Int
    public let description: String?

    private enum CodingKeys: String, CodingKey {
        case paymentHash = "payment_hash"
        case amount, description
    }

    public init(paymentHash: String, amount: Int, description: String? = nil) {
        self.paymentHash = paymentHash
        self.amount = amount
        self.description = description
    }
}

/// NWC Balance Changed Notification Data
public struct NWCBalanceChangedData: Codable {
    public let balance: Int
    public let previousBalance: Int?

    private enum CodingKeys: String, CodingKey {
        case balance
        case previousBalance = "previous_balance"
    }

    public init(balance: Int, previousBalance: Int? = nil) {
        self.balance = balance
        self.previousBalance = previousBalance
    }
}
