# Nubarium Face SDK • iOS (SPM)

SDK de **captura facial con prueba de vida (liveness)** para iOS.  
Guía al usuario (centrado, ojos/parpadeo), toma la foto **solo** si pasa los criterios y luego la **envía a un servicio REST**; el resultado de validación y la imagen en **Base64** regresan en el callback.

> **Repo SPM:** https://github.com/nubarium/nubarium-face-sdk-ios  
> **Mínimo:** iOS 13 · Xcode 15/16 · Swift 5.9+

---

## Instalación (Swift Package Manager)

### Opción A — Desde Xcode

1. **File ▸ Add Packages…**
2. Pega la URL del repo:
   ```
   https://github.com/nubarium/nubarium-face-sdk-ios.git
   ```
3. Elige la **versión** (tag) que quieras usar.
4. En *Add to Target*, marca tu app.
5. En el listado de productos, selecciona **`SDKFaceComponent`** (es el nombre del producto SPM).  
   > En tu código **importarás `SDKFaceKit`**, que es el *target* con la API del SDK.

### Opción B — `Package.swift`

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TuApp",
    platforms: [.iOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/nubarium/nubarium-face-sdk-ios.git",
                 from: "1.0.5") // o exact("1.0.5")
    ],
    targets: [
        .target(
            name: "TuApp",
            dependencies: [
                // Producto que expone el package
                .product(name: "SDKFaceComponent", package: "nubarium-face-sdk-ios")
            ]
        )
    ]
)
```

> **Nota de nombres**  
> - **Producto SPM:** `SDKFaceComponent` (así aparece al agregar el paquete).  
> - **Módulo a importar:** `SDKFaceKit` (donde vive la clase `FaceCaptureSDK`).

---

## Permisos

Agrega a tu **Info.plist** la clave de cámara:

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceder a la cámara para verificar prueba de vida y tomar una foto.</string>
```

> Prueba en **dispositivo real** (la cámara no funciona en simulador).

---

## Quick Start

```swift
import UIKit
import SDKFaceKit   // ⬅️ módulo del wrapper con la API pública

final class ViewController: UIViewController {

    // Mantén una referencia fuerte mientras el flujo está activo
    private var sdk: FaceCaptureSDK?
    
    // Modelo de respuesta del SDK
    struct FaceResult: Codable {
        let validate: String      // "ok" | "cancel" | "fail"
        let imageBase64: String   // JPEG en base64
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func startSDK(_ sender: Any) {
        print("Iniciando SDK...")

        // 1) Crear fachada del SDK
        let sdk = FaceCaptureSDK(hostViewController: self)

        // (Opcional) Config rápida
        sdk.enableVideoHelp = true
        sdk.enableTroubleshootHelp = false
        sdk.helpVideoURL = URL(string: "https://tu.video/ayuda")
        sdk.helpInstructionsURL = URL(string: "https://tu.pagina/faq")

        // 2) Iniciar flujo con credenciales
        sdk.startCaptureFlow(user: "demoUser", pass: "demoPass") { json in
            // 1) Parseo seguro
            guard let data = json.data(using: .utf8),
                  let result = try? JSONDecoder().decode(FaceResult.self, from: data) else {
                print("JSON inválido:", json)
                return
            }

            // 2) Log ligero (no imprimas todo el base64)
            print("validate =", result.validate,
                  "| base64 length =", result.imageBase64.count,
                  "| prefix =", result.imageBase64.prefix(32), "...")

            // 3) Ramas de flujo
            guard result.validate == "ok" else {
                // cancel u otro estado
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "SDK",
                                                  message: "Usuario canceló",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
                return
            }

            // 4) Decodificar la imagen
            let options: Data.Base64DecodingOptions = [.ignoreUnknownCharacters]
            if let imgData = Data(base64Encoded: result.imageBase64, options: options),
               let image = UIImage(data: imgData) {

                // Ejemplo: mostrarla
                DispatchQueue.main.async {
                    let vc = UIViewController()
                    vc.view.backgroundColor = .systemBackground
                    let iv = UIImageView(image: image)
                    iv.contentMode = .scaleAspectFit
                    iv.frame = vc.view.bounds
                    iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    vc.view.addSubview(iv)
                    self.present(vc, animated: true)
                }

                // (Opcional) Guardar a tmp
                let url = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("face.jpg")
                try? imgData.write(to: url)
                print("guardado en:", url.path)
            } else {
                print("No se pudo decodificar la imagen base64")
            }
        }

        // 3) Retén la instancia para que no se libere
        self.sdk = sdk
    }
}
```

---

## Qué hace el SDK

1. **Guía al usuario** para posicionar el rostro centrado.
2. **Verifica liveness** (apertura/parpadeo de ojos / microacciones).
3. **Captura** la fotografía **solo si** pasa los criterios.
4. **Envía** la imagen a un **servicio REST** (configurado dentro del SDK).
5. **Devuelve** un **JSON (String)** al callback con el resultado y la imagen en base64.

### Contrato de respuesta

```json
{
  "validate": "ok",
  "imageBase64": "/9j/4AAQSkZJRgABAQ..."
}
```

- `validate`: `"ok"` (éxito), `"cancel"` (usuario salió), `"fail"` (no pasó liveness u otro error).
- `imageBase64`: Foto en **JPEG** codificada en Base64.

---

## API Pública (resumen)

```swift
public final class FaceCaptureSDK {
    public init(hostViewController: UIViewController)

    // UI de ayuda opcional
    public var enableVideoHelp: Bool
    public var enableTroubleshootHelp: Bool
    public var helpVideoURL: URL?
    public var helpInstructionsURL: URL?

    /// Inicia el flujo guiado de captura y liveness.
    /// - Parameters:
    ///   - user: Usuario/ID para el backend.
    ///   - pass: Password/secret asociado.
    ///   - completion: JSON (String) con { validate, imageBase64 }.
    public func startCaptureFlow(
        user: String,
        pass: String,
        completion: @escaping (String) -> Void
    )
}
```

---

## Buenas prácticas

- **Referencia fuerte**: guarda `FaceCaptureSDK` como propiedad (`var sdk: FaceCaptureSDK?`) hasta recibir el callback.
- **UI en main**: presenta/cierras pantallas en `DispatchQueue.main`.
- **Logs**: evita imprimir el **Base64** completo en consola.
- **Privacidad**: informa al usuario sobre el uso de la cámara y tratamiento de imágenes.
- **ATS**: si tu backend no usa HTTPS estricto, configura *App Transport Security*.

---

## Versionado

- El package usa **tags** SemVer (`v1.0.5`, `v1.0.6`, …).
- Al agregar el paquete en Xcode puedes elegir la versión/intervalo (ej. *Up to Next Major*).
- Consulta *Releases* en GitHub para notas y cambios.

---

## Soporte

- Issues: https://github.com/nubarium/nubarium-face-sdk-ios/issues  
- Pull Requests: bienvenidos si aplican a docs / integración.
- Licencia: ver `LICENSE` en el repo.
