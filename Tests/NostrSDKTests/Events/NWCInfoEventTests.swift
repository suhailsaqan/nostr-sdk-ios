//
//  NWCInfoEventTests.swift
//  NostrSDKTests
//
//  Created by Suhail Saqan on 3/8/25.
//

import XCTest

@testable import NostrSDK

final class NWCInfoEventTests: XCTestCase, EventCreating, EventVerifying, FixtureLoading {

    func testCreateNWCInfoEvent() throws {
        let name = "Test Wallet"
        let description = "A test wallet service"
        let icon = "https://example.com/icon.png"
        let version = "1.0"
        let supportedMethods = ["get_info", "pay_invoice", "get_balance"]

        let nwcInfo = try NWCInfoEvent(
            name: name,
            description: description,
            icon: icon,
            version: version,
            supportedMethods: supportedMethods,
            signedBy: Keypair()!
        )

        // Verify basic properties
        XCTAssertEqual(nwcInfo.kind, .nwcInfo)
        XCTAssertEqual(nwcInfo.pubkey, Keypair()!.publicKey.hex)

        // Verify wallet info
        let walletInfo = try XCTUnwrap(nwcInfo.walletInfo)
        XCTAssertEqual(walletInfo.name, name)
        XCTAssertEqual(walletInfo.description, description)
        XCTAssertEqual(walletInfo.icon, icon)
        XCTAssertEqual(walletInfo.version, version)
        XCTAssertEqual(walletInfo.supportedMethods, supportedMethods)

        // Verify signature
        XCTAssertNotNil(nwcInfo.signature)
        try verifySignature(
            nwcInfo.signature!, for: nwcInfo.calculatedId,
            withPublicKey: Keypair()!.publicKey.hex)
    }

    func testCreateNWCInfoEventMinimal() throws {
        let name = "Minimal Wallet"
        let description = "A minimal wallet service"
        let supportedMethods = ["get_info"]

        let nwcInfo = try NWCInfoEvent(
            name: name,
            description: description,
            supportedMethods: supportedMethods,
            signedBy: Keypair()!
        )

        // Verify basic properties
        XCTAssertEqual(nwcInfo.kind, .nwcInfo)

        // Verify wallet info
        let walletInfo = try XCTUnwrap(nwcInfo.walletInfo)
        XCTAssertEqual(walletInfo.name, name)
        XCTAssertEqual(walletInfo.description, description)
        XCTAssertNil(walletInfo.icon)
        XCTAssertEqual(walletInfo.version, "1.0")  // Default version
        XCTAssertEqual(walletInfo.supportedMethods, supportedMethods)
    }

    func testNWCInfoEventDecoding() throws {
        let name = "Test Wallet"
        let description = "A test wallet service"
        let supportedMethods = ["get_info", "pay_invoice"]

        let originalNWCInfo = try NWCInfoEvent(
            name: name,
            description: description,
            supportedMethods: supportedMethods,
            signedBy: Keypair()!
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(originalNWCInfo)

        // Decode from JSON
        let decoder = JSONDecoder()
        let decodedNWCInfo = try decoder.decode(NWCInfoEvent.self, from: jsonData)

        // Verify properties match
        XCTAssertEqual(decodedNWCInfo.id, originalNWCInfo.id)
        XCTAssertEqual(decodedNWCInfo.pubkey, originalNWCInfo.pubkey)
        XCTAssertEqual(decodedNWCInfo.createdAt, originalNWCInfo.createdAt)
        XCTAssertEqual(decodedNWCInfo.kind, originalNWCInfo.kind)
        XCTAssertEqual(decodedNWCInfo.content, originalNWCInfo.content)
        XCTAssertEqual(decodedNWCInfo.signature, originalNWCInfo.signature)

        // Verify wallet info
        XCTAssertEqual(decodedNWCInfo.walletInfo?.name, originalNWCInfo.walletInfo?.name)
        XCTAssertEqual(
            decodedNWCInfo.walletInfo?.description, originalNWCInfo.walletInfo?.description)
        XCTAssertEqual(
            decodedNWCInfo.walletInfo?.supportedMethods,
            originalNWCInfo.walletInfo?.supportedMethods)
    }

    func testNWCInfoEventViaEventCreating() throws {
        let name = "Test Wallet"
        let description = "A test wallet service"
        let supportedMethods = ["get_info", "pay_invoice"]

        let nwcInfo = try nwcInfoEvent(
            name: name,
            description: description,
            supportedMethods: supportedMethods,
            signedBy: Keypair()!
        )

        XCTAssertEqual(nwcInfo.kind, .nwcInfo)
        XCTAssertEqual(nwcInfo.walletInfo?.name, name)
        XCTAssertEqual(nwcInfo.walletInfo?.description, description)
        XCTAssertEqual(nwcInfo.walletInfo?.supportedMethods, supportedMethods)
    }
}
