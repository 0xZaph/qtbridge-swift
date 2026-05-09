# Copyright (C) 2025 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

add_library(QtEventLoop STATIC
    QtEventLoop.swift
)

target_link_libraries(QtEventLoop
    PUBLIC
        _CQtEventLoop
)

set(package_name "-package-name" "QtEventLoop")
target_compile_options(QtEventLoop PRIVATE
    "$<$<COMPILE_LANGUAGE:Swift>:${package_name}>"
)

set_target_properties(QtEventLoop PROPERTIES
    Swift_LANGUAGE_VERSION 6
)
