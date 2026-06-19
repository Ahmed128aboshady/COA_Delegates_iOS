import SwiftUI

// --- Sales Orders List Screen ---
struct SalesOrdersScreen: View {
    let orders: [SalesOrderRecord]
    @Binding var filter: String
    let onOrderClick: (Int64) -> Void
    let onNewOrder: () -> Void
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
                Text("أوامر البيع")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onNewOrder) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(AppColors.primaryDarkBlue)
            
            // Filter Selector Segment
            Picker("", selection: $filter) {
                Text("الكل").tag("all")
                Text("اليوم").tag("today")
                Text("مسودة").tag("draft")
                Text("تمت المزامنة").tag("synced")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if filteredOrders.isEmpty {
                EmptyState(icon: "doc.text.fill", message: "لا توجد طلبات مبيعات مسجلة")
            } else {
                List(filteredOrders) { order in
                    HStack {
                        // Order Price and Status
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(String(format: "%.2f", order.grandTotal)) ج.م")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.accentRed)
                            
                            Text(order.status == "synced" ? "تمت المزامنة" : (order.status == "confirmed" ? "معمد" : "مسودة"))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(order.status).opacity(0.1))
                                .foregroundColor(statusColor(order.status))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        // Order Info
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(order.customerName)
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(formatTimestamp(order.date))
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
    
    private var filteredOrders: [SalesOrderRecord] {
        switch filter {
        case "today":
            let calendar = Calendar.current
            let todayStart = calendar.startOfDay(for: Date())
            let timestamp = Int64(todayStart.timeIntervalSince1970 * 1000)
            return orders.filter { $0.date >= timestamp }
        case "draft":
            return orders.filter { $0.status == "draft" }
        case "synced":
            return orders.filter { $0.status == "synced" }
        default:
            return orders
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "synced": return AppColors.successGreen
        case "confirmed": return AppColors.statusBlue
        default: return AppColors.warningOrange
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

// --- Create Sales Order Screen ---
struct CreateSalesOrderScreen: View {
    let customers: [CustomerRecord]
    let products: [ProductRecord]
    let onConfirm: (Int64, String, [OdooOrderItem], String) -> Void
    let onBack: () -> Void
    
    @State private var currentStep = 1 // 1: Customer, 2: Add Products, 3: Review
    
    // Step 1 State
    @State private var selectedCustomer: CustomerRecord? = nil
    @State private var customerSearch = ""
    
    // Step 2 State
    @State private var addedItems = [OdooOrderItem]()
    @State private var productSearch = ""
    @State private var showProductPicker = false
    
    // Step 3 State
    @State private var notes = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    if currentStep > 1 {
                        currentStep -= 1
                    } else {
                        onBack()
                    }
                }) {
                    Image(systemName: "arrow.right")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                Spacer()
                Text("أمر بيع جديد")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                // Placeholder
                Image(systemName: "arrow.right").foregroundColor(.clear)
            }
            .padding()
            .background(AppColors.primaryDarkBlue)
            
            // Stepper Indicator
            HStack(spacing: 8) {
                StepIndicator(stepNumber: 3, label: "المراجعة", isActive: currentStep >= 3)
                Spacer()
                StepIndicator(stepNumber: 2, label: "المنتجات", isActive: currentStep >= 2)
                Spacer()
                StepIndicator(stepNumber: 1, label: "العميل", isActive: currentStep >= 1)
            }
            .padding()
            .background(AppColors.cardGray.opacity(0.5))
            
            // Step Content
            VStack {
                if currentStep == 1 {
                    stepSelectCustomer()
                } else if currentStep == 2 {
                    stepAddProducts()
                } else {
                    stepReviewOrder()
                }
            }
        }
        .background(AppColors.backgroundWhite.edgesIgnoringSafeArea(.all))
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: $showProductPicker) {
            productPickerSheet()
        }
    }
    
    // --- Step 1: Select Customer ---
    @ViewBuilder
    private func stepSelectCustomer() -> some View {
        VStack(spacing: 12) {
            SearchBar(text: $customerSearch, placeholder: "بحث عن عميل...")
                .padding(.top, 12)
            
            let filtered = customers.filter { c in
                customerSearch.isEmpty || c.name.contains(customerSearch) || c.phone.contains(customerSearch)
            }
            
            List(filtered) { customer in
                HStack {
                    if selectedCustomer?.id == customer.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.accentRed)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(customer.name)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                        Text(customer.phone)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedCustomer = customer
                }
            }
            .listStyle(PlainListStyle())
            
            Button(action: {
                if selectedCustomer != nil {
                    currentStep = 2
                }
            }) {
                Text("التالي: إضافة المنتجات")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(selectedCustomer == nil ? Color.gray : AppColors.accentRed)
                    .cornerRadius(12)
            }
            .disabled(selectedCustomer == nil)
            .padding()
        }
    }
    
    // --- Step 2: Add Products ---
    @ViewBuilder
    private func stepAddProducts() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("المنتجات المضافة (\(addedItems.count))")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button(action: { showProductPicker = true }) {
                    HStack {
                        Text("إضافة صنف")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Image(systemName: "plus")
                    }
                    .foregroundColor(AppColors.accentRed)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.accentRed.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            if addedItems.isEmpty {
                EmptyState(icon: "cart.badge.plus", message: "لم تقم بإضافة منتجات بعد. اضغط على زر إضافة صنف بالأعلى.")
            } else {
                List {
                    ForEach(addedItems.indices, id: \.self) { index in
                        let item = addedItems[index]
                        HStack {
                            // Quantity selector
                            HStack(spacing: 12) {
                                Button(action: {
                                    if item.quantity > 1 {
                                        addedItems[index] = OdooOrderItem(productOdooId: item.productOdooId, quantity: item.quantity - 1, unitPrice: item.unitPrice)
                                    } else {
                                        addedItems.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(AppColors.accentRed)
                                        .font(.title3)
                                }
                                
                                Text("\(item.quantity)")
                                    .font(.body)
                                    .fontWeight(.bold)
                                
                                Button(action: {
                                    addedItems[index] = OdooOrderItem(productOdooId: item.productOdooId, quantity: item.quantity + 1, unitPrice: item.unitPrice)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(AppColors.successGreen)
                                        .font(.title3)
                                }
                            }
                            
                            Spacer()
                            
                            // Item name and price
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(getProductName(id: item.productOdooId))
                                    .font(.body)
                                    .fontWeight(.bold)
                                Text("\(String(format: "%.2f", item.unitPrice * Double(item.quantity))) ج.م")
                                    .font(.caption)
                                    .foregroundColor(AppColors.accentRed)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            // Subtotal summary bar
            HStack {
                Text("الإجمالي المؤقت:")
                    .font(.body)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text("\(String(format: "%.2f", getSubtotal())) ج.م")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.accentRed)
            }
            .padding(.horizontal)
            
            Button(action: {
                if !addedItems.isEmpty {
                    currentStep = 3
                }
            }) {
                Text("التالي: مراجعة الطلب")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(addedItems.isEmpty ? Color.gray : AppColors.accentRed)
                    .cornerRadius(12)
            }
            .disabled(addedItems.isEmpty)
            .padding()
        }
    }
    
    // --- Step 3: Review Order ---
    @ViewBuilder
    private func stepReviewOrder() -> some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(alignment: .trailing, spacing: 16) {
                    // Customer info
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("العميل")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(selectedCustomer?.name ?? "")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding()
                    .background(AppColors.cardGray)
                    .cornerRadius(10)
                    
                    // Invoice values summary
                    VStack(spacing: 12) {
                        HStack {
                            Text("الإجمالي قبل الضريبة")
                            Spacer()
                            Text("\(String(format: "%.2f", getSubtotal())) ج.م")
                        }
                        .foregroundColor(AppColors.textSecondary)
                        
                        HStack {
                            Text("ضريبة المبيعات (14%)")
                            Spacer()
                            Text("\(String(format: "%.2f", getSubtotal() * 0.14)) ج.م")
                        }
                        .foregroundColor(AppColors.textSecondary)
                        
                        Divider()
                        
                        HStack {
                            Text("الإجمالي النهائي")
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text("\(String(format: "%.2f", getSubtotal() * 1.14)) ج.م")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.accentRed)
                        }
                    }
                    .padding()
                    .background(AppColors.cardGray)
                    .cornerRadius(10)
                    
                    // Notes field
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("ملاحظات الفاتورة")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        TextField("مثال: تسليم عند البوابة، شحن سريع...", text: $notes)
                            .multilineTextAlignment(.trailing)
                            .padding()
                            .background(AppColors.cardGray)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            
            Button(action: {
                if let c = selectedCustomer {
                    onConfirm(c.id, c.name, addedItems, notes)
                }
            }) {
                Text("تأكيد وحفظ الفاتورة")
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
    
    // --- Product Picker Sheet ---
    @ViewBuilder
    private func productPickerSheet() -> some View {
        VStack {
            Text("اختر المنتج المراد إضافته")
                .font(.headline)
                .padding()
            
            SearchBar(text: $productSearch, placeholder: "بحث عن منتج...")
            
            let filtered = products.filter { p in
                productSearch.isEmpty || p.name.contains(productSearch) || p.sku.contains(productSearch)
            }
            
            List(filtered) { product in
                HStack {
                    Text("\(String(format: "%.2f", product.price)) ج.م")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.accentRed)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.name)
                            .font(.body)
                            .fontWeight(.bold)
                        Text("الرمز: \(product.sku)")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    let existingIdx = addedItems.firstIndex(where: { $0.productOdooId == product.odooId })
                    if let idx = existingIdx {
                        let currentItem = addedItems[idx]
                        addedItems[idx] = OdooOrderItem(productOdooId: currentItem.productOdooId, quantity: currentItem.quantity + 1, unitPrice: currentItem.unitPrice)
                    } else {
                        addedItems.append(OdooOrderItem(productOdooId: Int(product.odooId ?? 0), quantity: 1, unitPrice: product.price))
                    }
                    showProductPicker = false
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    // Helper Methods
    private func getProductName(id: Int) -> String {
        return products.first(where: { $0.odooId == id })?.name ?? "صنف غير معروف"
    }
    
    private func getSubtotal() -> Double {
        return addedItems.reduce(0.0) { sum, item in sum + (Double(item.quantity) * item.unitPrice) }
    }
}

// Custom Stepper Indicator Component
struct StepIndicator: View {
    let stepNumber: Int
    let label: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(isActive ? .bold : .medium)
                .foregroundColor(isActive ? AppColors.primaryDarkBlue : AppColors.textSecondary)
            
            ZStack {
                Circle()
                    .fill(isActive ? AppColors.primaryDarkBlue : Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                Text("\(stepNumber)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}
