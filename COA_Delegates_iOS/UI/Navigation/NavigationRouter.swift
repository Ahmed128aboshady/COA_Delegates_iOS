import SwiftUI

enum AppScreen: Hashable {
    case splash
    case login
    case home
    case customers
    case customerDetail(customerId: Int64)
    case addCustomer
    case editCustomer(customerId: Int64)
    case products
    case salesOrders
    case createSalesOrder
    case payments
    case createPayment
    case map
    case notifications
    case profile
}

class NavigationRouter: ObservableObject {
    @Published var currentScreen: AppScreen = .splash
    @Published var navigationPath = [AppScreen]()
    
    func navigateTo(_ screen: AppScreen) {
        if screen == .login || screen == .home {
            // Reset stack for root screens
            currentScreen = screen
            navigationPath.removeAll()
        } else {
            navigationPath.append(screen)
        }
    }
    
    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        navigationPath.removeAll()
    }
}
