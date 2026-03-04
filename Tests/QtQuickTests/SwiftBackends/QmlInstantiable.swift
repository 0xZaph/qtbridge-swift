// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtBridge

@QtBridgeable
public class QmlType1: QmlInstantiable {
    public var strProp : String = "testString"

    func updateStrProp(newStr: String) {
        strProp = newStr
    }

    required public init() {
    }
}

@QtBridgeable
public class QmlType2: QmlInstantiable {
    public var intProp : Int = 0

    func updateIntProp(newInt: Int) {
        intProp = newInt
    }

    required public init() {
    }
}

@QtBridgeable
public class QmlType3: QmlInstantiableStatus {
    public var prop1 : Int = 0
    public var prop2 : Int = 0
    public var prop3 : Int = 0
    public var sum : Int = 0

    required public init() {
    }

    public func componentComplete() {
        sum = prop1 + prop2 + prop3
    }
}
