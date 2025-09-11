//
//  Utils.swift
//  SDKFaceComponent
//
//  Created by Luis Arriaga on 10/09/25.
//

import Foundation

// MARK: - Bundle helper (SPM vs. no SPM)
public enum PackageBundle {
    /// Devuelve el bundle del paquete (SPM) o un bundle válido fuera de SPM.
    @inline(__always)
    public static var current: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        // Fallback (útil si este archivo se compila dentro de un framework/app)
        return Bundle(for: _BundleToken.self)
        #endif
    }
}

private final class _BundleToken {}


// MARK: - Localization
public enum Localization {
    /// Busca primero en `alternateTable`; si no existe, cae a `defaultTable` (Localizable por defecto).
    @inlinable
    public static func localizedString(_ key: String,
                                       defaultTable: String = "Localizable",
                                       alternateTable: String? = nil) -> String {
        let bundle = PackageBundle.current

        if let alt = alternateTable, !alt.isEmpty {
            let value = bundle.localizedString(forKey: key, value: nil, table: alt)
            if value != key { return value }
        }

        return bundle.localizedString(forKey: key, value: nil, table: defaultTable)
    }
}


// MARK: - Resource loading (URLs, Data, Strings, JSON)
public enum ResourceLoader {

    public static func url(forResource name: String,
                           withExtension ext: String? = nil,
                           subdirectory: String? = nil) -> URL? {
        PackageBundle.current.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
    }

    public static func data(forResource name: String,
                            withExtension ext: String? = nil,
                            subdirectory: String? = nil) throws -> Data {
        guard let url = url(forResource: name, withExtension: ext, subdirectory: subdirectory) else {
            throw NSError(domain: "SDKFaceComponent.ResourceLoader",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey:
                                     "Resource \(name)\(ext.map { ".\($0)" } ?? "") not found in bundle"])
        }
        return try Data(contentsOf: url)
    }

    public static func string(forResource name: String,
                              withExtension ext: String = "txt",
                              encoding: String.Encoding = .utf8) throws -> String {
        let data = try data(forResource: name, withExtension: ext)
        guard let str = String(data: data, encoding: encoding) else {
            throw NSError(domain: "SDKFaceComponent.ResourceLoader",
                          code: 2,
                          userInfo: [NSLocalizedDescriptionKey:
                                     "Unable to decode \(name).\(ext) as \(encoding)"])
        }
        return str
    }

    public static func decodeJSON<T: Decodable>(_ type: T.Type,
                                                named name: String,
                                                withExtension ext: String = "json",
                                                decoder: JSONDecoder = JSONDecoder()) throws -> T {
        let data = try data(forResource: name, withExtension: ext)
        return try decoder.decode(T.self, from: data)
    }
}


// MARK: - UIKit helpers (solo cuando UIKit está disponible)
#if canImport(UIKit)
import UIKit

public enum UIHelpers {

    /// Carga una imagen desde el bundle del paquete.
    public static func image(named name: String) -> UIImage? {
        UIImage(named: name, in: PackageBundle.current, compatibleWith: nil)
    }

    /// Instancia una vista desde un XIB dentro del paquete.
    public static func viewFromNib<T: UIView>(_ nibName: String, owner: Any? = nil) -> T {
        let nib = UINib(nibName: nibName, bundle: PackageBundle.current)
        guard let view = nib.instantiate(withOwner: owner, options: nil).first as? T else {
            fatalError("Unable to load \(T.self) from nib \(nibName)")
        }
        return view
    }

    /// Obtiene un storyboard dentro del paquete.
    public static func storyboard(name: String) -> UIStoryboard {
        UIStoryboard(name: name, bundle: PackageBundle.current)
    }
}
#endif
