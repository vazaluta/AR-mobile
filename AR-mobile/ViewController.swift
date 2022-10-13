
import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var lightButton: UIBarButtonItem!
    
    var display = UIImage()
    var photoNodes = [SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions.insert(.showFeaturePoints) // [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @IBAction func lightSwich(_ sender: UIBarButtonItem) {
        
        // 押すとライトON/OFFが切り替わる
        // さらにライトオン時とオフ時のアイコンを切り替える
        if let avCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) {
            if avCaptureDevice.hasTorch, avCaptureDevice.isTorchAvailable { // キャプチャデバイスにライトがあるか、　ライトが使用可能な状態か
                do {
                    try avCaptureDevice.lockForConfiguration() // デバイスにアクセスするときはこれする。
                    
                    if avCaptureDevice.isTorchActive {
                        avCaptureDevice.torchMode = .off // 消灯。明るさレベルは 0.0 ~ 1.0
                        lightButton.image = UIImage(systemName: "lightbulb.slash")
                    } else {
                        try avCaptureDevice.setTorchModeOn(level: 1.0) // 点灯。明るさレベルは 0.0 ~ 1.0
                        lightButton.image = UIImage(systemName: "lightbulb.fill")
                    }
                    
                } catch let error {
                    print(error)
                }
                avCaptureDevice.unlockForConfiguration()
            }
        }
    }
    
    private func showUIImagePicker() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let pickerView = UIImagePickerController()
            pickerView.sourceType = .photoLibrary
            pickerView.delegate = self
            pickerView.modalPresentationStyle = .overFullScreen
            self.present(pickerView, animated: true, completion: nil)
        }
    }
    
    private func setImageToScene(image: UIImage, location: ARRaycastResult) {
        
        let plane = SCNPlane(width: 0.2, height: 0.4)
        let material = SCNMaterial()
        material.diffuse.contents = image
        plane.materials = [material]
        let node = SCNNode()
        node.position = SCNVector3(
            x: location.worldTransform.columns.3.x,
            y: location.worldTransform.columns.3.y - Float(plane.height / 2),
            z: location.worldTransform.columns.3.z
        )
//        node.eulerAngles.z = -.pi / 2

        node.geometry = plane // node を中心として cube を配置する
        sceneView.scene.rootNode.addChildNode(node)
        
        photoNodes.append(node)
    }
}

//MARK: - Presenter
//MARK: - UIPickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            display = image
            print("retrieve image info")
        }
        picker.dismiss(animated: true, completion: nil)
        print("dismis display.")
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        print("canceled")
    }
    
    
    //MARK: - touchesBegan
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
//            print(touch) //生データ
            let touchLocation = touch.location(in: sceneView) //デコード
            
            // sceneView と、touchLocationが平面かをテストし、結果を返す。
            if let raycast = sceneView.raycastQuery(from: touchLocation, allowing: .estimatedPlane, alignment: .any) {
                if let raycastResult = sceneView.session.raycast(raycast).first {
                    setImageToScene(image: display, location: raycastResult)
                    print("size: \(display.size)")
                }
            }
        }
    }
    
    @IBAction func photoButtonTapped(_ sender: Any) {
        
        showUIImagePicker()
    }
    
    @IBAction func trachButton(_ sender: UIBarButtonItem) {

        if !photoNodes.isEmpty {
            for photo in photoNodes {
                photo.removeFromParentNode()
            }
        }
        photoNodes = [SCNNode]()
    }
}

//MARK: - ARSCNViewDelegateMethods
extension ViewController :ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}

        let planeNode = createPlane(withPlaneAnchor: planeAnchor)
        
        node.addChildNode(planeNode)

    }
    
    //MARK: - Plane Rendering Methods
    
    func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        var plane = SCNPlane()
        if #available(iOS 16.0, *) {
            plane = SCNPlane(width: CGFloat(planeAnchor.planeExtent.width), height: CGFloat(planeAnchor.planeExtent.height))
        } else {
            plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        }
        
        let planeNode = SCNNode()
        
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        
        let gridMaterial = SCNMaterial()
        
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        
        plane.materials = [gridMaterial]
        
        planeNode.geometry = plane
        
        return planeNode
    }
    
}
