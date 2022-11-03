//
//
//import Foundation
//import UIKit
//
//class BalloonView: UIView {
//
//    let triangleSideLength: CGFloat = 20
//    let triangleHeight: CGFloat = 17.3
//
//    override func draw(_ rect: CGRect) {
//        super.draw(rect)
//        
//        if let context = UIGraphicsGetCurrentContext() {
//            context.setFillColor(UIColor.green.cgColor)
//            contextBalloonPath(context: context, rect: rect)
//        }
//    }
//
//    func contextBalloonPath(context: CGContext, rect: CGRect) {
//        let triangleRightCorner = (x: (rect.size.width + triangleSideLength) / 2, y: CGRectGetMaxY(rect) - triangleHeight)
//        let triangleBottomCorner = (x: rect.size.width / 2, y: CGRectGetMaxY(rect))
//        let triangleLeftCorner = (x: (rect.size.width - triangleSideLength) / 2, y: CGRectGetMaxY(rect) - triangleHeight)
//
//        // 塗りつぶし
//        context.addRect(CGRectMake(0, 0, 280, rect.size.height - triangleHeight))
//        context.fillPath()
////        
////        CGContextMoveToPoint(context, triangleLeftCorner.x, triangleLeftCorner.y)
////        CGContextAddLineToPoint(context, triangleBottomCorner.x, triangleBottomCorner.y)
////        CGContextAddLineToPoint(context, triangleRightCorner.x, triangleRightCorner.y)
////        CGContextFillPath(context)
//    }
//
//}
