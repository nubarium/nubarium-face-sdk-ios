//
//  FaceDetection.swift
//  SDKFaceComponent
//

#if canImport(UIKit)
import UIKit
import AVFoundation
import Vision

/// Métricas de una cara en coordenadas de la vista (tras mapear desde Vision).
public struct FaceMetrics {
    public let rectInView: CGRect               // bbox en coords de la vista (previewLayer)
    public let yaw: CGFloat?                    // rotación Y (izq/der), radianes
    public let roll: CGFloat?                   // inclinación, radianes
    public let earLeft: CGFloat?                // eye-aspect-ratio aprox ojo izq
    public let earRight: CGFloat?               // eye-aspect-ratio aprox ojo der
    public var eyesClosed: Bool {               // true si ambos ojos "cerrados"
        let l = earLeft ?? 1, r = earRight ?? 1
        return l < 0.19 && r < 0.19
    }
}

public final class VisionFaceDetector {

    public init() {}

    /// Procesa un frame y devuelve métricas de cada cara detectada.
    public func process(pixelBuffer: CVPixelBuffer,
                        orientation: CGImagePropertyOrientation,
                        previewLayer: AVCaptureVideoPreviewLayer) throws -> [FaceMetrics] {

        let req = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: orientation,
                                            options: [:])
        try handler.perform([req])

        guard let results = req.results as? [VNFaceObservation], !results.isEmpty else {
            return []
        }

        return results.compactMap { obs in
            // Vision -> AVFoundation metadata rect (invierte eje Y)
            let vr = obs.boundingBox
            let avRect = CGRect(x: vr.origin.x,
                                y: 1 - vr.origin.y - vr.size.height,
                                width: vr.size.width,
                                height: vr.size.height)
            let rectInView = previewLayer.layerRectConverted(fromMetadataOutputRect: avRect)

            let earL = Self.ear(from: obs.landmarks?.leftEye)
            let earR = Self.ear(from: obs.landmarks?.rightEye)

            return FaceMetrics(
                rectInView: rectInView.integral,
                yaw: obs.yaw.map { CGFloat(truncating: $0) },
                roll: obs.roll.map { CGFloat(truncating: $0) },
                earLeft: earL,
                earRight: earR
            )
        }
    }

    // EAR aproximado con el bounding de puntos del ojo (robusto)
    private static func ear(from eye: VNFaceLandmarkRegion2D?) -> CGFloat? {
        guard let eye = eye, eye.pointCount >= 6 else { return nil }
        let pts = eye.normalizedPoints.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
        let xs = pts.map { $0.x }, ys = pts.map { $0.y }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return nil }
        let w = max(maxX - minX, 0.0001)
        let h = max(maxY - minY, 0.0001)
        return h / w
    }
}
#endif
