import SwiftUI

struct ProfileScreen: View {
    let userName: String
    let userPhone: String
    let userRegion: String
    let isGpsTrackingEnabled: Bool
    let onGpsTrackingToggle: (Bool) -> Void
    let onLogout: () -> Void
    let onBack: () -> Void
    
    @State private var showLogoutDialog = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header/Navigation bar
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "arrow.right")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("الملف الشخصي")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Transparent placeholder for alignment
                    Image(systemName: "arrow.right")
                        .font(.title3)
                        .foregroundColor(.clear)
                }
                .padding()
                .background(AppColors.primaryDarkBlue)
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Profile Avatar
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primaryDarkBlue.opacity(0.1))
                                    .frame(width: 90, height: 90)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(AppColors.primaryDarkBlue)
                            }
                            
                            Text(userName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.top, 24)
                        
                        // Info Card
                        VStack(alignment: .trailing, spacing: 12) {
                            Text("بيانات الحساب")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 16) {
                                // Phone number
                                HStack(spacing: 12) {
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("رقم الهاتف")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                        Text(userPhone.isEmpty ? "غير محدد" : userPhone)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(AppColors.primaryDarkBlue)
                                }
                                
                                Divider()
                                
                                // Region
                                HStack(spacing: 12) {
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("منطقة المندوب")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                        Text(userRegion.isEmpty ? "غير محدد" : userRegion)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(AppColors.primaryDarkBlue)
                                }
                            }
                            .padding()
                            .background(AppColors.cardGray)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Settings Card
                        VStack(alignment: .trailing, spacing: 12) {
                            Text("الإعدادات")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 16) {
                                // GPS Switch
                                HStack {
                                    Toggle(isOn: Binding(
                                        get: { isGpsTrackingEnabled },
                                        set: { onGpsTrackingToggle($0) }
                                    )) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("تتبع الموقع (GPS)")
                                                .font(.body)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.textPrimary)
                                            Text("تتبع خط السير تلقائياً في الخلفية")
                                                .font(.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primaryDarkBlue))
                                }
                                
                                Divider()
                                
                                // App version
                                HStack(spacing: 12) {
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("إصدار التطبيق")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                        Text("COA Egypt iOS v1.0.0 (إنتاج)")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(AppColors.primaryDarkBlue)
                                }
                            }
                            .padding()
                            .background(AppColors.cardGray)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                            .frame(height: 30)
                        
                        // Solid Red Logout Button
                        Button(action: {
                            showLogoutDialog = true
                        }) {
                            HStack {
                                Text("تسجيل الخروج")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.title3)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColors.accentRed)
                            .cornerRadius(12)
                            .shadow(color: AppColors.accentRed.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                    }
                }
            }
            .background(AppColors.backgroundWhite.edgesIgnoringSafeArea(.all))
            
            // Logout Confirmation Dialog
            if showLogoutDialog {
                ConfirmDialog(
                    title: "تسجيل الخروج",
                    message: "هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟ سيتم إيقاف تتبع الموقع GPS.",
                    confirmText: "تسجيل الخروج",
                    cancelText: "إلغاء",
                    onConfirm: {
                        showLogoutDialog = false
                        onLogout()
                    },
                    onDismiss: {
                        showLogoutDialog = false
                    }
                )
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}
