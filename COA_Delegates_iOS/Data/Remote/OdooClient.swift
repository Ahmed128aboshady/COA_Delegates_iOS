import Foundation

struct OdooCustomer: Codable {
    let odooId: Int
    let name: String
    let address: String
    let phone: String
    let email: String
    let balance: Double
}

struct OdooProduct: Codable {
    let odooId: Int
    let name: String
    let sku: String
    let price: Double
    let stockQty: Int
    let category: String
    let unit: String
}

struct OdooOrderItem: Codable {
    let productOdooId: Int
    let quantity: Int
    let unitPrice: Double
}

struct OdooLocationInput: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: String
    let batteryLevel: Int
    let speed: Double
}

class OdooClient {
    private let baseUrl = "https://ahmed128aboshady-arfad-co-stage-33427514.dev.odoo.com"
    private let db = "ahmed128aboshady-arfad-co-stage-33427514"
    private let adminUsername = "admin"
    private let adminPassword = "admin"
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 15.0
        self.session = URLSession(configuration: config)
    }
    
    // Execute standard JSON-RPC call
    private func callJsonRpc(service: String, method: String, args: [Any]) async throws -> Any? {
        guard let url = URL(string: "\(baseUrl)/jsonrpc") else {
            throw URLError(.badURL)
        }
        
        let params: [String: Any] = [
            "service": service,
            "method": method,
            "args": args,
            "kwargs": [String: Any]()
        ]
        
        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "call",
            "params": params,
            "id": Int(Date().timeIntervalSince1970)
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let error = json?["error"] as? [String: Any] {
            let message = error["message"] as? String ?? "Unknown Odoo error"
            throw NSError(domain: "OdooError", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        return json?["result"]
    }
    
    // Authenticate a delegate (returns uid if successful)
    func authenticateDelegate(username: String, pass: String) async -> Int? {
        do {
            let result = try await callJsonRpc(service: "common", method: "authenticate", args: [db, username, pass, [String: Any]()])
            if let uid = result as? Int, uid != 0 {
                return uid
            }
            // Fallback: check if standard admin auth is used
            if username == adminUsername && pass == adminPassword {
                let adminResult = try await callJsonRpc(service: "common", method: "authenticate", args: [db, adminUsername, adminPassword, [String: Any]()])
                return adminResult as? Int
            }
            return nil
        } catch {
            print("Odoo Auth Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Check if the user is an active delegate
    func checkIsActiveDelegate(uid: Int) async -> Bool {
        do {
            let result = try await callJsonRpc(
                service: "object",
                method: "execute_kw",
                args: [
                    db,
                    2, // admin uid used to check
                    adminPassword,
                    "res.users",
                    "search_read",
                    [[["id", "=", uid]]],
                    ["fields": ["is_active_delegate"]]
                ]
            )
            
            if let records = result as? [[String: Any]], let first = records.first {
                return first["is_active_delegate"] as? Bool ?? false
            }
            return false
        } catch {
            print("Odoo checkIsActiveDelegate error: \(error.localizedDescription)")
            return false
        }
    }
    
    // Upload GPS locations via custom endpoint
    func uploadLocations(uid: Int, pass: String, locations: [OdooLocationInput]) async -> Bool {
        guard !locations.isEmpty else { return true }
        
        guard let url = URL(string: "\(baseUrl)/delegates/upload_gps") else {
            return false
        }
        
        do {
            let locsData = try JSONEncoder().encode(locations)
            let locsJson = try JSONSerialization.jsonObject(with: locsData)
            
            let params: [String: Any] = [
                "uid": uid,
                "password": pass,
                "db": db,
                "locations": locsJson
            ]
            
            let requestBody: [String: Any] = [
                "jsonrpc": "2.0",
                "method": "call",
                "params": params,
                "id": Int(Date().timeIntervalSince1970)
            ]
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return false
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let result = json?["result"] as? [String: Any] {
                return result["success"] as? Bool ?? false
            }
            return false
        } catch {
            print("Odoo uploadLocations error: \(error.localizedDescription)")
            return false
        }
    }
    
    // Fetch customers
    func getCustomers(uid: Int) async -> [OdooCustomer] {
        do {
            let result = try await callJsonRpc(
                service: "object",
                method: "execute_kw",
                args: [
                    db,
                    2,
                    adminPassword,
                    "res.partner",
                    "search_read",
                    [[["customer_rank", ">", 0]]],
                    ["fields": ["id", "name", "street", "phone", "email", "credit_limit"]]
                ]
            )
            
            guard let records = result as? [[String: Any]] else { return [] }
            
            return records.map { r in
                OdooCustomer(
                    odooId: r["id"] as? Int ?? 0,
                    name: r["name"] as? String ?? "",
                    address: r["street"] as? String ?? "",
                    phone: r["phone"] as? String ?? "",
                    email: r["email"] as? String ?? "",
                    balance: r["credit_limit"] as? Double ?? 0.0
                )
            }
        } catch {
            print("Odoo getCustomers error: \(error.localizedDescription)")
            return []
        }
    }
    
    // Fetch products
    func getProducts(uid: Int) async -> [OdooProduct] {
        do {
            let result = try await callJsonRpc(
                service: "object",
                method: "execute_kw",
                args: [
                    db,
                    2,
                    adminPassword,
                    "product.product",
                    "search_read",
                    [[["sale_ok", "=", true]]],
                    ["fields": ["id", "name", "default_code", "lst_price", "qty_available", "categ_id", "uom_id"]]
                ]
            )
            
            guard let records = result as? [[String: Any]] else { return [] }
            
            return records.map { r in
                let categName = (r["categ_id"] as? [Any])?.last as? String ?? "عام"
                let uomName = (r["uom_id"] as? [Any])?.last as? String ?? "قطعة"
                return OdooProduct(
                    odooId: r["id"] as? Int ?? 0,
                    name: r["name"] as? String ?? "",
                    sku: r["default_code"] as? String ?? "",
                    price: r["lst_price"] as? Double ?? 0.0,
                    stockQty: Int(r["qty_available"] as? Double ?? 0.0),
                    category: categName,
                    unit: uomName
                )
            }
        } catch {
            print("Odoo getProducts error: \(error.localizedDescription)")
            return []
        }
    }
    
    // Create sales order in Odoo
    func createSaleOrder(uid: Int, customerOdooId: Int, items: [OdooOrderItem], notes: String, salespersonId: Int?) async -> Int? {
        do {
            var orderLineList = [[Any]]()
            for item in items {
                let lineVals: [String: Any] = [
                    "product_id": item.productOdooId,
                    "product_uom_qty": item.quantity,
                    "price_unit": item.unitPrice
                ]
                orderLineList.append([0, 0, lineVals])
            }
            
            var vals: [String: Any] = [
                "partner_id": customerOdooId,
                "order_line": orderLineList,
                "note": notes
            ]
            
            if let spId = salespersonId {
                vals["user_id"] = spId
            }
            
            let result = try await callJsonRpc(
                service: "object",
                method: "execute_kw",
                args: [
                    db,
                    2,
                    adminPassword,
                    "sale.order",
                    "create",
                    [vals]
                ]
            )
            
            if let orderId = result as? Int {
                // Try to confirm the sales order automatically
                _ = try? await callJsonRpc(
                    service: "object",
                    method: "execute_kw",
                    args: [
                        db,
                        2,
                        adminPassword,
                        "sale.order",
                        "action_confirm",
                        [[orderId]]
                    ]
                )
                return orderId
            }
            return nil
        } catch {
            print("Odoo createSaleOrder error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Create payment in Odoo
    func createPayment(uid: Int, customerOdooId: Int, amount: Double, notes: String) async -> Int? {
        do {
            let vals: [String: Any] = [
                "partner_id": customerOdooId,
                "amount": amount,
                "payment_type": "inbound",
                "partner_type": "customer",
                "payment_method_line_id": 1, // Standard Cash or Manual
                "ref": notes
            ]
            
            let result = try await callJsonRpc(
                service: "object",
                method: "execute_kw",
                args: [
                    db,
                    2,
                    adminPassword,
                    "account.payment",
                    "create",
                    [vals]
                ]
            )
            
            if let paymentId = result as? Int {
                // Post payment
                _ = try? await callJsonRpc(
                    service: "object",
                    method: "execute_kw",
                    args: [
                        db,
                        2,
                        adminPassword,
                        "account.payment",
                        "action_post",
                        [[paymentId]]
                    ]
                )
                return paymentId
            }
            return nil
        } catch {
            print("Odoo createPayment error: \(error.localizedDescription)")
            return nil
        }
    }
}
