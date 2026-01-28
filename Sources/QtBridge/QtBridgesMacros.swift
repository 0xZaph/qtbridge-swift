// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

@attached(member, names: arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: QObjectBuildable)
public macro QtBridgeable() = #externalMacro(module: "QtBridgeMacros", type: "QtBridgeableMacro")

@attached(accessor, names: named(didSet))
public macro QtTracked() = #externalMacro(module: "QtBridgeMacros", type: "QtTrackedMacro")

@attached(peer)
public macro QtIgnored() = #externalMacro(module: "QtBridgeMacros", type: "QtIgnoredMacro")

@attached(body)
public macro QtSignal() = #externalMacro(module: "QtBridgeMacros", type: "QtSignalMacro")
