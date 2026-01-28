// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtBridge
import Foundation

@QtBridgeable
public final class SignalsModel {
    var sigModel: QListModel<String> = ["one", "two"]
    var chainCompleted: Bool = false

    // Signals for signals chain
    @QtSignal
    func triggerNewString(newString: String)
    @QtSignal
    func newStringAdded()
    @QtSignal
    func chainEnded()

    // Signals without parameters
    @QtSignal
    func signalOne()

    // Signals with parameters of supported basic types
    @QtSignal
    func changeBool(isTrue: Bool)
    @QtSignal
    func changeInt(num: Int)
    @QtSignal
    func changeUInt(num: UInt)
    @QtSignal
    func changeDouble(num: Double)
    @QtSignal
    func changeFloat(num: Float)
    @QtSignal
    func changeString(text: String)
    @QtSignal
    func changeStringList(text: [String])

    // Signal with multiple parameters
    @QtSignal
    func changeMultipleParams(isTrue: Bool, num: UInt, text: String)

    func triggerNewStringSignal(newString: String) {
        triggerNewString(newString: newString)
    }

    func addString(newString: String) {
        sigModel.append(newString)
        newStringAdded()
    }

    func triggerSignals(isTrue: Bool, myInt: Int, myUInt: UInt, myDouble: Double,
                                     myFloat: Float, text: String, textList: [String]) {
        signalOne()
        changeBool(isTrue: isTrue)
        changeInt(num: myInt)
        changeUInt(num: myUInt)
        changeDouble(num: myDouble)
        changeFloat(num: myFloat)
        changeString(text: text)
        changeStringList(text: textList)
        changeMultipleParams(isTrue: isTrue, num: myUInt, text: text)
    }
}
