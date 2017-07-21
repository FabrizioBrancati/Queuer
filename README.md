<p align="center"><img src="https://github.fabriziobrancati.com/queuer/resources/queuer-banner.png" alt="Queuer Banner"></p>

[![Build Status](https://travis-ci.org/FabrizioBrancati/Queuer.svg?branch=master)](https://travis-ci.org/FabrizioBrancati/Queuer)
[![Codecov](https://codecov.io/gh/FabrizioBrancati/Queuer/branch/master/graph/badge.svg)](https://codecov.io/gh/FabrizioBrancati/Queuer)
[![codebeat](https://codebeat.co/badges/ba18628d-f16b-4cd4-81f7-f75e81d97b38)](https://codebeat.co/projects/github-com-fabriziobrancati-queuer)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/Queuer.svg?style=flat)][Documentation]
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/FabrizioBrancati/Queuer/blob/master/LICENSE)
<br>
[![Language](https://img.shields.io/badge/language-Swift%203.1%20/%204.0-orange.svg)](https://swift.org/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-ffc713.svg)][Documentation]

---

<p align="center">
    <a href="#swift-4">Swift 4</a> &bull;
    <a href="#features">Features</a> &bull;
    <a href="#requirements">Requirements</a> &bull;
    <a href="#communication">Communication</a> &bull;
    <a href="#contributing">Contributing</a> &bull;
    <a href="#installing-and-usage">Installing and Usage</a> &bull;
    <a href="#documentation">Documentation</a> &bull;
    <a href="#changelog">Changelog</a> &bull;
    <a href="#example">Example</a> &bull;
    <a href="#author">Author</a> &bull;
    <a href="#license">License</a>
</p>

---

Swift 4
=======

If you need Swift 4 support, please switch to [swift-4](https://github.com/FabrizioBrancati/Queuer/tree/swift-4) branch.

Features
========

Queuer is a queue manager, build on top of [OperationQueue](https://developer.apple.com/documentation/foundation/operationqueue) and [Dispatch](https://developer.apple.com/documentation/dispatch) (AKA GCD).<br>
It allows you to create any synchronous and asynchronous task easily, with just a few lines.<br>
Here is the list of all the features:
- [x] Works on all Swift compatible platforms (even Linux)
- [x] Easy to use and well documented
- [x] Create a single operation
- [x] Create chained operations
- [x] Create an operation block
- [x] Manage a centralized queue
- [x] Create unlimited queue
- [x] Declare how many concurrent operation a queue can handle
- [x] Create a network request operation
- [ ] Create a network download operation
- [ ] Create a network upload operation
- [ ] Ability to restore uncompleted network operations

Requirements
============

| **Swift** | **Xcode** | **Queuer** | **iOS** | **macOS** | **tvOS** | **watchOS** | **Linux** |
|-----------|-----------|------------|---------|-----------|----------|-------------|-----------|
| 3.1       | 8.3       | 1.0.0      | 8.0+    | 10.10     | 9.0      | 2.0+        | ![✓]      |
| 4.0       | 9.0       | ?.?.0      | 8.0+    | 10.10     | 9.0      | 2.0+        | ![✓]      |

Communication
=============

- If you need help, use Stack Overflow.
- If you found a bug, open an issue.
- If you have a feature request, open an issue.
- If you want to contribute, see [Contributing](https://github.com/FabrizioBrancati/Queuer#contributing) section.

Contributing
============

See [CONTRIBUTING.md](https://github.com/FabrizioBrancati/Queuer/blob/master/.github/CONTRIBUTING.md) file.

Installing and Usage
====================

See [Requirements](https://github.com/FabrizioBrancati/Queuer#requirements) section to check Swift, Xcode, Queuer and OS versions.

### Manual
- Open and build the framework from the project (**Queuer.xcodeproj**)
- Import Queuer.framework into your project
- Import the framework with ```import Queuer```
- Enjoy!

### CocoaPods
- Create a **Podfile** in your **project directory** and write into:

    ```ruby
    platform :ios, '8.0'
    xcodeproj 'Project.xcodeproj'
    use_frameworks!

    pod 'Queuer'
    ```
- Change **"Project"**  with your **real project name**
- Open **Terminal**, go to your **project directory** and type: ```pod install```
- Import the framework with ```import Queuer```
- Enjoy!

### Carthage
- Create a **Cartfile** in your **project directory** and write into:

    ```ruby
    github "FabrizioBrancati/Queuer"
    ```
- Open **Terminal**, go to **project directory** and type: ```carthage update```
- **Include the created Framework** in your project
- **Add Build Phase** with the following contents:

    ```sh
    /usr/local/bin/carthage copy-frameworks
    ```

    and add the paths to the Queuer framework under **Input Files**

    ```sh
    $(SRCROOT)/Carthage/Build/iOS/Queuer.framework
    ```
    This script works around an [App Store submission bug](http://www.openradar.me/radar?id=6409498411401216) triggered by universal binaries and ensures that necessary bitcode-related files are copied when archiving
- Import the framework with ```import Queuer```
- Enjoy!

### Swift Package Manager (Linux)
- Create a **Package.swift** file in your **project directory** and write into:

    ```swift
    import PackageDescription

    let package = Package(
        name: "Project",
        dependencies: [
            .Package(url: "https://github.com/FabrizioBrancati/Queuer.git", majorVersion: 1)
        ]
    )
    ```
- Change **"Project"**  with your **real project name**
- Open **Terminal**, go to **project directory** and type: ```swift build```
- Import the framework with ```import Queuer```
- Enjoy!

Documentation
=============

### [Documentation]
100% Documented

Changelog
=========

To see what has changed in recent versions of Queuer, see the **[CHANGELOG.md](https://github.com/FabrizioBrancati/Queuer/blob/master/CHANGELOG.md)** file.

Example
=======

Open and run the QueuerExample project in Example folder in this repo with Xcode and see Queuer in action!

Author
======

**Fabrizio Brancati**

[Website: https://www.fabriziobrancati.com](https://www.fabriziobrancati.com)
<br>
[Email: fabrizio.brancati@gmail.com](mailto:fabrizio.brancati@gmail.com)

License
=======

Queuer is available under the MIT license. See the **[LICENSE](https://github.com/FabrizioBrancati/Queuer/blob/master/LICENSE)** file for more info.

[Documentation]: https://github.fabriziobrancati.com/documentation/Queuer/
[✓]: https://github.fabriziobrancati.com/queuer/resources/check.png
