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
2. [Supported platforms](##Supported-platforms)
2. [Requirements](##Requirements)
3. [Installing Qt Bridge](##Installing-Qt-Bridge)
    1. [Importing Qt Bridge as a remote package](###Importing-Qt-Bridge-as-a-remote-package)
    2. [Importing Qt Bridge as a local package](Importing-Qt-Bridge-as-a-local-package)
    3. [Building local Qt package](###Building-local-Qt-package)
4. [Running examples](##Running-examples)
5. [Using Xcode templates](##Using-Xcode-templates)
6. [Stay in touch](##Stay-in-touch)

## Introduction

Qt Bridge for Swift is a bridge between Swift and QML, designed to write application logic in
Swift while using Qt Quick for the UI. Bridging mechanism is based on Swift and C++
interoperability.

Qt Bridge for Swift is intended for Apple developers who want to experiment with Qt and/or QML
without committing to a full C++ application. The repository includes example applications
and Xcode templates that demonstrate the recommended project structure, how to model data
and logic in Swift, and how to connect those models to QML views.

Detailed documentation can be found [here](https://doc-snapshots.qt.io/qtbridges-dev/qtbridges-swift-index.html).

## Supported platforms

Currently, only **macOS (Apple Silicon)** is supported, with plans to extend support in the future.

## Requirements

- **macOS 14** or later
- **Swift 6.0** or later
- [Xcode](https://developer.apple.com/xcode/) or [Swift Package Manager](https://github.com/swiftlang/swift-package-manager)

## Installing Qt Bridge

Qt Bridge is distributed as a Swift Package Manager package. You can add it to your project as a package dependency using either a local package reference or the repository URL.

By default, Qt Bridge references a **Qt package** hosted in an **internal repository** that contains bundled, prebuilt Qt binaries. To build successfully, you must have a private SSH key with access to this repository. The SSH key must be placed in the `~/.ssh` directory, and the `~/.ssh/config` file must be configured accordingly.

If you have access to the Qt internal repository, add it as a remote SwiftPM dependency. Otherwise, add Qt Bridge as a local package and build the local Qt package that Qt Bridge depends on.

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

If you have the private SSH key to the internal repo, the package will fetch its dependencies automatically.

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

If you don't have access to the Qt internal repository, follow the tutorial below to build the local Qt package and specify it as a dependency for Qt Bridge.

### Building local Qt package

#### 1. Create Qt package folder

Navigate to the cloned repository, copy Qt folder and place it next to the `qtbridge-swift` directory:

```
$ cd /path/to/qtbridge-swift
$ cp -R Qt ..
```
**This newly created Qt folder is our local Qt package and will be referred to as `/path/to/Qt` in these instructions.**

#### 2. Download and build Qt 6.10.0 from source

Check out the tutorial on how to [build Qt from source](https://wiki.qt.io/Building_Qt_6_from_Git), or follow the simplified instructions below.

Navigate to the directory that will contain the top-level **qt6** repository and run the following command to clone it:
```
$ git clone git://code.qt.io/qt/qt5.git qt6
```

Qt Bridge depends on **Qt 6.10.0**, so switch to the corresponding branch:
```
$ cd qt6
$ git switch 6.10.0
```

Next, fetch the submodule source code by running the following command from the `qt6` directory:
```
$ init-repository
```

Create a separate build directory parallel to the source directory:
```
$ cd ..
$ mkdir qt6-build
$ cd qt6-build
```

From the build directory, configure, build, and install Qt 6. Pass the desired installation path using the `-prefix` parameter:

```
$ ../qt6/configure \
   -release \
   -prefix your_qt_install_dir \
   -nomake tests \
   -nomake examples \
   -no-feature-sql \
   -no-feature-network \
   -no-feature-qml-network \
   -no-dbus \
   --module-subset=qtbase,qtdeclarative

$ cmake --build . --parallel

$ cmake --install .
```

#### 3. Create .xcframeworks for the Qt package

Navigate to `your_qt_install_dir/lib` folder and create .xcframework from each .framework:
```
$ cd your_qt_install_dir/lib

$ for fw in *.framework; do
  name="${fw%.framework}"
  xcodebuild -create-xcframework \
    -framework "$fw" \
    -output "${name}.xcframework"
done
```

Place the newly created .xcframeworks into the `path/to/Qt/lib/Frameworks` directory:

```
$ mkdir /path/to/Qt/lib/Frameworks
$ mv *.xcframework /path/to/Qt/lib/Frameworks
```

#### 4. Copy Qt headers into the Qt package

Copy `QtQmlIntegration` folder from `your_qt_install_dir/include` into the `path/to/Qt/include` directory:

```
$ cp -R ../include/QtQmlIntegration /path/to/Qt/include
```

#### 5. Copy plugins into the Qt package

Copy `qml` and `plugins` folders from `your_qt_install_dir` into the root of the Qt package:

```
$ cp -R ../qml /path/to/Qt
$ cp -R ../plugins /path/to/Qt
```

#### 6. Qt package is ready
At this point, the Qt package is ready and its structure should look like this:

```
Qt
├── Package.swift
├── bundle.swift
├── include
│ ├── QtQmlIntegration
│ └── _spmQtQmlIntegration.cpp
├── lib
│ ├── Frameworks
│ │ ├── QtCore.xcframework
│ │ ├── QtGui.xcframework
│ │ ├── QtQml.xcframework
│ │ └── ...
│ ├── _spmQtCore.cpp
│ └── ...
├── plugins
│ ├── platforms
│ └── ...
└── qml
  ├── QtCore
  └──...
```

#### 7. Modify `Package.swift` of the Qt Bridge

If you prefer building from Xcode, edit `qtbridge-swift/Package.swift` and set the `useLocalQt` variable to true:

`let useLocalQt: Bool = true`

If you prefer building from the terminal, you can set an environment variable to use the local Qt package before building:

```
$ export QTBRIDGE_USE_LOCAL_QT_PACKAGE="true"
```

At this point, the Qt Bridge and Qt packages are ready, and any projects referencing Qt Bridge can be built successfully.

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

When you use a Team in Xcode and enable automatic signing, Xcode may enable the
**Hardened Runtime** for the generated macOS app target. With Hardened Runtime enabled,
macOS enforces **library validation**, which restricts the app to loading only system
libraries and libraries signed with a compatible signature. Qt Bridge loads additional
Qt frameworks at runtime, and this can cause the app to fail to launch when library
validation is enabled.

If you see a code signing error, open the app target’s **Signing & Capabilities** tab,
expand Hardened Runtime, and manually check **Disable Library Validation**.
You can also disable Hardened Runtime by clicking **Delete** on the right side of the
tab.

At this point, the example application is ready to run. You can do so, by pressing
the **Run** button. The project template configures the basic build settings and
target configuration. For more advanced configuration, you can adjust
**Build Settings** in the project navigator.

## Stay in touch

You can reach us in the Qt Forum, specifically in the [Qt Bridges
category](https://forum.qt.io/category/78/qt-bridges).
