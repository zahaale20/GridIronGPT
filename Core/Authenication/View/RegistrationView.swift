//
//  RegistrationView.swift
//  GridIron GPT
//
//  Created by Alex Zaharia on 1/2/24.
//

import SwiftUI
import Combine

struct RegistrationView: View {
    @State private var email = ""
    @State private var fullName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @Environment (\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var validateEmail = false
    @State private var validateFullName = false
    
    var body: some View {
        VStack{
            // Logo
            Image("GridIronGPT_Transparent")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 120)
                .padding(.vertical, 32)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .onDisappear {
                        // Reset the error message when the view disappears
                        viewModel.errorMessage = nil
                    }
            }
            
            VStack(spacing:24){
                // email
                ZStack (alignment: .trailing) {
                    InputView(text: $email,
                              title: "Email Address",
                              placeholder: "name@example.com")
                        .autocapitalization(.none)
                        .onSubmit {
                            validateEmail = true
                        }

                    if validateEmail && isEmailValid(email) {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.large)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.systemGreen))
                    }
                }
                // full name
                ZStack (alignment: .trailing){
                    InputView(text: $fullName,
                              title: "Full Name",
                              placeholder: "Enter your name...")
                        .autocapitalization(.none)
                        .onSubmit {
                            validateFullName = true
                        }

                    if validateFullName && !fullName.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.large)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.systemGreen))
                    }
                }
                // password
                
                ZStack (alignment: .trailing){
                    InputView(text: $password,
                              title: "Password",
                              placeholder: "Enter your password...",
                              isSecureField: true)
                    if password.count > 5 && isPasswordValid(password) {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.large)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.systemGreen))
                    } else {
                        if password.count > 0 {
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.large)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemRed))
                        }
                    }
                }
                
                // confirm password
                ZStack (alignment: .trailing){
                    InputView(text: $confirmPassword,
                              title: "Confirm Password",
                              placeholder: "Confirm your password...",
                              isSecureField: true)
                    if !password.isEmpty && !confirmPassword.isEmpty {
                        if password == confirmPassword {
                            Image(systemName: "checkmark.circle.fill")
                                .imageScale(.large)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemGreen))
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.large)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemRed))
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Button{
                Task {
                    try await viewModel.createUser(withEmail: email, 
                                                   password: password,
                                                   fullName: fullName)
                }
            } label: {
                HStack {
                    Text("SIGN UP")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(width: UIScreen.main.bounds.width - 32,
                       height: 48)
            }
            .background(Color(.systemBlue))
            .cornerRadius(10)
            .disabled(!formIsValid)
            .opacity(formIsValid ? 1.0 : 0.5)
            .padding(.top, 24)
            
            Spacer()
            
            Button{
                dismiss()
            } label: {
                HStack (spacing: 3){
                    Text("Already have an account?")
                    Text("Sign in")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    
                }
                .font(.system(size: 14))
            }
        }
    }
    
    private func isEmailValid(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isPasswordValid(_ password: String) -> Bool {
        let passwordRegex = "(?=.*[0-9])(?=.*[!@#$%^&*(),.?\":{}|<>]).{6,}"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }
}

// MARK: AuthenticationFormProtocol

extension RegistrationView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES[c] %@", emailRegex)
        
        let passwordRegex = "(?=.*[0-9])(?=.*[!@#$%^&*(),.?\":{}|<>]).{6,}"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)

        let nameRegex = "^[a-zA-Z]+(?:[-'\\s][a-zA-Z]+)*$"
        let namePredicate = NSPredicate(format: "SELF MATCHES %@", nameRegex)

        return emailPredicate.evaluate(with: email)
            && passwordPredicate.evaluate(with: password)
            && namePredicate.evaluate(with: fullName)
            && confirmPassword == password
    }
}

#Preview {
    RegistrationView()
}
