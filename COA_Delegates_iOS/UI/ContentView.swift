import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var router = NavigationRouter()
    
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            switch router.currentScreen {
            case .splash:
                SplashScreen(onFinished: {
                    if viewModel.isLoggedIn {
                        router.navigateTo(.home)
                    } else {
                        router.navigateTo(.login)
                    }
                })
                
            case .login:
                LoginScreen(
                    onLogin: { username, password in
                        Task {
                            await viewModel.login(username: username, pass: password)
                            if viewModel.isLoggedIn {
                                router.navigateTo(.home)
                            }
                        }
                    },
                    isLoading: viewModel.isLoginLoading,
                    errorMessage: viewModel.loginError
                )
                
            case .home:
                ZStack {
                    VStack(spacing: 0) {
                        // Main Tab Views
                        TabView(selection: $selectedTab) {
                            // Tab 0: Home Dashboard
                            HomeScreen(
                                todaySales: viewModel.todaySalesTotal,
                                ordersCount: viewModel.todayOrdersCount,
                                paymentsTotal: viewModel.todayPaymentsTotal,
                                visitsCount: viewModel.todayVisitsCount,
                                pendingSyncCount: viewModel.pendingSyncCount,
                                isConnected: viewModel.isConnected,
                                isSyncing: viewModel.isSyncing,
                                userName: viewModel.currentUser?.name ?? "المندوب",
                                onSync: {
                                    Task {
                                        await viewModel.syncPendingRecords()
                                    }
                                },
                                onNavigate: { route in
                                    navigateFromHome(route)
                                }
                            )
                            .tabItem {
                                Label("الرئيسية", systemImage: "house.fill")
                            }
                            .tag(0)
                            
                            // Tab 1: Customers
                            CustomersScreen(
                                customers: viewModel.customers.filter { c in
                                    viewModel.customerSearchQuery.isEmpty || c.name.contains(viewModel.customerSearchQuery)
                                },
                                searchQuery: $viewModel.customerSearchQuery,
                                onCustomerClick: { id in
                                    router.navigateTo(.customerDetail(customerId: id))
                                },
                                onAddCustomer: {
                                    router.navigateTo(.addCustomer)
                                },
                                onCall: { phone in
                                    dialPhoneNumber(phone)
                                },
                                onBack: {
                                    selectedTab = 0
                                }
                            )
                            .tabItem {
                                Label("العملاء", systemImage: "person.3.fill")
                            }
                            .tag(1)
                            
                            // Tab 2: Products
                            ProductsScreen(
                                products: viewModel.products.filter { p in
                                    viewModel.productSearchQuery.isEmpty || p.name.contains(viewModel.productSearchQuery) || p.sku.contains(viewModel.productSearchQuery)
                                },
                                searchQuery: $viewModel.productSearchQuery,
                                onBack: {
                                    selectedTab = 0
                                }
                            )
                            .tabItem {
                                Label("المنتجات", systemImage: "tag.fill")
                            }
                            .tag(2)
                            
                            // Tab 3: Sales Orders
                            SalesOrdersScreen(
                                orders: viewModel.salesOrders,
                                filter: $viewModel.orderFilter,
                                onOrderClick: { _ in },
                                onNewOrder: {
                                    router.navigateTo(.createSalesOrder)
                                },
                                onBack: {
                                    selectedTab = 0
                                }
                            )
                            .tabItem {
                                Label("الفواتير", systemImage: "doc.text.fill")
                            }
                            .tag(3)
                            
                            // Tab 4: Profile / More
                            ProfileScreen(
                                userName: viewModel.currentUser?.name ?? "المندوب",
                                userPhone: viewModel.currentUser?.phone ?? "",
                                userRegion: viewModel.currentUser?.region ?? "",
                                isGpsTrackingEnabled: viewModel.isGpsEnabled,
                                onGpsTrackingToggle: { enabled in
                                    viewModel.toggleGpsTracking(enabled: enabled)
                                },
                                onLogout: {
                                    viewModel.logout()
                                    router.navigateTo(.login)
                                },
                                onBack: {
                                    selectedTab = 0
                                }
                            )
                            .tabItem {
                                Label("المزيد", systemImage: "ellipsis.circle.fill")
                            }
                            .tag(4)
                        }
                        .accentColor(AppColors.primaryDarkBlue)
                    }
                    
                    // Navigation overlay stack for sub-screens
                    if let subScreen = router.navigationPath.last {
                        presentSubScreen(subScreen)
                            .transition(.move(edge: .leading))
                            .zIndex(1)
                    }
                }
            }
        }
        .animation(.default, value: router.currentScreen)
        .onAppear {
            // Apply customized styling to tab bar
            UITabBar.appearance().backgroundColor = UIColor(AppColors.cardGray)
            UITabBar.appearance().unselectedItemTintColor = UIColor(AppColors.textSecondary.opacity(0.6))
        }
    }
    
    // Manage routing push/pop overlay sub-screens
    @ViewBuilder
    private func presentSubScreen(_ screen: AppScreen) -> View {
        switch screen {
        case .customerDetail(let customerId):
            if let customer = viewModel.customers.first(where: { $0.id == customerId }) {
                CustomerDetailScreen(
                    customerName: customer.name,
                    phone: customer.phone,
                    email: customer.email,
                    address: customer.address,
                    region: "",
                    balance: customer.balance,
                    onBack: { router.goBack() },
                    onEdit: { router.navigateTo(.editCustomer(customerId: customerId)) },
                    onNewOrder: { router.navigateTo(.createSalesOrder) },
                    onNewPayment: { router.navigateTo(.createPayment) }
                )
            }
            
        case .addCustomer:
            AddEditCustomerScreen(
                existingCustomer: nil,
                onSave: { name, address, phone, email, region, notes in
                    viewModel.addCustomer(name: name, address: address, phone: phone, email: email, region: region, notes: notes)
                    router.goBack()
                },
                onBack: { router.goBack() }
            )
            
        case .editCustomer(let customerId):
            if let customer = viewModel.customers.first(where: { $0.id == customerId }) {
                let uiModel = CustomerUiModel(id: customer.id, name: customer.name, address: customer.address, phone: customer.phone, balance: customer.balance)
                AddEditCustomerScreen(
                    existingCustomer: uiModel,
                    onSave: { name, address, phone, email, region, notes in
                        viewModel.updateCustomer(id: customerId, name: name, address: address, phone: phone, email: email, region: region, notes: notes)
                        router.goBack()
                    },
                    onBack: { router.goBack() }
                )
            }
            
        case .createSalesOrder:
            CreateSalesOrderScreen(
                customers: viewModel.customers,
                products: viewModel.products,
                onConfirm: { customerId, customerName, items, notes in
                    viewModel.createSalesOrder(customerId: customerId, customerName: customerName, items: items, notes: notes)
                    router.goBack()
                },
                onBack: { router.goBack() }
            )
            
        case .createPayment:
            CreatePaymentScreen(
                customers: viewModel.customers,
                onConfirm: { customerId, customerName, amount, method, checkNum, checkDate, notes in
                    viewModel.createPayment(customerId: customerId, customerName: customerName, amount: amount, method: method, checkNum: checkNum, checkDate: checkDate, notes: notes)
                    router.goBack()
                },
                onBack: { router.goBack() }
            )
            
        case .map:
            MapScreen(
                currentLat: viewModel.currentLat,
                currentLng: viewModel.currentLng,
                todayPointsCount: viewModel.gpsPointsCount,
                visitedCustomers: ["زيارة شركة النور للمقاولات", "زيارة سوبر ماركت الفاخر"],
                onBack: { router.goBack() }
            )
            
        case .notifications:
            NotificationsScreen(
                notifications: viewModel.notifications,
                onMarkAllRead: { viewModel.db.markAllNotificationsAsRead(); viewModel.loadLocalData() },
                onNotificationClick: { id in viewModel.db.markNotificationAsRead(id: id); viewModel.loadLocalData() },
                onBack: { router.goBack() }
            )
            
        default:
            EmptyView()
        }
    }
    
    private func navigateFromHome(_ route: String) {
        switch route {
        case "new_order": router.navigateTo(.createSalesOrder)
        case "new_payment": router.navigateTo(.createPayment)
        case "map": router.navigateTo(.map)
        case "notifications": router.navigateTo(.notifications)
        case "profile": selectedTab = 4
        default: break
        }
    }
    
    private func dialPhoneNumber(_ number: String) {
        guard let url = URL(string: "tel://\(number)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}

// Extends AppViewModel to expose computed stats
extension AppViewModel {
    var todaySalesTotal: Double {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let timestamp = Int64(todayStart.timeIntervalSince1970 * 1000)
        return salesOrders
            .filter { $0.date >= timestamp }
            .reduce(0.0) { sum, order in sum + order.grandTotal }
    }
    
    var todayOrdersCount: Int {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let timestamp = Int64(todayStart.timeIntervalSince1970 * 1000)
        return salesOrders.filter { $0.date >= timestamp }.count
    }
    
    var todayPaymentsTotal: Double {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let timestamp = Int64(todayStart.timeIntervalSince1970 * 1000)
        return payments
            .filter { $0.date >= timestamp }
            .reduce(0.0) { sum, p in sum + p.amount }
    }
    
    var todayVisitsCount: Int {
        // Mock visit counts based on local DB notifications or entries
        return notifications.filter { $0.title.contains("زيارة") }.count
    }
}
