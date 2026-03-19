// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

import Foundation

/// A protocol that enables a type to be exposed to QML.
///
/// Conforming to this protocol indicates that a type can be
/// bridged to QML.
/// You don't adopt this protocol directly. Instead, apply the
/// ``QtBridgeable()`` macro to a class to add the required
/// conformance and implementation automatically.
public protocol QObjectBuildable : AnyObject,
                                   QVariantGettable
{
    /// An internal holder for underlying QObject.
    ///
    /// This property is managed by the bridging system. Don't
    /// call it directly.
    var objectHolder: QObjectHolder { get }

    /// An internal builder used to construct QMetaObject.
    ///
    /// The value is provided by the ``QtBridgeable()`` macro.
    /// Don't access it directly.
    static var metaObjectBuilder: QMetaObjectBuilder { get }

    /// Registers methods and properties with the Qt Meta-Object
    /// System.
    ///
    /// This method is implemented by ``QtBridgeable()`` macro.
    /// Don't call or implement it yourself.
    static func registerMethodsAndProperties(for builder: QMetaObjectBuilder) -> Void
    static func registerQmlElement() -> Void
}

extension QObjectBuildable {
    /// Emits a signal with the given name.
    ///
    /// - Parameter propertyName: The name of the property for
    /// which change signal will be registered.
    ///
    /// This method is used by the bridging system. Don't call it
    /// directly.
    public func emitSignal(for propertyName: String) {
        Self.self.metaObjectBuilder.emitSignal(sender: self, for: propertyName)
    }

    /// Emits a signal with arguments.
    ///
    /// - Parameters:
    ///   - signalName: The name of the signal.
    ///   - args: The types of arguments emitted with the
    ///   signal.
    ///
    /// This method is used by the bridging system. Don't call it
    /// directly.
    public func emitSignal(signalName: String, args: [QVariant] = []) {
        Self.metaObjectBuilder.emitSignal(sender: self, signalName: signalName, args: args)
    }
}

extension QObjectBuildable {
    internal func addInitialProperty(to app: QMLApp, name: String) {
        app.addInitialProperty(name: name, value: self.toVariant())
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
