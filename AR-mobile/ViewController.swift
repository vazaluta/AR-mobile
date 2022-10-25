
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
    var isFirst = true
    var timer = Timer()

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
        
        nodeRotate() // 回転させる
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        timer.invalidate() // 回転を止める
    }
    
    @IBAction func slideWidth(_ sender: UISlider) {
        let width = String(format: "%.2f", sender.value)
        widthValue.text = "\(width)m"
    }
    
    @IBAction func slideHeight(_ sender: UISlider) {
        let height = String(format: "%.2f", sender.value)
        heightValue.text = "\(height)m"
    }
    
    
    
    //MARK: - 写真を設置
    private func setImageToScene(image: UIImage, location: ARRaycastResult) {
        if !isFirst {
            
            // ２回目以降の設置は、前回作成のnode削除
            photoNodes.last?.removeFromParentNode()
            photoNodes[photoNodes.count - 2].removeFromParentNode()
            photoNodes = photoNodesBU // BuckUp

        }
        isFirst = false

        
        let width = widthSlider.value
        let height = heightSlider.value
        
        let plane = planeSizing(width: width, height: height) // setting plane node
        let material = SCNMaterial()
        material.diffuse.contents = image
        plane.materials = [material]
                
        let nodePosition = SCNVector3(
            x: location.worldTransform.columns.3.x,
            y: location.worldTransform.columns.3.y - Float(plane.height / 2),
            z: location.worldTransform.columns.3.z
        )
        
        let node = SCNNode() // nodeを作成
        node.geometry = plane
        
        var node2 = SCNNode() // nodeのクローンを作成する
        node2 = node.clone()
        
        if let camera = self.sceneView.pointOfView {
            node.eulerAngles.y = camera.eulerAngles.y // カメラのy軸のオイラー角と同じにする
            node2.eulerAngles.y = camera.eulerAngles.y + .pi // node2は裏側としてレンダリングする
        }
        
        node.position = nodePosition
        node2.position = nodePosition
        
        sceneView.scene.rootNode.addChildNode(node)
        sceneView.scene.rootNode.addChildNode(node2)
        
        photoNodes.append(node) // nodeをArrayに追加する
        photoNodes.append(node2)
    }
}


//MARK: - Presenter
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func planeSizing(width: Float, height: Float) -> SCNPlane {
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        return plane
    }
    
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
        
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView) //デコード
            // sceneView と、touchLocationが平面かをテストし、結果を返す。
            if let raycast = sceneView.raycastQuery(from: touchLocation, allowing: .estimatedPlane, alignment: .any) {
                if let raycastResult = sceneView.session.raycast(raycast).first {
                    // トリミングした画像とタッチした座標をもとに、nodeをsettingする。
                    setImageToScene(image: display, location: raycastResult)
                    print("size: \(display.size)")
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
            cropUIImagePicker(pickerImage: image, with: picker) //　トリミングする
            
            isFirst = true // first flag
            photoNodesBU = photoNodes // Update to buckUp
        }
        picker.dismiss(animated: true, completion: nil) // UIimageへのダウンキャストが失敗した時
    }
    
    
    //MARK: - ライトのON/OFF
    @IBAction func lightSwich(_ sender: UIBarButtonItem) {
        
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
    
    //MARK: - ノードの全削除
    @IBAction func trachButton(_ sender: UIBarButtonItem) {

        if !photoNodes.isEmpty {
            for photo in photoNodes {
                photo.removeFromParentNode()
            }
        }
        
        photoNodes = [SCNNode]()
        photoNodesBU = [SCNNode]()
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
        
        //今回は使わない、余計なボタン等を非表示にする。
//        cropController.aspectRatioPickerButtonHidden = true
//        cropController.resetAspectRatioEnabled = false
//        cropController.rotateButtonsHidden = true
        
        //cropBoxのサイズを固定する。
//        cropController.cropView.cropBoxResizeEnabled = false
        
        //pickerを閉じたら、cropControllerを表示する。
        picker.dismiss(animated: true) {
            
            self.present(cropController, animated: true, completion: nil)
        }
        
    }
    
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        //加工した画像が取得できる
        display = image
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    public func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        // キャンセル時
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

//func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
//    //トリミング編集が終えたら、呼び出される。
//    updateImageViewWithImage(image, fromCropViewController: cropViewController)
//    print(image)
//}
//
//func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
//    //トリミングした画像をsceneViewのimageに代入する。
//    display = image
//    print(image)
//
//    cropViewController.dismiss(animated: true, completion: nil)
//}

//MARK: - 平面をレンダリング
extension ViewController :ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}

        let planeNode = createPlane(withPlaneAnchor: planeAnchor)
        
        node.addChildNode(planeNode)

    }
    
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
