// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

import Foundation
import QtBridgeCpp

/// An internal builder used to construct QMetaObject.
///
/// This class is responsible for registering properties, signals
/// and slots so they can be accessed from QML.
/// Don't use this type directly. Instead, apply the
/// ``QtBridgeable()`` macro to a class to add the required
/// implementation automatically.
public class QMetaObjectBuilder
{
    private var builder: SwiftMetaObjectBuilder

    struct PropertyData {
        public let name: String
        public let getter: (Any) -> QVariant
        public let setter: ((Any, QVariant) -> Bool)?

        public init(
            name: String,
            getter: @escaping (Any) -> QVariant,
            setter: ((Any, QVariant) -> Bool)? = nil
        ) {
            self.name = name
            self.getter = getter
            self.setter = setter
        }
    }

    private var properties: [PropertyData] = []
    private var methods: [(Any, QMetaParamsList) -> QVariant] = []
    private var bridgeRoot: ((UnsafeMutableRawPointer) -> Any?)?

    private init(type: QObjectBuildable.Type) {
        self.builder = SwiftMetaObjectBuilder(String(describing: type))
    }

    /// Creates a Meta-Object Builder from a type conforming to
    /// `QObjectBuildable`.
    ///
    /// - Parameter type: The type used to describe the
    /// Meta-Object.
    /// - Returns: A `QMetaObjectBuilder` instance.
    ///
    /// This method is used by the bridging system. Don't call
    /// it directly.
    static public func create(from type: QObjectBuildable.Type) -> QMetaObjectBuilder {
        let builder = QMetaObjectBuilder(type: type)
        type.registerMethodsAndProperties(for: builder)
        builder.endMetaRegistration()
        return builder
    }

    internal func setMetaObjectTo(objectHolder: QObjectHolder) {
        builder.setMetaObjectTo(objectHolder.proxy)
    }

    internal func getProperty(propIndex: Int, root: Any) -> QVariant {
        guard propIndex >= 0, propIndex < properties.count else {
            return QVariant()
        }

        return properties[propIndex].getter(root)
    }

    internal func setProperty(propIndex: Int, root: Any, value: QVariant) -> Bool {
        guard propIndex >= 0, propIndex < properties.count else {
            return false
        }

        if let setter = self.properties[propIndex].setter {
            return setter(root, value)
        }
        return false
    }

    internal var propertyNames: [String] {
        return properties.map { $0.name }
    }

    /// Begins Meta-Object registration for the given root type.
    ///
    /// - Parameter root: The Swift type being exposed to QML.
    ///
    /// This method is used by the bridging system. Don't call it
    /// directly.
    public func startRegistration<Root: QObjectBuildable>(for root: Root.Type) {
        if bridgeRoot == nil {
            bridgeRoot = { ptr in
                return Unmanaged<Root>.fromOpaque(ptr).takeUnretainedValue()
            }
        }
    }

    /// Registers a signal with no arguments.
    ///
    /// - Parameter propertyName: The name of the property for
    /// which change signal will be registered.
    ///
    /// This method is used by the bridging system. Don't call it
    /// directly.
    public func registerSignal(for propertyName: String) {
        self.builder.registerSignal(QMetaObjectBuilder.signalName(for: propertyName), [])
    }

    /// Registers a signal with the specified argument types.
    ///
    /// - Parameters:
    ///   - signalName: The name of the signal.
    ///   - argTypes: The types of arguments emitted with the
    ///   signal.
    ///
    /// This method is used by the bridging system. Don't call it
    /// directly.
    public func registerSignal(signalName: String, argTypes: [QVariantGettable.Type] = []) {
        var cppArgTypeIds = CppVectorOfInt()
        for argType in argTypes {
            cppArgTypeIds.push_back(argType.metaType())
        }
        self.builder.registerSignal(signalName, cppArgTypeIds)
    }

    internal func emitSignal(sender: QObjectBuildable, for propertyName: String) {
        self.builder.emitSignal(sender.objectHolder.proxy,
                                QMetaObjectBuilder.signalName(for: propertyName), [])
    }

    internal func emitSignal(sender: QObjectBuildable, signalName: String, args: [QVariant] = []) {
        var argsVector = CppVectorOfQVariant()
        argsVector.reserve(args.count)
        for arg in args {
            argsVector.push_back(arg.cppVariant())
        }
        self.builder.emitSignal(sender.objectHolder.proxy, signalName, argsVector)
    }

    /// Registers a writable property that can be accessed and
    /// modified from QML.
    ///
    /// - Parameters:
    ///   - name: The name of the property exposed to QML.
    ///   - keyPath: A writable keypath to the property.
    ///
    /// This method is used by the bridging system. Don't call it
    /// directly.
    public func registerProperty<Root: QObjectBuildable, Member: QVariantSettable & Equatable>(
        name: String,
        keyPath: WritableKeyPath<Root, Member>)
    {
        registerSignal(for: name)

        let propInfoId = Int32(properties.count)

        let getter: (Any) -> QVariant = { root in
            guard let root = root as? Root else {
                return QVariant()
            }
            let value: Member = root[keyPath: keyPath]
            return value.toVariant()
        }

        let setter: (Any, QVariant) -> Bool = { root, variant in
            guard var root = root as? Root else {
                return false
            }
            let newValue: Member = variant.value()
            if newValue == root[keyPath: keyPath] {
                return false
            }
            root[keyPath: keyPath] = newValue
            return true
        }

        properties.append(PropertyData(
            name: name,
            getter: getter,
            setter: setter
        ))

        builder.registerProperty(name, QMetaObjectBuilder.bridge(self),
                                 propInfoId, Member.metaType(),
        { (propertyId: Int32,
           selfPtr: UnsafeMutableRawPointer?,
           objPt: UnsafeMutableRawPointer?) -> QtBridgeCpp.QVariant in
            guard let selfPtr,
                  let mySelf = QMetaObjectBuilder.bridge(selfPtr)
            else { return QtBridgeCpp.QVariant() }
            return mySelf.getProperty(propIndex: Int(propertyId), rootPtr: objPt).cppVariant()
        },
        { (propertyId: Int32,
           selfPtr: UnsafeMutableRawPointer?,
           objPtr: UnsafeMutableRawPointer?,
           variant: UnsafePointer<QtBridgeCpp.QVariant>?) -> Bool in
            guard let selfPtr,
                  let mySelf = QMetaObjectBuilder.bridge(selfPtr)
            else { return false }
            return mySelf.setProperty(propIndex: Int(propertyId),
                                      rootPtr: objPtr,
                                      value: QVariant(value: variant.pointee))
        })
    }

    /// Registers a property that can be accessed from QML.
    ///
    /// - Parameters:
    ///   - name: The name of the property exposed to QML.
    ///   - keyPath: A writable keypath to the property.
    ///
    /// This method is used by the bridging system. Don't call it
    /// directly.
    public func registerProperty<Root: QObjectBuildable, Member: QVariantGettable>(
        name: String,
        keyPath: WritableKeyPath<Root, Member>)
    {
        registerSignal(for: name)
        registerProperty(name: name, keyPath: keyPath as KeyPath<Root, Member>)
    }

    /// Registers a read-only property that can be accessed from QML.
    ///
    /// - Parameters:
    ///   - name: The name of the property exposed to QML.
    ///   - keyPath: A writable keypath to the property.
    ///
    /// This method is used by the bridging system. Don't call it
    /// directly.
    public func registerProperty<Root: QObjectBuildable, Member: QVariantGettable>(
        name: String,
        keyPath: KeyPath<Root, Member>)
    {
        let propertyId = Int32(properties.count)

        let getter: (Any) -> QVariant = { root in
            guard let root = root as? Root else {
                return QVariant()
            }
            let value: Member = root[keyPath: keyPath]
            return value.toVariant()
        }

        properties.append(PropertyData(
            name: name,
            getter: getter,
            setter: nil
        ))

        builder.registerProperty(name, QMetaObjectBuilder.bridge(self),
                                 propertyId, Member.metaType(),
        { (propertyId: Int32,
           selfPtr: UnsafeMutableRawPointer?,
           objPt: UnsafeMutableRawPointer?) -> QtBridgeCpp.QVariant in
            guard let selfPtr,
                  let mySelf = QMetaObjectBuilder.bridge(selfPtr)
            else { return QtBridgeCpp.QVariant() }
            return mySelf.getProperty(propIndex: Int(propertyId), rootPtr: objPt).cppVariant()
        }, nil)
    }

    /// Registers a slot that can be invoked from QML.
    ///
    /// - Parameters:
    ///   - name: The name of the method.
    ///   - argTypes: The types of arguments.
    ///   - method: The implementation to invoke when the slot
    ///   is called.
    ///
    /// This method is used by the bridging system. Don't call it
    /// directly.
    public func registerSlot(name: String,
                             returnType: QVariantGettable.Type? = nil,
                             argTypes: [QVariantGettable.Type],
                             method: @escaping (Any, QMetaParamsList) -> QVariant)
    {
        let returnTypeId = returnType?.metaType() ?? 43 // QMetaType::Void
        let methodId = Int32(methods.count)
        methods.append(method)

        var metaArgs = CppVectorOfInt()
        for type in argTypes {
            metaArgs.push_back(type.metaType())
        }

        builder.registerSlot(name, QMetaObjectBuilder.bridge(self), methodId, returnTypeId, metaArgs,
        { (methodId: Int32,
           selfPtr: UnsafeMutableRawPointer?,
           objPtr: UnsafeMutableRawPointer?,
           params: MetaParamsList) -> QtBridgeCpp.QVariant in
            guard let selfPtr,
                  let mySelf = QMetaObjectBuilder.bridge(selfPtr)
            else { return QtBridgeCpp.QVariant() }
            return mySelf.invoke(
                methodIndex: Int(methodId), rootPtr: objPtr,
                args: QMetaParamsList(args: params)).cppVariant()
        })
    }

    internal func endMetaRegistration() {
        builder.endMetaRegistration()
    }

    private func invoke(methodIndex: Int, rootPtr: UnsafeMutableRawPointer?, args: QMetaParamsList) -> QVariant {
        guard let rootPtr = rootPtr else { return QVariant() }
        guard let bridgeRoot = self.bridgeRoot else { return QVariant() }
        guard let root = bridgeRoot(rootPtr) else { return QVariant() }
        guard methodIndex >= 0, methodIndex < methods.count else {
            return QVariant()
        }
        return methods[methodIndex](root, args)
    }

    private func getProperty(propIndex: Int, rootPtr: UnsafeMutableRawPointer?) -> QVariant {
        guard let rootPtr = rootPtr else { return QVariant() }
        guard let bridgeRoot = self.bridgeRoot else { return QVariant() }
        guard let root = bridgeRoot(rootPtr) else { return QVariant() }
        return getProperty(propIndex: propIndex, root: root)
    }

    private func setProperty(propIndex: Int, rootPtr: UnsafeMutableRawPointer?, value: QVariant) -> Bool {
        guard let rootPtr = rootPtr else { return false }
        guard let bridgeRoot = self.bridgeRoot else { return false }
        guard let root = bridgeRoot(rootPtr) else { return false }
        return setProperty(propIndex: propIndex, root: root, value: value)
    }

    private static func signalName(for propertyName: String) -> String {
        return "\(propertyName)Changed"
    }

    private static func bridge(_ obj: QMetaObjectBuilder) -> UnsafeMutableRawPointer {
        return UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    }

    private static func bridge(_ ptr: UnsafeMutableRawPointer) -> QMetaObjectBuilder? {
        return Unmanaged<QMetaObjectBuilder>.fromOpaque(ptr).takeUnretainedValue()
    }
}
