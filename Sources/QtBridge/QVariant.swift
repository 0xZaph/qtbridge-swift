// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

import QtBridgeCpp

public struct QVariant
{
    private var variant : QtBridgeCpp.QVariant

    internal init(value: QtBridgeCpp.QVariant) {
        self.variant = value
    }
    public init() {
        self.variant = QtBridgeCpp.QVariant()
    }
    public init(value: Int) {
        self.variant = QtBridgeCpp.QVariant(Int64(value))
    }
    public init(value: UInt) {
        self.variant = QtBridgeCpp.QVariant(UInt64(value))
    }
    public init(value: Bool) {
        self.variant = QtBridgeCpp.QVariant(value)
    }
    public init(value: Double) {
        self.variant = QtBridgeCpp.QVariant(value)
    }
    public init(value: Float) {
        self.variant = QtBridgeCpp.QVariant(value)
    }
    public init(value: String) {
        self.variant = QtBridgeCpp.QVariant(value)
    }
    public init(value: [String]) {
        var list: QStringList = QStringList()
        value.forEach { str in
#if QT_IS_CXX_20
            // QString.init(_:) becomes ambiguous with C++20
            let stdStr = std.string(str)
            list.append(QString.fromStdString(stdStr))
#else
            list.append(QString(str))
#endif
        }
        self.variant = QtBridgeCpp.QVariant(list)
    }

    public init(value: QObjectBuildable) {
        self.variant = value.objectHolder.proxy.toVariant()
    }
    internal init(model: QAbstractListModel) {
        self.variant = model.getCppModel().toVariant()
    }

    public func value<T: QVariantSettable>() -> T {
        return T.value(from: self)
    }

    fileprivate func toBool() -> Bool { return variant.toBool() }
    fileprivate func toInt() -> Int { return Int(variant.toInt()) }
    fileprivate func toUInt() -> UInt { return UInt(variant.toUInt()) }
    fileprivate func toDouble() -> Double { return variant.toDouble() }
    fileprivate func toFloat() -> Float { return variant.toFloat()}
    fileprivate func toString() -> String { return String(variant.toString().toStdString()) }
    fileprivate func toStringList() -> [String] {
        var result : [String] = []
        let cppStrings = variant.toStringList()
        for i in 0..<cppStrings.size() {
            result.append(String(cppStrings[i].toStdString()))
        }
        return result
    }

    internal func cppVariant() -> QtBridgeCpp.QVariant {
        return variant
    }
}

public protocol QVariantGettable {
    func toVariant() -> QVariant
    static func metaType() -> Int32
}

public protocol QVariantSettable : QVariantGettable {
    static func value(from variant: QVariant) -> Self
}

extension Bool: QVariantSettable {
    public func toVariant() -> QVariant { QVariant(value: self) }
    public static func value(from variant: QVariant) -> Bool { variant.toBool() }
    public static func metaType() -> Int32 { return 1 }
}

extension Int: QVariantSettable {
    public func toVariant() -> QVariant { QVariant(value: self) }
    public static func value(from variant: QVariant) -> Int { variant.toInt() }
    public static func metaType() -> Int32 { return 4 }
}

extension UInt: QVariantSettable {
    public func toVariant() -> QVariant { QVariant(value: self) }
    public static func value(from variant: QVariant) -> UInt { variant.toUInt() }
    public static func metaType() -> Int32 { return 5 }
}

extension Double: QVariantSettable {
    public func toVariant() -> QVariant { QVariant(value: self) }
    public static func value(from variant: QVariant) -> Double { variant.toDouble() }
    public static func metaType() -> Int32 { return 6 }
}

extension Float: QVariantSettable {
    public func toVariant() -> QVariant { QVariant(value: self) }
    public static func value(from variant: QVariant) -> Float { variant.toFloat() }
    public static func metaType() -> Int32 { return 38 }
}

extension String: QVariantSettable {
    public func toVariant() -> QVariant { QVariant(value: self) }
    public static func value(from variant: QVariant) -> String { variant.toString() }
    public static func metaType() -> Int32 { return 10 }
}

extension Array: QVariantGettable where Element == String {
    public func toVariant() -> QVariant { QVariant(value: self) }
    public static func metaType() -> Int32 { return 11 }
}

extension Array: QVariantSettable where Element == String {
    public static func value(from variant: QVariant) -> [String] { variant.toStringList() }
}
