
import UIKit
import SceneKit
import ARKit
import CropViewController
  
class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var lightButton: UIBarButtonItem!
    @IBOutlet weak var widthValue: UILabel!
    @IBOutlet weak var heightValue: UILabel!
    @IBOutlet weak var widthSlider: UISlider!
    @IBOutlet weak var heightSlider: UISlider!
    
    var display = UIImage()
    var photoNodes = [SCNNode]()
    var photoNodesBU = [SCNNode]()
    var timer = Timer()
    var touchResult: ARRaycastResult? = nil
    var isFirst = true
    var xCounter: Float = 0.0
    var zCounter: Float = 0.0
    

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
        
        configuration.planeDetection = [.horizontal, .vertical]

        // Run the view's session
        sceneView.session.run(configuration)
        
        nodeRotate() // 回転させる
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        timer.invalidate() // 回転を止める
    }
    
    //MARK: - Arrow Buttonでnodeを移動する
    
    @IBAction func moveToUp(_ sender: UIButton) {
        zCounter += 5
        setImageToScene(location: touchResult!)

    }
    
    @IBAction func moveToDown(_ sender: UIButton) {
        zCounter += -5
        setImageToScene(location: touchResult!)

    }
    
    @IBAction func moveToLeft(_ sender: UIButton) {
        xCounter += 5
        setImageToScene(location: touchResult!)

    }
    @IBAction func moveToRight(_ sender: UIButton) {
        xCounter += -5
        setImageToScene(location: touchResult!)
        
    }
    
    //MARK: - slidebar でnodeの大きさを調整する
    @IBAction func slideWidth(_ sender: UISlider) {
        let width = sender.value * 100
        let widthString = String(format: "%.1f", width)
        widthValue.text = "\(widthString)cm"
    }
    @IBAction func slideHeight(_ sender: UISlider) {
        let height = sender.value * 100
        let heightString = String(format: "%.1f", height)
        heightValue.text = "\(heightString)cm"
    }
    
    //MARK: - 写真を設置
    private func setImageToScene(location: ARRaycastResult) {
        if !isFirst {
            
            // ２回目以降の設置は、前回作成のnode削除
            photoNodes.last?.removeFromParentNode()
            photoNodes[photoNodes.count - 2].removeFromParentNode()
            photoNodes = photoNodesBU // BuckUp

        }
        isFirst = false

        // create plane geometry
        let width = widthSlider.value
        let height = heightSlider.value
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        
        // set plane material
        let material = SCNMaterial()
        material.diffuse.contents = display
        plane.materials = [material]
        
        // create node and node2
        let node = SCNNode()
        node.geometry = plane
        var node2 = SCNNode()
        node2 = node.clone()
        
        //　初期の平面の向きがカメラに向くように設定
        if let camera = self.sceneView.pointOfView {
            node.eulerAngles.y = camera.eulerAngles.y // カメラのy軸のオイラー角と同じにする
            node2.eulerAngles.y = camera.eulerAngles.y + .pi // node2は裏側としてレンダリングする
        }
        
        // set position
        let nodePosition = SCNVector3(
            x: location.worldTransform.columns.3.x + xCounter * 0.01,
            y: location.worldTransform.columns.3.y - Float(plane.height / 2),
            z: location.worldTransform.columns.3.z + zCounter * 0.01
        )
        node.position = nodePosition
        node2.position = nodePosition
        
        // render sceneView
        sceneView.scene.rootNode.addChildNode(node)
        sceneView.scene.rootNode.addChildNode(node2)
        
        // add node to Array
        photoNodes.append(node)
        photoNodes.append(node2)
    }
}


//MARK: - Presenter
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: - ノードの回転
    func nodeRotate() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (Timer) in
            for photo in self.photoNodes {
                photo.eulerAngles.y += .pi/180
            }
        }
        
    }
    
    //MARK: - タッチした時の処理
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        xCounter = 0.0
        zCounter = 0.0
        
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView) //デコード
            // sceneView と、touchLocationが平面かをテストし、結果を返す。
            if let raycast = sceneView.raycastQuery(from: touchLocation, allowing: .estimatedPlane, alignment: .any) {
                if let raycastResult = sceneView.session.raycast(raycast).first {
                    setImageToScene(location: raycastResult) // render image
                    
                    touchResult = raycastResult // 位置調整用にタッチ座標を使用するためグローバル変数へ渡す
                }
            }
        }
    }
    
    //MARK: - 写真を選択
    @IBAction func photoButtonTapped(_ sender: Any) {
        showUIImagePicker()
    }
    
    //MARK: -選んだ写真をUIImagePickerControllerとして作り、ViewControllerにpresentする。
    private func showUIImagePicker() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let pickerView = UIImagePickerController()
            pickerView.sourceType = .photoLibrary
            pickerView.delegate = self
            pickerView.modalPresentationStyle = .overFullScreen
            self.present(pickerView, animated: true, completion: nil)
        }
    }
    
    //MARK: - 画像選択をキャンセル
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - 画像選択処理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            cropUIImagePicker(pickerImage: image, with: picker) // trimming image
            
            isFirst = true // first flag
            xCounter = 0.0 // reset moving distance at x-axis
            zCounter = 0.0 // reset moving distance at z-axis
            
            photoNodesBU = photoNodes // Update to buckUp
        }
        picker.dismiss(animated: true, completion: nil) // UIimageへのダウンキャストが失敗した時
    }
    
    
    //MARK: - ライトのON/OFF
    @IBAction func lightSwich(_ sender: UIBarButtonItem) {
        
        if let avCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) {
            // キャプチャデバイスにライトがあるか、ライトが使用可能な状態か
            if avCaptureDevice.hasTorch, avCaptureDevice.isTorchAvailable {
                do {
                    try avCaptureDevice.lockForConfiguration() // access your device
                    
                    if avCaptureDevice.isTorchActive {
                        avCaptureDevice.torchMode = .off // lights out.
                        lightButton.image = UIImage(systemName: "lightbulb.slash") // set button image
                    } else {
                        try avCaptureDevice.setTorchModeOn(level: 1.0) // lighting.brightness level 0.0 ~ 1.0
                        lightButton.image = UIImage(systemName: "lightbulb.fill") // set button image
                    }
                } catch let error {
                    print(error)
                }
                avCaptureDevice.unlockForConfiguration() // release control
            }
        }
    }
    
    //MARK: - ノードの全削除
    @IBAction func trachButton(_ sender: UIBarButtonItem) {

        if !photoNodes.isEmpty {
            for photo in photoNodes {
                photo.removeFromParentNode()
            }
        }
        // initialize property
        photoNodes = [SCNNode]()
        photoNodesBU = [SCNNode]()
        isFirst = true
        xCounter = 0.0
        zCounter = 0.0
    }
    
}

//MARK: - cropViewControllerDelegate
extension ViewController: CropViewControllerDelegate {
    
    //MARK: - 選んだ写真をトリミング
    private func cropUIImagePicker(pickerImage: UIImage, with picker: UIImagePickerController) {
        //CropViewControllerを初期化する。pickerImage(処理する画像)を指定する。
        let cropController = CropViewController(croppingStyle: .default, image: pickerImage)
        
        cropController.delegate = self
        
        //AspectRatioのサイズをimageViewのサイズに合わせる。
        cropController.customAspectRatio = sceneView.frame.size
        
        //pickerを閉じたら、cropControllerを表示する。
        picker.dismiss(animated: true) {
            
            self.present(cropController, animated: true, completion: nil)
        }
        
    }
    
    //MARK: - 加工した画像の取得
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        
        display = image
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - キャンセル処理
    public func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        
        cropViewController.dismiss(animated: true, completion: nil)
    }
}


//MARK: - 平面をレンダリング
extension ViewController :ARSCNViewDelegate {
    
    internal func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { fatalError("Can't create plane geometry") }
        
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        planeGeometry.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.6)
        let planeNode = SCNNode(geometry: planeGeometry)

        planeNode.simdPosition = planeAnchor.center
        planeNode.eulerAngles.x = -.pi / 2
        node.addChildNode(planeNode)
    }

}
