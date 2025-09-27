//
//  Data+Additions.swift
//
//
//  Created by Bryan Montz on 6/20/23.
//

import CommonCrypto
import Foundation

extension Data {

    /// The SHA256 hash of the data.
    var sha256: Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(count), &hash)
        }
        return Data(hash)
    }

    /// Random data of a given size.
    static func randomBytes(count: Int) -> Data {
        var bytes = [Int8](repeating: 0, count: count)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            fatalError("can't copy secure random data")
        }
        return Data(bytes: bytes, count: count)
    }

    /// The bytes array representation of the data.
    var bytes: [UInt8] {
        return Array(self)
    }

    // MARK: - AES-256-CBC Encryption/Decryption

    /// AES-256-CBC Encryption
    func aes256Encrypt(withKey key: Data, iv: Data) throws -> Data {
        return try crypt(operation: CCOperation(kCCEncrypt), key: key, iv: iv)
    }

    /// AES-256-CBC Decryption
    func aes256Decrypt(withKey key: Data, iv: Data) throws -> Data {
        return try crypt(operation: CCOperation(kCCDecrypt), key: key, iv: iv)
    }

    private func crypt(operation: CCOperation, key: Data, iv: Data) throws -> Data {
        guard key.count == kCCKeySizeAES256 else {
            throw NSError(domain: "Invalid key size", code: -1, userInfo: nil)
        }
        guard iv.count == kCCBlockSizeAES128 else {
            throw NSError(domain: "Invalid IV size", code: -1, userInfo: nil)
        }

        var outLength = Int(0)
        let options = CCOptions(kCCOptionPKCS7Padding)
        let bufferSize = self.count + kCCBlockSizeAES128
        var outData = Data(count: bufferSize)

        let status = outData.withUnsafeMutableBytes { outBytes in
            self.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            operation,
                            CCAlgorithm(kCCAlgorithmAES),
                            options,
                            keyBytes.baseAddress, key.count,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, self.count,
                            outBytes.baseAddress, bufferSize,
                            &outLength)
                    }
                }
            }
        }

        guard status == kCCSuccess else {
            throw NSError(domain: "Encryption/Decryption failed", code: Int(status), userInfo: nil)
        }

        outData.removeSubrange(outLength..<outData.count)
        return outData
    }

    // MARK: - Hex String Conversion

    /// Initialize Data from Hexadecimal String
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var index = hexString.startIndex
        for _ in 0..<len {
            let nextIndex = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }
}
