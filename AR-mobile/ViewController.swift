
import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!

    
    var display = UIImage()
    var photoNodes = [SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
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
            y: location.worldTransform.columns.3.y + Float(plane.height / 2),
            z: location.worldTransform.columns.3.z
        )
        print(node.frame.height)
        node.geometry = plane // node を中心として cube を配置する
        sceneView.scene.rootNode.addChildNode(node)
        
        photoNodes.append(node)
    }
    
//    private func createPhotoNode(_ image: UIImage, position: SCNVector3) -> SCNNode {
//        let photoNode = SCNNode()
//        let scale: CGFloat = 0.3
//        let geometry = SCNBox(width: image.size.width * scale / image.size.height,
//                              height: scale,
//                              length: 0.00000001,
//                              chamferRadius: 0.0)
//        geometry.firstMaterial?.diffuse.contents = image
//        photoNode.geometry = geometry
//        photoNode.position = position
//        return photoNode
//    }
}

//MARK: - Presenter
//MARK: - UIPickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            display = image
            print("retrieve image info")
            print(display)
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
            if let raycast = sceneView.raycastQuery(from: touchLocation, allowing: .estimatedPlane, alignment: .horizontal) {
                if let raycastResult = sceneView.session.raycast(raycast).first {
                    print(raycastResult)
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
