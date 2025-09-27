//
//  HTTPAuthDemoView.swift
//
//
//  Created by Suhail Saqan on 03/08/25.
//

import NostrSDK
import SwiftUI

struct HTTPAuthDemoView: View {
    @State private var urlString = "https://api.example.com/resource"
    @State private var method = "GET"
    @State private var generatedToken = ""
    @State private var validationResult = ""
    @State private var isGenerating = false
    @State private var isValidating = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let keypair = Keypair.test

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("NIP-98 HTTP Authentication Demo")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)

                    Text(
                        "This demo shows how to generate and validate HTTP authentication tokens using NIP-98."
                    )
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)

                    // URL Input Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL")
                            .font(.headline)
                        TextField("Enter URL", text: $urlString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    // Method Input Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HTTP Method")
                            .font(.headline)
                        Picker("Method", selection: $method) {
                            Text("GET").tag("GET")
                            Text("POST").tag("POST")
                            Text("PUT").tag("PUT")
                            Text("DELETE").tag("DELETE")
                            Text("PATCH").tag("PATCH")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    // Generate Token Button
                    Button(action: generateToken) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isGenerating ? "Generating..." : "Generate Token")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isGenerating || urlString.isEmpty)

                    // Generated Token Section
                    if !generatedToken.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Generated Token")
                                .font(.headline)
                            Text(generatedToken)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                        }

                        // Validate Token Button
                        Button(action: validateToken) {
                            HStack {
                                if isValidating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text(isValidating ? "Validating..." : "Validate Token")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isValidating || generatedToken.isEmpty)
                    }

                    // Validation Result Section
                    if !validationResult.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Validation Result")
                                .font(.headline)
                            Text(validationResult)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    // Example Usage Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example Usage")
                            .font(.headline)
                        Text(
                            """
                            // Generate token
                            let token = try HTTPAuthTokenGenerator.generateToken(
                                url: URL(string: "https://api.example.com/resource")!,
                                method: "GET",
                                signedBy: keypair,
                                includeAuthorizationScheme: true
                            )

                            // Use in HTTP request
                            var request = URLRequest(url: url)
                            request.setValue(token, forHTTPHeaderField: "Authorization")
                            """
                        )
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("HTTP Auth (NIP-98)")
            .alert("Error", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func generateToken() {
        guard let url = URL(string: urlString) else {
            alertMessage = "Invalid URL format"
            showAlert = true
            return
        }

        isGenerating = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let token = try HTTPAuthTokenGenerator.generateToken(
                    url: url,
                    method: method,
                    signedBy: keypair,
                    includeAuthorizationScheme: true
                )

                DispatchQueue.main.async {
                    self.generatedToken = token
                    self.isGenerating = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMessage = "Failed to generate token: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isGenerating = false
                }
            }
        }
    }

    private func validateToken() {
        guard let url = URL(string: urlString) else {
            alertMessage = "Invalid URL format"
            showAlert = true
            return
        }

        isValidating = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try HTTPAuthTokenValidator.validateToken(
                    generatedToken,
                    url: url,
                    method: method
                )

                DispatchQueue.main.async {
                    self.validationResult = """
                        ✅ Token is valid!

                        Public Key: \(result.publicKey)
                        URL: \(result.url.absoluteString)
                        Method: \(result.method)
                        Created At: \(Date(timeIntervalSince1970: TimeInterval(result.createdAt)))
                        """
                    self.isValidating = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.validationResult =
                        "❌ Token validation failed: \(error.localizedDescription)"
                    self.isValidating = false
                }
            }
        }
    }
}

#Preview {
    HTTPAuthDemoView()
}

