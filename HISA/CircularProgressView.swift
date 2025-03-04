import UIKit

class CircularProgressView: UIView {
    
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        let circularPath = UIBezierPath(
            arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2),
            radius: (min(bounds.width, bounds.height) / 2) - 5,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )
        
        trackLayer.path = circularPath.cgPath
        trackLayer.strokeColor = UIColor.lightGray.cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = 10
        layer.addSublayer(trackLayer)
        
        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = UIColor.systemBlue.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 10
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }
    
    func setProgress(to progress: CGFloat, animated: Bool = true, duration: CFTimeInterval = 0.5) {
        let clampedProgress = max(0, min(progress, 1))
        
        switch clampedProgress {
        case 0...0.2:
            progressLayer.strokeColor = UIColor.systemRed.cgColor
        case 0.2...0.4:
            progressLayer.strokeColor = UIColor.systemOrange.cgColor
        case 0.4...0.6:
            progressLayer.strokeColor = UIColor.systemYellow.cgColor
        case 0.6...0.8:
            progressLayer.strokeColor = UIColor.systemGreen.cgColor
        case 0.8...1.0:
            progressLayer.strokeColor = UIColor.systemBlue.cgColor
        default:
            progressLayer.strokeColor = UIColor.clear.cgColor
        }
        
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = clampedProgress
            animation.duration = duration
            progressLayer.add(animation, forKey: "progressAnimation")
        }
        
        progressLayer.strokeEnd = clampedProgress
    }
}
