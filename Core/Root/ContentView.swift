//
//  ContentView.swift
//  GridIron GPT
//
//  Created by Alex Zaharia on 12/26/23.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading = true
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        Group {
            if let session = viewModel.userSession {
                MainContentView()
            } else {
                LoginView()
            }
        }
    }
    
    
}

struct ContentView_Previews: PreviewProvider{
    static var previews: some View {
        ContentView()
    }
}
