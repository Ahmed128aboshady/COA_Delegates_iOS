import SwiftUI

struct MapScreen: View {
    let currentLat: Double
    let currentLng: Double
    let todayPointsCount: Int
    let visitedCustomers: [String]
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.right")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                Spacer()
                Text("خريطة خط السير")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.right").foregroundColor(.clear)
            }
            .padding()
            .background(AppColors.primaryDarkBlue)
            
            // Map Placeholder
            ZStack {
                // Background grid pattern to simulate a map visual
                Color(hex: 0xE5E9F0)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 4) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppColors.primaryDarkBlue.opacity(0.3))
                        .padding()
                    
                    Text("خريطة خط السير التفاعلية")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("سيتم عرض تتبع GPS الحقيقي هنا عند إضافة خرائط آبل (MapKit).")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .frame(height: 300)
            
            // Coordinates and tracking details Card
            VStack(alignment: .trailing, spacing: 16) {
                Text("إحصائيات تتبع اليوم")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("نقاط الموقع المسجلة اليوم")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(todayPointsCount) نقطة")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primaryDarkBlue)
                    }
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(AppColors.primaryDarkBlue)
                }
                
                Divider()
                
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("الإحداثيات الحالية")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(String(format: "Lat: %.5f, Lng: %.5f", currentLat, currentLng))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    Image(systemName: "scope")
                        .foregroundColor(AppColors.primaryDarkBlue)
                }
            }
            .padding()
            .background(AppColors.cardGray)
            .cornerRadius(12)
            .padding()
            
            // Visits list
            VStack(alignment: .trailing, spacing: 8) {
                Text("الزيارات المنفذة اليوم")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(visitedCustomers, id: \.self) { visit in
                            HStack {
                                Spacer()
                                Text(visit)
                                    .font(.body)
                                    .foregroundColor(AppColors.textPrimary)
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.successGreen)
                            }
                            .padding()
                            .background(AppColors.cardGray.opacity(0.6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .background(AppColors.backgroundWhite.edgesIgnoringSafeArea(.all))
        .environment(\.layoutDirection, .rightToLeft)
    }
}
