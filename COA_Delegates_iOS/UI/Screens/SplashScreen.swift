import SwiftUI

struct SplashScreen: View {
    let onFinished: () -> Void
    
    @State private var textOpacity = 0.0
    @State private var subtitleOpacity = 0.0
    
    var body: some View {
        ZStack {
            AppColors.primaryDarkBlue
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                Spacer()
                
                Text("COA Delegates")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(textOpacity)
                
                Text("كوميونتي أوف أكونتنتس")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(subtitleOpacity)
                
                Spacer()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                self.textOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
                self.subtitleOpacity = 1.0
            }
            
            // Navigate after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onFinished()
            }
        }
    }
}
