import SwiftUI

// --- Payments List Screen ---
struct PaymentsScreen: View {
    let payments: [PaymentRecord]
    let onNewPayment: () -> Void
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
                Text("المقبوضات والتحصيلات")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onNewPayment) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(AppColors.primaryDarkBlue)
            
            if payments.isEmpty {
                EmptyState(icon: "banknote.fill", message: "لا توجد سندات قبض مسجلة حتى الآن")
            } else {
                List(payments) { payment in
                    HStack {
                        // Amount & Method
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(String(format: "%.2f", payment.amount)) ج.م")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.successGreen)
                            
                            Text(payment.method)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(methodColor(payment.method).opacity(0.1))
                                .foregroundColor(methodColor(payment.method))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        // Customer & Date
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(payment.customerName)
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(formatTimestamp(payment.date))
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
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
    
    private func methodColor(_ method: String) -> Color {
        if method == "نقداً" {
            return AppColors.successGreen
        } else if method == "شيك" {
            return AppColors.statusBlue
        } else {
            return AppColors.methodPurple
        }
    }
    
    private func formatTimestamp(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "yyyy/MM/dd hh:mm a"
        return formatter.string(from: date)
    }
}

// --- Create Payment Screen ---
struct CreatePaymentScreen: View {
    let customers: [CustomerRecord]
    let onConfirm: (Int64, String, Double, String, String, Date, String) -> Void
    let onBack: () -> Void
    
    @State private var selectedCustomer: CustomerRecord? = nil
    @State private var customerSearch = ""
    @State private var amount = ""
    @State private var paymentMethod = "نقداً" // "نقداً", "شيك", "تحويل"
    @State private var checkNumber = ""
    @State private var checkDate = Date()
    @State private var notes = ""
    @State private var validationError = ""
    
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
                Text("تسجيل سند قبض")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.right").foregroundColor(.clear)
            }
            .padding()
            .background(AppColors.primaryDarkBlue)
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Choose Customer
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("اختر العميل *")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        SearchBar(text: $customerSearch, placeholder: "بحث عن عميل...")
                            .padding(.horizontal, 0)
                        
                        let filtered = customers.filter { c in
                            customerSearch.isEmpty || c.name.contains(customerSearch)
                        }
                        
                        if selectedCustomer != nil {
                            HStack {
                                Button(action: { selectedCustomer = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppColors.accentRed)
                                }
                                Spacer()
                                Text(selectedCustomer?.name ?? "")
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.primaryDarkBlue)
                            }
                            .padding()
                            .background(AppColors.primaryDarkBlue.opacity(0.08))
                            .cornerRadius(8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(filtered.prefix(5)) { customer in
                                        Button(action: {
                                            selectedCustomer = customer
                                        }) {
                                            Text(customer.name)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(AppColors.cardGray)
                                                .foregroundColor(AppColors.textPrimary)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Amount and details
                    VStack(alignment: .trailing, spacing: 16) {
                        // Amount input
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("المبلغ المحصل (ج.م) *")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("0.00", text: $amount)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(AppColors.cardGray)
                                .cornerRadius(8)
                        }
                        
                        // Payment Method
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("طريقة الدفع")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack(spacing: 12) {
                                ForEach(["نقداً", "شيك", "تحويل"], id: \.self) { method in
                                    Button(action: {
                                        paymentMethod = method
                                    }) {
                                        Text(method)
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(paymentMethod == method ? AppColors.primaryDarkBlue : AppColors.cardGray)
                                            .foregroundColor(paymentMethod == method ? .white : AppColors.textPrimary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // If Check details
                        if paymentMethod == "شيك" {
                            VStack(alignment: .trailing, spacing: 12) {
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("رقم الشيك *")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    TextField("", text: $checkNumber)
                                        .multilineTextAlignment(.trailing)
                                        .padding()
                                        .background(AppColors.cardGray)
                                        .cornerRadius(8)
                                }
                                
                                DatePicker("تاريخ استحقاق الشيك", selection: $checkDate, displayedComponents: .date)
                                    .environment(\.locale, Locale(identifier: "ar"))
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .transition(.opacity)
                        }
                        
                        // Notes
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("ملاحظات")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("مثال: دفعة تحت الحساب...", text: $notes)
                                .multilineTextAlignment(.trailing)
                                .padding()
                                .background(AppColors.cardGray)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    if !validationError.isEmpty {
                        Text(validationError)
                            .font(.caption)
                            .foregroundColor(AppColors.accentRed)
                            .padding(.horizontal)
                    }
                    
                    // Confirm button
                    Button(action: {
                        confirmPayment()
                    }) {
                        Text("تأكيد وحفظ السند")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColors.successGreen)
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .background(AppColors.backgroundWhite.edgesIgnoringSafeArea(.all))
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    private func confirmPayment() {
        validationError = ""
        guard let customer = selectedCustomer else {
            validationError = "يرجى اختيار العميل أولاً"
            return
        }
        guard let paymentAmount = Double(amount), paymentAmount > 0 else {
            validationError = "يرجى إدخال مبلغ محصل صالح"
            return
        }
        if paymentMethod == "شيك" && checkNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "يرجى إدخال رقم الشيك"
            return
        }
        
        onConfirm(customer.id, customer.name, paymentAmount, paymentMethod, checkNumber, checkDate, notes)
    }
}
