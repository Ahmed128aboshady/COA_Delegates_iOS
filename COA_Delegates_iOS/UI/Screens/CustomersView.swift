import SwiftUI

// --- Customers List Screen ---
struct CustomersScreen: View {
    let customers: [CustomerRecord]
    @Binding var searchQuery: String
    let onCustomerClick: (Int64) -> Void
    let onAddCustomer: () -> Void
    let onCall: (String) -> Void
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
                Text("العملاء")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onAddCustomer) {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(AppColors.primaryDarkBlue)
            
            // Search Bar
            SearchBar(text: $searchQuery, placeholder: "بحث عن عميل...")
                .padding(.top, 12)
            
            if customers.isEmpty {
                EmptyState(icon: "person.3", message: "لا يوجد عملاء مطبقين للبحث")
            } else {
                List(customers) { customer in
                    HStack(spacing: 12) {
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                onCall(customer.phone)
                            }) {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(AppColors.successGreen)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                onCustomerClick(customer.id)
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Spacer()
                        
                        // Customer text details
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(customer.name)
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(customer.address.isEmpty ? "لا يوجد عنوان مسجل" : customer.address)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("الرصيد: \(String(format: "%.2f", customer.balance)) ج.م")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(customer.balance > 0 ? AppColors.accentRed : AppColors.successGreen)
                        }
                        .onTapGesture {
                            onCustomerClick(customer.id)
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
}

// --- Add / Edit Customer Form Screen ---
struct AddEditCustomerScreen: View {
    let existingCustomer: CustomerUiModel?
    let onSave: (String, String, String, String, String, String) -> Void
    let onBack: () -> Void
    
    @State private var name = ""
    @State private var address = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var region = ""
    @State private var notes = ""
    @State private var validationError = ""
    
    init(existingCustomer: CustomerUiModel? = nil, onSave: @escaping (String, String, String, String, String, String) -> Void, onBack: @escaping () -> Void) {
        self.existingCustomer = existingCustomer
        self.onSave = onSave
        self.onBack = onBack
        
        if let c = existingCustomer {
            _name = State(initialValue: c.name)
            _address = State(initialValue: c.address)
            _phone = State(initialValue: c.phone)
            _email = State(initialValue: "") // default empty
            _region = State(initialValue: "")
            _notes = State(initialValue: "")
        }
    }
    
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
                Text(existingCustomer == nil ? "إضافة عميل جديد" : "تعديل عميل")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                // Placeholder
                Image(systemName: "arrow.right").foregroundColor(.clear)
            }
            .padding()
            .background(AppColors.primaryDarkBlue)
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Form fields
                    VStack(alignment: .trailing, spacing: 16) {
                        // Name
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("اسم العميل *")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("", text: $name)
                                .multilineTextAlignment(.trailing)
                                .padding()
                                .background(AppColors.cardGray)
                                .cornerRadius(8)
                        }
                        
                        // Phone
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("رقم الهاتف")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("", text: $phone)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.phonePad)
                                .padding()
                                .background(AppColors.cardGray)
                                .cornerRadius(8)
                        }
                        
                        // Address
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("العنوان")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("", text: $address)
                                .multilineTextAlignment(.trailing)
                                .padding()
                                .background(AppColors.cardGray)
                                .cornerRadius(8)
                        }
                        
                        // Email
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("البريد الإلكتروني")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("", text: $email)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(AppColors.cardGray)
                                .cornerRadius(8)
                        }
                        
                        // Region
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("المنطقة")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("", text: $region)
                                .multilineTextAlignment(.trailing)
                                .padding()
                                .background(AppColors.cardGray)
                                .cornerRadius(8)
                        }
                        
                        // Notes
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("ملاحظات")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            TextEditor(text: $notes)
                                .frame(height: 80)
                                .padding(4)
                                .background(AppColors.cardGray)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                )
                        }
                    }
                    .padding()
                    
                    if !validationError.isEmpty {
                        Text(validationError)
                            .font(.caption)
                            .foregroundColor(AppColors.accentRed)
                            .padding(.horizontal)
                    }
                    
                    // Save Button
                    Button(action: {
                        saveCustomer()
                    }) {
                        Text("حفظ العميل")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColors.accentRed)
                            .cornerRadius(12)
                            .shadow(color: AppColors.accentRed.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding()
                }
            }
        }
        .background(AppColors.backgroundWhite.edgesIgnoringSafeArea(.all))
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    private func saveCustomer() {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "الاسم حقل مطلوب"
            return
        }
        onSave(name, address, phone, email, region, notes)
    }
}

// --- Customer Detail Screen ---
struct CustomerDetailScreen: View {
    let customerName: String
    let phone: String
    let email: String
    let address: String
    let region: String
    let balance: Double
    let onBack: () -> Void
    let onEdit: () -> Void
    let onNewOrder: () -> Void
    let onNewPayment: () -> Void
    
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
                Text("تفاصيل العميل")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(AppColors.primaryDarkBlue)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar and Name Card
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(AppColors.primaryDarkBlue)
                        
                        Text(customerName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.top, 20)
                    
                    // Balance Section
                    VStack(spacing: 6) {
                        Text("الرصيد المستحق")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("\(String(format: "%.2f", balance)) ج.م")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(balance > 0 ? AppColors.accentRed : AppColors.successGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(balance > 0 ? AppColors.accentRed.opacity(0.05) : AppColors.successGreen.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Information Details Card
                    VStack(alignment: .trailing, spacing: 16) {
                        // Phone
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("رقم الهاتف")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(phone.isEmpty ? "غير محدد" : phone)
                                    .font(.body)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            Image(systemName: "phone.fill")
                                .foregroundColor(AppColors.primaryDarkBlue)
                                .padding(.leading, 8)
                        }
                        
                        Divider()
                        
                        // Email
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("البريد الإلكتروني")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(email.isEmpty ? "غير محدد" : email)
                                    .font(.body)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppColors.primaryDarkBlue)
                                .padding(.leading, 8)
                        }
                        
                        Divider()
                        
                        // Address
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("العنوان")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(address.isEmpty ? "غير محدد" : address)
                                    .font(.body)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(AppColors.primaryDarkBlue)
                                .padding(.leading, 8)
                        }
                    }
                    .padding()
                    .background(AppColors.cardGray)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // Quick Action Buttons
                    HStack(spacing: 16) {
                        Button(action: onNewPayment) {
                            Text("تحصيل دفعة")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.primaryDarkBlue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.primaryDarkBlue, lineWidth: 1.5)
                                )
                        }
                        
                        Button(action: onNewOrder) {
                            Text("أمر بيع جديد")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppColors.accentRed)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(AppColors.backgroundWhite.edgesIgnoringSafeArea(.all))
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// Simple Helper customer UI model
struct CustomerUiModel: Identifiable {
    let id: Int64
    let name: String
    let address: String
    let phone: String
    let balance: Double
}
