//
//  ContentSigning.swift
//
//
//  Created by Bryan Montz on 6/20/23.
//

import Foundation
import secp256k1

public protocol ContentSigning {}
extension ContentSigning {

    /// Produces a Schnorr signature of the provided `content` using the `privateKey`.
    ///
    /// - Parameters:
    ///   - content: The content to sign.
    ///   - privateKey: A private key to sign the content with.
    /// - Returns: The signature.
    public func signatureForContent(_ content: String, privateKey: String) throws -> String {
        guard let privateKeyData = privateKey.hexadecimalData else {
            throw NSError(
                domain: "ContentSigning", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid private key hex format"])
        }
        let signingKey = try secp256k1.Schnorr.PrivateKey(dataRepresentation: privateKeyData)

        guard let contentData = content.hexadecimalData else {
            print("❌ ContentSigning: Invalid content hex format")
            throw NSError(
                domain: "ContentSigning", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid content hex format"])
        }
        var contentBytes = [UInt8](contentData)

        var rand = Data.randomBytes(count: 64)
        let signature = try signingKey.signature(message: &contentBytes, auxiliaryRand: &rand)

        let result = signature.dataRepresentation.hexString
        return result
    }
}

extension PrivateKey: ContentSigning {
    func signatureForContent(_ content: String) throws -> String {
        try signatureForContent(content, privateKey: hex)
    }
}
