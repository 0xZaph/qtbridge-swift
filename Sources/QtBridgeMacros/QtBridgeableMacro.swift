// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct QtBridgeableMacro {
    static let moduleName = "QtBridge"

    static let conformanceName = "QObjectBuildable"
    static var qualifiedConformanceName: String {
      return "\(moduleName).\(conformanceName)"
    }
    static var initalPropConformanceName: String {
        return "\(moduleName).QmlInitialProperty"
    }

    static var qtBridgeableConformanceType: TypeSyntax {
        "\(raw: qualifiedConformanceName)"
      }

    static let trackedMacroName = "QtTracked"
    static let ignoredMacroName = "QtIgnored"

    static let paramsListName = "QMetaParamsList"

    static let holderTypeName = "QObjectHolder"
    static var qualifiedHolderTypeName: String {
        return "\(moduleName).\(holderTypeName)"
    }
    static let holderVariableName = "objectHolder"

    static var holderVariable : DeclSyntax {
        return
          """
          public lazy var \(raw: holderVariableName): \(raw: qualifiedHolderTypeName) = {
              return \(raw: qualifiedHolderTypeName)(owner: self)
          }()
          """
    }

    static let builderTypeName = "QMetaObjectBuilder"
    static var qualifiedBuilderTypeName: String {
        return "\(moduleName).\(builderTypeName)"
    }
    static let builderVariableName = "metaObjectBuilder"

    static func builderVariable(className: String) -> DeclSyntax {
        let modifiers = DeclModifierListSyntax {
            DeclModifierSyntax(
                name: .identifier("nonisolated(unsafe)")
            )
            DeclModifierSyntax(name: .identifier("static"))
            DeclModifierSyntax(name: .identifier("public"))
        }

        let typeAnn = TypeAnnotationSyntax(
            colon: .colonToken(),
            type: IdentifierTypeSyntax(name: .identifier(qualifiedBuilderTypeName))
        )

        let closureLiteral: ExprSyntax = """
        {
            return \(raw: qualifiedBuilderTypeName).create(from: \(raw: className).self)
        }()
        """

        let binding = PatternBindingSyntax(
            pattern: IdentifierPatternSyntax(identifier: .identifier(builderVariableName)),
            typeAnnotation: typeAnn,
            initializer: InitializerClauseSyntax(equal: .equalToken(), value: closureLiteral)
        )

        let varDecl = VariableDeclSyntax(
            attributes: [],
            modifiers: modifiers,
            bindingSpecifier: .keyword(.let),
            bindings: PatternBindingListSyntax([binding])
        )

        return DeclSyntax(varDecl)
    }

    static func registerMethodsAndPropertiesFunction(registrations : [String]) -> DeclSyntax {
        return """
        public static func registerMethodsAndProperties(for builder: \(raw: qualifiedBuilderTypeName)) {
            builder.startRegistration(for: self)
            \(raw: registrations.joined(separator: "\n\n"))
        }
        """
    }

    static func didSetAccessor(propertyName: String) -> AccessorDeclSyntax {
        return """
        didSet {
            self.emitSignal(for: "\(raw: propertyName)")
        }
        """
    }

    static var emitSignalFunction : DeclSyntax {
        return
            """
            private func emitSignal(for propertyName: String) {
                type(of: self).metaObjectBuilder.emitSignal(sender: self, for: propertyName)
            }
            """
    }

    private static let supportedBasicTypes: Set<String> = [
        "Int", "UInt", "Double", "Float", "String", "Bool", "[String]", "Array<String>"
    ]

    static func isSupportedBasicType(type: String) -> Bool {
        return supportedBasicTypes.contains(type)
    }

    static func isQListModelType(type: String) -> Bool {
        let t = type.replacingOccurrences(of: " ", with: "")
        return t.hasPrefix("QListModel<") && t.hasSuffix(">")
    }

    private static func processFunctionDeclaration(className : String,
                                                   functionDecl: FunctionDeclSyntax,
                                                   into registrationsArr: inout [String],
                                                   methodCounter : inout Int) -> Void
    {
        guard functionDecl.isValidForRegistration else {
            return
        }

        if functionDecl.hasAttribute(QtBridgeableMacro.ignoredMacroName) {
            return
        }

        let methodName = functionDecl.name.text
        let params = functionDecl.signature.parameterClause.parameters

        let arrayName = "argTypes\(methodCounter)"

        var pushCalls: [String] = []
        var paramExtraction: [String] = []
        var args: [String] = []

        var isSupported = true
        for (index, param) in params.enumerated() {
            let paramName = param.firstName.text
            let paramType = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)

            guard isSupportedBasicType(type: paramType) else {
                isSupported = false
                break
            }

            pushCalls.append("\(arrayName).append(\(paramType).self)")

            let extractor = "let \(paramName) : \(paramType) = args.get(\(index))"
            paramExtraction.append(extractor)
            args.append("\(paramName): \(paramName)")
        }

        guard isSupported else {
            return
        }

        let arrayVar = pushCalls.isEmpty ? "let" : "var"
        let arrayInit = "\(arrayVar) \(arrayName) : [QVariantGettable.Type] = []"

        let call = args.isEmpty
            ? "self.\(methodName)()"
            : "self.\(methodName)(\(args.joined(separator: ", ")))"

        let registration =
        """
        \(arrayInit)
        \(pushCalls.joined(separator: "\n"))
        builder.registerSlot(
            name: "\(methodName)",
            argTypes: \(arrayName),
            method: { (owner: Any, args: \(paramsListName)) in
            guard let self = owner as? \(className) else {
                return
            }
            \(paramExtraction.joined(separator: "\n    "))
            \(call)
        })
        """

        methodCounter += 1
        registrationsArr.append(registration)
    }

    private static func processVariableDeclaration(className : String,
                                                   variableDecl: VariableDeclSyntax,
                                                   into registrationsArr: inout [String]) -> Void
    {
        guard variableDecl.isValidForRegistration else {
            return
        }

        if variableDecl.hasAttribute(QtBridgeableMacro.ignoredMacroName) {
            return
        }

        let propertyName = variableDecl.identifier!.text
        var isSupportedType : Bool = false
        if let propertyType = variableDecl.type {
            isSupportedType = isSupportedBasicType(type: propertyType)
                              || isQListModelType(type: propertyType)
        }

        guard isSupportedType
                || variableDecl.hasAttribute(QtBridgeableMacro.trackedMacroName) else {
            return
        }

        let registrationCode =
        """
        builder.registerProperty(
            name: \"\(propertyName)\",
            keyPath: \\\(className).\(propertyName)
        )
        """

        registrationsArr.append(registrationCode)
    }
}

struct BridgeableDiagnostic: DiagnosticMessage {
    enum ID: String {
        case invalidApplication = "invalid type"
    }

    var message: String
    var diagnosticID: MessageID
    var severity: DiagnosticSeverity

    init(message: String, diagnosticID: SwiftDiagnostics.MessageID,
         severity: SwiftDiagnostics.DiagnosticSeverity = .error) {
        self.message = message
        self.diagnosticID = diagnosticID
        self.severity = severity
    }

    init(message: String, domain: String, id: ID,
         severity: SwiftDiagnostics.DiagnosticSeverity = .error) {
        self.message = message
        self.diagnosticID = MessageID(domain: domain, id: id.rawValue)
        self.severity = severity
    }
}

extension DiagnosticsError {
    init<S: SyntaxProtocol>(syntax: S,
                          message: String,
                          domain: String = "QtBridge",
                          id: BridgeableDiagnostic.ID,
                          severity: SwiftDiagnostics.DiagnosticSeverity = .error) {
        self.init(diagnostics: [
            Diagnostic(node: Syntax(syntax),
                       message: BridgeableDiagnostic(message: message,
                                                     domain: domain,
                                                     id: id,
                                                     severity: severity))
        ])
    }
}

extension QtBridgeableMacro : MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let identified = declaration.asProtocol(NamedDeclSyntax.self) else {
            return []
        }

        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
          throw DiagnosticsError(syntax: node,
                                 message: "'@QtBridgeable' can only be applied to class type",
                                 id: .invalidApplication)
        }

        let typeName = identified.name.trimmed.text

        var declarations: [DeclSyntax] = []
        declarations.append(QtBridgeableMacro.holderVariable)
        declarations.append(QtBridgeableMacro.builderVariable(className: typeName))

        var registrations: [String] = []
        var nMethods = 1
        for member in classDecl.memberBlock.members {
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                processFunctionDeclaration(className: typeName, functionDecl: functionDecl,
                                           into: &registrations, methodCounter: &nMethods)
            } else if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                processVariableDeclaration(className: typeName, variableDecl: variableDecl,
                                           into: &registrations)
            } else {
               continue
            }
        }

        declarations.append(registerMethodsAndPropertiesFunction(registrations: registrations))
        declarations.append(QtBridgeableMacro.emitSignalFunction)
        return declarations
    }
}

extension QtBridgeableMacro : ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        if protocols.isEmpty {
          return []
        }

        return [
            try ExtensionDeclSyntax(
                "extension \(raw: type.trimmedDescription): \(raw: qualifiedConformanceName) {}")
        ]
    }
}

extension QtBridgeableMacro: MemberAttributeMacro {
    public static func expansion<
        Declaration: DeclGroupSyntax,
        MemberDeclaration: DeclSyntaxProtocol,
        Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        attachedTo declaration: Declaration,
        providingAttributesFor member: MemberDeclaration,
        in context: Context
    ) throws -> [AttributeSyntax] {
        guard let property = member.as(VariableDeclSyntax.self),
                  property.isValidForRegistration && property.type != nil else  {
            return []
        }

        if property.hasAttribute(QtBridgeableMacro.trackedMacroName) ||
            property.hasAttribute(QtBridgeableMacro.ignoredMacroName) {
            return []
        }

        guard isSupportedBasicType(type: property.type!) ||
              isQListModelType(type: property.type!) else { return [] }

        return [
            AttributeSyntax(
                attributeName: IdentifierTypeSyntax(name: .identifier(QtBridgeableMacro.trackedMacroName)))
        ]
    }
}

public struct QtTrackedMacro: AccessorMacro {
    public static func expansion<
      Context: MacroExpansionContext,
      Declaration: DeclSyntaxProtocol
    >(
      of node: AttributeSyntax,
      providingAccessorsOf declaration: Declaration,
      in context: Context
    ) throws -> [AccessorDeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
                  property.isValidForRegistration,
                  !property.isImmutable else {
          return []
        }

        let propertyName = property.identifier!.text
        return [ QtBridgeableMacro.didSetAccessor(propertyName: propertyName) ]
    }
}

public struct QtIgnoredMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

@main
struct QtBridgePackagePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        QtBridgeableMacro.self,
        QtTrackedMacro.self,
        QtIgnoredMacro.self
    ]
}
