// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import Foundation
import QtBridgeCpp
import QmlImports
import XCTest

public func runQtQuickTests() -> Int32 {
    var qTestApp = QTestAppCpp()

    qTestApp.setImportPath(
        Bundle.qmlImports.url(forResource: "qml", withExtension: nil)!.path)
    qTestApp.setPluginsPath(
        Bundle.qmlImports.url(forResource: "plugins", withExtension: nil)!.path)

    // Tests are run in alphabetical order based on "name" set in TestCase in tst_*.qml file,
    // so for clarity, new tests should be added in the same way below:
    let signalsModel = SignalsModel()
    let customQListModel = PhoneBookModel()
    let listModel = ListModel()
    let simpleQListModel = SimpleQListModel()
    let slotsModel = SlotsModel()

    qTestApp.registerQmlSingleton("QtBridgeTest", 1, 0,
                                 "PhoneBookModel",
                                  customQListModel.objectHolder.proxy)

    qTestApp.registerQmlSingleton("QtBridgeTest", 1, 0,
                                 "ListModel",
                                 listModel.objectHolder.proxy)

    qTestApp.registerQmlSingleton("QtBridgeTest", 1, 0,
                                 "SimpleQListModel",
                                  simpleQListModel.objectHolder.proxy)

    qTestApp.registerQmlSingleton("QtBridgeTest", 1, 0,
                                 "SignalsModel",
                                  signalsModel.objectHolder.proxy)

    qTestApp.registerQmlSingleton("QtBridgeTest", 1, 0,
                                 "SlotsModel",
                                  slotsModel.objectHolder.proxy)

    let qmlDir = Bundle.module.url(forResource: "qml", withExtension: nil)!
    qTestApp.setInputDir(qmlDir.path)

    let args = ["qtbridge-qmltestrunner", "-platform", "offscreen"]
    var argv: [UnsafeMutablePointer<Int8>?] = args.map { strdup($0) }
    defer { argv.forEach { free($0) } }

    return qTestApp.runQtQuickTests(Int32(argv.count), &argv)
}

final class QtQuickTestsRunner: XCTestCase {
    func testQtQuickSuite() throws {
        let code = runQtQuickTests()
        XCTAssertEqual(code, 0, "QtQuickTests failed with exit code \(code)")
    }
}
