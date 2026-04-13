// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

import QtBridgeCpp

/// A type-erased container used to bridge values between Swift
/// and QML.
///
/// Swift values must be converted to `QVariant` in order to be
/// visible to QML. The conversion is handled automatically for
/// supported types via ``QVariantGettable`` and
/// ``QVariantSettable``. Qt Bridge provides built-in support
/// for common Swift types such as `Int`, `UInt`, `Bool`,
/// `Double`, `Float`, `String`, and array of `String` elements.
@MainActor
public struct QVariant
{
    private var variant : QtBridgeCpp.QVariant

    internal init(value: QtBridgeCpp.QVariant) {
        self.variant = value
    }
    /// Creates an invalid variant.
    ///
    /// Invalid variants are typically used to represent the
    /// absence of a value.
    public init() {
        self.variant = QtBridgeCpp.QVariant()
    }
    /// Creates a variant containing an integer value.
    ///
    /// - Parameter value: The integer value to store.
    public init(value: Int) {
        self.variant = QtBridgeCpp.QVariant(Int64(value))
    }
    /// Creates a variant containing an unsigned integer value.
    ///
    /// - Parameter value: The unsigned integer value to store.
    public init(value: UInt) {
        self.variant = QtBridgeCpp.QVariant(UInt64(value))
    }
    /// Creates a variant containing a Boolean value.
    ///
    /// - Parameter value: The Boolean value to store.
    public init(value: Bool) {
        self.variant = QtBridgeCpp.QVariant(value)
    }
    /// Creates a variant containing a double value.
    ///
    /// - Parameter value: The double value to store.
    public init(value: Double) {
        self.variant = QtBridgeCpp.QVariant(value)
    }
    /// Creates a variant containing a float value.
    ///
    /// - Parameter value: The float value to store.
    public init(value: Float) {
        self.variant = QtBridgeCpp.QVariant(value)
    }
    /// Creates a variant containing a string value.
    ///
    /// - Parameter value: The string value to store.
    public init(value: String) {
        self.variant = QtBridgeCpp.QVariant(value)
    }
    /// Creates a variant containing an array of strings.
    ///
    /// - Parameter value: The string array to store.
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

    /// Creates a variant containing a Swift object exposed to QML.
    ///
    /// - Parameter value: A Swift type annotated with the
    /// ``QtBridgeable()`` macro.
    public init(value: QObjectBuildable) {
        self.variant = value.objectHolder.proxy.toVariant()
    }
    internal init(model: QAbstractListModel) {
        self.variant = model.getCppModel().toVariant()
    }
    internal init(model: QAbstractTableModel) {
        self.variant = model.getCppModel().toVariant()
    }

    internal func value<T: QVariantSettable>() -> T {
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

/// A type that can be converted to a `QVariant`.
///
/// Conforming to this protocol allows a Swift type to be exposed
/// to QML as a read-only value.
@MainActor
public protocol QVariantGettable {
    /// Converts the value to a `QVariant`.
    func toVariant() -> QVariant
    /// Returns the
    /// [Qt Meta-Type identifier](https://doc.qt.io/qt-6/qmetatype.html#Type-enum)
    /// for this type.
    static func metaType() -> Int32
}

/// A type that can be converted to and from a `QVariant`.
///
/// This protocol extends `QVariantGettable` to support modifying
/// data from QML.
public protocol QVariantSettable : QVariantGettable {
    /// Converts a `QVariant` to the value.
    ///
    /// - Parameter variant: The variant containing the QML value.
    /// - Returns: A Swift value converted from the variant.
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
