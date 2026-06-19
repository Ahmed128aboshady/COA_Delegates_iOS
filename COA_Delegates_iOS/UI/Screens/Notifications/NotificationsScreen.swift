import SwiftUI

struct NotificationsScreen: View {
    let notifications: [NotificationRecord]
    let onMarkAllRead: () -> Void
    let onNotificationClick: (Int64) -> Void
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
                Text("الإشعارات والتنبيهات")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onMarkAllRead) {
                    Text("تعليم الكل كمقروء")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(AppColors.primaryDarkBlue)
            
            if notifications.isEmpty {
                EmptyState(icon: "bell.slash.fill", message: "لا توجد إشعارات أو تنبيهات واردة بعد")
            } else {
                List(notifications) { notification in
                    HStack(spacing: 12) {
                        if !notification.isRead {
                            Circle()
                                .fill(AppColors.accentRed)
                                .frame(width: 8, height: 8)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(notification.title)
                                .font(.body)
                                .fontWeight(notification.isRead ? .regular : .bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(notification.body)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.trailing)
                            
                            Text(formatTimestamp(notification.date))
                                .font(.system(size: 9))
                                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                        }
                        .onTapGesture {
                            onNotificationClick(notification.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
            }
        }
        .background(AppColors.backgroundWhite.edgesIgnoringSafeArea(.all))
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    private func formatTimestamp(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "yyyy/MM/dd hh:mm a"
        return formatter.string(from: date)
    }
}
