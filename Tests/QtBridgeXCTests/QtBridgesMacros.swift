// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtBridge
import QtBridgeMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class QtBridgeableExpansionTest: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "QtBridgeable": QtBridgeableMacro.self,
        "QtTracked": QtTrackedMacro.self,
        "QtIgnored": QtIgnoredMacro.self,
        "QtSignal": QtSignalMacro.self
    ]

    func testQtBridgeableOnUnsupportedTypeEmitsError() {
        assertMacroExpansion(
            """
            @QtBridgeable
            public struct TestModel {
                var someVar: [String] = ["test String"]
            }
            """,
            expandedSource:
            """
            public struct TestModel {
                var someVar: [String] = ["test String"] {
                    didSet {
                        self.emitSignal(for: "someVar")
                    }
                }
            }
            """,
            diagnostics: [
                .init(
                    message: "'@QtBridgeable' can only be applied to class type",
                    line: 1, column: 1, severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testIsQtTrackedAttached() {
        assertMacroExpansion(
            """
            @QtBridgeable
            public class TestModel {
                var someVar: [String] = ["test String"]
            }
            """,
            expandedSource:
            """
            public class TestModel {
                @QtTracked
                var someVar: [String] = ["test String"]

                \(QtBridgableOutputs.holderVar)

                \(QtBridgableOutputs.builderVar(className: "TestModel"))

                public static func registerMethodsAndProperties(for builder: QtBridge.QMetaObjectBuilder) {
                    builder.startRegistration(for: self)
                    builder.registerProperty(
                    name: "someVar",
                    keyPath: \\TestModel.someVar
                    )
                }
            }
            """,
            macros: ["QtBridgeable": QtBridgeableMacro.self],
            indentationWidth: .spaces(4)
            )
    }

    func testQtBridgeableMacroFullExpansion() {
        assertMacroExpansion(
            """
            @QtBridgeable
            public class TestType {
                var name: String = ""
                public init(name: String) {
                    self.name = name
                }
            }

            @QtBridgeable
            public class TestModel {
                var someVar: [String] = ["test String"]

                @QtTracked
                var userType: [TestType] = []

                var userTypeNotTracked: [TestType] = []
            }
            """,
            expandedSource:
            """
            public class TestType {
                var name: String = "" {
                    didSet {
                        self.emitSignal(for: "name")
                    }
                }
                public init(name: String) {
                    self.name = name
                }

                \(QtBridgableOutputs.holderVar)

                \(QtBridgableOutputs.builderVar(className: "TestType"))

                public static func registerMethodsAndProperties(for builder: QtBridge.QMetaObjectBuilder) {
                    builder.startRegistration(for: self)
                    builder.registerProperty(
                    name: "name",
                    keyPath: \\TestType.name
                    )
                }
            }
            public class TestModel {
                var someVar: [String] = ["test String"] {
                    didSet {
                        self.emitSignal(for: "someVar")
                    }
                }
                var userType: [TestType] = [] {
                    didSet {
                        self.emitSignal(for: "userType")
                    }
                }

                var userTypeNotTracked: [TestType] = []

                \(QtBridgableOutputs.holderVar)

                \(QtBridgableOutputs.builderVar(className: "TestModel"))

                public static func registerMethodsAndProperties(for builder: QtBridge.QMetaObjectBuilder) {
                    builder.startRegistration(for: self)
                    builder.registerProperty(
                    name: "someVar",
                    keyPath: \\TestModel.someVar
                    )

                    builder.registerProperty(
                        name: "userType",
                        keyPath: \\TestModel.userType
                    )
                }
            }
            """,
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testQtTrackedExpansion() {
        assertMacroExpansion(
            """
            @QtBridgeable
            public class Person {
                var name: String = ""
                var lastName: String = ""
                var phone: Int = 0
                public init(name: String, lastName: String, phone: Int) {
                    self.name = name
                    self.lastName = lastName
                    self.phone = phone
                }
            }

            @QtBridgeable
            public class PhoneBook {
                @QtTracked
                var contacts: [Person] = []
            }
            """,
            expandedSource:
            """
            @QtBridgeable
            public class Person {
                var name: String = ""
                var lastName: String = ""
                var phone: Int = 0
                public init(name: String, lastName: String, phone: Int) {
                    self.name = name
                    self.lastName = lastName
                    self.phone = phone
                }
            }

            @QtBridgeable
            public class PhoneBook {
                var contacts: [Person] = [] {
                    didSet {
                        self.emitSignal(for: "contacts")
                    }
                }
            }
            """,
            macros: ["QtTracked": QtTrackedMacro.self],
            indentationWidth: .spaces(4)
        )
    }

    func testQtIgnored() {
        assertMacroExpansion(
            """
            @QtBridgeable
            public class TestModel {
                @QtIgnored
                var someVar: [String] = ["test String"]
            }
            """,
            expandedSource:
            """
            public class TestModel {
                var someVar: [String] = ["test String"]

                \(QtBridgableOutputs.holderVar)

                \(QtBridgableOutputs.builderVar(className: "TestModel"))

                public static func registerMethodsAndProperties(for builder: QtBridge.QMetaObjectBuilder) {
                    builder.startRegistration(for: self)

                }
            }
            """,
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testConstantProp() {
        assertMacroExpansion(
            """
            @QtBridgeable
            public class TestModel {
                let someConst: [String] = ["test String"]
                private var somePrivate: [String] = ["test String"]
                static var someStatic: [String] = ["test String"]
            }
            """,
            expandedSource:
            """
            public class TestModel {
                let someConst: [String] = ["test String"]
                private var somePrivate: [String] = ["test String"]
                static var someStatic: [String] = ["test String"]

                \(QtBridgableOutputs.holderVar)

                \(QtBridgableOutputs.builderVar(className: "TestModel"))

                public static func registerMethodsAndProperties(for builder: QtBridge.QMetaObjectBuilder) {
                    builder.startRegistration(for: self)
                    builder.registerProperty(
                    name: "someConst",
                    keyPath: \\TestModel.someConst
                    )
                }
            }
            """,
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testSupportedBasicTypes() {
        assertMacroExpansion(
            """
            @QtBridgeable
            public class TestModel {
                var someInt: Int = 1
                var someUInt: UInt = 3
                var someBool: Bool = true
                var someDouble: Double = 1.33
                var someFloat: Float = 1.3
                var someString: String = "some String"
                var someArray: [String] = ["some Array"]
                var someArrayTwo: Array<String> = ["some Array"]
            }
            """,
            expandedSource:
            """
            public class TestModel {
                @QtTracked
                var someInt: Int = 1
                @QtTracked
                var someUInt: UInt = 3
                @QtTracked
                var someBool: Bool = true
                @QtTracked
                var someDouble: Double = 1.33
                @QtTracked
                var someFloat: Float = 1.3
                @QtTracked
                var someString: String = "some String"
                @QtTracked
                var someArray: [String] = ["some Array"]
                @QtTracked
                var someArrayTwo: Array<String> = ["some Array"]

                \(QtBridgableOutputs.holderVar)

                \(QtBridgableOutputs.builderVar(className: "TestModel"))

                public static func registerMethodsAndProperties(for builder: QtBridge.QMetaObjectBuilder) {
                    builder.startRegistration(for: self)
                    builder.registerProperty(
                    name: "someInt",
                    keyPath: \\TestModel.someInt
                    )

                    builder.registerProperty(
                        name: "someUInt",
                        keyPath: \\TestModel.someUInt
                    )

                    builder.registerProperty(
                        name: "someBool",
                        keyPath: \\TestModel.someBool
                    )

                    builder.registerProperty(
                        name: "someDouble",
                        keyPath: \\TestModel.someDouble
                    )

                    builder.registerProperty(
                        name: "someFloat",
                        keyPath: \\TestModel.someFloat
                    )

                    builder.registerProperty(
                        name: "someString",
                        keyPath: \\TestModel.someString
                    )

                    builder.registerProperty(
                        name: "someArray",
                        keyPath: \\TestModel.someArray
                    )

                    builder.registerProperty(
                        name: "someArrayTwo",
                        keyPath: \\TestModel.someArrayTwo
                    )
                }
            }
            """,
            macros: ["QtBridgeable": QtBridgeableMacro.self],
            indentationWidth: .spaces(4)
        )
    }

    func testUnsupportedBasicTypes() {
        assertMacroExpansion(
            """
            @QtBridgeable
            public class TestModel {
                var someInt8: Int8 = 1
                var someUInt8: UInt8 = 3
                var someInt16: Int16 = 1
                var someUInt16: UInt16 = 3
                var someInt32: Int32 = 1
                var someUInt32: UInt32 = 3
                var someInt64: Int64 = 1
                var someUInt64: UInt64 = 3
                var someChar: Character = "M"
                var someSubstring: Substring = "Hello, Qt!".prefix(5)
                var someAny: Any = 13
                var someAnyObject: AnyObject = NSObject()
                var someData: Data = Data([0x51, 0x74])
                var someDate: Date = Date(timeIntervalSince1970: 0)
                var someURL: URL = URL(string: "https://example.com")!
                var someUUID: UUID = UUID(uuidString: "1234-1234-1234-1234")!
                var someDecimal: Decimal = Decimal(string: "123456.789")!
                var someDictionary: [String: Int] = ["one": 1, "two": 2]
                var someSet: Set<String> = ["apple", "banana", "cherry"]
                var someOptional: String? = "Hello Optional"
                var someIntList: [Int] = [1, 3]
                var someCharList: [Character] = ["M", "L"]
                var someAnyList: [Any] = ["M", 13]
            }
            """,
            expandedSource:
            """
            public class TestModel {
                var someInt8: Int8 = 1
                var someUInt8: UInt8 = 3
                var someInt16: Int16 = 1
                var someUInt16: UInt16 = 3
                var someInt32: Int32 = 1
                var someUInt32: UInt32 = 3
                var someInt64: Int64 = 1
                var someUInt64: UInt64 = 3
                var someChar: Character = "M"
                var someSubstring: Substring = "Hello, Qt!".prefix(5)
                var someAny: Any = 13
                var someAnyObject: AnyObject = NSObject()
                var someData: Data = Data([0x51, 0x74])
                var someDate: Date = Date(timeIntervalSince1970: 0)
                var someURL: URL = URL(string: "https://example.com")!
                var someUUID: UUID = UUID(uuidString: "1234-1234-1234-1234")!
                var someDecimal: Decimal = Decimal(string: "123456.789")!
                var someDictionary: [String: Int] = ["one": 1, "two": 2]
                var someSet: Set<String> = ["apple", "banana", "cherry"]
                var someOptional: String? = "Hello Optional"
                var someIntList: [Int] = [1, 3]
                var someCharList: [Character] = ["M", "L"]
                var someAnyList: [Any] = ["M", 13]

                \(QtBridgableOutputs.holderVar)

                \(QtBridgableOutputs.builderVar(className: "TestModel"))

                public static func registerMethodsAndProperties(for builder: QtBridge.QMetaObjectBuilder) {
                    builder.startRegistration(for: self)

                }
            }
            """,
            macros: ["QtBridgeable": QtBridgeableMacro.self],
            indentationWidth: .spaces(4)
        )
    }

    func testQSignalMacroExpansionNoParams() {
        assertMacroExpansion(
            """
            @QtBridgeable
            public class TestModel {
                @QtSignal
                func mySignal()
            }
            """,
            expandedSource:
            """
            public class TestModel {
                func mySignal() {
                    emitSignal(signalName: "mySignal", args: [])
                }

                \(QtBridgableOutputs.holderVar)

                \(QtBridgableOutputs.builderVar(className: "TestModel"))

                public static func registerMethodsAndProperties(for builder: QtBridge.QMetaObjectBuilder) {
                    builder.startRegistration(for: self)
                    let signalArgTypes1 : [QVariantGettable.Type] = []

                    builder.registerSignal(signalName: "mySignal", argTypes: signalArgTypes1)
                }
            }
            """,
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testQSignalMacroExpansionWithParams() {
        assertMacroExpansion(
            """
            @QtBridgeable
            public class TestModel {
                @QtSignal
                func mySignal(text: String)

                @QtSignal
                func mySignal2(intParam: Int, boolParam: Bool, doubleParam: Double)
            }
            """,
            expandedSource:
            """
            public class TestModel {
                func mySignal(text: String) {
                    emitSignal(signalName: "mySignal", args: [text.toVariant()])
                }
                func mySignal2(intParam: Int, boolParam: Bool, doubleParam: Double) {
                    emitSignal(signalName: "mySignal2", args: [intParam.toVariant(), boolParam.toVariant(), doubleParam.toVariant()])
                }

                \(QtBridgableOutputs.holderVar)

                \(QtBridgableOutputs.builderVar(className: "TestModel"))

                public static func registerMethodsAndProperties(for builder: QtBridge.QMetaObjectBuilder) {
                    builder.startRegistration(for: self)
                    var signalArgTypes1 : [QVariantGettable.Type] = []
                    signalArgTypes1.append(String.self)
                    builder.registerSignal(signalName: "mySignal", argTypes: signalArgTypes1)

                    var signalArgTypes2 : [QVariantGettable.Type] = []
                    signalArgTypes2.append(Int.self)
                    signalArgTypes2.append(Bool.self)
                    signalArgTypes2.append(Double.self)
                    builder.registerSignal(signalName: "mySignal2", argTypes: signalArgTypes2)
                }
            }
            """,
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testQtSignalWithFunctionBody() {
        assertMacroExpansion(
            """
            public class TestModel {
                @QtSignal
                func mySignal() {
                    print("Signal!")
                }
            }
            """,
            expandedSource:
            """
            public class TestModel {
                func mySignal() {
                    print("Signal!")
                }
            }
            """,
            diagnostics: [
                .init(
                    message: "'@QtSignal' functions must not have a body",
                    line: 2, column: 5, severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testQtSignalUnSupportedParameterType() {
        assertMacroExpansion(
            """
            public class TestModel {
                @QtSignal
                func mySignal(someVar: Any)
            }
            """,
            expandedSource:
            """
            public class TestModel {
                func mySignal(someVar: Any)
            }
            """,
            diagnostics: [
                .init(
                    message: "Unsupported parameter type: Any",
                    line: 2, column: 5, severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }
}
