// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

enum QtBridgableOutputs {
    static let holderVar : String = """
    public lazy var objectHolder: QtBridge.QObjectHolder = {
            return QtBridge.QObjectHolder(owner: self)
        }()
    """

    static func builderVar(className: String) -> String { """
    nonisolated(unsafe) static public let metaObjectBuilder: QtBridge.QMetaObjectBuilder = {
            return QtBridge.QMetaObjectBuilder.create(from: \(className).self)
        }()
    """
    }

    static let signalFunc : String  = """
    private func emitSignal(for propertyName: String) {
            type(of: self).metaObjectBuilder.emitSignal(sender: self, for: propertyName)
        }
    """
}
