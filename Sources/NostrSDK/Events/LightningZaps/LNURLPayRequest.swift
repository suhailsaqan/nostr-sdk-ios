//
//  LNURLPayRequest.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import Foundation

/// LNURL Pay Request Response
///
/// This represents the response from an LNURL pay request endpoint.
/// - Note: See [LUD-06: Lightning Address Protocol](https://github.com/lnurl/luds/blob/luds/06.md) for details.
public struct LNURLPayRequest: Codable {
    /// The callback URL for the pay request
    public let callback: String

    /// Maximum amount in millisats that can be sent
    public let maxSendable: Int64

    /// Minimum amount in millisats that can be sent
    public let minSendable: Int64

    /// Metadata about the payee
    public let metadata: String

    /// Optional tag for additional information
    public let tag: String

    /// Optional comment allowed length
    public let commentAllowed: Int?

    /// Optional payer data requirements
    public let payerData: PayerData?

    /// Optional nostr pubkey for zap requests
    public let nostrPubkey: String?

    /// Optional allows nostr field
    public let allowsNostr: Bool?

    private enum CodingKeys: String, CodingKey {
        case callback
        case maxSendable = "maxSendable"
        case minSendable = "minSendable"
        case metadata
        case tag
        case commentAllowed = "commentAllowed"
        case payerData = "payerData"
        case nostrPubkey = "nostrPubkey"
        case allowsNostr = "allowsNostr"
    }
}

/// Payer data requirements for LNURL pay requests
public struct PayerData: Codable {
    /// Required payer data fields
    public let required: [String]?

    /// Optional payer data fields
    public let optional: [String]?
}

/// LNURL Pay Response
///
/// This represents the response from an LNURL pay callback.
public struct LNURLPayResponse: Codable {
    /// The status of the payment request (optional - some services don't include it)
    public let status: String?

    /// The bolt11 invoice (if successful)
    public let pr: String?

    /// Error message (if failed)
    public let reason: String?

    /// Success action (if successful)
    public let successAction: SuccessAction?

    /// Verify URL (if successful)
    public let verify: String?

    private enum CodingKeys: String, CodingKey {
        case status
        case pr
        case reason
        case successAction = "successAction"
        case verify
    }
}

/// Success action for LNURL pay responses
public struct SuccessAction: Codable {
    /// The type of success action
    public let tag: String

    /// The description of the action
    public let description: String?

    /// The URL for the action
    public let url: String?

    /// The message for the action
    public let message: String?
}

/// LNURL Pay Request Error
public enum LNURLPayRequestError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case paymentFailed(String)
    case amountOutOfRange(min: Int64, max: Int64, requested: Int64)
    case nostrNotSupported
    case nostrPubkeyMismatch

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid LNURL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from LNURL endpoint"
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        case .amountOutOfRange(let min, let max, let requested):
            return "Amount \(requested) msats is out of range [\(min), \(max)]"
        case .nostrNotSupported:
            return "Nostr zaps not supported by this LNURL endpoint"
        case .nostrPubkeyMismatch:
            return "Nostr pubkey mismatch"
        }
    }
}

/// LNURL Pay Request Manager
///
/// Handles LNURL pay request flow for Lightning Zaps
public class LNURLPayRequestManager {

    /// Fetches LNURL pay request from the given URL
    ///
    /// - Parameter lnurl: The LNURL string (bech32 encoded or HTTP URL)
    /// - Returns: The LNURL pay request response
    /// - Throws: LNURLPayRequestError if the request fails
    public static func fetchPayRequest(from lnurl: String) async throws -> LNURLPayRequest {
        let url: URL

        // Handle bech32 encoded LNURL
        if lnurl.hasPrefix("lnurl") {
            url = try Bech32.decode(lnurl)
        } else if let httpURL = URL(string: lnurl) {
            url = httpURL
        } else {
            throw LNURLPayRequestError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(LNURLPayRequest.self, from: data)
            return response
        } catch {
            if error is LNURLPayRequestError {
                throw error
            } else {
                throw LNURLPayRequestError.networkError(error)
            }
        }
    }

    /// Validates that the LNURL pay request supports Nostr zaps
    ///
    /// - Parameters:
    ///   - payRequest: The LNURL pay request
    ///   - expectedNostrPubkey: The expected Nostr pubkey (optional)
    /// - Throws: LNURLPayRequestError if validation fails
    public static func validateNostrSupport(
        _ payRequest: LNURLPayRequest,
        expectedNostrPubkey: String? = nil
    ) throws {
        guard payRequest.allowsNostr == true else {
            throw LNURLPayRequestError.nostrNotSupported
        }

        if let expectedPubkey = expectedNostrPubkey,
            let nostrPubkey = payRequest.nostrPubkey,
            expectedPubkey != nostrPubkey
        {
            print("🔍 LNURL Validation: Expected pubkey: \(expectedPubkey)")
            print("🔍 LNURL Validation: LNURL nostrPubkey: \(nostrPubkey)")
            print("❌ LNURL Validation: Pubkey mismatch detected")
            throw LNURLPayRequestError.nostrPubkeyMismatch
        }
    }

    /// Validates the zap amount against the LNURL pay request limits
    ///
    /// - Parameters:
    ///   - amount: The zap amount in millisats
    ///   - payRequest: The LNURL pay request
    /// - Throws: LNURLPayRequestError if amount is out of range
    public static func validateAmount(
        _ amount: Int64,
        against payRequest: LNURLPayRequest
    ) throws {
        guard amount >= payRequest.minSendable && amount <= payRequest.maxSendable else {
            throw LNURLPayRequestError.amountOutOfRange(
                min: payRequest.minSendable,
                max: payRequest.maxSendable,
                requested: amount
            )
        }
    }

    /// Creates a zap request callback URL
    ///
    /// - Parameters:
    ///   - payRequest: The LNURL pay request
    ///   - amount: The zap amount in millisats
    ///   - zapRequestJSON: The JSON-encoded zap request
    ///   - comment: Optional comment
    /// - Returns: The callback URL with parameters
    public static func createCallbackURL(
        from payRequest: LNURLPayRequest,
        amount: Int64,
        zapRequestJSON: String,
        comment: String? = nil
    ) -> URL? {
        var components = URLComponents(string: payRequest.callback)
        components?.queryItems = [
            URLQueryItem(name: "amount", value: String(amount)),
            URLQueryItem(name: "nostr", value: zapRequestJSON),
        ]

        if let comment = comment {
            components?.queryItems?.append(URLQueryItem(name: "comment", value: comment))
        }

        return components?.url
    }

    /// Sends the zap request to the LNURL callback
    ///
    /// - Parameters:
    ///   - callbackURL: The callback URL
    /// - Returns: The LNURL pay response
    /// - Throws: LNURLPayRequestError if the request fails
    public static func sendZapRequest(to callbackURL: URL) async throws -> LNURLPayResponse {
        do {
            let (data, _) = try await URLSession.shared.data(from: callbackURL)

            // Debug: Print the raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 LNURL Response: \(responseString)")
            }

            let response = try JSONDecoder().decode(LNURLPayResponse.self, from: data)

            // If status is present, it must be "OK". If status is missing, check for pr field
            if let status = response.status {
                guard status == "OK" else {
                    print("❌ LNURL Error: \(response.reason ?? "Unknown error")")
                    throw LNURLPayRequestError.paymentFailed(response.reason ?? "Unknown error")
                }
            } else {
                // If no status field, check if we have a bolt11 invoice (pr field)
                guard response.pr != nil else {
                    throw LNURLPayRequestError.paymentFailed(
                        "No invoice received and no status field")
                }
            }

            return response
        } catch {
            if error is LNURLPayRequestError {
                throw error
            } else {
                throw LNURLPayRequestError.networkError(error)
            }
        }
    }
}

/// Extension to decode LNURL from bech32
extension Bech32 {
    /// Decodes a bech32 LNURL string to a URL
    ///
    /// - Parameter lnurl: The bech32 encoded LNURL string
    /// - Returns: The decoded URL
    /// - Throws: Error if decoding fails
    public static func decode(_ lnurl: String) throws -> URL {
        // Remove the "lnurl" prefix if present
        let cleanLnurl = lnurl.hasPrefix("lnurl") ? String(lnurl.dropFirst(5)) : lnurl

        // Decode bech32
        let (_, data) = try NostrSDK.Bech32.decode(cleanLnurl)

        // Convert to URL
        guard let urlString = String(data: data, encoding: .utf8),
            let url = URL(string: urlString)
        else {
            throw LNURLPayRequestError.invalidURL
        }

        return url
    }
}
