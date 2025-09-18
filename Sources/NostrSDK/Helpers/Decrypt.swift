//
//  Decrypt.swift
//  NostrSDK
//
//  Created by Suhail Saqan on 03/08/25.
//

import secp256k1
import Foundation
import CryptoKit
import CommonCrypto

public func decryptContent(
    _ privkey: PrivateKey?, pubkey: PublicKey, content: String, encoding: EncEncoding
)
    -> String?
{
    guard let privkey = privkey else {
        return nil
    }
    guard let shared_sec = get_shared_secret(privkey: privkey, pubkey: pubkey) else {
        return nil
    }
    guard let dat = (encoding == .base64 ? decode_base64(content) : decode_bech32(content)) else {
        return nil
    }
    guard let dat = aes_decrypt(data: dat.content, iv: dat.iv, shared_sec: shared_sec) else {
        return nil
    }
    return String(data: dat, encoding: .utf8)
}

//func decrypt_note(
//    our_privkey: PrivateKey, their_pubkey: PublicKey, enc_note: String, encoding: EncEncoding
//) -> NostrEvent? {
//    guard
//        let dec = decryptContent(our_privkey, pubkey: their_pubkey, content: enc_note, encoding: encoding)
//    else {
//        return nil
//    }
//
//    return decode_nostr_event_json(json: dec)
//}

func get_shared_secret(privkey: PrivateKey, pubkey: PublicKey) -> [UInt8]? {
    let privkey_bytes = privkey.dataRepresentation.bytes
    var pk_bytes = pubkey.dataRepresentation.bytes

    pk_bytes.insert(2, at: 0)

    var publicKey = secp256k1_pubkey()
    var shared_secret = [UInt8](repeating: 0, count: 32)

    var ok =
        secp256k1_ec_pubkey_parse(
            secp256k1.Context.rawRepresentation,
            &publicKey,
            pk_bytes,
            pk_bytes.count) != 0

    if !ok {
        return nil
    }

    ok =
        secp256k1_ecdh(
            secp256k1.Context.rawRepresentation,
            &shared_secret,
            &publicKey,
            privkey_bytes,
            { (output, x32, _, _) in
                memcpy(output, x32, 32)
                return 1
            }, nil) != 0

    if !ok {
        return nil
    }

    return shared_secret
}

public enum EncEncoding {
    case base64
    case bech32
}

struct EncryptedContent {
    let content: [UInt8]
    let iv: [UInt8]
}

//func encode_bech32(content: [UInt8], iv: [UInt8]) -> String {
//    let content_bech32 = bech32_encode(hrp: "data", content)
//    let iv_bech32 = bech32_encode(hrp: "iv", iv)
//    return content_bech32 + "_" + iv_bech32
//}

func decode_bech32(_ all: String) -> EncryptedContent? {
    let parts = all.split(separator: "_")
    guard parts.count == 2 else {
        return nil
    }

    let content_bech32 = String(parts[0])
    let iv_bech32 = String(parts[1])

    guard let content_tup = try? Bech32.decode(content_bech32) else {
        return nil
    }
    guard let iv_tup = try? Bech32.decode(iv_bech32) else {
        return nil
    }
    guard content_tup.hrp == "data" else {
        return nil
    }
    guard iv_tup.hrp == "iv" else {
        return nil
    }

    return EncryptedContent(content: content_tup.checksum.bytes, iv: iv_tup.checksum.bytes)
}

func encode_base64(content: [UInt8], iv: [UInt8]) -> String {
    let content_b64 = base64_encode(content)
    let iv_b64 = base64_encode(iv)
    return content_b64 + "?iv=" + iv_b64
}

func decode_base64(_ all: String) -> EncryptedContent? {
    let splits = Array(all.split(separator: "?"))

    if splits.count != 2 {
        return nil
    }

    guard let content = base64_decode(String(splits[0])) else {
        return nil
    }

    var sec = String(splits[1])
    if !sec.hasPrefix("iv=") {
        return nil
    }

    sec = String(sec.dropFirst(3))
    guard let iv = base64_decode(sec) else {
        return nil
    }

    return EncryptedContent(content: content, iv: iv)
}

func base64_encode(_ content: [UInt8]) -> String {
    return Data(content).base64EncodedString()
}

func base64_decode(_ content: String) -> [UInt8]? {
    guard let dat = Data(base64Encoded: content) else {
        return nil
    }
    return dat.bytes
}

func aes_decrypt(data: [UInt8], iv: [UInt8], shared_sec: [UInt8]) -> Data? {
    return aes_operation(
        operation: CCOperation(kCCDecrypt), data: data, iv: iv, shared_sec: shared_sec)
}

func aes_encrypt(data: [UInt8], iv: [UInt8], shared_sec: [UInt8]) -> Data? {
    return aes_operation(
        operation: CCOperation(kCCEncrypt), data: data, iv: iv, shared_sec: shared_sec)
}

func aes_operation(operation: CCOperation, data: [UInt8], iv: [UInt8], shared_sec: [UInt8]) -> Data?
{
    let data_len = data.count
    let bsize = kCCBlockSizeAES128
    let len = Int(data_len) + bsize
    var decrypted_data = [UInt8](repeating: 0, count: len)

    let key_length = size_t(kCCKeySizeAES256)
    if shared_sec.count != key_length {
        assert(false, "unexpected shared_sec len: \(shared_sec.count) != 32")
        return nil
    }

    let algorithm: CCAlgorithm = UInt32(kCCAlgorithmAES128)
    let options: CCOptions = UInt32(kCCOptionPKCS7Padding)

    var num_bytes_decrypted: size_t = 0

    let status = CCCrypt(
        operation, /*op:*/
        algorithm, /*alg:*/
        options, /*options:*/
        shared_sec, /*key:*/
        key_length, /*keyLength:*/
        iv, /*iv:*/
        data, /*dataIn:*/
        data_len, /*dataInLength:*/
        &decrypted_data, /*dataOut:*/
        len, /*dataOutAvailable:*/
        &num_bytes_decrypted /*dataOutMoved:*/
    )

    if UInt32(status) != UInt32(kCCSuccess) {
        return nil
    }

    return Data(bytes: decrypted_data, count: num_bytes_decrypted)
}
