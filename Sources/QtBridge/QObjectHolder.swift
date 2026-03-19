// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

import Foundation
import QtBridgeCpp

/// An internal container for underlying QObject.
///
/// You don't create or use this type directly. Instances are
/// created and managed by the ``QtBridgeable()`` macro.
public class QObjectHolder {
    package var proxy: QObjectProxy
    internal weak var owner: (QObjectBuildable)?

    /// Creates a holder for a specified owner.
    ///
    /// This initializer is used by the bridging code.
    /// Don’t call it directly.
    public init(owner: QObjectBuildable) {
        self.owner = owner
        self.proxy = QObjectProxy(QObjectHolder.bridge(owner))
        type(of: owner).metaObjectBuilder.setMetaObjectTo(objectHolder: self)
    }

    internal func getProperty(propIndex: Int) -> QVariant {
        guard let owner = owner else { return QVariant() }
        return type(of: owner).metaObjectBuilder.getProperty(propIndex: propIndex, root: owner)
    }

    internal func setProperty(propIndex: Int, value: QVariant) -> Bool {
        guard let owner = owner else { return false }
        return type(of: owner).metaObjectBuilder.setProperty(propIndex: propIndex, root: owner, value: value)
    }

    private static func bridge<T: AnyObject>(_ obj: T) -> UnsafeMutableRawPointer {
        UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    }
}
