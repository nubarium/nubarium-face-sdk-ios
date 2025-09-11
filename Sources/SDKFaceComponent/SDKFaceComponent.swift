import Foundation

#if canImport(UIKit)
import UIKit

/// Fachada principal del SDK que expondrás al integrador.
public final class SDKFaceComponent {

    // MARK: - Config pública (API)
    public var livenessRequired: Bool = true
    public var level: AntispoofingLevel = .medium
    public var showPreview: Bool = false
    public var showIntro: Bool = true
    public var enableVideoHelp: Bool = false
    public var enableTroubleshootHelp: Bool = false
    public var timeout: Int = 180
    public var maxValidations: Int = 3
    public var sideView: CameraSideView = .front
    public var allowManualSideView: Bool = false

    private weak var hostViewController: UIViewController?

    // MARK: - Init
    public init(hostViewController: UIViewController) {
        self.hostViewController = hostViewController
    }

    // MARK: - Flujo principal (mínimo para compilar)
    @discardableResult
    public func startCaptureFlow() -> UIViewController {
        let vc = UIResources.makeCaptureViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        hostViewController?.present(nav, animated: true, completion: nil)
        return nav
    }
}

#else

// Fallback para macOS / entornos sin UIKit, para permitir `swift build` sin error.
public final class SDKFaceComponent {
    public var livenessRequired: Bool = true
    public var level: AntispoofingLevel = .medium
    public var showPreview: Bool = false
    public var showIntro: Bool = true
    public var enableVideoHelp: Bool = false
    public var enableTroubleshootHelp: Bool = false
    public var timeout: Int = 180
    public var maxValidations: Int = 3
    public var sideView: CameraSideView = .front
    public var allowManualSideView: Bool = false

    public init(hostViewController: Any? = nil) {
        preconditionFailure("SDKComponent requiere iOS/UIKit. Compila con Xcode apuntando a un destino iOS.")
    }

    @discardableResult
    public func startCaptureFlow() -> Any { return () }
}

#endif
