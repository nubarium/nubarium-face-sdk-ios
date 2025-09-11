#if canImport(UIKit)
import UIKit
import AVFoundation

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    var session: AVCaptureSession? {
        get { videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.videoGravity = .resizeAspectFill
        if let connection = videoPreviewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }
}
#endif
