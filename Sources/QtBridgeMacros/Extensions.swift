// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

import SwiftSyntax
import SwiftSyntaxMacros

extension VariableDeclSyntax {
    var identifier: TokenSyntax? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier
    }

    var type: String? {
       return bindings.first?.typeAnnotation?.type.trimmed.description
    }

    var isImmutable: Bool {
        bindingSpecifier.tokenKind == .keyword(.let)
    }

    var isInstance: Bool {
        !modifiers.contains { mod in
            mod.name.tokenKind == .keyword(.static) ||
            mod.name.tokenKind == .keyword(.class)
        }
    }

    var isPrivate: Bool {
        modifiers.contains { mod in
            mod.name.tokenKind == .keyword(.private)
        }
    }

    var isValidForRegistration: Bool {
       !isPrivate && !isComputed && !hasDidSet && isInstance && identifier != nil
    }

    var hasPublished : Bool {
        return !isImmutable && hasAttribute("Published")
    }

    func hasAttribute(_ attributeName: String) -> Bool {
        attributes.contains(where: { attr in
            attr.as(AttributeSyntax.self)?.attributeName.trimmedDescription == attributeName
        })
    }

    func accessorsMatching(_ predicate: (TokenKind) -> Bool) -> [AccessorDeclSyntax] {
        let accessors: [AccessorDeclListSyntax.Element] = bindings.compactMap { patternBinding in
          switch patternBinding.accessorBlock?.accessors {
          case .accessors(let accessors):
            return accessors
          default:
            return nil
          }
        }.flatMap { $0 }
        return accessors.compactMap { accessor in
          if predicate(accessor.accessorSpecifier.tokenKind) {
            return accessor
          } else {
            return nil
          }
        }
      }

    var hasDidSet: Bool {
        return accessorsMatching({ $0 == .keyword(.didSet) }).count > 0
    }

    var isComputed: Bool {
        if accessorsMatching({ $0 == .keyword(.get) }).count > 0 {
            return true
        } else {
            return bindings.contains { binding in
                if case .getter = binding.accessorBlock?.accessors {
                    return true
                } else {
                    return false
                }
            }
        }
    }
}

extension FunctionDeclSyntax {
    var isInstance: Bool {
        !modifiers.contains { mod in
            mod.name.tokenKind == .keyword(.static) ||
            mod.name.tokenKind == .keyword(.class)
        }
    }

    var isPrivate: Bool {
        modifiers.contains { mod in
            mod.name.tokenKind == .keyword(.private)
        }
    }

    var isValidForRegistration: Bool {
       !isPrivate && isInstance
    }

    func hasAttribute(_ attributeName: String) -> Bool {
        attributes.contains(where: { attr in
            attr.as(AttributeSyntax.self)?.attributeName.trimmedDescription == attributeName
        })
    }
}
