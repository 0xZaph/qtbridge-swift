// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

import Foundation
import QtBridgeCpp
#if !QT_IS_CMAKE_BUILD
// `QmlImports` is provided by the Swift Package `qtforswift` and exposes a
// resource bundle that contains QML files, bundled Qt plugins, and binary artifacts.
// For CMake builds, the equivalent resources come from the system Qt installation.
import QmlImports

#endif

public class QMLApp {
    var qmlApp: QAppCpp

    public init() {
        self.qmlApp = QAppCpp()
    }

    public func setImportPath(path: String) {
        qmlApp.setImportPath(path)
    }

    public func setPluginsPath(path: String) {
        qmlApp.setPluginsPath(path)
    }

    public func addInitialProperty(name: String, value: QVariant) {
        qmlApp.addInitialProperty(name, value.cppVariant())
    }

    public func setRootQml(path: String) {
        qmlApp.setRootQml(path)
    }

    public func run(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>!) {
        qmlApp.run(argc, argv)
    }
}

@MainActor public protocol QApp {
    init()
    var qmlFileName: String { get }
    var bundle: Bundle { get }
    var initialProperties: [String : QObjectBuildable] { get }
}

@MainActor public extension QApp {
    var bundle: Bundle { .main }

    static func main() {
        let qApp = Self()
        let app = QMLApp()

        #if !QT_IS_CMAKE_BUILD
        // For SPM builds `QmlImports` exposes `Bundle.qmlImports` containing
        // the QML files and bundled plugins. For CMake builds the equivalent
        // resources come from the system Qt installation so this is skipped
        // when using CMake.
        app.setImportPath(path: Bundle.qmlImports.url(forResource: "qml", withExtension: nil)!.path)
        app.setPluginsPath(path: Bundle.qmlImports.url(forResource: "plugins", withExtension: nil)!.path)
        #endif

        for (name, property) in qApp.initialProperties {
            property.addInitialProperty(to: app, name: name)
        }

        let fileName = qApp.qmlFileName
        guard let qmlUrl = qApp.bundle.url(forResource: fileName, withExtension: "qml") else {
            fatalError("Missing QML file '\(fileName).qml' in app bundle.")
        }
        app.setRootQml(path: qmlUrl.path)
        app.run(argc: CommandLine.argc, argv: CommandLine.unsafeArgv)
    }
}
