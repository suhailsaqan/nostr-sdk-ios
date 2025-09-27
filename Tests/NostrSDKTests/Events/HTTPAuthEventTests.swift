//
//  HTTPAuthEventTests.swift
//
//
//  Created by Suhail Saqan on 03/08/25.
//

import XCTest

@testable import NostrSDK

final class HTTPAuthEventTests: XCTestCase, EventCreating, EventVerifying, FixtureLoading {

    func testCreateHTTPAuthEvent() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "GET"

        let event = try HTTPAuthEvent.Builder()
            .url(url)
            .method(method)
            .build(signedBy: Keypair.test)

        XCTAssertEqual(event.kind, .httpAuth)
        XCTAssertEqual(event.url, url)
        XCTAssertEqual(event.method, method.uppercased())
        XCTAssertEqual(event.content, "")

        try verifyEvent(event)
    }

    func testCreateHTTPAuthEventWithCustomTimestamp() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "POST"
        let timestamp = Int64(1_682_327_852)

        let event = try HTTPAuthEvent.Builder()
            .url(url)
            .method(method)
            .createdAt(timestamp)
            .build(signedBy: Keypair.test)

        XCTAssertEqual(event.kind, .httpAuth)
        XCTAssertEqual(event.url, url)
        XCTAssertEqual(event.method, method.uppercased())
        XCTAssertEqual(event.createdAt, timestamp)
        XCTAssertEqual(event.content, "")

        try verifyEvent(event)
    }

    func testCreateHTTPAuthEventWithDifferentMethods() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))

        let methods = ["GET", "POST", "PUT", "DELETE", "PATCH"]

        for method in methods {
            let event = try HTTPAuthEvent.Builder()
                .url(url)
                .method(method)
                .build(signedBy: Keypair.test)

            XCTAssertEqual(event.kind, .httpAuth)
            XCTAssertEqual(event.url, url)
            XCTAssertEqual(event.method, method.uppercased())
            XCTAssertEqual(event.content, "")

            try verifyEvent(event)
        }
    }

    func testCreateHTTPAuthEventWithEventCreating() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "GET"

        let event = try createHTTPAuthEvent(url: url, method: method, signedBy: Keypair.test)

        XCTAssertEqual(event.kind, .httpAuth)
        XCTAssertEqual(event.url, url)
        XCTAssertEqual(event.method, method.uppercased())
        XCTAssertEqual(event.content, "")

        try verifyEvent(event)
    }

    func testDecodeHTTPAuthEvent() throws {
        let json = """
            {
                "id": "fe964e758903360f28d8424d092da8494ed207cba823110be3a57dfe4b578734",
                "pubkey": "63fe6318dc58583cfe16810f86dd09e18bfd76aabc24a0081ce2856f330504ed",
                "content": "",
                "kind": 27235,
                "created_at": 1682327852,
                "tags": [
                    ["u", "https://api.example.com/resource"],
                    ["method", "GET"]
                ],
                "sig": "signature"
            }
            """

        let data = json.data(using: .utf8)!
        let event = try JSONDecoder().decode(HTTPAuthEvent.self, from: data)

        XCTAssertEqual(event.kind, .httpAuth)
        XCTAssertEqual(event.url?.absoluteString, "https://api.example.com/resource")
        XCTAssertEqual(event.method, "GET")
        XCTAssertEqual(event.content, "")
        XCTAssertEqual(event.createdAt, 1_682_327_852)
    }

    func testHTTPAuthEventTags() throws {
        let url = try XCTUnwrap(URL(string: "https://api.example.com/resource"))
        let method = "POST"

        let event = try HTTPAuthEvent.Builder()
            .url(url)
            .method(method)
            .build(signedBy: Keypair.test)

        // Check that the event has the required tags
        let uTag = event.tags.first { $0.name == "u" }
        let methodTag = event.tags.first { $0.name == "method" }

        XCTAssertNotNil(uTag)
        XCTAssertEqual(uTag?.value, url.absoluteString)

        XCTAssertNotNil(methodTag)
        XCTAssertEqual(methodTag?.value, method.uppercased())
    }
}

