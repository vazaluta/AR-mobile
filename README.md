# AR-mobile
 iPhoneのカメラを使用して、部屋にモビールを置くシミュレーションができるアプリです。<br >
 <img width="700" alt="Simulator Screen Shot - iPhone 14 Pro - 2022-11-04 at 20.55.17" src="https://user-images.githubusercontent.com/103005182/200112814-d172c5d9-c120-4da8-87de-0dac07b2e92d.PNG">

# URL
https://apps.apple.com/jp/app/ar-mobile/id6444208755 <br>
①このアプリは、デフォルトでは白い平面が生成されます。<br>
②フォルダマークから画像を選択することで、好きな画像を配置することができます(○ボタン)。<br>
③また、デフォルトで物体が回るように設定しているため、<br>
モビールが回転したときのサイズ感が分かります。(回転は□ボタンで止められます。)<br>
④物体は前後左右と上下に動かすことが可能で、移動速度も変更可能です(xボタン)。<br>
<img width="700" alt="スクリーンショット 2022-11-05 19 38 57" src="https://user-images.githubusercontent.com/103005182/200115959-00a58b45-2ec6-452f-a101-9cde545269c9.png"> <br>
<br>
このように、部屋にモビールを飾ったときの雰囲気をつかむことに、最適なアプリケーションとなっています。
<img width="700" alt="スクリーンショット 2022-11-05 19 38 57" src="https://user-images.githubusercontent.com/103005182/203094604-49fd3e1e-140e-4bfc-ae0e-b60cfdf55252.png">


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
