//
//  CaptureViewController.swift
//  SDKFaceComponent
//

#if canImport(UIKit)
import UIKit
import SafariServices
import Lottie

/// Pantalla de introducción del SDK (título, texto, ilustración y botón INICIAR),
/// con menú de ayuda “?” que muestra: Video de explicación / Instrucciones y dudas.
public final class CaptureViewController: UIViewController {

    // MARK: - Config pública (la app cliente puede modificar esto)

    /// Muestra u oculta las opciones del menú de ayuda.
    public var enableVideoHelp: Bool = true
    public var enableTroubleshootHelp: Bool = true

    /// Callbacks opcionales inyectados por la app cliente.
    public var onHelpVideo: (() -> Void)?
    public var onHelpInstructions: (() -> Void)?
    public var onStart: (() -> Void)?

    /// Si no se proveen callbacks, el SDK usará estas URLs como comportamiento por defecto.
    public var helpVideoURL: URL?
    public var helpInstructionsURL: URL? = URL(string: "https://github.com/nubarium/Biometric-SDK-iOS")
    

    // MARK: - UI

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = Localization.localizedString("NBM_FACE_TITLE") // "Prueba de vida y Captura Facial"
        l.font = .boldSystemFont(ofSize: 22)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.text = Localization.localizedString("NBM_FACE_BODY")
        l.font = .systemFont(ofSize: 16)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let heroContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var animationView: LottieAnimationView?

    private let startButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(Localization.localizedString("NBM_FACE_START").uppercased(), for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 17)
        b.backgroundColor = .systemBlue
        b.tintColor = .white
        b.layer.cornerRadius = 10
        b.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureNavBar()
        buildLayout()
        loadHero()
    }

    // MARK: - NavBar

    private func configureNavBar() {
        

        // Si este VC es root del UINavigationController, añadimos un "Back" manual
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: Localization.localizedString("NBM_BACK"),
                style: .plain,
                target: self,
                action: #selector(closeTapped)
            )
        }

        // Botón de ayuda (?) sólo si hay alguna opción activa
        if enableVideoHelp || enableTroubleshootHelp {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "questionmark.circle"),
                style: .plain,
                target: self,
                action: #selector(helpTapped)
            )
        }
    }

    // MARK: - Layout

    private func buildLayout() {
        [titleLabel, bodyLabel, heroContainer, startButton].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            heroContainer.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 24),
            heroContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heroContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.62),
            heroContainer.heightAnchor.constraint(equalTo: heroContainer.widthAnchor),

            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            startButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.55)
        ])

        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
    }

    private func loadHero() {
        // 1) Intenta con Lottie (face_capture.json en Resources/Lotties)
        if let anim = LottieAnimation.named("face_capture", bundle: PackageBundle.current) {
            let av = LottieAnimationView(animation: anim)
            av.loopMode = .loop
            av.contentMode = .scaleAspectFit
            av.translatesAutoresizingMaskIntoConstraints = false
            heroContainer.addSubview(av)
            NSLayoutConstraint.activate([
                av.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
                av.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
                av.topAnchor.constraint(equalTo: heroContainer.topAnchor),
                av.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor)
            ])
            av.play()
            animationView = av
            return
        }

        // 2) Fallback: imagen (face_hero.* en Resources/Images)
        if let img = UIImage(named: "face_hero", in: PackageBundle.current, with: nil) {
            let iv = UIImageView(image: img)
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            heroContainer.addSubview(iv)
            NSLayoutConstraint.activate([
                iv.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
                iv.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
                iv.topAnchor.constraint(equalTo: heroContainer.topAnchor),
                iv.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor)
            ])
        }
    }

    // MARK: - Actions

    @objc private func startTapped() {
        if let onStart { onStart(); return }       // la app cliente intercepta si quiere
        print("SDKFaceComponent: onStart no configurado, continuar al flujo de cámara")
        // Comportamiento por defecto: continuar al flujo de cámara
        let vc = CameraViewController()
            navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func closeTapped() {
        if presentingViewController != nil && navigationController?.viewControllers.first === self {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Help Menu

    @objc private func helpTapped() {
        presentHelpMenu(from: navigationItem.rightBarButtonItem)
    }

    private func presentHelpMenu(from barButton: UIBarButtonItem?) {
        let title   = Localization.localizedString("NBM_HELP_TITLE")       // "Ayuda"
        let message = Localization.localizedString("NBM_HELP_SUBTITLE")    // "Selecciona…"

        // .alert para que se vea como tu captura; usa .actionSheet si prefieres
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if enableVideoHelp {
            alert.addAction(UIAlertAction(
                title: Localization.localizedString("NBM_HELP_VIDEO"),     // "Video de explicación"
                style: .default,
                handler: { [weak self] _ in self?.handleHelpVideo() }
            ))
        }

        if enableTroubleshootHelp {
            alert.addAction(UIAlertAction(
                title: Localization.localizedString("NBM_HELP_FAQ"),       // "Instrucciones y dudas"
                style: .default,
                handler: { [weak self] _ in self?.handleHelpInstructions() }
            ))
        }

        alert.addAction(UIAlertAction(
            title: Localization.localizedString("NBM_CANCEL"),             // "Cancelar"
            style: .cancel
        ))

        // iPad (si decides cambiar a .actionSheet, esto es necesario)
        if let pop = alert.popoverPresentationController {
            if let barButton { pop.barButtonItem = barButton }
            else { pop.sourceView = view; pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 1, width: 1, height: 1) }
        }

        present(alert, animated: true)
    }

    // MARK: - Handlers (callbacks o defaults)

    private func handleHelpVideo() {
        if let onHelpVideo {
            onHelpVideo()
        } else if let url = helpVideoURL {
            openInSafari(url)
        } else {
            showNotConfigured()
        }
    }

    private func handleHelpInstructions() {
        if let onHelpInstructions {
            onHelpInstructions()
        } else if let url = helpInstructionsURL {
            openInSafari(url)
        } else {
            showNotConfigured()
        }
    }

    // MARK: - Utilidades

    private func openInSafari(_ url: URL) {
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }

    private func showNotConfigured() {
        let alert = UIAlertController(
            title: Localization.localizedString("NBM_HELP_TITLE"),
            message: Localization.localizedString("NBM_NOT_CONFIGURED", defaultTable: "Localizable"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Localization.localizedString("NBM_OK"), style: .default))
        present(alert, animated: true)
    }
}
#endif
