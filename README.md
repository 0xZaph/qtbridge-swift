# Qt Bridge - Swift

> Copyright (C) 2025 The Qt Company Ltd.
> SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

This is a pre-release implementation of Qt Bridges for Swift.
By installing this package, you agree to the terms and conditions stated in https://www.qt.io/terms-conditions.
These terms and conditions also apply to the Qt Framework, which is used as a major dependency in this package.

This SDK is built on top of the Swift programming language provided by the Swift Project (https://www.swift.org).

The Qt Bridge for Swift is built using the Swift programming language and related tools provided by the Swift Project
Swift and its associated components are licensed under the Apache License, Version 2.0 with Runtime Library Exception.

## Contents

1. [Introduction](##Introduction)
2. [Status](##Status)
3. [Supported platforms](##Supported-platforms)
4. [Requirements](##Requirements)
5. [Installing Qt Bridge](##Installing-Qt-Bridge)
    1. [Importing Qt Bridge as a remote package](###Importing-Qt-Bridge-as-a-remote-package)
    2. [Importing Qt Bridge as a local package](Importing-Qt-Bridge-as-a-local-package)
    3. [Disable Library Validation Entitlement](###Disable-Library-Validation-Entitlement)
6. [Running examples](##Running-examples)
7. [Using Xcode templates](##Using-Xcode-templates)
8. [Stay in touch](##Stay-in-touch)

## Introduction

Qt Bridge for Swift is a bridge between Swift and QML, designed to write application logic in
Swift while using Qt Quick for the UI. Bridging mechanism is based on Swift and C++
interoperability.

Qt Bridge for Swift is intended for Apple developers who want to experiment with Qt and/or QML
without committing to a full C++ application. The repository includes example applications
and Xcode templates that demonstrate the recommended project structure, how to model data
and logic in Swift, and how to connect those models to QML views.

Detailed documentation can be found [here](https://doc-snapshots.qt.io/qtbridges-dev/qtbridges-swift-index.html).

## Status

Qt Bridge for Swift is currently in early preview, and in active development.

Notable limitations include:
- APIs may change or even be removed.
- There are many known issues and missing features.

## Supported platforms

Currently, only **macOS (Apple Silicon)** is supported, with plans to extend support in the future.

## Requirements

- **macOS 14** or later
- **Swift 6.0** or later
- [Xcode](https://developer.apple.com/xcode/) or [Swift Package Manager](https://github.com/swiftlang/swift-package-manager)

## Installing Qt Bridge

Qt Bridge is distributed as a Swift Package Manager package. You can add it to your project as a package dependency using either a local package reference or the repository URL.

### Importing Qt Bridge as a remote package

#### Add via Xcode

1. In Xcode, select *File* → *Add Package Dependencies*.
2. Enter https://github.com/qt/qtbridge-swift
3. Enable Swift-C++ interoperability:
    1. Go to the target's *Build Settings*.
    2. Switch the filter to *All + Combined*.
    3. Search for *Interoperability*.
    4. Under *Swift Compiler - Language*, set *C++ and Objective-C Interoperability* mode to *C++/Objective-C++*.

#### Add via Package.swift

1. Specify the Qt Bridge package URL in the dependencies section.
2. Link the *QtBridge* product to your target.
3. Enable Swift-C++ interoperability in *swiftSettings* with .*interoperabilityMode(.Cxx)* mode.
```
dependencies: [
    .package(url: "https://github.com/qt/qtbridge-swift", exact: "0.1.0-alpha")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "QtBridge", package: "qtbridge-swift")
        ],
        swiftSettings: [
            .interoperabilityMode(.Cxx)
        ]
    )
]
```

### Importing Qt Bridge as a local package

Firstly, clone the [Qt Bridge for Swift repo](https://github.com/qt/qtbridge-swift):

```
$ git clone https://github.com/qt/qtbridge-swift
$ cd qtbridge-swift
$ git checkout 0.1.0-alpha
```

#### Add via Xcode

1. In Xcode, select *File* → *Add Package Dependencies*.
2. Click the *Add Local* button and select the folder that contains cloned Qt Bridge repo.
3. Enable Swift-C++ interoperability:
    1. Go to the target's *Build Settings*.
    2. Switch the filter to *All + Combined*.
    3. Search for *Interoperability*.
    4. Under *Swift Compiler - Language*, set *C++ and Objective-C Interoperability* mode to *C++/Objective-C++*.

#### Add via Package.swift

1. Specify a path to the cloned Qt Bridge repo in the dependencies section.
2. Link *QtBridge* product to your target.
3. Enable Swift-C++ interoperability in *swiftSettings* with .*interoperabilityMode(.Cxx)* mode.

```
dependencies: [
    .package(path: "path/to/qtbridge-swift")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "QtBridge", package: "qtbridge-swift")
        ],
        swiftSettings: [
            .interoperabilityMode(.Cxx)
        ]
    )
]
```

### Disable Library Validation Entitlement

When you use a Team in Xcode and enable automatic signing, Xcode may enable the
**Hardened Runtime** for the generated macOS app target. With Hardened Runtime enabled,
macOS enforces **library validation**, which restricts the app to loading only system
libraries and libraries signed with a compatible signature. Qt Bridge loads additional
Qt frameworks at runtime, and this can cause the app to fail to launch when library
validation is enabled.

To fix this:

1. Open the *Signing & Capabilities* tab.
2. Select your app target.
3. Expand *Hardened Runtime*.
4. Manually chech *Disable Library Validation*.

Alternatively, you can disable *Hardened Runtime* entirely by clicking *Delete* next to
it, but disabling Library Validation alone is sufficient.

## Running examples

**Examples** directory contains simple projects implemented with Qt Bridge. For instance, to build and run MinimalApp:

```
$ cd qtbridge-swift/Examples/MinimalApp

$ xcodebuild \
  -project MinimalApp.xcodeproj \
  -scheme MinimalApp \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  build

$ open build/Build/Products/Debug/MinimalApp.app
```

## Using Xcode templates

**Templates** directory contains:

- **a project template** for starting a new Swift + QML macOS application
- **file templates** for adding Swift models and QML views

### Installing the templates into Xcode

Copy `Templates` folder into `~/Library/Developer/Xcode/Templates/`.

### Creating a new project from the Qt Bridge project template

1. Open Xcode.
2. Choose *Create New Project...*
3. In the template chooser, select the *macOS* platform.
4. Scroll down to *Qt Bridge* section.
5. Select the *Qt Bridge* project template and click *Next*.
6. Fill in the template options:
  - *Product Name* – the name of the application (also used for the target name and
  bundle name).
  - *Organization Identifier* – a reverse-DNS identifier such as com.example.
  - *Model Type Name* – the Swift type used as the backend model, for example MyModel.
  - *QML File Name* – the base name of the initial QML file, without the .qml
  extension (for example main or myView).
  - *Model Context Name* – the name under which the model is exposed to QML, usually in
  lowerCamelCase (for example myModel).
- Choose a location for the project and click *Create*.

7. The generated project will contain:

- an application entry point with `@main`,
- a Swift model type with the name you provided,
- a QML file with the chosen base name, already included in the app’s bundle
resources,
- a macOS app target with Swift/C++ interoperability enabled

8. The project template sets up the application structure, but you still need to add the
Qt Bridge as a package dependency.

### Running the example application

The generated project may fail to launch if **Hardened Runtime** is enabled because Qt Bridge dynamically loads Qt frameworks at runtime. To fix this, you need to disable **Library Validation**. For detailed instructions, see [Disable Library Validation Entitlement](##Disable-Library-Validation-Entitlement)
.

At this point, the example application is ready to run. You can do so, by pressing
the *Run* button. The project template configures the basic build settings and
target configuration. For more advanced configuration, you can adjust
*Build Settings* in the project navigator.

## Stay in touch

You can reach us in the Qt Forum, specifically in the [Qt Bridges
category](https://forum.qt.io/category/78/qt-bridges).
