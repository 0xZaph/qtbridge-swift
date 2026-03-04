// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

public protocol QmlInstantiable: QObjectBuildable {
    init()
}

extension QmlInstantiable {
    package static func registerQmlElement() {
        metaObjectBuilder.registerInitializer(initFn: self.init)
        metaObjectBuilder.registerQmlElement(from: Self.self)
    }
}
