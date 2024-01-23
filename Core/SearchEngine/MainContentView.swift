//
//  MainContentView.swift
//  GridIron GPT
//
//  Created by Alex Zaharia on 1/3/24.
//

import SwiftUI

struct MainContentView: View {
    @EnvironmentObject var connector: OpenAIConnector
    @State var textField = ""
    @State var showingHelp = false
    
    var body: some View {
        NavigationView { // Add NavigationView here
            VStack {
                HStack (spacing: 16){
                    Image("GridIronGPT_Transparent3") // Your logo image here
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    VStack (spacing: 0){
                        Text("GridIron GPT")
                            .font(Font.custom("Nexa Rust Sans", size: 28))
                            .foregroundColor(Color(red: 23/255.0, green: 164/255.0, blue: 255/255.0))
                            .frame(alignment: .bottomLeading)
                        Text("Elevate your game.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 23/255.0, green: 164/255.0, blue: 255/255.0))
                            .frame(alignment: .topLeading)
                    }
                }
                .padding()
                
                ScrollViewReader { scrollView in
                    ScrollView {
                        ForEach(connector.messageLog.indices, id: \.self) { index in
                            MessageView(message: connector.messageLog[index])
                                .id(index)
                        }
                    }
                    .onChange(of: connector.messageLog.count) { _ in
                        withAnimation {
                            scrollView.scrollTo(connector.messageLog.count - 1)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    TextField("Ask a question...", text: $textField)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    Button(action: {
                        // user prompt
                        connector.sendToAssistant(userQuestion: textField)
                        
                        //test function to save api fees
                        //connector.test()
                        textField = "" // Clear the text field after sending
                    }) {
                        Text("Ask")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .disabled(textField.isEmpty) // Disable the button when the text field is empty
                }
                .padding()
            }
        }
        .padding()
    }
}

#Preview {
    MainContentView()
}
