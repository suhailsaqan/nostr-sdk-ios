//
//  HTTPAuthTokenValidatorTests.swift
//
//
//  Created by Suhail Saqan on 03/08/25.
//

import XCTest

@testable import NostrSDK

final class HTTPAuthTokenValidatorTests: XCTestCase {

    func testValidateValidToken() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "GET"

        let token = try HTTPAuthTokenGenerator.generateToken(
            url: url,
            method: method,
            signedBy: Keypair.test
        )

        let result = try HTTPAuthTokenValidator.validateToken(token, url: url, method: method)

        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.publicKey, Keypair.test.publicKey.hex)
        XCTAssertEqual(result.url, url)
        XCTAssertEqual(result.method, method.uppercased())
    }

    func testValidateTokenWithAuthorizationScheme() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "POST"

        let token = try HTTPAuthTokenGenerator.generateToken(
            url: url,
            method: method,
            signedBy: Keypair.test,
            includeAuthorizationScheme: true
        )

        let result = try HTTPAuthTokenValidator.validateToken(token, url: url, method: method)

        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.publicKey, Keypair.test.publicKey.hex)
        XCTAssertEqual(result.url, url)
        XCTAssertEqual(result.method, method.uppercased())
    }

    func testValidateTokenWithDifferentMethods() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let methods = ["GET", "POST", "PUT", "DELETE", "PATCH"]

        for method in methods {
            let token = try HTTPAuthTokenGenerator.generateToken(
                url: url,
                method: method,
                signedBy: Keypair.test
            )

            let result = try HTTPAuthTokenValidator.validateToken(token, url: url, method: method)

            XCTAssertTrue(result.isValid)
            XCTAssertEqual(result.publicKey, Keypair.test.publicKey.hex)
            XCTAssertEqual(result.url, url)
            XCTAssertEqual(result.method, method.uppercased())
        }
    }

    func testExtractPublicKey() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "GET"

        let token = try HTTPAuthTokenGenerator.generateToken(
            url: url,
            method: method,
            signedBy: Keypair.test
        )

        let publicKey = try HTTPAuthTokenValidator.extractPublicKey(
            from: token,
            url: url,
            method: method
        )

        XCTAssertEqual(publicKey, Keypair.test.publicKey.hex)
    }

    func testValidateTokenWithCustomMaxAge() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "GET"
        let timestamp = Int64(Date().timeIntervalSince1970) - 30  // 30 seconds ago

        let token = try HTTPAuthTokenGenerator.generateToken(
            url: url,
            method: method,
            signedBy: Keypair.test,
            createdAt: timestamp
        )

        // Should be valid with 60 second max age
        let result = try HTTPAuthTokenValidator.validateToken(
            token, url: url, method: method, maxAge: 60)
        XCTAssertTrue(result.isValid)

        // Should be invalid with 10 second max age
        XCTAssertThrowsError(
            try HTTPAuthTokenValidator.validateToken(token, url: url, method: method, maxAge: 10)
        ) { error in
            XCTAssertTrue(error is HTTPAuthValidationError)
            if let validationError = error as? HTTPAuthValidationError {
                XCTAssertEqual(validationError, .tokenExpired)
            }
        }
    }

    func testValidateTokenWithURLMismatch() throws {
        let url1 = try XCTUnwrap(URL(string: "https://api.example.com/resource1"))
        let url2 = try XCTUnwrap(URL(string: "https://api.example.com/resource2"))
        let method = "GET"

        let token = try HTTPAuthTokenGenerator.generateToken(
            url: url1,
            method: method,
            signedBy: Keypair.test
        )

        XCTAssertThrowsError(
            try HTTPAuthTokenValidator.validateToken(token, url: url2, method: method)
        ) { error in
            XCTAssertTrue(error is HTTPAuthValidationError)
            if let validationError = error as? HTTPAuthValidationError {
                XCTAssertEqual(validationError, .urlMismatch)
            }
        }
    }

    func testValidateTokenWithMethodMismatch() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method1 = "GET"
        let method2 = "POST"

        let token = try HTTPAuthTokenGenerator.generateToken(
            url: url,
            method: method1,
            signedBy: Keypair.test
        )

        XCTAssertThrowsError(
            try HTTPAuthTokenValidator.validateToken(token, url: url, method: method2)
        ) { error in
            XCTAssertTrue(error is HTTPAuthValidationError)
            if let validationError = error as? HTTPAuthValidationError {
                XCTAssertEqual(validationError, .methodMismatch)
            }
        }
    }

    func testValidateInvalidTokenFormat() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "GET"
        let invalidToken = "invalid-base64-token"

        XCTAssertThrowsError(
            try HTTPAuthTokenValidator.validateToken(invalidToken, url: url, method: method)
        ) { error in
            XCTAssertTrue(error is HTTPAuthValidationError)
            if let validationError = error as? HTTPAuthValidationError {
                XCTAssertEqual(validationError, .invalidTokenFormat)
            }
        }
    }

    func testValidateTokenWithInvalidEventFormat() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "GET"
        let invalidEventData = "invalid-event-data"
        let invalidToken = invalidEventData.data(using: .utf8)!.base64EncodedString()

        XCTAssertThrowsError(
            try HTTPAuthTokenValidator.validateToken(invalidToken, url: url, method: method)
        ) { error in
            XCTAssertTrue(error is HTTPAuthValidationError)
            if let validationError = error as? HTTPAuthValidationError {
                XCTAssertEqual(validationError, .invalidEventFormat)
            }
        }
    }

    func testValidateTokenWithWrongEventKind() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "GET"

        // Create a text note event instead of HTTP auth event
        let textNoteEvent = try TextNoteEvent.Builder()
            .content("Hello, world!")
            .build(signedBy: Keypair.test)

        let tokenData = try JSONEncoder().encode(textNoteEvent)
        let token = tokenData.base64EncodedString()

        XCTAssertThrowsError(
            try HTTPAuthTokenValidator.validateToken(token, url: url, method: method)
        ) { error in
            XCTAssertTrue(error is HTTPAuthValidationError)
            if let validationError = error as? HTTPAuthValidationError {
                XCTAssertEqual(validationError, .invalidEventKind)
            }
        }
    }

    func testValidateTokenWithComplexURL() throws {
        let url = try XCTUnwrap(
            URL(string: "https://api.example.com/v1/users/123/posts?limit=10&offset=0"))
        let method = "GET"

        let token = try HTTPAuthTokenGenerator.generateToken(
            url: url,
            method: method,
            signedBy: Keypair.test
        )

        let result = try HTTPAuthTokenValidator.validateToken(token, url: url, method: method)

        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.publicKey, Keypair.test.publicKey.hex)
        XCTAssertEqual(result.url, url)
        XCTAssertEqual(result.method, method.uppercased())
    }
}

