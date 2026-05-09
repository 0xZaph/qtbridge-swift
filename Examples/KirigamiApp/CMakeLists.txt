cmake_minimum_required(VERSION 3.29)
project(KirigamiApp LANGUAGES CXX Swift)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_MODULE_PATH})
find_package(Qt6 REQUIRED COMPONENTS Widgets QuickControls2 Qml Quick)
find_package(KF6 REQUIRED COMPONENTS Kirigami I18n CoreAddons IconThemes)

add_subdirectory(KirigamiSupport)

if(NOT TARGET QtBridge)
    include(FetchContent)
    FetchContent_Declare(QtBridgeLocal
        SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../.."
    )
    FetchContent_MakeAvailable(QtBridgeLocal)
endif()

add_executable(KirigamiApp
    Sources/App.swift
)

target_link_libraries(KirigamiApp
    PRIVATE
        QtBridge
        KirigamiSupport
)

target_compile_options(KirigamiApp PRIVATE 
    "$<$<COMPILE_LANGUAGE:Swift>:-cxx-interoperability-mode=default>"
    "$<$<COMPILE_LANGUAGE:Swift>:-parse-as-library>"
)

set(MAIN_QML_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Resources/main.qml")

if(APPLE)
    set_target_properties(KirigamiApp PROPERTIES
        MACOSX_BUNDLE TRUE
    )
    target_sources(KirigamiApp PRIVATE "${MAIN_QML_FILE}")
    set_source_files_properties("${MAIN_QML_FILE}" PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources
    )
else()
    add_custom_command(
        TARGET KirigamiApp POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            "${MAIN_QML_FILE}"
            "$<TARGET_FILE_DIR:KirigamiApp>/main.qml"
        COMMENT "Copying QML file next to executable"
    )
endif()