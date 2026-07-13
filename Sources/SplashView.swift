import SwiftUI

public struct SplashView: View {
    @State private var isActive = false

    public init() {}

    public var body: some View {
        if isActive {
            ScannerView()
        } else {
            VStack(spacing: 20) {
                Image(systemName: "scooter")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                Text("SoFlow")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Your E-Scooter Companion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ProgressView()
                    .padding(.top, 20)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { isActive = true }
                }
            }
        }
    }
}
