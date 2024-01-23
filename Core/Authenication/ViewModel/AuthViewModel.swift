//
//  AuthViewModel.swift
//  GridIron GPT
//
//  Created by Alex Zaharia on 1/2/24.
//

import Foundation
import FirebaseAuth
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore

protocol AuthenticationFormProtocol {
    var formIsValid: Bool { get }
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var errorMessage: String?
    
    
    init(){
        self.userSession = Auth.auth().currentUser
        Task {
            await fetchUser()
        }
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.invalidEmail.rawValue:
                self.errorMessage = "Invalid email address."
            case AuthErrorCode.wrongPassword.rawValue:
                self.errorMessage = "Incorrect password. Please try again."
            case AuthErrorCode.userNotFound.rawValue:
                self.errorMessage = "No user found with this email."
            default:
                self.errorMessage = "Login failed: \(error.localizedDescription)"
            }
        }
    }
    
    func createUser(withEmail email: String, password: String, fullName: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            let user = User(id: result.user.uid, fullName: fullName, email: email)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.invalidEmail.rawValue:
                self.errorMessage = "Invalid email address."
            case AuthErrorCode.weakPassword.rawValue:
                self.errorMessage = "Password is too weak. It must be at least 8 characters long and include a number."
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                self.errorMessage = "An account already exists with this email."
            default:
                self.errorMessage = "Failed to create account: \(error.localizedDescription)"
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut() // signs out user on back end
            self.userSession = nil // wipes out user session and goes back to login screen
            self.currentUser = nil // wipes out current user data model
        } catch {
            print("DEBUG: Failed to sign out with error \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }

        // Delete user data from Firestore
        let db = Firestore.firestore()
        let userId = user.uid
        do {
            try await db.collection("users").document(userId).delete()
            print("DEBUG: User data deleted from Firestore.")
        } catch let error {
            print("DEBUG: Error deleting user data from Firestore: \(error.localizedDescription)")
            throw error
        }

        // Delete user from Firebase Authentication
        do {
            try await user.delete()
            self.userSession = nil
            self.currentUser = nil
            print("DEBUG: User deleted from Firebase Authentication.")
        } catch let error {
            print("DEBUG: Error deleting user from Firebase Authentication: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else { return }
        self.currentUser = try? snapshot.data(as: User.self)
        print("DEBUG: Current user is \(self.currentUser)")
    }
}
 
