Changelog
=========

---

All notable changes to this project will be documented in this file.<br>
`Queuer` adheres to [Semantic Versioning](http://semver.org/).

---

### 1.x Releases
- `1.3.x` Releases - [1.3.0](#130---open-everything) | [1.3.1](#131---swift-41-support)
- `1.2.x` Releases - [1.2.0](#120---swift-4-support) | [1.2.1](#121---unwanted-alert)
- `1.1.x` Releases - [1.1.0](#110---quality-of-service)
- `1.0.x` Releases - [1.0.0](#100---first-queue)

---

## Develop
### Added
- Added `QualityOfService` on Linux
- Deprecated `RequestOperation`, it will be removed in Queuer 2

### Improved
- Updated SwiftLint to 0.26.0
- Improved code with new SwiftLint rules

---

## [1.3.1](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.3.1) - Swift 4.1 Support
### 2 Apr 2018
### Added
- Added support to Xcode 9.3 and Swift 4.1

### Improved
- `OperationQueue` in Queuer class is now `open`

Thanks to [@BabyAzerty](https://github.com/BabyAzerty) for this release

---

## [1.3.0](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.3.0) - Open Everything
### 18 Feb 2018
### Added
- Added `swift_version` property in podspec file for CocoaPods 1.4.0
- Added Hound CI

### Improved
- `body`, `headers` and `query` parameters in RequestOperation class may now be `nil`
- RequestOperation class and all of its functions are now `open`
- `session` object in RequestOperation class in now open and has `waitsForConnectivity` sets to `true` for iOS 11 or later by default
- Updated SwiftLint to 0.25.0

### Fixed
- Now Swift Package Manager correctly builds Queuer with Swift 4
- Removed `self` captures

---

## [1.2.1](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.2.1) - Unwanted Alert
### 22 Oct 2017
### Fixed
- Removed alert on Xcode 9 that shows the ability to convert the code to Swift 4 even it's already written in Swift 4

---

## [1.2.0](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.2.0) - Swift 4 Support
### 23 Sep 2017
### Added
- Added support to Swift 4 and Xcode 9

### Improved
- Using new Xcode 9 build system
- Updated SwiftLint to 0.22.0

---

## [1.1.0](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.1.0) - Quality Of Service
### 1 Sep 2017
### Added
- Added `qualityOfService` property on Queuer class
- Added `ddChainedOperations(_ operations: Operation..., completionHandler:` convenience function on Queuer class

### Improved
- Improved the `init` function on Queuer class with `maxConcurrentOperationCount` and `qualityOfService` properties, both with a default value, so no changes are required
- Updated SwiftLint to 0.21.0

### Fixed
- Now `ConcurrentOperation` is subclassable with `open` instead of `public` Access Control [#2](https://github.com/FabrizioBrancati/Queuer/issue/2)
- Fixed tests that sometimes fails

---

## [1.0.0](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.0.0) - First Queue
### 26 Jul 2017
### Added
- Added `ConcurrentOperation` to create asynchronous operations
- Added `Queuer` to handle a `shared` queue or create a custom one
- Added `RequestOperation` to create network request operations
- Added `Semaphore` to create a Dispath semaphore
- Added `SynchronousOperation` to create synchronous operations
