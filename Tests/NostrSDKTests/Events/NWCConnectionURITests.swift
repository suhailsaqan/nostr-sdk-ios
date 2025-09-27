//
//  NWCConnectionURITests.swift
//  NostrSDKTests
//
//  Created by Suhail Saqan on 3/8/25.
//

import XCTest

@testable import NostrSDK

final class NWCConnectionURITests: XCTestCase {

    func testValidNWCConnectionURI() throws {
        let uriString =
            "nostr+walletconnect://d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62?relay=wss://relay.example.com&secret=abcdef1234567890"

        let uri = try NWCConnectionURI(uriString: uriString)

        XCTAssertEqual(
            uri.walletPubkey, "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62")
        XCTAssertEqual(uri.relayURL, "wss://relay.example.com")
        XCTAssertEqual(uri.secret, "abcdef1234567890")
        XCTAssertEqual(uri.uriString, uriString)
    }

    func testInvalidScheme() {
        let uriString =
            "https://d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62?relay=wss://relay.example.com&secret=abcdef1234567890"

        XCTAssertThrowsError(try NWCConnectionURI(uriString: uriString)) { error in
            XCTAssertTrue(error is NWCConnectionURIError)
            if let nwcError = error as? NWCConnectionURIError {
                XCTAssertEqual(nwcError, .invalidScheme)
            }
        }
    }

    func testMissingWalletPubkey() {
        let uriString =
            "nostr+walletconnect://?relay=wss://relay.example.com&secret=abcdef1234567890"

        XCTAssertThrowsError(try NWCConnectionURI(uriString: uriString)) { error in
            XCTAssertTrue(error is NWCConnectionURIError)
            if let nwcError = error as? NWCConnectionURIError {
                XCTAssertEqual(nwcError, .missingWalletPubkey)
            }
        }
    }

    func testInvalidWalletPubkey() {
        let uriString =
            "nostr+walletconnect://invalidpubkey?relay=wss://relay.example.com&secret=abcdef1234567890"

        XCTAssertThrowsError(try NWCConnectionURI(uriString: uriString)) { error in
            XCTAssertTrue(error is NWCConnectionURIError)
            if let nwcError = error as? NWCConnectionURIError {
                XCTAssertEqual(nwcError, .invalidWalletPubkey)
            }
        }
    }

    func testMissingRelayURL() {
        let uriString =
            "nostr+walletconnect://d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62?secret=abcdef1234567890"

        XCTAssertThrowsError(try NWCConnectionURI(uriString: uriString)) { error in
            XCTAssertTrue(error is NWCConnectionURIError)
            if let nwcError = error as? NWCConnectionURIError {
                XCTAssertEqual(nwcError, .missingRelayURL)
            }
        }
    }

    func testMissingSecret() {
        let uriString =
            "nostr+walletconnect://d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62?relay=wss://relay.example.com"

        XCTAssertThrowsError(try NWCConnectionURI(uriString: uriString)) { error in
            XCTAssertTrue(error is NWCConnectionURIError)
            if let nwcError = error as? NWCConnectionURIError {
                XCTAssertEqual(nwcError, .missingSecret)
            }
        }
    }

    func testCreateFromComponents() {
        let walletPubkey = "d9fa34214aa9d151c4f4db843e9c2af4f246bab4205137731f91bcfa44d66a62"
        let relayURL = "wss://relay.example.com"
        let secret = "abcdef1234567890"

        let uri = NWCConnectionURI(walletPubkey: walletPubkey, relayURL: relayURL, secret: secret)

        XCTAssertEqual(uri.walletPubkey, walletPubkey)
        XCTAssertEqual(uri.relayURL, relayURL)
        XCTAssertEqual(uri.secret, secret)
        XCTAssertEqual(
            uri.uriString,
            "nostr+walletconnect://\(walletPubkey)?relay=\(relayURL)&secret=\(secret)")
    }
}
