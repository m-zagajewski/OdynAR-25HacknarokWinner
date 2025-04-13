import SwiftUI

struct ARContentView: View {
    @Environment(\.dismiss) var dismiss
    @State private var sceneScaleIndex = 1
    @State private var showModelSelector = false
    
    private var sceneScale: SIMD3<Float> {
        AppConfig.sceneScales[sceneScaleIndex]
    }

    var body: some View {
        ARContainerView(sceneScale: sceneScale)
            .overlay {
                VStack {
                    // Top bar: Dismiss button
                    HStack {
                        Spacer()
                        Button(action: dismiss.callAsFunction) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                                
                        }
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 24)

                    Spacer()

                    // Bottom controls
                    HStack {
                        // Model selection button (left-aligned)
                        Button(action: {
                            showModelSelector.toggle()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                                
                        }
                        .padding(.trailing, 20)
                        
                        // Spacer pushes the shutter button to center
                        Spacer()
                        
                        // Camera shutter button (centered)
                        Button(action: { /* Take photo action here */ }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 68, height: 68)
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 80, height: 80)
                            }
                        }
                        
                        // Another spacer to balance the layout
                        Spacer()
                        
                        // Invisible placeholder to balance the left button
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 54, height: 54)
                            .padding(.leading, 20)
                    }
                    .padding(.bottom, 40)
                    .padding(.horizontal, 30)
                }
                .sheet(isPresented: $showModelSelector) {
                    ModelSelectorView() // You'll need to create this view
                        .presentationDetents([.medium])
                }
            }
    }

    private func scaleChange() {
        sceneScaleIndex = sceneScaleIndex == AppConfig.sceneScales.count - 1
                            ? 0 : sceneScaleIndex + 1
    }
}

// Placeholder for the model selector view
struct ModelSelectorView: View {
    let models = ["Chair", "Table", "Lamp", "Sofa", "Plant"] // Example models
    
    var body: some View {
        NavigationStack {
            List(models, id: \.self) { model in
                Text(model)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .onTapGesture {
                        // Handle model selection here
                        print("Selected model: \(model)")
                    }
            }
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ARContentView_Previews: PreviewProvider {
    static var previews: some View {
        ARContentView()
    }
}
