//
//  HTTPAuthTokenGeneratorTests.swift
//
//
//  Created by Suhail Saqan on 03/08/25.
//

import XCTest

@testable import NostrSDK

final class HTTPAuthTokenGeneratorTests: XCTestCase {

    func testGenerateToken() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "GET"

        let token = try HTTPAuthTokenGenerator.generateToken(
            url: url,
            method: method,
            signedBy: Keypair.test
        )

        // Token should be base64 encoded
        XCTAssertNotNil(Data(base64Encoded: token))

        // Decode and verify the token contains the expected event
        let tokenData = try XCTUnwrap(Data(base64Encoded: token))
        let event = try JSONDecoder().decode(HTTPAuthEvent.self, from: tokenData)

        XCTAssertEqual(event.kind, .httpAuth)
        XCTAssertEqual(event.url, url)
        XCTAssertEqual(event.method, method.uppercased())
        XCTAssertEqual(event.content, "")
    }

    func testGenerateTokenWithAuthorizationScheme() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "POST"

        let token = try HTTPAuthTokenGenerator.generateToken(
            url: url,
            method: method,
            signedBy: Keypair.test,
            includeAuthorizationScheme: true
        )

        // Token should start with "Nostr "
        XCTAssertTrue(token.hasPrefix("Nostr "))

        // Remove the prefix and decode
        let cleanToken = String(token.dropFirst(6))
        let tokenData = try XCTUnwrap(Data(base64Encoded: cleanToken))
        let event = try JSONDecoder().decode(HTTPAuthEvent.self, from: tokenData)

        XCTAssertEqual(event.kind, .httpAuth)
        XCTAssertEqual(event.url, url)
        XCTAssertEqual(event.method, method.uppercased())
    }

    func testGenerateTokenWithCustomTimestamp() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "PUT"
        let timestamp = Int64(1_682_327_852)

        let token = try HTTPAuthTokenGenerator.generateToken(
            url: url,
            method: method,
            signedBy: Keypair.test,
            createdAt: timestamp
        )

        let tokenData = try XCTUnwrap(Data(base64Encoded: token))
        let event = try JSONDecoder().decode(HTTPAuthEvent.self, from: tokenData)

        XCTAssertEqual(event.kind, .httpAuth)
        XCTAssertEqual(event.url, url)
        XCTAssertEqual(event.method, method.uppercased())
        XCTAssertEqual(event.createdAt, timestamp)
    }

    func testGenerateTokenWithDifferentMethods() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let methods = ["GET", "POST", "PUT", "DELETE", "PATCH"]

        for method in methods {
            let token = try HTTPAuthTokenGenerator.generateToken(
                url: url,
                method: method,
                signedBy: Keypair.test
            )

            let tokenData = try XCTUnwrap(Data(base64Encoded: token))
            let event = try JSONDecoder().decode(HTTPAuthEvent.self, from: tokenData)

            XCTAssertEqual(event.kind, .httpAuth)
            XCTAssertEqual(event.url, url)
            XCTAssertEqual(event.method, method.uppercased())
        }
    }

    func testGenerateTokenWithComplexURL() throws {
        let url = try XCTUnwrap(
            URL(string: "https://api.example.com/v1/users/123/posts?limit=10&offset=0"))
        let method = "GET"

        let token = try HTTPAuthTokenGenerator.generateToken(
            url: url,
            method: method,
            signedBy: Keypair.test
        )

        let tokenData = try XCTUnwrap(Data(base64Encoded: token))
        let event = try JSONDecoder().decode(HTTPAuthEvent.self, from: tokenData)

        XCTAssertEqual(event.kind, .httpAuth)
        XCTAssertEqual(event.url, url)
        XCTAssertEqual(event.method, method.uppercased())
    }
}

