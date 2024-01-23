//
//  LoadingView.swift
//  GridIron GPT
//
//  Created by Alex Zaharia on 1/3/24.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(red: 205/255, green: 205/255, blue: 205/255) // Background color
                .ignoresSafeArea() // Ignore safe area to cover the entire screen

            VStack {
                Image("GridIronGPT_Transparent") // Replace with your logo image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100) // Adjust the size as needed
                Text("Loading...")
                    .font(.title)
            }
        }
    }
}

#Preview {
    LoadingView()
}
