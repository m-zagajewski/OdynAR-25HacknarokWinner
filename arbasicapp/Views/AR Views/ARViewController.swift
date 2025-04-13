import UIKit
import ARKit
import RealityKit
import Combine

class ARViewController: UIViewController, ARSessionDelegate {
    private var arView: ARView!
    private var subscriptions = Set<AnyCancellable>()
    private var sceneScale: SIMD3<Float> = .one  // domyślna wartość

    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        runImageTracking()
    }

    func setup() {
        // Można zainicjalizować wszystko od zera, jeśli potrzeba
        // Ale my to robimy już w viewDidLoad, więc nie trzeba nic tu robić
    }

    func update(sceneScale: SIMD3<Float>) {
        self.sceneScale = sceneScale
        // W razie potrzeby można zaktualizować rozmiar modelu
    }

    private func setupARView() {
        arView = ARView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(arView)
        arView.session.delegate = self
    }

    private func runImageTracking() {
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "ARmarkers", bundle: nil) else {
            fatalError("Brak markerów w ARMarkers!")
        }

        let config = ARWorldTrackingConfiguration()
        config.detectionImages = referenceImages
        config.maximumNumberOfTrackedImages = 1

        arView.session.run(config, options: [.removeExistingAnchors, .resetTracking])
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let imageAnchor = anchor as? ARImageAnchor {
                handleDetectedImage(imageAnchor)
            }
        }
    }

    private func handleDetectedImage(_ imageAnchor: ARImageAnchor) {
        print("WYKRYTO MARKER: \(imageAnchor.referenceImage.name ?? "brak nazwy")")
        let anchorEntity = AnchorEntity(anchor: imageAnchor)

        // Tworzymy np. 3D napis
        let textMesh = MeshResource.generateText("Witaj!", extrusionDepth: 0.01, font: .systemFont(ofSize: 0.1), containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [material])

        // Skalowanie
        textEntity.scale = sceneScale

        // Pozycjonowanie nad markerem
        textEntity.position = SIMD3<Float>(0, 0.05, 0)
        anchorEntity.addChild(textEntity)
        arView.scene.addAnchor(anchorEntity)
    }
}
