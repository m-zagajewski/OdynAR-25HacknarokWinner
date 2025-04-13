import SwiftUI

struct ContentView: View {
    @State private var showingAR = false

    var body: some View {
        ZStack {
            // Background: dark, slightly gradient for depth
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.08)]),
                                  startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
            
            // Viking symbol - now much larger and centered at top
            Image("VikingSymbolWhite")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .frame(maxHeight: .infinity, alignment: .center)
                        .padding(.bottom, 150)
            
            // Bottom content with fog overlay
            VStack {
                Spacer()
                
                VStack {
                    // Title with runic styling vibe
                    Text("PRZETRWAJ RAGNAROK")
                        .font(.custom("Copperplate", size: 35))
                        .foregroundColor(.white)
                        .kerning(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 6)
                    
                    Rectangle()
                        .fill(.white)
                        .frame(width: 160, height: 2)
                        .padding(.bottom, 20)
                    
                    // Subtitle
                    Text("Chwyć klawiaturę i wyrusz w podróż przez nordycką mitologię.")
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(Color(white: 0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil) // Don’t restrict number of lines
                        .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                        .frame(maxWidth: 300) // Optional: constrain width
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                    
                    // Call-to-action button
                    Button(action: showAR) {
                        Text("✦ Pokaż Świat AR ✦")
                            .font(.custom("Copperplate", size: 18))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.87, green: 0.74, blue: 0.4)) // Norse gold tone
                            .cornerRadius(12)
                            .shadow(color: .white.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.bottom, 60)
                .padding(.top, 40)
                .frame(maxWidth: .infinity)
                .background(
                    // Foggy overlay at bottom
                    LinearGradient(gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.9)
                    ]), startPoint: .top, endPoint: .bottom)
                )
            }
        }
        .fullScreenCover(isPresented: $showingAR) {
            ARContentView()
        }
    }

    private func showAR() {
        showingAR = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
