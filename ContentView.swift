//
//  ContentView.swift
//  GridIronGPT
//
//  Created by Alex Zaharia on 8/24/23.
//

import SwiftUI

struct ContentView: View {
    @State var textField = ""
    @EnvironmentObject var connector: OpenAIConnector
    var body: some View {
        VStack {
            ScrollView {
                ForEach(connector.messageLog) { message in
                    MessageView(message: message)
                }
            }
            
            Divider()
            
            HStack {
                TextField("Type here", text: $textField)
                Button("Send") {
                    connector.logMessage(textField, messageUserType: .user)
                    connector.sendToAssistant(userQuestion: textField)
                    print("messageLog")
                }
            }
            
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct MessageView: View {
    var message: [String: String]
    
    var messageColor: Color {
        if message["role"] == "user" {
            return .gray
        } else if message["role"] == "assistant" {
            return .green
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack {
            if message["role"] == "user" {
                Spacer()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 25).foregroundColor(messageColor)
                Text(message["content"] ?? "error")
            }
            if message["role"] == "assistant" {
                Spacer()
            }
        }
    }
}
