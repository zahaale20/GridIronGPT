//
//  GridIronGPTApp.swift
//  GridIronGPT
//
//  Created by Alex Zaharia on 8/24/23.
//

import SwiftUI

@main
struct GridIronGPTApp: App {
    init() {}
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(OpenAIConnector())
        }
    }
}
