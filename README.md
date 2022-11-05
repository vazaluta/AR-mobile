# AR-mobile
 iPhoneのカメラを使用して、部屋にモビールを置くシミュレーションができるアプリです。<br >
 <img width="700" alt="スクリーンショット 2020-05-07 0 06 18" src="https://user-images.githubusercontent.com/103005182/200112814-d172c5d9-c120-4da8-87de-0dac07b2e92d.PNG">

このアプリは、デフォルトでは白い平面が生成されます。フォルダマークから画像を選択することで、好きな画像を配置することができます(○ボタン)。また、デフォルトで物体が回るように設定しているため、モビールが回転したときのサイズ感が分かります。(回転は□ボタンで止められます。)
物体は前後左右と上下に動かすことが可能で、移動速度も変更可能です(xボタン)。
このように、部屋にモビールを飾ったときの雰囲気をつかむことに、最適なアプリケーションとなっています。

# 使用技術
- Swift 5.7.1
- ARKit(SceneKit)
- CocoaPods
- Delegate

# 機能一覧
- 画像処理
  - 画像選択（UIImagePickerControllerDelegate, UINavigationControllerDelegate）
  - 画像トリミング（CropViewControllerDelegate）
- AR(ARSCNViewDelegate)
  - ノードの作成
  - ノードの回転
  - ノードの移動 
  - ノードの削除
