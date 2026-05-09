# Copyright (C) 2025 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

add_library(_CQtEventLoop STATIC
    _CQtEventLoop.cpp
)

target_link_libraries(_CQtEventLoop
    PUBLIC
        Qt6::Core
)

target_include_directories(_CQtEventLoop
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)
