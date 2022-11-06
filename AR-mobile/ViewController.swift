
import UIKit
import SceneKit
import ARKit
import CropViewController
  
class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var widthValue: UILabel!
    @IBOutlet weak var heightValue: UILabel!
    @IBOutlet weak var widthSlider: UISlider!
    @IBOutlet weak var heightSlider: UISlider!
    @IBOutlet weak var multipleNumber: UILabel!
    
    var display = UIImage()
    var photoNodes = [SCNNode]()
    var photoNodesBU = [SCNNode]()
    var axesNodes = [SCNNode]()
    var timer = Timer()
    var isFirst = true
    var rotateNow = true
    var position = SCNVector3()
    var number: Float = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        nodeRotate() // 回転させる
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("disappear")
        // Pause the view's session
        sceneView.session.pause()
        
        timer.invalidate() // 回転を止める
    }

    
    //MARK: - nodeを移動する
    @IBAction func moveToUp(_ sender: UIButton) {
        
        position = SCNVector3(position.x, position.y + 0.05 * number, position.z)
        setImageToScene()
    }
    
    @IBAction func moveToDown(_ sender: UIButton) {
        
        position = SCNVector3(position.x, position.y - 0.05 * number, position.z)
        setImageToScene()
    }
    
    @IBAction func moveToForward(_ sender: UIButton) {
        
        position = SCNVector3(position.x, position.y, position.z - 0.05 * number)
        setImageToScene()
    }
        
    @IBAction func moveToBack(_ sender: UIButton) {
        
        position = SCNVector3(position.x, position.y, position.z + 0.05 * number)
        setImageToScene()
    }
    
    @IBAction func moveToLeft(_ sender: UIButton) {

        position = SCNVector3(position.x - 0.05 * number, position.y, position.z)
        setImageToScene()

    }
    @IBAction func moveToRight(_ sender: UIButton) {
        
        position = SCNVector3(position.x + 0.05 * number, position.y, position.z)
        setImageToScene()
    }
    
    //MARK: - fuction Buttonで機能を割り当て
    //MARK: - △ボタン 表示/非表示切り替え
    @IBAction func triangleButton(_ sender: UIButton) {
        
        widthSlider.isHidden.toggle()
        heightSlider.isHidden.toggle()
        
    }
    
    //MARK: - ○ボタン ノードの発生
    @IBAction func circleButton(_ sender: UIButton) {
        
        if let camera = self.sceneView.pointOfView {
            let offset = SCNVector3(x: 0, y: 0.25, z: -2)
            position = camera.convertPosition(offset, to: nil)
        }
        
        setImageToScene()
        
        isFirst = false
    }
    
    //MARK: - xボタン 移動倍率制御
    @IBAction func xmarkButton(_ sender: UIButton) {
        
        if number == 1.0        { number = 2.0 }
        else if number == 2.0   { number = 3.0 }
        else                    { number = 1.0 }
        multipleNumber.text = "x\(Int(number))"
        
    }
    
    //MARK: - □ボタン 回転制御
    @IBAction func squareButton(_ sender: UIButton) {
        
        if rotateNow {
            timer.invalidate()
        } else {
            nodeRotate()
        }
        rotateNow.toggle()

    }
    
    //MARK: - slidebar でnodeの大きさ調整
    @IBAction func slideWidth(_ sender: UISlider) {
        let width = sender.value * 100
        let widthString = String(format: "%.1f", width)
        widthValue.text = "Width: \(widthString)cm"
    }
    @IBAction func slideHeight(_ sender: UISlider) {
        let height = sender.value * 100
        let heightString = String(format: "%.1f", height)
        heightValue.text = "Height: \(heightString)cm"
    }
    
    //MARK: - 写真を設置
    private func setImageToScene() {
        if !isFirst {
            
            // ２回目以降の設置は、前回作成のnode削除
            photoNodes.last?.removeFromParentNode()
            photoNodes[photoNodes.count - 2].removeFromParentNode()
            photoNodes = photoNodesBU // BuckUp

        }
        
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
        let node2 = node.clone()
        
        // カメラの位置からノードの角度を調整する。
        if let camera = self.sceneView.pointOfView {
            let cameraAngleY = camera.eulerAngles.y
            node.eulerAngles.y = cameraAngleY // カメラのy軸のオイラー角と同じにする
            node2.eulerAngles.y = cameraAngleY + .pi // node2は裏側としてレンダリングする
        }
        
        node.position = position
        node2.position = position
        
        // render sceneView
        sceneView.scene.rootNode.addChildNode(node)
        sceneView.scene.rootNode.addChildNode(node2)
        
        // add node to Array
        photoNodes.append(node)
        photoNodes.append(node2)
        
        createAxes() // 軸をレンダー
    }
}


//MARK: - Presenter
//MARK: - ノードの処理
extension ViewController {
    //MARK: - 軸ノードを作成
    func createAxes() {
        
        if !isFirst {
            if !axesNodes.isEmpty {
                for axes in axesNodes {
                    axes.removeFromParentNode()
                }
            }
            axesNodes = [SCNNode]() // initialize property
        }
        
        // create line geometry
        let lineX = SCNCylinder(radius: 0.002, height: 0.5)
        let lineY = SCNCylinder(radius: 0.002, height: 0.5)
        let lineZ = SCNCylinder(radius: 0.002, height: 0.5)
        
        // set line material
        let materialX = SCNMaterial()
        let materialY = SCNMaterial()
        let materialZ = SCNMaterial()
        materialX.diffuse.contents = UIColor.red
        materialY.diffuse.contents = UIColor.green
        materialZ.diffuse.contents = UIColor.blue
        lineX.materials = [materialX]
        lineY.materials = [materialY]
        lineZ.materials = [materialZ]
        
        // create nodeX, nodeY and nodeZ
        let nodeX = SCNNode(geometry: lineX)
        let nodeY = SCNNode(geometry: lineY)
        let nodeZ = SCNNode(geometry: lineZ)
        
        // set position
        nodeX.position = SCNVector3(position.x + Float(lineX.height)/2, position.y, position.z)
        nodeY.position = SCNVector3(position.x, position.y + Float(lineY.height)/2, position.z)
        nodeZ.position = SCNVector3(position.x, position.y, position.z + Float(lineZ.height)/2)
        
        // set angles
        nodeX.eulerAngles.z = .pi/2
        nodeZ.eulerAngles.x = .pi/2
        
        // render sceneView
        sceneView.scene.rootNode.addChildNode(nodeX)
        sceneView.scene.rootNode.addChildNode(nodeY)
        sceneView.scene.rootNode.addChildNode(nodeZ)
        
        // add node to Array
        axesNodes.append(nodeX)
        axesNodes.append(nodeY)
        axesNodes.append(nodeZ)
        
    }
    
    //MARK: - ノードの回転
    func nodeRotate() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (Timer) in
            
            for photo in self.photoNodes {
                photo.eulerAngles.y += .pi/180
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
        if !axesNodes.isEmpty {
            for axes in axesNodes {
                axes.removeFromParentNode()
            }
        }
        // initialize property
        photoNodes = [SCNNode]()
        photoNodesBU = [SCNNode]()
        axesNodes = [SCNNode]()
        isFirst = true
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
            photoNodesBU = photoNodes // Update to buckUp
        }
        picker.dismiss(animated: true, completion: nil) // UIimageへのダウンキャストが失敗した時
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
