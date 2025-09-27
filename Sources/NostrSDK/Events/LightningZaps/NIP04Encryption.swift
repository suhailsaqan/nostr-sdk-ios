//
//  NIP04Encryption.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 3/8/25.
//

import CommonCrypto
import CryptoKit
import Foundation
import secp256k1

/// NIP-04 Encryption Error
public enum NIP04EncryptionError: Error, LocalizedError {
    case invalidPrivateKey
    case invalidPublicKey
    case invalidSharedSecret
    case encryptionFailed
    case decryptionFailed
    case invalidBase64
    case invalidJSON
    case invalidIV
    case invalidCiphertext
    case invalidFormat

    public var errorDescription: String? {
        switch self {
        case .invalidPrivateKey:
            return "Invalid private key"
        case .invalidPublicKey:
            return "Invalid public key"
        case .invalidSharedSecret:
            return "Invalid shared secret"
        case .encryptionFailed:
            return "Encryption failed"
        case .decryptionFailed:
            return "Decryption failed"
        case .invalidBase64:
            return "Invalid base64 encoding"
        case .invalidJSON:
            return "Invalid JSON"
        case .invalidIV:
            return "Invalid initialization vector"
        case .invalidCiphertext:
            return "Invalid ciphertext"
        case .invalidFormat:
            return "Invalid message format"
        }
    }
}

/// NIP-04 Encryption Protocol
///
/// Implements the encryption scheme defined in NIP-04 for encrypted direct messages.
/// Uses AES-256-CBC with a shared secret derived from ECDH.
///
/// > Warning: NIP-04 is deprecated due to security vulnerabilities. It lacks message authentication,
/// > making it susceptible to undetectable alterations during transmission. Use NIP-17 or NIP-44 instead.
@available(
    *, deprecated,
    message: "NIP-04 is deprecated due to security vulnerabilities. Use NIP-17 or NIP-44 instead."
)
public protocol NIP04Encryption {
    /// Encrypts a message using NIP-04 encryption
    ///
    /// - Parameters:
    ///   - message: The plaintext message to encrypt
    ///   - recipientPublicKey: The recipient's public key
    ///   - senderPrivateKey: The sender's private key
    /// - Returns: The encrypted message in NIP-04 format: base64(encrypted_message)?iv=base64(iv)
    /// - Throws: NIP04EncryptionError if encryption fails
    func encryptNIP04(
        message: String,
        recipientPublicKey: PublicKey,
        senderPrivateKey: PrivateKey
    ) throws -> String

    /// Decrypts a message using NIP-04 encryption
    ///
    /// - Parameters:
    ///   - encryptedMessage: The encrypted message in NIP-04 format: base64(encrypted_message)?iv=base64(iv)
    ///   - senderPublicKey: The sender's public key
    ///   - recipientPrivateKey: The recipient's private key
    /// - Returns: The decrypted plaintext message
    /// - Throws: NIP04EncryptionError if decryption fails
    func decryptNIP04(
        encryptedMessage: String,
        senderPublicKey: PublicKey,
        recipientPrivateKey: PrivateKey
    ) throws -> String
}

/// Default implementation of NIP-04 encryption
extension NIP04Encryption {

    public func encryptNIP04(
        message: String,
        recipientPublicKey: PublicKey,
        senderPrivateKey: PrivateKey
    ) throws -> String {

        // Compute shared secret using ECDH
        let sharedSecret = try computeSharedSecret(
            privateKey: senderPrivateKey,
            publicKey: recipientPublicKey
        )

        // Generate random IV (16 bytes)
        let iv = Data.randomBytes(count: 16)

        // Convert message to data
        guard let messageData = message.data(using: .utf8) else {
            throw NIP04EncryptionError.encryptionFailed
        }

        // Encrypt using AES-256-CBC
        let encryptedData = try encryptAES256CBC(
            data: messageData,
            key: sharedSecret,
            iv: iv
        )

        // Format according to NIP-04: base64(encrypted_message)?iv=base64(iv)
        let encryptedBase64 = encryptedData.base64EncodedString()
        let ivBase64 = iv.base64EncodedString()

        return "\(encryptedBase64)?iv=\(ivBase64)"
    }

    public func decryptNIP04(
        encryptedMessage: String,
        senderPublicKey: PublicKey,
        recipientPrivateKey: PrivateKey
    ) throws -> String {

        // Parse NIP-04 format: base64(encrypted_message)?iv=base64(iv)
        let sections = encryptedMessage.split(separator: "?")
        guard sections.count == 2 else {
            throw NIP04EncryptionError.invalidFormat
        }

        // Extract encrypted content
        guard let encryptedBase64 = sections.first,
            let encryptedData = Data(base64Encoded: String(encryptedBase64))
        else {
            throw NIP04EncryptionError.invalidBase64
        }

        // Extract IV
        guard let ivSection = sections.last,
            ivSection.hasPrefix("iv=")
        else {
            throw NIP04EncryptionError.invalidFormat
        }

        let ivBase64 = String(ivSection.dropFirst(3))  // Remove "iv=" prefix
        guard let iv = Data(base64Encoded: ivBase64) else {
            throw NIP04EncryptionError.invalidBase64
        }

        print("🔍 NIP04: Encrypted data length: \(encryptedData.count) bytes")
        print("🔍 NIP04: IV length: \(iv.count) bytes")
        print("🔍 NIP04: IV hex: \(iv.map { String(format: "%02x", $0) }.joined())")

        // Compute shared secret using ECDH
        let sharedSecret = try computeSharedSecret(
            privateKey: recipientPrivateKey,
            publicKey: senderPublicKey
        )

        print("🔍 NIP04: Shared secret length: \(sharedSecret.count) bytes")
        print(
            "🔍 NIP04: Shared secret hex: \(sharedSecret.map { String(format: "%02x", $0) }.joined())"
        )

        // Decrypt using AES-256-CBC
        let decryptedData = try decryptAES256CBC(
            data: encryptedData,
            key: sharedSecret,
            iv: iv
        )

        // Convert back to string
        guard let decryptedMessage = String(data: decryptedData, encoding: .utf8) else {
            print("❌ NIP04: Failed to convert decrypted data to string")
            print("❌ NIP04: Decrypted data length: \(decryptedData.count) bytes")
            print(
                "❌ NIP04: Decrypted data hex: \(decryptedData.map { String(format: "%02x", $0) }.joined())"
            )
            print(
                "❌ NIP04: Decrypted data as string (force): \(String(data: decryptedData, encoding: .utf8) ?? "nil")"
            )

            // Try other encodings
            if let latin1 = String(data: decryptedData, encoding: .isoLatin1) {
                print("❌ NIP04: Decrypted data as Latin1: \(latin1)")
            }
            if let ascii = String(data: decryptedData, encoding: .ascii) {
                print("❌ NIP04: Decrypted data as ASCII: \(ascii)")
            }

            // Check if it might be compressed data (gzip/deflate)
            if decryptedData.count > 0 {
                let firstByte = decryptedData[0]
                print("❌ NIP04: First byte: 0x\(String(format: "%02x", firstByte))")
                if firstByte == 0x1f {  // gzip magic number
                    print("❌ NIP04: Data might be gzip compressed")
                } else if firstByte == 0x78 {  // deflate magic number
                    print("❌ NIP04: Data might be deflate compressed")
                }
            }

            // Try to see if it's JSON with some corruption
            if let partialString = String(data: decryptedData.prefix(50), encoding: .utf8) {
                print("❌ NIP04: First 50 bytes as UTF-8: \(partialString)")
            }

            throw NIP04EncryptionError.decryptionFailed
        }

        return decryptedMessage
    }

    // MARK: - Private Methods

    private func computeSharedSecret(
        privateKey: PrivateKey,
        publicKey: PublicKey
    ) throws -> Data {

        // Convert private key to bytes
        let privateKeyBytes = privateKey.dataRepresentation.bytes

        // Convert public key to compressed format (add 0x02 prefix)
        let publicKeyBytes = preparePublicKeyBytes(from: publicKey)

        // Parse public key
        var secp256k1PublicKey = secp256k1_pubkey()
        guard
            secp256k1_ec_pubkey_parse(
                secp256k1.Context.rawRepresentation,
                &secp256k1PublicKey,
                publicKeyBytes,
                publicKeyBytes.count
            ) != 0
        else {
            throw NIP04EncryptionError.invalidPublicKey
        }

        // Compute ECDH shared secret
        var sharedSecret = [UInt8](repeating: 0, count: 32)
        guard
            secp256k1_ecdh(
                secp256k1.Context.rawRepresentation,
                &sharedSecret,
                &secp256k1PublicKey,
                privateKeyBytes,
                { (output, x32, _, _) in
                    memcpy(output, x32, 32)
                    return 1
                },
                nil
            ) != 0
        else {
            throw NIP04EncryptionError.invalidSharedSecret
        }

        return Data(sharedSecret)
    }

    private func preparePublicKeyBytes(from pubkey: PublicKey) -> [UInt8] {
        var bytes = pubkey.dataRepresentation.bytes
        bytes.insert(0x02, at: 0)  // Add compressed prefix
        return bytes
    }

    private func encryptAES256CBC(
        data: Data,
        key: Data,
        iv: Data
    ) throws -> Data {

        // Use the first 32 bytes of the shared secret as the AES key
        let aesKey = key.prefix(32)

        // Create AES context
        let keyBytes = Array(aesKey)
        let ivBytes = Array(iv)
        let dataBytes = Array(data)

        // Perform AES-256-CBC encryption
        let encryptedBytes = try AES.encrypt(
            data: dataBytes,
            key: keyBytes,
            iv: ivBytes
        )

        return Data(encryptedBytes)
    }

    private func decryptAES256CBC(
        data: Data,
        key: Data,
        iv: Data
    ) throws -> Data {

        // Use the first 32 bytes of the shared secret as the AES key
        let aesKey = key.prefix(32)

        // Create AES context
        let keyBytes = Array(aesKey)
        let ivBytes = Array(iv)
        let dataBytes = Array(data)

        // Perform AES-256-CBC decryption
        let decryptedBytes = try AES.decrypt(
            data: dataBytes,
            key: keyBytes,
            iv: ivBytes
        )

        return Data(decryptedBytes)
    }
}

/// AES-256-CBC implementation using CommonCrypto
private struct AES {

    static func encrypt(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
        let dataLength = data.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesEncrypted: size_t = 0

        // Validate key length for AES-256
        guard key.count == kCCKeySizeAES256 else {
            throw NIP04EncryptionError.encryptionFailed
        }

        let status = CCCrypt(
            CCOperation(kCCEncrypt),
            CCAlgorithm(kCCAlgorithmAES128),  // CommonCrypto uses AES128 for both AES-128 and AES-256
            CCOptions(kCCOptionPKCS7Padding),
            key,
            key.count,
            iv,
            data,
            dataLength,
            &buffer,
            bufferSize,
            &numBytesEncrypted
        )

        guard status == kCCSuccess else {
            throw NIP04EncryptionError.encryptionFailed
        }

        return Array(buffer.prefix(numBytesEncrypted))
    }

    static func decrypt(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
        let dataLength = data.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted: size_t = 0

        // Validate key length for AES-256
        guard key.count == kCCKeySizeAES256 else {
            throw NIP04EncryptionError.decryptionFailed
        }

        let status = CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES128),  // CommonCrypto uses AES128 for both AES-128 and AES-256
            CCOptions(kCCOptionPKCS7Padding),
            key,
            key.count,
            iv,
            data,
            dataLength,
            &buffer,
            bufferSize,
            &numBytesDecrypted
        )

        guard status == kCCSuccess else {
            print("❌ NIP04: AES decryption failed with status: \(status)")
            print(
                "❌ NIP04: Data length: \(dataLength), Key length: \(key.count), IV length: \(iv.count)"
            )
            throw NIP04EncryptionError.decryptionFailed
        }

        return Array(buffer.prefix(numBytesDecrypted))
    }
}
