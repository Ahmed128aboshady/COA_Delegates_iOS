import Foundation
import SQLite3

// Database struct declarations
struct UserRecord {
    let id: Int64
    let username: String
    let passwordHash: String
    let name: String
    let phone: String
    let region: String
    let role: String
    let isActive: Bool
    let createdAt: Int64
}

struct CustomerRecord: Identifiable {
    let id: Int64
    let odooId: Int?
    let name: String
    let address: String
    let phone: String
    let email: String
    let balance: Double
    let isSynced: Bool
    let createdAt: Int64
}

struct ProductRecord: Identifiable {
    let id: Int64
    let odooId: Int?
    let name: String
    let sku: String
    let price: Double
    let stockQty: Int
    let category: String
    let unit: String
    let isSynced: Bool
}

struct SalesOrderRecord: Identifiable {
    let id: Int64
    let odooId: Int?
    let customerId: Int64
    let customerName: String
    let date: Int64
    let subtotal: Double
    let tax: Double
    let grandTotal: Double
    let status: String // "draft", "confirmed", "synced"
    let notes: String
    let isSynced: Bool
    let createdAt: Int64
}

struct SalesOrderItemRecord: Identifiable {
    let id: Int64
    let orderId: Int64
    let productId: Int64
    let productName: String
    let quantity: Int
    let unitPrice: Double
    let total: Double
}

struct PaymentRecord: Identifiable {
    let id: Int64
    let odooId: Int?
    let customerId: Int64
    let customerName: String
    let amount: Double
    let method: String
    let checkNumber: String
    let checkDate: Int64
    let notes: String
    let date: Int64
    let isSynced: Bool
    let createdAt: Int64
}

struct GpsLocationRecord: Identifiable {
    let id: Int64
    let latitude: Double
    let longitude: Double
    let accuracy: Float
    let speed: Float
    let timestamp: Int64
    let batteryLevel: Int
    let connectionType: String
    let isSynced: Bool
}

struct NotificationRecord: Identifiable {
    let id: Int64
    let title: String
    let body: String
    let date: Int64
    let isRead: Bool
}

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?

    private func readString(_ stmt: OpaquePointer?, _ col: Int32) -> String {
        if let ptr = sqlite3_column_text(stmt, col) {
            return String(cString: ptr)
        }
        return ""
    }

    
    private init() {
        openDatabase()
        createTables()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    private func openDatabase() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to find documents directory.")
            return
        }
        let dbURL = documentsURL.appendingPathComponent("coa_delegates_db.sqlite")
        
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        } else {
            print("Successfully opened database at \(dbURL.path)")
        }
    }
    
    private func executeNonQuery(sql: String) -> Bool {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("Error preparing query: \(errmsg)")
            return false
        }
        
        let result = sqlite3_step(statement) == SQLITE_DONE
        sqlite3_finalize(statement)
        return result
    }
    
    private func createTables() {
        // Users Table
        _ = executeNonQuery(sql: """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE,
                passwordHash TEXT,
                name TEXT,
                phone TEXT,
                region TEXT,
                role TEXT,
                isActive INTEGER,
                createdAt INTEGER
            );
        """)
        
        // Customers Table
        _ = executeNonQuery(sql: """
            CREATE TABLE IF NOT EXISTS customers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                odooId INTEGER,
                name TEXT,
                address TEXT,
                phone TEXT,
                email TEXT,
                balance REAL,
                isSynced INTEGER,
                createdAt INTEGER
            );
        """)
        
        // Products Table
        _ = executeNonQuery(sql: """
            CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                odooId INTEGER,
                name TEXT,
                sku TEXT,
                price REAL,
                stockQty INTEGER,
                category TEXT,
                unit TEXT,
                isSynced INTEGER
            );
        """)
        
        // Sales Orders Table
        _ = executeNonQuery(sql: """
            CREATE TABLE IF NOT EXISTS sales_orders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                odooId INTEGER,
                customerId INTEGER,
                customerName TEXT,
                date INTEGER,
                subtotal REAL,
                tax REAL,
                grandTotal REAL,
                status TEXT,
                notes TEXT,
                isSynced INTEGER,
                createdAt INTEGER
            );
        """)
        
        // Sales Order Items Table
        _ = executeNonQuery(sql: """
            CREATE TABLE IF NOT EXISTS sales_order_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                orderId INTEGER,
                productId INTEGER,
                productName TEXT,
                quantity INTEGER,
                unitPrice REAL,
                total REAL
            );
        """)
        
        // Payments Table
        _ = executeNonQuery(sql: """
            CREATE TABLE IF NOT EXISTS payments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                odooId INTEGER,
                customerId INTEGER,
                customerName TEXT,
                amount REAL,
                method TEXT,
                checkNumber TEXT,
                checkDate INTEGER,
                notes TEXT,
                date INTEGER,
                isSynced INTEGER,
                createdAt INTEGER
            );
        """)
        
        // GPS Locations Table
        _ = executeNonQuery(sql: """
            CREATE TABLE IF NOT EXISTS gps_locations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                latitude REAL,
                longitude REAL,
                accuracy REAL,
                speed REAL,
                timestamp INTEGER,
                batteryLevel INTEGER,
                connectionType TEXT,
                isSynced INTEGER
            );
        """)
        
        // Notifications Table
        _ = executeNonQuery(sql: """
            CREATE TABLE IF NOT EXISTS notifications (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT,
                body TEXT,
                date INTEGER,
                isRead INTEGER
            );
        """)
    }
    
    // --- User DAO Methods ---
    
    func insertUser(user: UserRecord) -> Bool {
        let sql = "INSERT OR REPLACE INTO users (username, passwordHash, name, phone, region, role, isActive, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        
        sqlite3_bind_text(stmt, 1, (user.username as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (user.passwordHash as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (user.name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (user.phone as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 5, (user.region as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 6, (user.role as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 7, user.isActive ? 1 : 0)
        sqlite3_bind_int64(stmt, 8, user.createdAt)
        
        let success = sqlite3_step(stmt) == SQLITE_DONE
        sqlite3_finalize(stmt)
        return success
    }
    
    func getUserByUsername(username: String) -> UserRecord? {
        let sql = "SELECT id, username, passwordHash, name, phone, region, role, isActive, createdAt FROM users WHERE username = ? LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        
        sqlite3_bind_text(stmt, 1, (username as NSString).utf8String, -1, nil)
        
        var user: UserRecord?
        if sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let username = readString(stmt, 1)
            let passwordHash = readString(stmt, 2)
            let name = readString(stmt, 3)
            let phone = readString(stmt, 4)
            let region = readString(stmt, 5)
            let role = readString(stmt, 6)
            let isActive = sqlite3_column_int(stmt, 7) == 1
            let createdAt = sqlite3_column_int64(stmt, 8)
            
            user = UserRecord(id: id, username: username, passwordHash: passwordHash, name: name, phone: phone, region: region, role: role, isActive: isActive, createdAt: createdAt)
        }
        
        sqlite3_finalize(stmt)
        return user
    }
    
    // --- Customers DAO Methods ---
    
    func insertCustomer(c: CustomerRecord) -> Bool {
        let sql = "INSERT OR REPLACE INTO customers (odooId, name, address, phone, email, balance, isSynced, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        
        if let oId = c.odooId {
            sqlite3_bind_int(stmt, 1, Int32(oId))
        } else {
            sqlite3_bind_null(stmt, 1)
        }
        sqlite3_bind_text(stmt, 2, (c.name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (c.address as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (c.phone as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 5, (c.email as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 6, c.balance)
        sqlite3_bind_int(stmt, 7, c.isSynced ? 1 : 0)
        sqlite3_bind_int64(stmt, 8, c.createdAt)
        
        let success = sqlite3_step(stmt) == SQLITE_DONE
        sqlite3_finalize(stmt)
        return success
    }
    
    func getAllCustomers() -> [CustomerRecord] {
        let sql = "SELECT id, odooId, name, address, phone, email, balance, isSynced, createdAt FROM customers ORDER BY name ASC;"
        var stmt: OpaquePointer?
        var list = [CustomerRecord]()
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let odooId = sqlite3_column_type(stmt, 1) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 1))
            let name = readString(stmt, 2)
            let address = readString(stmt, 3)
            let phone = readString(stmt, 4)
            let email = readString(stmt, 5)
            let balance = sqlite3_column_double(stmt, 6)
            let isSynced = sqlite3_column_int(stmt, 7) == 1
            let createdAt = sqlite3_column_int64(stmt, 8)
            
            list.append(CustomerRecord(id: id, odooId: odooId, name: name, address: address, phone: phone, email: email, balance: balance, isSynced: isSynced, createdAt: createdAt))
        }
        
        sqlite3_finalize(stmt)
        return list
    }
    
    func getCustomerById(_ id: Int64) -> CustomerRecord? {
        let sql = "SELECT id, odooId, name, address, phone, email, balance, isSynced, createdAt FROM customers WHERE id = ? LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        
        sqlite3_bind_int64(stmt, 1, id)
        
        var record: CustomerRecord?
        if sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let odooId = sqlite3_column_type(stmt, 1) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 1))
            let name = readString(stmt, 2)
            let address = readString(stmt, 3)
            let phone = readString(stmt, 4)
            let email = readString(stmt, 5)
            let balance = sqlite3_column_double(stmt, 6)
            let isSynced = sqlite3_column_int(stmt, 7) == 1
            let createdAt = sqlite3_column_int64(stmt, 8)
            
            record = CustomerRecord(id: id, odooId: odooId, name: name, address: address, phone: phone, email: email, balance: balance, isSynced: isSynced, createdAt: createdAt)
        }
        sqlite3_finalize(stmt)
        return record
    }
    
    func getCustomerByOdooId(_ odooId: Int) -> CustomerRecord? {
        let sql = "SELECT id, odooId, name, address, phone, email, balance, isSynced, createdAt FROM customers WHERE odooId = ? LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        
        sqlite3_bind_int(stmt, 1, Int32(odooId))
        
        var record: CustomerRecord?
        if sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let odooIdVal = Int(sqlite3_column_int(stmt, 1))
            let name = readString(stmt, 2)
            let address = readString(stmt, 3)
            let phone = readString(stmt, 4)
            let email = readString(stmt, 5)
            let balance = sqlite3_column_double(stmt, 6)
            let isSynced = sqlite3_column_int(stmt, 7) == 1
            let createdAt = sqlite3_column_int64(stmt, 8)
            
            record = CustomerRecord(id: id, odooId: odooIdVal, name: name, address: address, phone: phone, email: email, balance: balance, isSynced: isSynced, createdAt: createdAt)
        }
        sqlite3_finalize(stmt)
        return record
    }
    
    func updateCustomerOdooId(id: Int64, odooId: Int) {
        _ = executeNonQuery(sql: "UPDATE customers SET odooId = \(odooId), isSynced = 1 WHERE id = \(id)")
    }
    
    func updateCustomer(c: CustomerRecord) -> Bool {
        let sql = "UPDATE customers SET name=?, address=?, phone=?, email=?, balance=?, isSynced=? WHERE id=?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        
        sqlite3_bind_text(stmt, 1, (c.name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (c.address as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (c.phone as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (c.email as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 5, c.balance)
        sqlite3_bind_int(stmt, 6, c.isSynced ? 1 : 0)
        sqlite3_bind_int64(stmt, 7, c.id)
        
        let success = sqlite3_step(stmt) == SQLITE_DONE
        sqlite3_finalize(stmt)
        return success
    }
    
    // --- Products DAO Methods ---
    
    func insertProduct(p: ProductRecord) -> Bool {
        let sql = "INSERT OR REPLACE INTO products (odooId, name, sku, price, stockQty, category, unit, isSynced) VALUES (?, ?, ?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        
        if let oId = p.odooId {
            sqlite3_bind_int(stmt, 1, Int32(oId))
        } else {
            sqlite3_bind_null(stmt, 1)
        }
        sqlite3_bind_text(stmt, 2, (p.name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (p.sku as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 4, p.price)
        sqlite3_bind_int(stmt, 5, Int32(p.stockQty))
        sqlite3_bind_text(stmt, 6, (p.category as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 7, (p.unit as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 8, p.isSynced ? 1 : 0)
        
        let success = sqlite3_step(stmt) == SQLITE_DONE
        sqlite3_finalize(stmt)
        return success
    }
    
    func getAllProducts() -> [ProductRecord] {
        let sql = "SELECT id, odooId, name, sku, price, stockQty, category, unit, isSynced FROM products ORDER BY name ASC;"
        var stmt: OpaquePointer?
        var list = [ProductRecord]()
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let odooId = sqlite3_column_type(stmt, 1) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 1))
            let name = readString(stmt, 2)
            let sku = readString(stmt, 3)
            let price = sqlite3_column_double(stmt, 4)
            let stockQty = Int(sqlite3_column_int(stmt, 5))
            let category = readString(stmt, 6)
            let unit = readString(stmt, 7)
            let isSynced = sqlite3_column_int(stmt, 8) == 1
            
            list.append(ProductRecord(id: id, odooId: odooId, name: name, sku: sku, price: price, stockQty: stockQty, category: category, unit: unit, isSynced: isSynced))
        }
        
        sqlite3_finalize(stmt)
        return list
    }
    
    func getProductById(_ id: Int64) -> ProductRecord? {
        let sql = "SELECT id, odooId, name, sku, price, stockQty, category, unit, isSynced FROM products WHERE id = ? LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        
        sqlite3_bind_int64(stmt, 1, id)
        
        var record: ProductRecord?
        if sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let odooId = sqlite3_column_type(stmt, 1) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 1))
            let name = readString(stmt, 2)
            let sku = readString(stmt, 3)
            let price = sqlite3_column_double(stmt, 4)
            let stockQty = Int(sqlite3_column_int(stmt, 5))
            let category = readString(stmt, 6)
            let unit = readString(stmt, 7)
            let isSynced = sqlite3_column_int(stmt, 8) == 1
            
            record = ProductRecord(id: id, odooId: odooId, name: name, sku: sku, price: price, stockQty: stockQty, category: category, unit: unit, isSynced: isSynced)
        }
        sqlite3_finalize(stmt)
        return record
    }
    
    func getProductByOdooId(_ odooId: Int) -> ProductRecord? {
        let sql = "SELECT id, odooId, name, sku, price, stockQty, category, unit, isSynced FROM products WHERE odooId = ? LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        
        sqlite3_bind_int(stmt, 1, Int32(odooId))
        
        var record: ProductRecord?
        if sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let odooIdVal = Int(sqlite3_column_int(stmt, 1))
            let name = readString(stmt, 2)
            let sku = readString(stmt, 3)
            let price = sqlite3_column_double(stmt, 4)
            let stockQty = Int(sqlite3_column_int(stmt, 5))
            let category = readString(stmt, 6)
            let unit = readString(stmt, 7)
            let isSynced = sqlite3_column_int(stmt, 8) == 1
            
            record = ProductRecord(id: id, odooId: odooIdVal, name: name, sku: sku, price: price, stockQty: stockQty, category: category, unit: unit, isSynced: isSynced)
        }
        sqlite3_finalize(stmt)
        return record
    }
    
    func updateProduct(p: ProductRecord) -> Bool {
        let sql = "UPDATE products SET name=?, sku=?, price=?, stockQty=?, category=?, unit=?, isSynced=? WHERE id=?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        
        sqlite3_bind_text(stmt, 1, (p.name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (p.sku as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 3, p.price)
        sqlite3_bind_int(stmt, 4, Int32(p.stockQty))
        sqlite3_bind_text(stmt, 5, (p.category as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 6, (p.unit as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 7, p.isSynced ? 1 : 0)
        sqlite3_bind_int64(stmt, 8, p.id)
        
        let success = sqlite3_step(stmt) == SQLITE_DONE
        sqlite3_finalize(stmt)
        return success
    }
    
    // --- Sales Orders DAO Methods ---
    
    func insertSalesOrder(o: SalesOrderRecord, items: [SalesOrderItemRecord]) -> Int64 {
        let sql = "INSERT INTO sales_orders (odooId, customerId, customerName, date, subtotal, tax, grandTotal, status, notes, isSynced, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        
        if let oId = o.odooId {
            sqlite3_bind_int(stmt, 1, Int32(oId))
        } else {
            sqlite3_bind_null(stmt, 1)
        }
        sqlite3_bind_int64(stmt, 2, o.customerId)
        sqlite3_bind_text(stmt, 3, (o.customerName as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(stmt, 4, o.date)
        sqlite3_bind_double(stmt, 5, o.subtotal)
        sqlite3_bind_double(stmt, 6, o.tax)
        sqlite3_bind_double(stmt, 7, o.grandTotal)
        sqlite3_bind_text(stmt, 8, (o.status as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 9, (o.notes as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 10, o.isSynced ? 1 : 0)
        sqlite3_bind_int64(stmt, 11, o.createdAt)
        
        var orderId: Int64 = 0
        if sqlite3_step(stmt) == SQLITE_DONE {
            orderId = sqlite3_last_insert_rowid(db)
            
            // Insert Items
            for item in items {
                let itemSql = "INSERT INTO sales_order_items (orderId, productId, productName, quantity, unitPrice, total) VALUES (?, ?, ?, ?, ?, ?);"
                var itemStmt: OpaquePointer?
                if sqlite3_prepare_v2(db, itemSql, -1, &itemStmt, nil) == SQLITE_OK {
                    sqlite3_bind_int64(itemStmt, 1, orderId)
                    sqlite3_bind_int64(itemStmt, 2, item.productId)
                    sqlite3_bind_text(itemStmt, 3, (item.productName as NSString).utf8String, -1, nil)
                    sqlite3_bind_int(itemStmt, 4, Int32(item.quantity))
                    sqlite3_bind_double(itemStmt, 5, item.unitPrice)
                    sqlite3_bind_double(itemStmt, 6, item.total)
                    sqlite3_step(itemStmt)
                    sqlite3_finalize(itemStmt)
                }
            }
        }
        
        sqlite3_finalize(stmt)
        return orderId
    }
    
    func getAllSalesOrders() -> [SalesOrderRecord] {
        let sql = "SELECT id, odooId, customerId, customerName, date, subtotal, tax, grandTotal, status, notes, isSynced, createdAt FROM sales_orders ORDER BY date DESC;"
        var stmt: OpaquePointer?
        var list = [SalesOrderRecord]()
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let odooId = sqlite3_column_type(stmt, 1) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 1))
            let customerId = sqlite3_column_int64(stmt, 2)
            let customerName = readString(stmt, 3)
            let date = sqlite3_column_int64(stmt, 4)
            let subtotal = sqlite3_column_double(stmt, 5)
            let tax = sqlite3_column_double(stmt, 6)
            let grandTotal = sqlite3_column_double(stmt, 7)
            let status = readString(stmt, 8)
            let notes = readString(stmt, 9)
            let isSynced = sqlite3_column_int(stmt, 10) == 1
            let createdAt = sqlite3_column_int64(stmt, 11)
            
            list.append(SalesOrderRecord(id: id, odooId: odooId, customerId: customerId, customerName: customerName, date: date, subtotal: subtotal, tax: tax, grandTotal: grandTotal, status: status, notes: notes, isSynced: isSynced, createdAt: createdAt))
        }
        
        sqlite3_finalize(stmt)
        return list
    }
    
    func getSalesOrderItems(orderId: Int64) -> [SalesOrderItemRecord] {
        let sql = "SELECT id, orderId, productId, productName, quantity, unitPrice, total FROM sales_order_items WHERE orderId = ?;"
        var stmt: OpaquePointer?
        var list = [SalesOrderItemRecord]()
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_int64(stmt, 1, orderId)
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let orderIdVal = sqlite3_column_int64(stmt, 1)
            let productId = sqlite3_column_int64(stmt, 2)
            let productName = readString(stmt, 3)
            let quantity = Int(sqlite3_column_int(stmt, 4))
            let unitPrice = sqlite3_column_double(stmt, 5)
            let total = sqlite3_column_double(stmt, 6)
            
            list.append(SalesOrderItemRecord(id: id, orderId: orderIdVal, productId: productId, productName: productName, quantity: quantity, unitPrice: unitPrice, total: total))
        }
        
        sqlite3_finalize(stmt)
        return list
    }
    
    func getUnsyncedOrders() -> [SalesOrderRecord] {
        let sql = "SELECT id, odooId, customerId, customerName, date, subtotal, tax, grandTotal, status, notes, isSynced, createdAt FROM sales_orders WHERE isSynced = 0;"
        var stmt: OpaquePointer?
        var list = [SalesOrderRecord]()
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let odooId = sqlite3_column_type(stmt, 1) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 1))
            let customerId = sqlite3_column_int64(stmt, 2)
            let customerName = readString(stmt, 3)
            let date = sqlite3_column_int64(stmt, 4)
            let subtotal = sqlite3_column_double(stmt, 5)
            let tax = sqlite3_column_double(stmt, 6)
            let grandTotal = sqlite3_column_double(stmt, 7)
            let status = readString(stmt, 8)
            let notes = readString(stmt, 9)
            let isSynced = sqlite3_column_int(stmt, 10) == 1
            let createdAt = sqlite3_column_int64(stmt, 11)
            
            list.append(SalesOrderRecord(id: id, odooId: odooId, customerId: customerId, customerName: customerName, date: date, subtotal: subtotal, tax: tax, grandTotal: grandTotal, status: status, notes: notes, isSynced: isSynced, createdAt: createdAt))
        }
        
        sqlite3_finalize(stmt)
        return list
    }
    
    func updateSalesOrderSync(id: Int64, odooId: Int) {
        _ = executeNonQuery(sql: "UPDATE sales_orders SET odooId = \(odooId), isSynced = 1, status = 'synced' WHERE id = \(id)")
    }
    
    // --- Payments DAO Methods ---
    
    func insertPayment(p: PaymentRecord) -> Bool {
        let sql = "INSERT INTO payments (odooId, customerId, customerName, amount, method, checkNumber, checkDate, notes, date, isSynced, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        
        if let oId = p.odooId {
            sqlite3_bind_int(stmt, 1, Int32(oId))
        } else {
            sqlite3_bind_null(stmt, 1)
        }
        sqlite3_bind_int64(stmt, 2, p.customerId)
        sqlite3_bind_text(stmt, 3, (p.customerName as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 4, p.amount)
        sqlite3_bind_text(stmt, 5, (p.method as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 6, (p.checkNumber as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(stmt, 7, p.checkDate)
        sqlite3_bind_text(stmt, 8, (p.notes as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(stmt, 9, p.date)
        sqlite3_bind_int(stmt, 10, p.isSynced ? 1 : 0)
        sqlite3_bind_int64(stmt, 11, p.createdAt)
        
        let success = sqlite3_step(stmt) == SQLITE_DONE
        sqlite3_finalize(stmt)
        return success
    }
    
    func getAllPayments() -> [PaymentRecord] {
        let sql = "SELECT id, odooId, customerId, customerName, amount, method, checkNumber, checkDate, notes, date, isSynced, createdAt FROM payments ORDER BY date DESC;"
        var stmt: OpaquePointer?
        var list = [PaymentRecord]()
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let odooId = sqlite3_column_type(stmt, 1) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 1))
            let customerId = sqlite3_column_int64(stmt, 2)
            let customerName = readString(stmt, 3)
            let amount = sqlite3_column_double(stmt, 4)
            let method = readString(stmt, 5)
            let checkNumber = readString(stmt, 6)
            let checkDate = sqlite3_column_int64(stmt, 7)
            let notes = readString(stmt, 8)
            let date = sqlite3_column_int64(stmt, 9)
            let isSynced = sqlite3_column_int(stmt, 10) == 1
            let createdAt = sqlite3_column_int64(stmt, 11)
            
            list.append(PaymentRecord(id: id, odooId: odooId, customerId: customerId, customerName: customerName, amount: amount, method: method, checkNumber: checkNumber, checkDate: checkDate, notes: notes, date: date, isSynced: isSynced, createdAt: createdAt))
        }
        sqlite3_finalize(stmt)
        return list
    }
    
    func getUnsyncedPayments() -> [PaymentRecord] {
        let sql = "SELECT id, odooId, customerId, customerName, amount, method, checkNumber, checkDate, notes, date, isSynced, createdAt FROM payments WHERE isSynced = 0;"
        var stmt: OpaquePointer?
        var list = [PaymentRecord]()
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let odooId = sqlite3_column_type(stmt, 1) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 1))
            let customerId = sqlite3_column_int64(stmt, 2)
            let customerName = readString(stmt, 3)
            let amount = sqlite3_column_double(stmt, 4)
            let method = readString(stmt, 5)
            let checkNumber = readString(stmt, 6)
            let checkDate = sqlite3_column_int64(stmt, 7)
            let notes = readString(stmt, 8)
            let date = sqlite3_column_int64(stmt, 9)
            let isSynced = sqlite3_column_int(stmt, 10) == 1
            let createdAt = sqlite3_column_int64(stmt, 11)
            
            list.append(PaymentRecord(id: id, odooId: odooId, customerId: customerId, customerName: customerName, amount: amount, method: method, checkNumber: checkNumber, checkDate: checkDate, notes: notes, date: date, isSynced: isSynced, createdAt: createdAt))
        }
        sqlite3_finalize(stmt)
        return list
    }
    
    func updatePaymentSync(id: Int64, odooId: Int) {
        _ = executeNonQuery(sql: "UPDATE payments SET odooId = \(odooId), isSynced = 1 WHERE id = \(id)")
    }
    
    // --- GPS Locations DAO Methods ---
    
    func insertLocation(loc: GpsLocationRecord) -> Bool {
        let sql = "INSERT INTO gps_locations (latitude, longitude, accuracy, speed, timestamp, batteryLevel, connectionType, isSynced) VALUES (?, ?, ?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        
        sqlite3_bind_double(stmt, 1, loc.latitude)
        sqlite3_bind_double(stmt, 2, loc.longitude)
        sqlite3_bind_double(stmt, 3, Double(loc.accuracy))
        sqlite3_bind_double(stmt, 4, Double(loc.speed))
        sqlite3_bind_int64(stmt, 5, loc.timestamp)
        sqlite3_bind_int(stmt, 6, Int32(loc.batteryLevel))
        sqlite3_bind_text(stmt, 7, (loc.connectionType as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 8, loc.isSynced ? 1 : 0)
        
        let success = sqlite3_step(stmt) == SQLITE_DONE
        sqlite3_finalize(stmt)
        return success
    }
    
    func getUnsyncedLocations() -> [GpsLocationRecord] {
        let sql = "SELECT id, latitude, longitude, accuracy, speed, timestamp, batteryLevel, connectionType, isSynced FROM gps_locations WHERE isSynced = 0 ORDER BY timestamp ASC;"
        var stmt: OpaquePointer?
        var list = [GpsLocationRecord]()
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let latitude = sqlite3_column_double(stmt, 1)
            let longitude = sqlite3_column_double(stmt, 2)
            let accuracy = Float(sqlite3_column_double(stmt, 3))
            let speed = Float(sqlite3_column_double(stmt, 4))
            let timestamp = sqlite3_column_int64(stmt, 5)
            let batteryLevel = Int(sqlite3_column_int(stmt, 6))
            let connectionType = readString(stmt, 7)
            let isSynced = sqlite3_column_int(stmt, 8) == 1
            
            list.append(GpsLocationRecord(id: id, latitude: latitude, longitude: longitude, accuracy: accuracy, speed: speed, timestamp: timestamp, batteryLevel: batteryLevel, connectionType: connectionType, isSynced: isSynced))
        }
        sqlite3_finalize(stmt)
        return list
    }
    
    func markLocationAsSynced(id: Int64) {
        _ = executeNonQuery(sql: "UPDATE gps_locations SET isSynced = 1 WHERE id = \(id)")
    }
    
    func getTodayLocationsCount(todayStart: Int64) -> Int {
        let sql = "SELECT COUNT(*) FROM gps_locations WHERE timestamp >= ?;"
        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, todayStart)
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }
    
    func getLatestLocation() -> GpsLocationRecord? {
        let sql = "SELECT id, latitude, longitude, accuracy, speed, timestamp, batteryLevel, connectionType, isSynced FROM gps_locations ORDER BY timestamp DESC LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        
        var record: GpsLocationRecord?
        if sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let latitude = sqlite3_column_double(stmt, 1)
            let longitude = sqlite3_column_double(stmt, 2)
            let accuracy = Float(sqlite3_column_double(stmt, 3))
            let speed = Float(sqlite3_column_double(stmt, 4))
            let timestamp = sqlite3_column_int64(stmt, 5)
            let batteryLevel = Int(sqlite3_column_int(stmt, 6))
            let connectionType = readString(stmt, 7)
            let isSynced = sqlite3_column_int(stmt, 8) == 1
            
            record = GpsLocationRecord(id: id, latitude: latitude, longitude: longitude, accuracy: accuracy, speed: speed, timestamp: timestamp, batteryLevel: batteryLevel, connectionType: connectionType, isSynced: isSynced)
        }
        sqlite3_finalize(stmt)
        return record
    }
    
    func getUnsyncedCount() -> Int {
        var count = 0
        let sql = "SELECT (SELECT COUNT(*) FROM sales_orders WHERE isSynced = 0) + (SELECT COUNT(*) FROM payments WHERE isSynced = 0) + (SELECT COUNT(*) FROM gps_locations WHERE isSynced = 0);"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }
    
    func clearAllData() {
        _ = executeNonQuery(sql: "DELETE FROM customers;")
        _ = executeNonQuery(sql: "DELETE FROM products;")
        _ = executeNonQuery(sql: "DELETE FROM sales_orders;")
        _ = executeNonQuery(sql: "DELETE FROM sales_order_items;")
        _ = executeNonQuery(sql: "DELETE FROM payments;")
        _ = executeNonQuery(sql: "DELETE FROM gps_locations;")
        _ = executeNonQuery(sql: "DELETE FROM notifications;")
    }
    
    // --- Notifications DAO ---
    
    func insertNotification(title: String, body: String) {
        let sql = "INSERT INTO notifications (title, body, date, isRead) VALUES (?, ?, ?, 0);"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (body as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 3, Int64(Date().timeIntervalSince1970 * 1000))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
    
    func getAllNotifications() -> [NotificationRecord] {
        let sql = "SELECT id, title, body, date, isRead FROM notifications ORDER BY date DESC;"
        var stmt: OpaquePointer?
        var list = [NotificationRecord]()
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let title = readString(stmt, 1)
            let body = readString(stmt, 2)
            let date = sqlite3_column_int64(stmt, 3)
            let isRead = sqlite3_column_int(stmt, 4) == 1
            
            list.append(NotificationRecord(id: id, title: title, body: body, date: date, isRead: isRead))
        }
        sqlite3_finalize(stmt)
        return list
    }
    
    func markNotificationAsRead(id: Int64) {
        _ = executeNonQuery(sql: "UPDATE notifications SET isRead = 1 WHERE id = \(id)")
    }
    
    func markAllNotificationsAsRead() {
        _ = executeNonQuery(sql: "UPDATE notifications SET isRead = 1")
    }
}
