import SwiftUI

struct LoginScreen: View {
    let onLogin: (String, String) -> Void
    let isLoading: Bool
    let errorMessage: String
    
    @State private var username = ""
    @State private var password = ""
    @State private var passwordVisible = false
    @State private var localError = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)
            
            // Logo area
            VStack(spacing: 8) {
                Text("COA Delegates")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryDarkBlue)
                
                Rectangle()
                    .fill(AppColors.accentRed)
                    .frame(width: 80, height: 3)
            }
            .padding(.top, 40)
            
            Spacer()
                .frame(height: 20)
            
            VStack(alignment: .trailing, spacing: 20) {
                Text("تسجيل الدخول")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                // Username field
                VStack(alignment: .trailing, spacing: 6) {
                    Text("اسم المستخدم")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(AppColors.textSecondary)
                        
                        TextField("", text: $username)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.alphabet)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(AppColors.cardGray)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Password field
                VStack(alignment: .trailing, spacing: 6) {
                    Text("كلمة المرور")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack {
                        Button(action: {
                            passwordVisible.toggle()
                        }) {
                            Image(systemName: passwordVisible ? "eye.slash" : "eye")
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        if passwordVisible {
                            TextField("", text: $password)
                                .multilineTextAlignment(.trailing)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("", text: $password)
                                .multilineTextAlignment(.trailing)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Image(systemName: "lock")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding()
                    .background(AppColors.cardGray)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            
            // Error Display
            let currentError = !errorMessage.isEmpty ? errorMessage : localError
            if !currentError.isEmpty {
                Text(currentError)
                    .font(.subheadline)
                    .foregroundColor(AppColors.accentRed)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Login Button
            Button(action: {
                validateAndLogin()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 8)
                    }
                    Text("تسجيل الدخول")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppColors.accentRed)
                .cornerRadius(12)
                .shadow(color: AppColors.accentRed.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .disabled(isLoading)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            Spacer()
        }
        .background(AppColors.backgroundWhite.edgesIgnoringSafeArea(.all))
        .environment(\.layoutDirection, .rightToLeft) // RTL layout
    }
    
    private func validateAndLogin() {
        localError = ""
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty {
            localError = "يرجى إدخال اسم المستخدم وكلمة المرور"
            return
        }
        onLogin(username, password)
    }
}
