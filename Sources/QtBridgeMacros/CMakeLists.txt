# Copyright (C) 2025 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

# QtBridgeMacros standalone CMake project
# This is built as an ExternalProject from the main build because:
# 1. Macros must be built for the build machine, not the target
# 2. SwiftSyntax is fetched and built as part of the macro

cmake_minimum_required(VERSION 3.29)

project(QtBridgeMacros LANGUAGES Swift)

include(FetchContent)

FetchContent_Declare(SwiftSyntax
    GIT_REPOSITORY https://github.com/swiftlang/swift-syntax.git
    GIT_TAG 600.0.1
)
FetchContent_MakeAvailable(SwiftSyntax)

if(WIN32)
  # swiftc on Windows expects a lib-prefixed import library; copy the built lib accordingly
  set(_qtbridge_swiftsyntax_lib_targets
        SwiftSyntax
        SwiftSyntaxMacros
        SwiftCompilerPlugin
        SwiftCompilerPluginMessageHandling
        SwiftSyntaxMacroExpansion
        SwiftSyntaxBuilder
        SwiftParserDiagnostics
        SwiftBasicFormat
        SwiftOperators
        SwiftParser
        SwiftDiagnostics
        SwiftIDEUtils
        SwiftLibraryPluginProvider
    )
  foreach(_t IN LISTS _qtbridge_swiftsyntax_lib_targets)
    if(TARGET ${_t})
      add_custom_target(_qtbridge_copy_${_t} ALL
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "$<TARGET_FILE:${_t}>"
                    "$<TARGET_FILE_DIR:${_t}>/lib$<TARGET_FILE_BASE_NAME:${_t}>$<TARGET_FILE_SUFFIX:${_t}>"
                DEPENDS ${_t}
                COMMENT "Copy ${_t} to lib-prefixed import lib for Windows"
            )
    endif()
  endforeach()
endif()

add_executable(QtBridgeMacros
    Extensions.swift
    QtBridgeableMacro.swift
)

target_compile_options(QtBridgeMacros PRIVATE
    -parse-as-library
)

target_link_libraries(QtBridgeMacros PRIVATE
    SwiftSyntax
    SwiftSyntaxMacros
    SwiftCompilerPlugin
)

set_target_properties(QtBridgeMacros PROPERTIES
    Swift_LANGUAGE_VERSION 6
)

install(TARGETS QtBridgeMacros
    RUNTIME DESTINATION bin
)
