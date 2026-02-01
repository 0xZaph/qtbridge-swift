# Copyright (C) 2025 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

set(QTBRIDGE_SWIFT_SOURCES
    QAbstractItemModel.swift
    QAbstractListModel.swift
    QApp.swift
    QListModel.swift
    QMetaObjectBuilder.swift
    QMetaParamsList.swift
    QModelIndex.swift
    QNamespace.swift
    QObjectBuildable.swift
    QObjectHolder.swift
    QVariant.swift
    QtBridgesMacros.swift
)

set(QTBRIDGE_CPP_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/../QtBridgeCpp/abstractitemmodel.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../QtBridgeCpp/abstractlistmodel.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../QtBridgeCpp/callbackbase.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../QtBridgeCpp/metaparamslist.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../QtBridgeCpp/qappcpp.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../QtBridgeCpp/qobjectproxy.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../QtBridgeCpp/qtestappcpp.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../QtBridgeCpp/swiftmetaobjectbuilder.cpp
)

add_library(QtBridge
    ${QTBRIDGE_SWIFT_SOURCES}
    ${QTBRIDGE_CPP_SOURCES}
)

target_link_libraries(QtBridge
    PUBLIC
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
    PRIVATE
        Qt6::CorePrivate
)

set_target_properties(QtBridge PROPERTIES
    AUTOMOC ON
)

target_include_directories(QtBridge PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/../QtBridgeCpp/include
)

target_compile_options(QtBridge PUBLIC
    "$<$<COMPILE_LANGUAGE:Swift>:-cxx-interoperability-mode=default>"
)

target_compile_options(QtBridge PRIVATE
    "$<$<COMPILE_LANGUAGE:Swift>:-DCMAKE>"
)

# Depend on macros being built
add_dependencies(QtBridge QtBridgeMacros)

# Add macro plugin path for the Swift compiler
if(DEFINED QTBRIDGE_MACROS_PLUGIN_PATH)
    target_compile_options(QtBridge PUBLIC
        "$<$<COMPILE_LANGUAGE:Swift>:-load-plugin-executable>"
        "$<$<COMPILE_LANGUAGE:Swift>:${QTBRIDGE_MACROS_PLUGIN_PATH}>"
    )
endif()

# Set Swift version
set_target_properties(QtBridge PROPERTIES
    Swift_LANGUAGE_VERSION 6
)
