import Foundation
import KirigamiSupport
import QtBridge

@main
struct KirigamiDemoApp: QApp {
    var requiresQtWidgets: Bool { true }

    let qmlFileName: String = "main"

    func preApplicationCreate() {
        QMLApp.setOrganizationName("KDE")
        QMLApp.setOrganizationDomain("kde.org")
        QMLApp.setApplicationName("Kirigami Swift Demo")
        QMLApp.setDesktopFileName("org.kde.kirigamiswiftdemo")

        setupKirigamiPreApp()
    }

    func postApplicationCreate() {
        QMLApp.setStyle("breeze")
        setupKirigamiPostApp()
    }

    func engineDidCreate(enginePointer: UnsafeMutableRawPointer) {
        setupKirigamiEngine(enginePointer)
    }
}
