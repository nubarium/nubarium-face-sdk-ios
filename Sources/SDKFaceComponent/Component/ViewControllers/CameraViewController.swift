//
//  CameraViewController.swift
//  SDKFaceComponent
//

#if canImport(UIKit)
import UIKit
import AVFoundation
import Vision

public final class CameraViewController: UIViewController,
                                         AVCaptureVideoDataOutputSampleBufferDelegate,
                                         AVCapturePhotoCaptureDelegate {

    // MARK: - Config pública
    public var onCapture: ((UIImage) -> Void)?
    public var onCancel: (() -> Void)?
    public var livenessRequired: Bool = false
    public var autoCapture: Bool = true
    public var debugLogs: Bool = true   // logs en consola

    // MARK: - AV
    private let session = AVCaptureSession()
    private var videoInput: AVCaptureDeviceInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoQueue = DispatchQueue(label: "sdkface.video")

    // MARK: - Vision
    private let detector = VisionFaceDetector()
    private var okStableCount = 0
    private var lastBlinkTs: TimeInterval = 0

    // MARK: - UI (overlay)
    private let overlayView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = false
        v.backgroundColor = .clear
        return v
    }()
    private let messageLabel: UILabel = {
        let l = UILabel()
        l.text = Localization.localizedString("NBM_FACE_ALIGN")
        l.font = .boldSystemFont(ofSize: 18)
        l.textAlignment = .center
        l.textColor = .systemOrange
        l.numberOfLines = 3
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let dimmingLayer = CAShapeLayer()
    private let borderLayer  = CAShapeLayer()
    private var ovalRect: CGRect = .zero

    private enum CaptureState: String {
        case noFace, many, far, close, left, right, up, down, align, blink, hold, captured
    }
    private var state: CaptureState = .align {
        didSet {
            guard state != oldValue else { return }
            if debugLogs { print("SDKFaceComponent/State:", state.rawValue) }
            applyUI(for: state)
        }
    }

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureNavBar()
        buildLayout()
        requestCameraAndStart()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutPreviewAndMask()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    // MARK: - UI
    private func configureNavBar() {
        title = "Cámara"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self, action: #selector(closeTapped)
        )
    }

    private func buildLayout() {
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        dimmingLayer.fillRule = .evenOdd
        dimmingLayer.fillColor = view.backgroundColor?.cgColor ?? UIColor.white.cgColor
        borderLayer.strokeColor = UIColor.systemGray3.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 2
        overlayView.layer.addSublayer(dimmingLayer)
        overlayView.layer.addSublayer(borderLayer)
    }

    private func layoutPreviewAndMask() {
        previewLayer?.frame = view.bounds
        overlayView.frame = view.bounds

        let w = view.bounds.width * 0.65
        let h = w * 1.25
        let x = (view.bounds.width - w) / 2.0
        let top = messageLabel.frame.maxY + 24
        let availH = view.bounds.height - top - 80
        let y = top + (availH - h) / 2.0
        ovalRect = CGRect(x: x, y: max(top, y), width: w, height: h)

        let outer = UIBezierPath(rect: overlayView.bounds)
        let inner = UIBezierPath(ovalIn: ovalRect)
        outer.append(inner)
        dimmingLayer.path = outer.cgPath
        borderLayer.path = UIBezierPath(ovalIn: ovalRect).cgPath

        view.bringSubviewToFront(messageLabel)
    }

    private func applyUI(for state: CaptureState) {
        switch state {
        case .noFace:   setMessage("NBM_FACE_NOFACE",  color: .systemOrange)
        case .many:     setMessage("NBM_FACE_MANY",    color: .systemOrange)
        case .far:      setMessage("NBM_FACE_FAR",     color: .systemOrange)
        case .close:    setMessage("NBM_FACE_CLOSE",   color: .systemOrange)
        case .left:     setMessage("NBM_FACE_LEFT",    color: .systemOrange)
        case .right:    setMessage("NBM_FACE_RIGHT",   color: .systemOrange)
        case .up:       setMessage("NBM_FACE_UP",      color: .systemOrange)
        case .down:     setMessage("NBM_FACE_DOWN",    color: .systemOrange)
        case .align:    setMessage("NBM_FACE_ALIGN",   color: .systemOrange)
        case .blink:    setMessage("NBM_FACE_BLINK",   color: .systemOrange)
        case .hold:     setMessage("NBM_FACE_HOLD",    color: .systemGreen)
        case .captured: setMessage("NBM_OK",           color: .systemGreen)
        }
    }

    private func setMessage(_ key: String, color: UIColor) {
        messageLabel.text = Localization.localizedString(key)
        messageLabel.textColor = color
        borderLayer.strokeColor = color.withAlphaComponent(0.85).cgColor
    }

    // MARK: - Cámara
    private func requestCameraAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async { granted ? self?.setupSession() : self?.showDeniedAlert() }
            }
        default: showDeniedAlert()
        }
    }

    private func setupSession() {
        if debugLogs { print("SDKFaceComponent:", "setupSession") }

        session.beginConfiguration()
        session.sessionPreset = .high

        // input frontal
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        ).devices.first ?? AVCaptureDevice.default(for: .video) else {
            session.commitConfiguration(); return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input); videoInput = input }
        } catch { print("SDKFaceComponent/Error input:", error) }

        // video frames para Vision
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:
                                     Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        videoOutput.connection(with: .video)?.videoOrientation = .portrait

        // foto final
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }

        // preview
        if previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(layer, at: 0)
            previewLayer = layer
        }

        session.commitConfiguration()
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                if self?.debugLogs == true { print("SDKFaceComponent:", "session.startRunning") }
            }
        }
    }

    private func showDeniedAlert() {
        let alert = UIAlertController(
            title: Localization.localizedString("NBM_CAMERA_DENIED_TITLE"),
            message: Localization.localizedString("NBM_CAMERA_DENIED_BODY"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Localization.localizedString("NBM_OK"), style: .default))
        present(alert, animated: true)
    }

    @objc private func closeTapped() {
        onCancel?()
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Video frames → Vision
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {

        guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer),
              let pl = self.previewLayer else { return }

        // Front/portrait → .leftMirrored (estable y rápido)
        let exif: CGImagePropertyOrientation = .leftMirrored

        do {
            let faces = try detector.process(pixelBuffer: pixel,
                                             orientation: exif,
                                             previewLayer: pl)
            DispatchQueue.main.async { self.evaluate(faces: faces) }
        } catch {
            if debugLogs { print("SDKFaceComponent/Vision error:", error) }
        }
    }

    // MARK: - Evaluación y mensajes
    private func evaluate(faces: [FaceMetrics]) {
        guard !faces.isEmpty else {
            state = .noFace; okStableCount = 0; return
        }
        if faces.count > 1 {
            state = .many; okStableCount = 0; return
        }
        guard let f = faces.first else { return }

        // Distancia por tamaño relativo al óvalo
        let faceH = f.rectInView.height
        let targetH = ovalRect.height * 0.80
        if faceH < targetH * 0.65 { state = .far; okStableCount = 0; return }
        if faceH > targetH * 1.25 { state = .close; okStableCount = 0; return }

        // Centrando
        let faceCenter = CGPoint(x: f.rectInView.midX, y: f.rectInView.midY)
        let ovalCenter = CGPoint(x: ovalRect.midX, y: ovalRect.midY)
        let dx = (faceCenter.x - ovalCenter.x) / ovalRect.width
        let dy = (faceCenter.y - ovalCenter.y) / ovalRect.height
        let tol: CGFloat = 0.14
        if dx < -tol { state = .left; okStableCount = 0; return }
        if dx >  tol { state = .right; okStableCount = 0; return }
        if dy < -tol { state = .up; okStableCount = 0; return }
        if dy >  tol { state = .down; okStableCount = 0; return }

        // Orientación (yaw/roll en grados)
        let toDeg = { (r: CGFloat?) -> CGFloat in (r ?? 0) * 180 / .pi }
        if abs(toDeg(f.yaw))  > 10 { state = .align; okStableCount = 0; return }
        if abs(toDeg(f.roll)) > 10 { state = .align; okStableCount = 0; return }

        // Liveness: parpadeo reciente
        if livenessRequired {
            let now = CACurrentMediaTime()
            if f.eyesClosed { lastBlinkTs = now }
            if now - lastBlinkTs > 5.0 {
                state = .blink; okStableCount = 0; return
            }
        }

        // OK estable
        state = .hold
        okStableCount += 1

        if autoCapture && okStableCount >= 12 {
            okStableCount = 0
            capturePhoto()
        }
    }

    // MARK: - Foto
    private func capturePhoto() {
        if debugLogs { print("SDKFaceComponent:", "capturePhoto") }
        let settings = AVCapturePhotoSettings()
        if videoInput?.device.hasFlash == true { settings.flashMode = .off }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    public func photoOutput(_ output: AVCapturePhotoOutput,
                            didFinishProcessingPhoto photo: AVCapturePhoto,
                            error: Error?) {
        if let err = error { print("SDKFaceComponent/photo error:", err); return }
        guard let data = photo.fileDataRepresentation(),
              let img = UIImage(data: data) else { return }
        state = .captured
        onCapture?(img)
        navigationController?.popViewController(animated: true)
    }
}
#endif
