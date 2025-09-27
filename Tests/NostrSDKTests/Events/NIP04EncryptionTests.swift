//
//  NIP04EncryptionTests.swift
//  NostrSDKTests
//
//  Created by Suhail Saqan on 3/8/25.
//

import XCTest

@testable import NostrSDK

final class NIP04EncryptionTests: XCTestCase, NIP04Encryption {

    func testNIP04EncryptionDecryption() throws {
        let message = "Hello, this is a test message!"
        let senderKeypair = Keypair.test
        // Create a second test keypair for recipient
        let recipientKeypair = Keypair(
            nsec: "nsec1xy2yqen2aqg6ufzrwgckq2vv0yxjj68c3n0rta2nun7vq0fe9j8snc4r8")!

        // Encrypt message
        let encryptedMessage = try encryptNIP04(
            message: message,
            recipientPublicKey: recipientKeypair.publicKey,
            senderPrivateKey: senderKeypair.privateKey
        )

        // Verify format: base64(encrypted_message)?iv=base64(iv)
        XCTAssertTrue(encryptedMessage.contains("?iv="))
        let sections = encryptedMessage.split(separator: "?")
        XCTAssertEqual(sections.count, 2)
        XCTAssertTrue(sections.last?.hasPrefix("iv=") == true)

        // Decrypt message
        let decryptedMessage = try decryptNIP04(
            encryptedMessage: encryptedMessage,
            senderPublicKey: senderKeypair.publicKey,
            recipientPrivateKey: recipientKeypair.privateKey
        )

        XCTAssertEqual(decryptedMessage, message)
    }

    func testNIP04EncryptionWithEmptyMessage() throws {
        let message = ""
        let senderKeypair = Keypair.test
        let recipientKeypair = Keypair(
            nsec: "nsec1xy2yqen2aqg6ufzrwgckq2vv0yxjj68c3n0rta2nun7vq0fe9j8snc4r8")!

        // Encrypt message
        let encryptedMessage = try encryptNIP04(
            message: message,
            recipientPublicKey: recipientKeypair.publicKey,
            senderPrivateKey: senderKeypair.privateKey
        )

        // Decrypt message
        let decryptedMessage = try decryptNIP04(
            encryptedMessage: encryptedMessage,
            senderPublicKey: senderKeypair.publicKey,
            recipientPrivateKey: recipientKeypair.privateKey
        )

        XCTAssertEqual(decryptedMessage, message)
    }

    func testNIP04EncryptionWithLongMessage() throws {
        let message = String(
            repeating: "This is a very long message that should test the encryption properly. ",
            count: 100)
        let senderKeypair = Keypair.test
        let recipientKeypair = Keypair(
            nsec: "nsec1xy2yqen2aqg6ufzrwgckq2vv0yxjj68c3n0rta2nun7vq0fe9j8snc4r8")!

        // Encrypt message
        let encryptedMessage = try encryptNIP04(
            message: message,
            recipientPublicKey: recipientKeypair.publicKey,
            senderPrivateKey: senderKeypair.privateKey
        )

        // Decrypt message
        let decryptedMessage = try decryptNIP04(
            encryptedMessage: encryptedMessage,
            senderPublicKey: senderKeypair.publicKey,
            recipientPrivateKey: recipientKeypair.privateKey
        )

        XCTAssertEqual(decryptedMessage, message)
    }

    func testNIP04EncryptionWithSpecialCharacters() throws {
        let message =
            "Hello! 🚀 This message contains special characters: @#$%^&*()_+{}|:<>?[]\\;'\",./ and emojis 🎉"
        let senderKeypair = Keypair.test
        let recipientKeypair = Keypair(
            nsec: "nsec1xy2yqen2aqg6ufzrwgckq2vv0yxjj68c3n0rta2nun7vq0fe9j8snc4r8")!

        // Encrypt message
        let encryptedMessage = try encryptNIP04(
            message: message,
            recipientPublicKey: recipientKeypair.publicKey,
            senderPrivateKey: senderKeypair.privateKey
        )

        // Decrypt message
        let decryptedMessage = try decryptNIP04(
            encryptedMessage: encryptedMessage,
            senderPublicKey: senderKeypair.publicKey,
            recipientPrivateKey: recipientKeypair.privateKey
        )

        XCTAssertEqual(decryptedMessage, message)
    }

    func testNIP04DecryptionWithInvalidFormat() throws {
        let senderKeypair = Keypair.test
        let recipientKeypair = Keypair(
            nsec: "nsec1xy2yqen2aqg6ufzrwgckq2vv0yxjj68c3n0rta2nun7vq0fe9j8snc4r8")!

        // Test invalid format - missing iv parameter
        XCTAssertThrowsError(
            try decryptNIP04(
                encryptedMessage: "invalidbase64",
                senderPublicKey: senderKeypair.publicKey,
                recipientPrivateKey: recipientKeypair.privateKey
            )
        ) { error in
            XCTAssertTrue(error is NIP04EncryptionError)
        }

        // Test invalid format - missing ? separator
        XCTAssertThrowsError(
            try decryptNIP04(
                encryptedMessage: "invalidbase64iv=invalidiv",
                senderPublicKey: senderKeypair.publicKey,
                recipientPrivateKey: recipientKeypair.privateKey
            )
        ) { error in
            XCTAssertTrue(error is NIP04EncryptionError)
        }
    }

    func testNIP04FormatCompatibility() throws {
        // Test that our implementation produces the correct NIP-04 format
        let message = "Secret message."
        let senderKeypair = Keypair.test
        let recipientKeypair = Keypair(
            nsec: "nsec1xy2yqen2aqg6ufzrwgckq2vv0yxjj68c3n0rta2nun7vq0fe9j8snc4r8")!

        // Use our new implementation
        let encryptedMessage = try encryptNIP04(
            message: message,
            recipientPublicKey: recipientKeypair.publicKey,
            senderPrivateKey: senderKeypair.privateKey
        )

        // Verify NIP-04 format: base64(encrypted_message)?iv=base64(iv)
        XCTAssertTrue(encryptedMessage.contains("?iv="))
        let sections = encryptedMessage.split(separator: "?")
        XCTAssertEqual(sections.count, 2)
        XCTAssertTrue(sections.last?.hasPrefix("iv=") == true)

        // Should be decryptable
        let decryptedMessage = try decryptNIP04(
            encryptedMessage: encryptedMessage,
            senderPublicKey: senderKeypair.publicKey,
            recipientPrivateKey: recipientKeypair.privateKey
        )

        XCTAssertEqual(decryptedMessage, message)
    }
}
