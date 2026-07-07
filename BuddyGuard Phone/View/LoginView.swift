//
//  LoginView.swift
//  BuddyGuard
//
//  Created by George Maximillian Theodore on 06/07/26.
//


import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit
import GoogleSignIn // 1. Added this import
import FirebaseCore

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var currentNonce: String?
    
    var body: some View {
        VStack(spacing: 40) {
            
            Spacer()
            
            // MARK: - Header & Logo
            VStack(spacing: 12) {
                Image(systemName: "teddybear.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color("dark", bundle: nil))
                
                Text("BuddyGuard")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                
                Text("Your personal safety companion.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // MARK: - Sign In Buttons
            VStack(spacing: 12) {
                
                // 1. Apple Sign In — Primary
                SignInWithAppleButton(.signIn) { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                } onCompletion: { result in
                    handleAppleLogin(result: result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 55)
                .cornerRadius(12)
                
                // 2. Custom Google Sign In Button
                Button(action: {
                    handleGoogleLogin()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "g.circle.fill")
                            .font(.title2)
                        
                        Text("Sign in with Google")
                            .font(.system(size: 19, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .foregroundColor(.black)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)

        }
        .background(Color("lightD", bundle: nil).ignoresSafeArea())
    }
    
    // MARK: - Google Auth Logic
    
    private func handleGoogleLogin() {
        // 1. Get the Client ID from your Firebase config
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // 2. Create the Google configuration
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // 3. Find the root view controller to present the Google login window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("There is no root view controller!")
            return
        }
        
        // 4. Start the Google Sign In flow
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Google Sign-In Error: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Error: Missing Google Auth Token")
                return
            }
            
            let accessToken = user.accessToken.tokenString
            
            // 5. Create the Firebase Credential
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)
            
            // 6. Authenticate with Firebase
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Google Sign-In Error: \(error.localizedDescription)")
                    return
                }
                
                if let user = authResult?.user {
                    print("✅ Success! Firebase User UID (Google): \(user.uid)")
                    // Navigate to the emergency view here!
                }
            }
        }
    }
    
    // MARK: - Apple Auth Logic
    
    private func handleAppleLogin(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                
                guard let nonce = currentNonce else { return }
                guard let appleIDToken = appleIDCredential.identityToken else { return }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else { return }
                
                let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                               rawNonce: nonce,
                                                               fullName: appleIDCredential.fullName)
                
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if let error = error {
                        print("Firebase Sign-In Error: \(error.localizedDescription)")
                        return
                    }
                    
                    if let user = authResult?.user {
                        print("✅ Success! Firebase User UID (Apple): \(user.uid)")
                    }
                }
            }
            
        case .failure(let error):
            print("Apple Auth Failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cryptography Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}


