import SwiftUI

// --- Connection Status Bar ---
struct ConnectionStatusBar: View {
    let isConnected: Bool
    let pendingSyncCount: Int
    
    var body: some View {
        if !isConnected || pendingSyncCount > 0 {
            HStack {
                Spacer()
                if !isConnected {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.white)
                    Text("وضع الأوفلاين")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.white)
                    Text("\(pendingSyncCount) سجلات في انتظار المزامنة")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.vertical, 6)
            .background(!isConnected ? AppColors.warningOrange : AppColors.statusBlue)
            .transition(.move(edge: .top))
            .animation(.easeInOut, value: isConnected)
        }
    }
}

// --- KPI Card ---
struct KPICard: View {
    let icon: String
    let value: String
    let label: String
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(accentColor)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.1))
                .clipShape(Circle())
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.cardGray)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// --- Search Bar ---
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField(placeholder, text: $text)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.trailing) // RTL alignment
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(10)
        .background(AppColors.cardGray)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// --- Empty State View ---
struct EmptyState: View {
    let icon: String
    let message: String
    var actionLabel: String? = nil
    var onAction: (() -> View)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary.opacity(0.4))
            
            Text(message)
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// --- Custom Confirmation Dialog ---
struct ConfirmDialog: View {
    let title: String
    let message: String
    var confirmText: String = "تأكيد"
    var cancelText: String = "إلغاء"
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 20) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 12) {
                    Button(action: {
                        onDismiss()
                    }) {
                        Text(cancelText)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.cardGray)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        onConfirm()
                    }) {
                        Text(confirmText)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.accentRed)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 32)
        }
    }
}
