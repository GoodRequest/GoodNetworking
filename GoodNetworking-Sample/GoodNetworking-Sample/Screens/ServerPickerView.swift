//
//  ServerPickerView.swift
//  GoodNetworking-Sample
//
//  Created by Andrej Jasso on 16/10/2024.
//

import SwiftUI
import GoodNetworking

struct ServerPickerView: View {

    // MARK: - State Object

    @StateObject private var provider: SampleSelectableBaseUrlProvider = NetworkSession.baseURLProvider!

    // MARK: - State
    
    @State private var selectedServer: ApiServer = .init(name: "Empty", url: "")
    @State private var availableServers: [ApiServer] = []
    
    var body: some View {
        ScrollView {
            Picker("Server", selection: $selectedServer) {
                ForEach(availableServers, id: \.self) { server in
                    VStack {
                        Text(server.name)
                        Text(server.url)
                    }
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .task {
            self.selectedServer = await provider.getSelectedServer()
            self.availableServers = await provider.serverCollection.servers
        }
        .onChange(of: selectedServer) {
            Task {
                await provider.setSelectedServer(selectedServer)
            }
        }
    }
    
}

