import SwiftUI

struct HomeScreen: View {
    let todaySales: Double
    let ordersCount: Int
    let paymentsTotal: Double
    let visitsCount: Int
    let pendingSyncCount: Int
    let isConnected: Bool
    let isSyncing: Bool
    let userName: String
    let onSync: () -> Void
    let onNavigate: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Connection Status Bar
            ConnectionStatusBar(isConnected: isConnected, pendingSyncCount: pendingSyncCount)
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Welcome Header
                    HStack {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("مرحباً، \(userName)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(getArabicFormattedDate())
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Sync Button
                        Button(action: {
                            onSync()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primaryDarkBlue)
                                    .frame(width: 48, height: 48)
                                    .shadow(color: AppColors.primaryDarkBlue.opacity(0.2), radius: 4, x: 0, y: 2)
                                
                                if isSyncing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(isSyncing)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // KPIs Section
                    VStack(alignment: .trailing, spacing: 12) {
                        Text("إحصائيات اليوم")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            KPICard(
                                icon: "dollarsign.circle",
                                value: String(format: "%.2f ج.م", todaySales),
                                label: "مبيعات اليوم",
                                accentColor: AppColors.successGreen
                            )
                            
                            KPICard(
                                icon: "cart",
                                value: "\(ordersCount)",
                                label: "أوامر البيع",
                                accentColor: AppColors.primaryDarkBlue
                            )
                            
                            KPICard(
                                icon: "creditcard",
                                value: String(format: "%.2f ج.م", paymentsTotal),
                                label: "التحصيلات",
                                accentColor: AppColors.methodPurple
                            )
                            
                            KPICard(
                                icon: "mappin.and.ellipse",
                                value: "\(visitsCount)",
                                label: "الزيارات",
                                accentColor: AppColors.warningOrange
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Quick Actions Section
                    VStack(alignment: .trailing, spacing: 12) {
                        Text("إجراءات سريعة")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                onNavigate("new_order")
                            }) {
                                HStack {
                                    Spacer()
                                    Text("أمر بيع جديد")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                }
                                .foregroundColor(.white)
                                .frame(height: 54)
                                .background(AppColors.accentRed)
                                .cornerRadius(12)
                                .shadow(color: AppColors.accentRed.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    onNavigate("map")
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("عرض الخريطة")
                                            .font(.body)
                                            .fontWeight(.bold)
                                        Spacer()
                                        Image(systemName: "map")
                                    }
                                    .foregroundColor(AppColors.primaryDarkBlue)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.primaryDarkBlue, lineWidth: 1.5)
                                    )
                                }
                                
                                Button(action: {
                                    onNavigate("new_payment")
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("تسجيل تحصيل")
                                            .font(.body)
                                            .fontWeight(.bold)
                                        Spacer()
                                        Image(systemName: "banknote")
                                    }
                                    .foregroundColor(AppColors.primaryDarkBlue)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.primaryDarkBlue, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
        }
        .background(AppColors.backgroundWhite.edgesIgnoringSafeArea(.all))
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    private func getArabicFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_EG")
        formatter.dateFormat = "EEEE، d MMMM yyyy"
        return formatter.string(from: Date())
    }
}
