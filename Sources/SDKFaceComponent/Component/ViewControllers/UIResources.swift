#if canImport(UIKit)
import UIKit

public enum UIResources {
    /// Devuelve el VC principal del SDK.
    public static func makeCaptureViewController() -> UIViewController {
        return CaptureViewController()
    }
}
#endif
