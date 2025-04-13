import SwiftUI
import RealityKit
import ARKit
import Photos

struct ARContentView: View {
    @Environment(\.dismiss) var dismiss
    @State private var arView = ARView(frame: .zero)
    @State private var showModelSelector = false
    @State private var placedAnchors: [AnchorEntity] = []
    @State private var showPhotoErrorAlert = false
    @State private var photoError: String?
    
    // Model dictionary with display names
    private let modelDictionary: [String: String] = [
        "toy_biplane": "Biplane ✈️",
        "toy_car": "Vintage Car 🚗",
        "toy_robot_vintage": "Retro Robot 🤖"
    ]
    
    var body: some View {
        ZStack {
            ARViewContainer(arView: $arView, placedAnchors: $placedAnchors)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top bar with close button
                HStack {
                    Spacer()
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 24)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Bottom controls
                HStack {
                    // Model selection button
                    Button(action: { showModelSelector.toggle() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 20)
                    
                    Spacer()
                    
                    // Shutter button
                    Button(action: captureAndSavePhoto) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 68, height: 68)
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                        }
                    }
                    
                    Spacer()
                    
                    // Clear models button
                    Button(action: clearModels) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 20)
                }
                .padding(.bottom, 40)
                .padding(.horizontal, 30)
            }
        }
        .sheet(isPresented: $showModelSelector) {
            ModelSelectorView(models: modelDictionary) { modelName in
                placeModel(named: modelName)
                showModelSelector = false
            }
        }
        .alert("Photo Error", isPresented: $showPhotoErrorAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(photoError ?? "Unknown error occurred while saving photo")
        }
        .onAppear { setupAR() }
    }
    
    private func setupAR() {
        let config = ARWorldTrackingConfiguration()
        guard let refImages = ARReferenceImage.referenceImages(inGroupNamed: "ARmarkers", bundle: nil) else { return }
        config.detectionImages = refImages
        arView.session.run(config)
    }
    
    private func placeModel(named name: String) {
        do {
            let model = try Entity.loadModel(named: name)
            model.generateCollisionShapes(recursive: true)
            arView.installGestures([.translation, .rotation, .scale], for: model)
            
            let cameraTransform = arView.cameraTransform
            let position = cameraTransform.matrix.columns.3
            model.position = SIMD3(position.x, position.y - 0.1, position.z - 0.5)
            
            let anchor = AnchorEntity(world: model.position)
            anchor.addChild(model)
            arView.scene.addAnchor(anchor)
            placedAnchors.append(anchor)
            
        } catch {
            showPhotoError("Failed to load model: \(error.localizedDescription)")
        }
    }
    
    private func captureAndSavePhoto() {
        // 1. Capture snapshot
        arView.snapshot(saveToHDR: false) { image in
            guard let image = image else {
                showPhotoError("Failed to capture AR scene")
                return
            }
            
            // 2. Check authorization status
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { newStatus in
                    if newStatus == .authorized {
                        saveImageToLibrary(image)
                    } else {
                        showPhotoError("Please enable photo access in Settings")
                    }
                }
                
            case .authorized, .limited:
                saveImageToLibrary(image)
                
            case .denied, .restricted:
                showPhotoError("Photo access denied. Enable in Settings.")
                
            @unknown default:
                showPhotoError("Unknown authorization status")
            }
        }
    }
    
    private func saveImageToLibrary(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    showPhotoError("Save failed: \(error.localizedDescription)")
                } else if !success {
                    showPhotoError("Photo failed to save")
                }
            }
        }
    }
    
    private func showPhotoError(_ message: String) {
        DispatchQueue.main.async {
            photoError = message
            showPhotoErrorAlert = true
        }
    }
    
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func clearModels() {
        placedAnchors.forEach { anchor in
            arView.scene.removeAnchor(anchor)
        }
        placedAnchors.removeAll()
    }
}

// MARK: - Supporting Views
struct ARViewContainer: UIViewRepresentable {
    @Binding var arView: ARView
    @Binding var placedAnchors: [AnchorEntity]
    
    func makeUIView(context: Context) -> ARView { arView }
    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct ModelSelectorView: View {
    let models: [String: String]
    var onSelect: (String) -> Void
    
    var body: some View {
        NavigationView {
            List(models.sorted(by: { $0.key < $1.key }), id: \.key) { key, displayName in
                Button(action: { onSelect(key) }) {
                    Text(displayName)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
