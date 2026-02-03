# Copyright (C) 2025 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

cmake_minimum_required(VERSION 3.29)

project(QtBridge
    VERSION 0.1.0
    LANGUAGES CXX Swift
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Verify compiler requirements
if("${CMAKE_Swift_COMPILER_VERSION}" VERSION_LESS 6.0)
    message(FATAL_ERROR "QtBridge requires Swift 6.0 or greater. Have ${CMAKE_Swift_COMPILER_VERSION}")
endif()

# This is needed due to swift/bridging not being included in the path by default on non-Xcode toolchains
# Issue can be tracked: https://github.com/swiftlang/swift-package-manager/issues/9010
if(NOT APPLE)
    # Query Swift compiler for runtime resource path
    execute_process(
        COMMAND "${CMAKE_Swift_COMPILER}" -print-target-info
        OUTPUT_VARIABLE SWIFT_TARGET_INFO
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE SWIFT_TARGET_INFO_RESULT
    )

    if(SWIFT_TARGET_INFO_RESULT EQUAL 0)
        # Parse runtimeResourcePath from JSON output
        string(JSON SWIFT_RUNTIME_RESOURCE_PATH ERROR_VARIABLE JSON_ERROR
            GET "${SWIFT_TARGET_INFO}" "paths" "runtimeResourcePath")

        if(NOT JSON_ERROR AND SWIFT_RUNTIME_RESOURCE_PATH)
            # runtimeResourcePath is typically <prefix>/lib/swift
            # bridging headers are at <prefix>/include/swift/bridging
            cmake_path(GET SWIFT_RUNTIME_RESOURCE_PATH PARENT_PATH SWIFT_LIB_DIR)
            cmake_path(GET SWIFT_LIB_DIR PARENT_PATH SWIFT_PREFIX_DIR)
            set(SWIFT_INCLUDE_CANDIDATE "${SWIFT_PREFIX_DIR}/include")

            if(EXISTS "${SWIFT_INCLUDE_CANDIDATE}/swift/bridging")
                set(QTBRIDGE_SWIFT_BRIDGING_INCLUDE "${SWIFT_INCLUDE_CANDIDATE}" CACHE PATH "Swift bridging header include path")
                message(STATUS "Using Swift bridging include: ${QTBRIDGE_SWIFT_BRIDGING_INCLUDE}")
            else()
                message(WARNING "Swift bridging headers not found at ${SWIFT_INCLUDE_CANDIDATE}. Set QTBRIDGE_SWIFT_BRIDGING_INCLUDE manually if needed.")
            endif()
        else()
            message(WARNING "Could not parse Swift target info. Set QTBRIDGE_SWIFT_BRIDGING_INCLUDE manually if needed.")
        endif()
    else()
        message(WARNING "Could not query Swift compiler. Set QTBRIDGE_SWIFT_BRIDGING_INCLUDE manually if needed.")
    endif()
endif()

find_package(Qt6 6.10 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickTest
    CorePrivate
)

# Suppress Qt private module warning
set(QT_NO_PRIVATE_MODULE_WARNING ON)

set(CMAKE_AUTOMOC ON)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Build QtBridgeMacros via ExternalProject (must build for host, not target)
include(ExternalProject)
ExternalProject_Add(QtBridgeMacros_External
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Sources/QtBridgeMacros"
    CMAKE_ARGS
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
    BUILD_ALWAYS ON
    INSTALL_COMMAND ""
)
ExternalProject_Get_Property(QtBridgeMacros_External BINARY_DIR)
set(QTBRIDGE_MACROS_BINARY_DIR "${BINARY_DIR}" CACHE PATH "Path to QtBridgeMacros build")

if(CMAKE_HOST_WIN32)
    set(QTBRIDGE_MACROS_PLUGIN_PATH "${BINARY_DIR}/QtBridgeMacros.exe#QtBridgeMacros" CACHE STRING "Macro plugin load path")
else()
    set(QTBRIDGE_MACROS_PLUGIN_PATH "${BINARY_DIR}/QtBridgeMacros#QtBridgeMacros" CACHE STRING "Macro plugin load path")
endif()

add_library(QtBridgeMacros INTERFACE)
add_dependencies(QtBridgeMacros QtBridgeMacros_External)

add_subdirectory(Sources/QtBridge)
