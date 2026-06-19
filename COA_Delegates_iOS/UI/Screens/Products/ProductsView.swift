import SwiftUI

struct ProductsScreen: View {
    let products: [ProductRecord]
    @Binding var searchQuery: String
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
                Text("المنتجات")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                // Placeholder
                Image(systemName: "arrow.right").foregroundColor(.clear)
            }
            .padding()
            .background(AppColors.primaryDarkBlue)
            
            // Search Bar
            SearchBar(text: $searchQuery, placeholder: "بحث عن منتج...")
                .padding(.top, 12)
            
            if products.isEmpty {
                EmptyState(icon: "tag.fill", message: "لا توجد منتجات مطابقة للبحث")
            } else {
                List(products) { product in
                    HStack {
                        // Product Price & Stock
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(String(format: "%.2f", product.price)) ج.م")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.accentRed)
                            
                            Text("المخزن: \(product.stockQty) \(product.unit)")
                                .font(.caption)
                                .foregroundColor(product.stockQty > 10 ? AppColors.textSecondary : AppColors.accentRed)
                        }
                        
                        Spacer()
                        
                        // Product Name & Category
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(product.name)
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("الرمز: \(product.sku.isEmpty ? "غير محدد" : product.sku)")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text(product.category)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.primaryDarkBlue.opacity(0.08))
                                .foregroundColor(AppColors.primaryDarkBlue)
                                .cornerRadius(4)
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

// Simple Helper Product UI model
struct ProductUiModel: Identifiable {
    let id: Int64
    let name: String
    let sku: String
    let price: Double
    let stockQty: Int
    let category: String
    let unit: String
}
