// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

import Foundation

public protocol QObjectBuildable : AnyObject,
                                   QVariantGettable
{
    var objectHolder: QObjectHolder { get }

    static var metaObjectBuilder: QMetaObjectBuilder { get }

    static func registerMethodsAndProperties(for builder: QMetaObjectBuilder) -> Void
    static func registerQmlElement() -> Void
}

extension QObjectBuildable {
    public func addInitialProperty(to app: QMLApp, name: String) {
        guard let gettable = self as? QVariantGettable else { return }
        app.addInitialProperty(name: name, value: gettable.toVariant())
    }
}

extension QObjectBuildable {
    public func toVariant() -> QVariant { QVariant(value: self) }
    public static func metaType() -> Int32 { return 39 }
}

extension QObjectBuildable {
    public static func registerQmlElement() -> Void {
        // TODO: Implement instantiable types
    }

}
