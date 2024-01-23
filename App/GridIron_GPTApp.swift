//
//  GridIron_GPTApp.swift
//  GridIron GPT
//
//  Created by Alex Zaharia on 12/26/23.
//

import SwiftUI
import Firebase

@main
struct GridIron_GPTApp: App {
    @StateObject var viewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(OpenAIConnector())
        }
    }
}
