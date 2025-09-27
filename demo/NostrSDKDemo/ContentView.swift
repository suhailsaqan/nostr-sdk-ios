//
//  ContentView.swift
//  NostrSDKDemo
//
//  Created by Joel Klabo on 6/10/23.
//

import NostrSDK
import SwiftUI

struct ContentView: View {

    @State private var relay: Relay?

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ListOptionView(
                        destinationView: AnyView(RelaysView()),
                        imageName: "network",
                        labelText: "Configure Relays")
                    ListOptionView(
                        destinationView: AnyView(QueryRelayDemoView()),
                        imageName: "list.bullet.rectangle.portrait",
                        labelText: "Query Relays")
                    ListOptionView(
                        destinationView:
                            AnyView(LegacyDirectMessageDemoView()),
                        imageName: "list.bullet",
                        labelText: "NIP-04 Direct Message")
                    ListOptionView(
                        destinationView: AnyView(GenerateKeyDemoView()),
                        imageName: "key",
                        labelText: "Key Generation")
                    ListOptionView(
                        destinationView: AnyView(NIP05VerficationDemoView()),
                        imageName: "checkmark.seal",
                        labelText: "NIP-05")
                    ListOptionView(
                        destinationView: AnyView(HTTPAuthDemoView()),
                        imageName: "lock.shield",
                        labelText: "NIP-98 HTTP Auth")
                }
            }
            .navigationTitle("Nostr SDK Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
