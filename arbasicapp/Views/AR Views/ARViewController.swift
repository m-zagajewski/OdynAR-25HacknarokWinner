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

    }

    func update(sceneScale: SIMD3<Float>) {
        self.sceneScale = sceneScale
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
    private var posterOverlayView: UIView?

    private func showPosterOverlay() {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.85)

        let imageView = UIImageView(image: UIImage(named: "imagePoster")) // ← dodaj plakat do Assets
        imageView.contentMode = .scaleAspectFit
        imageView.frame = overlay.bounds.insetBy(dx: 20, dy: 80)
        overlay.addSubview(imageView)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("X", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
        closeButton.frame = CGRect(x: overlay.bounds.width - 60, y: 40, width: 40, height: 40)
        closeButton.addTarget(self, action: #selector(dismissPosterOverlay), for: .touchUpInside)
        overlay.addSubview(closeButton)

        view.addSubview(overlay)
        posterOverlayView = overlay
    }

    @objc private func dismissPosterOverlay() {
        posterOverlayView?.removeFromSuperview()
    }

    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: arView)
        if let tappedEntity = arView.entity(at: location), tappedEntity.name == "poster" {
            showPosterOverlay()
        }
    }

    private func handleDetectedImage(_ imageAnchor: ARImageAnchor) {
        let imageName = imageAnchor.referenceImage.name ?? ""
        let posterImageName = "posterImage_" + imageName  // np. "posterImage_marker1"

        guard let texture = try? TextureResource.load(named: posterImageName) else {
            print("Nie udało się załadować tekstury dla: \(posterImageName)")
            return
        }

        var material = UnlitMaterial()
        material.baseColor = .texture(texture)

        let planeMesh = MeshResource.generatePlane(width: 0.2, height: 0.3)
        let posterEntity = ModelEntity(mesh: planeMesh, materials: [material])
        posterEntity.name = "poster"

        // Transformacja do ściany (rotacja)
        let transform = Transform(matrix: imageAnchor.transform)
        posterEntity.transform.rotation = transform.rotation * simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        posterEntity.position.z += 0.001

        let anchorEntity = AnchorEntity(anchor: imageAnchor)
        posterEntity.generateCollisionShapes(recursive: true)
        anchorEntity.addChild(posterEntity)
        arView.scene.addAnchor(anchorEntity)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }


}
