import Foundation
import Combine
import SwiftUI
import Network

@MainActor
class AppViewModel: ObservableObject {
    private let db = DatabaseManager.shared
    private let client = OdooClient()

    // Network State
    @Published var isConnected = true
    private let pathMonitor = NWPathMonitor()

    
    // Auth States
    @Published var isLoggedIn = false
    @Published var currentUser: UserRecord?
    @Published var isLoginLoading = false
    @Published var loginError = ""
    
    // GPS States
    @Published var isGpsEnabled = false
    @Published var currentLat = 30.0444 // Cairo
    @Published var currentLng = 31.2357
    @Published var gpsPointsCount = 0
    
    // UI Lists
    @Published var customers = [CustomerRecord]()
    @Published var products = [ProductRecord]()
    @Published var salesOrders = [SalesOrderRecord]()
    @Published var payments = [PaymentRecord]()
    @Published var notifications = [NotificationRecord]()
    
    // Sync & UI helper States
    @Published var isSyncing = false
    @Published var pendingSyncCount = 0
    @Published var customerSearchQuery = ""
    @Published var productSearchQuery = ""
    @Published var orderFilter = "all" // "all", "today", "week", "month"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkSession()
        loadLocalData()

        // Monitor network status
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        pathMonitor.start(queue: DispatchQueue.global(qos: .background))

        
        // Monitor GPS coordinator changes from LocationManager
        LocationManager.shared.$lastLocation
            .sink { [weak self] location in
                guard let self = self, let loc = location else { return }
                self.currentLat = loc.coordinate.latitude
                self.currentLng = loc.coordinate.longitude
                self.updateGpsStats()
            }
            .store(in: &cancellables)
            
        // Monitor tracking state
        LocationManager.shared.$isTrackingActive
            .sink { [weak self] active in
                self?.isGpsEnabled = active
            }
            .store(in: &cancellables)
    }
    
    func checkSession() {
        let defaults = UserDefaults.standard
        if let username = defaults.string(forKey: "username"),
           defaults.bool(forKey: "verified_delegate") {
            if let user = db.getUserByUsername(username: username) {
                self.currentUser = user
                self.isLoggedIn = true
                
                // Resume GPS tracking if was enabled
                let gpsSaved = defaults.bool(forKey: "gps_tracking")
                self.isGpsEnabled = gpsSaved
                if gpsSaved {
                    LocationManager.shared.startTracking()
                }
            }
        }
    }
    
    func loadLocalData() {
        self.customers = db.getAllCustomers()
        self.products = db.getAllProducts()
        self.salesOrders = db.getAllSalesOrders()
        self.payments = db.getAllPayments()
        self.notifications = db.getAllNotifications()
        self.updatePendingSyncCount()
        self.updateGpsStats()
    }
    
    func updatePendingSyncCount() {
        self.pendingSyncCount = db.getUnsyncedCount()
    }
    
    func updateGpsStats() {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let timestamp = Int64(todayStart.timeIntervalSince1970 * 1000)
        self.gpsPointsCount = db.getTodayLocationsCount(todayStart: timestamp)
        self.updatePendingSyncCount()
    }
    
    // --- Login ---
    
    func login(username: String, pass: String) async {
        isLoginLoading = true
        loginError = ""
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let uid = await client.authenticateDelegate(username: trimmedUser, pass: pass) else {
            // Online failed, try offline authentication
            if let localUser = db.getUserByUsername(username: trimmedUser),
               localUser.passwordHash == pass,
               UserDefaults.standard.string(forKey: "username") == trimmedUser,
               UserDefaults.standard.bool(forKey: "verified_delegate") {
                
                self.currentUser = localUser
                self.isLoggedIn = true
                self.isGpsEnabled = true
                LocationManager.shared.startTracking()
                isLoginLoading = false
                return
            }
            
            loginError = "اسم المستخدم أو كلمة المرور غير صحيحة"
            isLoginLoading = false
            return
        }
        
        // Online login succeeded. Now verify if active delegate
        let isActive = await client.checkIsActiveDelegate(uid: uid)
        guard isActive else {
            loginError = "هذا الحساب غير مفعّل كمندوب. تواصل مع المدير."
            isLoginLoading = false
            return
        }
        
        // Success
        let localUser = UserRecord(
            id: 0,
            username: trimmedUser,
            passwordHash: pass,
            name: "مندوب: \(trimmedUser)",
            phone: "",
            region: "",
            role: "delegate",
            isActive: true,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        
        _ = db.insertUser(user: localUser)
        let user = db.getUserByUsername(username: trimmedUser)
        
        self.currentUser = user
        self.isLoggedIn = true
        
        let defaults = UserDefaults.standard
        defaults.set(trimmedUser, forKey: "username")
        defaults.set(pass, forKey: "password")
        defaults.set(uid, forKey: "odoo_uid")
        defaults.set(true, forKey: "gps_tracking")
        defaults.set(true, forKey: "verified_delegate")
        
        self.isGpsEnabled = true
        LocationManager.shared.startTracking()
        
        loadLocalData()
        isLoginLoading = false
    }
    
    func logout() {
        LocationManager.shared.stopTracking()
        isGpsEnabled = false
        currentUser = nil
        isLoggedIn = false
        
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "username")
        defaults.removeObject(forKey: "password")
        defaults.removeObject(forKey: "odoo_uid")
        defaults.set(false, forKey: "gps_tracking")
        defaults.set(false, forKey: "verified_delegate")
        
        db.clearAllData()
        loadLocalData()
    }
    
    func toggleGpsTracking(enabled: Bool) {
        isGpsEnabled = enabled
        if enabled {
            LocationManager.shared.startTracking()
        } else {
            LocationManager.shared.stopTracking()
        }
    }
    
    // --- Data Modifications (Offline First) ---
    
    func addCustomer(name: String, address: String, phone: String, email: String, region: String, notes: String) {
        let record = CustomerRecord(
            id: 0,
            odooId: nil,
            name: name,
            address: address,
            phone: phone,
            email: email,
            balance: 0.0,
            isSynced: false,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        _ = db.insertCustomer(c: record)
        db.insertNotification(title: "عميل جديد محلي", body: "تم إضافة العميل \(name) محلياً وهو في انتظار المزامنة.")
        loadLocalData()
    }
    
    func updateCustomer(id: Int64, name: String, address: String, phone: String, email: String, region: String, notes: String) {
        guard let existing = db.getCustomerById(id) else { return }
        let record = CustomerRecord(
            id: id,
            odooId: existing.odooId,
            name: name,
            address: address,
            phone: phone,
            email: email,
            balance: existing.balance,
            isSynced: false,
            createdAt: existing.createdAt
        )
        _ = db.updateCustomer(c: record)
        loadLocalData()
    }
    
    func createSalesOrder(customerId: Int64, customerName: String, items: [OdooOrderItem], notes: String) {
        var subtotal = 0.0
        var itemList = [SalesOrderItemRecord]()
        
        for item in items {
            let total = Double(item.quantity) * item.unitPrice
            subtotal += total
            let itemRecord = SalesOrderItemRecord(
                id: 0,
                orderId: 0,
                productId: Int64(item.productOdooId), // Map product ID
                productName: "صنف #\(item.productOdooId)",
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                total: total
            )
            itemList.append(itemRecord)
        }
        
        let tax = subtotal * 0.14
        let grandTotal = subtotal + tax
        
        let order = SalesOrderRecord(
            id: 0,
            odooId: nil,
            customerId: customerId,
            customerName: customerName,
            date: Int64(Date().timeIntervalSince1970 * 1000),
            subtotal: subtotal,
            tax: tax,
            grandTotal: grandTotal,
            status: "draft",
            notes: notes,
            isSynced: false,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        
        _ = db.insertSalesOrder(o: order, items: itemList)
        db.insertNotification(title: "أمر بيع جديد", body: "تم إنشاء فاتورة للعميل \(customerName) بقيمة \(String(format: "%.2f", grandTotal)) ج.م.")
        loadLocalData()
    }
    
    func createPayment(customerId: Int64, customerName: String, amount: Double, method: String, checkNum: String, checkDate: Date, notes: String) {
        let payment = PaymentRecord(
            id: 0,
            odooId: nil,
            customerId: customerId,
            customerName: customerName,
            amount: amount,
            method: method,
            checkNumber: checkNum,
            checkDate: Int64(checkDate.timeIntervalSince1970 * 1000),
            notes: notes,
            date: Int64(Date().timeIntervalSince1970 * 1000),
            isSynced: false,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        
        _ = db.insertPayment(p: payment)
        db.insertNotification(title: "سند قبض جديد", body: "تم تحصيل مبلغ \(String(format: "%.2f", amount)) ج.م من العميل \(customerName).")
        loadLocalData()
    }
    
    // --- Synchronization Engine ---
    
    func syncPendingRecords() async {
        guard !isSyncing else { return }
        isSyncing = true
        
        let defaults = UserDefaults.standard
        let odooUsername = defaults.string(forKey: "username") ?? ""
        let odooPassword = defaults.string(forKey: "password") ?? ""
        var delegateOdooUid = defaults.integer(forKey: "odoo_uid")
        
        db.insertNotification(title: "بدء المزامنة", body: "جاري الاتصال بسيرفر Odoo وبدء مزامنة البيانات...")
        
        guard let uid = await client.authenticateDelegate(username: odooUsername, pass: odooPassword) else {
            db.insertNotification(title: "فشل الاتصال", body: "فشل الاتصال بـ Odoo. تحقق من الشبكة وبيانات الدخول.")
            isSyncing = false
            return
        }
        
        delegateOdooUid = uid
        defaults.set(uid, forKey: "odoo_uid")
        
        // 0. Sync GPS Locations
        let unsyncedLocations = db.getUnsyncedLocations()
        if !unsyncedLocations.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            
            let uploadInputs = unsyncedLocations.map { loc in
                let dateStr = formatter.string(from: Date(timeIntervalSince1970: Double(loc.timestamp) / 1000))
                return OdooLocationInput(
                    latitude: loc.latitude,
                    longitude: loc.longitude,
                    timestamp: dateStr,
                    batteryLevel: loc.batteryLevel,
                    speed: Double(loc.speed)
                )
            }
            
            let locsSuccess = await client.uploadLocations(uid: uid, pass: odooPassword, locations: uploadInputs)
            if locsSuccess {
                for loc in unsyncedLocations {
                    db.markLocationAsSynced(id: loc.id)
                }
            }
        }
        
        // 1. Sync Sales Orders
        let unsyncedOrders = db.getUnsyncedOrders()
        var ordersSyncedCount = 0
        for localOrder in unsyncedOrders {
            guard let customer = db.getCustomerById(localOrder.customerId) else { continue }
            let customerOdooId = customer.odooId
            
            let items = db.getSalesOrderItems(orderId: localOrder.id)
            let odooItems = items.map { item in
                OdooOrderItem(productOdooId: Int(item.productId), quantity: item.quantity, unitPrice: item.unitPrice)
            }
            
            if let customerId = customerOdooId, !odooItems.isEmpty {
                let orderOdooId = await client.createSaleOrder(
                    uid: uid,
                    customerOdooId: customerId,
                    items: odooItems,
                    notes: localOrder.notes,
                    salespersonId: delegateOdooUid
                )
                
                if let oId = orderOdooId {
                    db.updateSalesOrderSync(id: localOrder.id, odooId: oId)
                    ordersSyncedCount += 1
                }
            }
        }
        
        // 2. Sync Payments
        let unsyncedPayments = db.getUnsyncedPayments()
        var paymentsSyncedCount = 0
        for localPayment in unsyncedPayments {
            guard let customer = db.getCustomerById(localPayment.customerId),
                  let customerId = customer.odooId else { continue }
            
            let memo = "\(localPayment.notes) (مستند محلي #\(localPayment.id))"
            let paymentOdooId = await client.createPayment(
                uid: uid,
                customerOdooId: customerId,
                amount: localPayment.amount,
                notes: memo
            )
            
            if let pId = paymentOdooId {
                db.updatePaymentSync(id: localPayment.id, odooId: pId)
                paymentsSyncedCount += 1
            }
        }
        
        // 3. Fetch Updated Customers
        let odooCustomers = await client.getCustomers(uid: uid)
        for oc in odooCustomers {
            if let existing = db.getCustomerByOdooId(oc.odooId) {
                _ = db.updateCustomer(c: CustomerRecord(
                    id: existing.id,
                    odooId: oc.odooId,
                    name: oc.name,
                    address: oc.address,
                    phone: oc.phone,
                    email: oc.email,
                    balance: oc.balance,
                    isSynced: true,
                    createdAt: existing.createdAt
                ))
            } else {
                _ = db.insertCustomer(c: CustomerRecord(
                    id: 0,
                    odooId: oc.odooId,
                    name: oc.name,
                    address: oc.address,
                    phone: oc.phone,
                    email: oc.email,
                    balance: oc.balance,
                    isSynced: true,
                    createdAt: Int64(Date().timeIntervalSince1970 * 1000)
                ))
            }
        }
        
        // 4. Fetch Updated Products
        let odooProducts = await client.getProducts(uid: uid)
        for op in odooProducts {
            if let existing = db.getProductByOdooId(op.odooId) {
                _ = db.updateProduct(p: ProductRecord(
                    id: existing.id,
                    odooId: op.odooId,
                    name: op.name,
                    sku: op.sku,
                    price: op.price,
                    stockQty: op.stockQty,
                    category: op.category,
                    unit: op.unit,
                    isSynced: true
                ))
            } else {
                _ = db.insertProduct(p: ProductRecord(
                    id: 0,
                    odooId: op.odooId,
                    name: op.name,
                    sku: op.sku,
                    price: op.price,
                    stockQty: op.stockQty,
                    category: op.category,
                    unit: op.unit,
                    isSynced: true
                ))
            }
        }
        
        db.insertNotification(
            title: "مزامنة Odoo ناجحة",
            body: "تم بنجاح رفع عدد \(ordersSyncedCount) فواتير و \(paymentsSyncedCount) مدفوعات، وتحديث المنتجات والعملاء من أودو."
        )
        loadLocalData()
        
        isSyncing = false
    }
    
    func markAllNotificationsAsRead() {
        db.markAllNotificationsAsRead()
        loadLocalData()
    }
    
    func markNotificationAsRead(id: Int64) {
        db.markNotificationAsRead(id: id)
        loadLocalData()
    }
}
