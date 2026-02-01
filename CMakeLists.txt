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

if(NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" AND
   NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
    message(FATAL_ERROR "QtBridge requires building with Clang. Have ${CMAKE_CXX_COMPILER_ID}")
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