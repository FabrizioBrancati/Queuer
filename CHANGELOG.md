# Changelog

> [!NOTE]
> All notable changes to this project will be documented in this file.
>
> `Queuer` adheres to [Semantic Versioning](http://semver.org/).

## 3.x Releases

- `3.0.x` Releases - [3.0.0](#300---)

## 2.x Releases

- `2.1.x` Releases - [2.1.0](#210---swift-50-support) | [2.1.1](#211---swift-51-support)
- `2.0.x` Releases - [2.0.0](#200---let-me-retry) | [2.0.1](#201---better-apis)

## 1.x Releases

- `1.3.x` Releases - [1.3.0](#130---open-everything) | [1.3.1](#131---swift-41-support) | [1.3.2](#132---linux-quality)
- `1.2.x` Releases - [1.2.0](#120---swift-4-support) | [1.2.1](#121---unwanted-alert)
- `1.1.x` Releases - [1.1.0](#110---quality-of-service)
- `1.0.x` Releases - [1.0.0](#100---first-queue)

## [3.0.0](https://github.com/FabrizioBrancati/Queuer/releases/tag/3.0.0) - ???

### XX XXX 2024

> [!WARNING]
> The goal of this release is to make the repo more maintainable. To do so, only Swift Package Manager will be supported. If you rely on any of the removed services, like CocoaPods or Carthage, please stick to the porevious version.

### Changed

- Changed CI service to GitHub Actions
- Changed minumum iOS version to 12.0 [#24](https://github.com/FabrizioBrancati/Queuer/issues/24)
- Changed minimum macOS version to 10.13
- Changed minimum tvOS version to 12.0
- Changed minimum watchOS version to 4.0
- Changed minimum macCatalyst version to 13.0

### Added

- Added visionOS 1.0 support
- Added full Linux support
- Added new `GroupOperation` operation type [#14](https://github.com/FabrizioBrancati/Queuer/issues/14) and [#17](https://github.com/FabrizioBrancati/Queuer/pull/17), more info on how to use it [here](https://github.com/FabrizioBrancati/Queuer#group-operations)
- Added support to Xcode 15.3 and Swift 5.10
- Added `macCatalyst` support
- Added Swift Package Index documentation support [#26](https://github.com/FabrizioBrancati/Queuer/issues/26) and [#30](https://github.com/FabrizioBrancati/Queuer/issues/30)
- Added Dependabot support

### Fixed

- Fixed a `Scheduler` bug that may prevent to correctly call the event handler

### Improved

- Improved tests
- Improved [CONTRIBUTING.md](https://github.com/FabrizioBrancati/Queuer/blob/main/.github/CONTRIBUTING.md) guidelines

### Removed

- Removed `hasFailed` variable from `ConcurrentOperation` class as it was deprecated in version 2.0.1
- Removed `finish(_ hasFailed: Bool)` function from `ConcurrentOperation` class as it was deprecated in version 2.0.1
- Removed SwiftLint
- Removed CocoaPods support
- Removed Carthage support
- Removed Coveralls support
- Removed Slather support
- Removed Jazzy support

Thanks to [@Kalzem](https://github.com/Kalzem), [@changmingw96](https://github.com/changmingw96), [cristianilea-lateral](https://github.com/cristianilea-lateral) and [@marinofaggiana](https://github.com/marinofaggiana) for this release.

## [2.1.1](https://github.com/FabrizioBrancati/Queuer/releases/tag/2.1.1) - Swift 5.1 Support

### 6 Nov 2019

### Added

- Added support to Xcode 11.2 and Swift 5.1

### Improved

- Updated SwiftLint to 0.35.0

## [2.1.0](https://github.com/FabrizioBrancati/Queuer/releases/tag/2.1.0) - Swift 5.0 Support

### 12 Apr 2019

### Added

- Added support to Xcode 10.2 and Swift 5.0

## [2.0.1](https://github.com/FabrizioBrancati/Queuer/releases/tag/2.0.1) - Better APIs

### 26 Dec 2018

### Changed

- Renamed `open func finish(_ hasFailed: Bool)` to `open func finish(success: Bool = true)`, the old one has been deprecated but still valid [#12](https://github.com/FabrizioBrancati/Queuer/issues/12)
- Renamed `hasFailed` variable to `success`, the old one has been deprecated but still valid [#12](https://github.com/FabrizioBrancati/Queuer/issues/12)

### Improved

- Updated SwiftLint to 0.29.2

Thanks to [@zykloman](https://github.com/zykloman) for this release

## [2.0.0](https://github.com/FabrizioBrancati/Queuer/releases/tag/2.0.0) - Let Me Retry

### 1 Nov 2018

### Added

- Added support to Xcode 10 and Swift 4.2
- Added retry feature to `ConcurrentOperation` class [#10](https://github.com/FabrizioBrancati/Queuer/issues/10), more info on how to use it [here](https://github.com/FabrizioBrancati/Queuer#automatically-retry-an-operation) and [here](https://github.com/FabrizioBrancati/Queuer#manually-retry-an-operation)
- Added `addCompletionHandler(_:)` function to `Queuer` class
- Added a `Scheduler` class to better schedule your tasks, more info on how to use it [here](https://github.com/FabrizioBrancati/Queuer#scheduler)
- Added queue state restoration (beta) feature, more info on how to use it [here](https://github.com/FabrizioBrancati/Queuer#queue-state-restoration-beta)

### Changed

- Changed `executionBlock` of `ConcurrentOperation` to pass the `concurrentOperation` variable inside the closure to be able to use the retry feature. If you don't need it simply put `_ in` after the block creation:

  ```swift
  let concurrentOperation = ConcurrentOperation { _ in
      /// Your task here
  }
  ```

  This also affects `SynchronousOperation`
- Changed from Codecov to Coveralls service for code coverage

### Improved

- Improved `Semaphore` with timeout handling
- Updated SwiftLint to 0.27.0

### Removed

- Removed watchOS 2.0 support in favor of watchOS 3.0, thanks to an App Store submission bug [#11](https://github.com/FabrizioBrancati/Queuer/issues/11)
- Removed Hound CI

Thanks to [@SureshSc](https://github.com/SureshSc), [@zykloman](https://github.com/zykloman) and [@debjitk](https://github.com/debjitk) for this release

## [1.3.2](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.3.2) - Linux Quality

### 7 Jul 2018

### Added

- Added `QualityOfService` on Linux
- Deprecated `RequestOperation`, it will be removed in Queuer 2

### Improved

- Updated SwiftLint to 0.26.0
- Improved code with new SwiftLint rules

## [1.3.1](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.3.1) - Swift 4.1 Support

### 2 Apr 2018

### Added

- Added support to Xcode 9.3 and Swift 4.1

### Improved

- `OperationQueue` in Queuer class is now `open`

Thanks to [@BabyAzerty](https://github.com/BabyAzerty) for this release

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

## [1.2.1](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.2.1) - Unwanted Alert

### 22 Oct 2017

### Fixed

- Removed alert on Xcode 9 that shows the ability to convert the code to Swift 4 even it's already written in Swift 4

## [1.2.0](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.2.0) - Swift 4 Support

### 23 Sep 2017

### Added

- Added support to Swift 4 and Xcode 9

### Improved

- Using new Xcode 9 build system
- Updated SwiftLint to 0.22.0

## [1.1.0](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.1.0) - Quality Of Service

### 1 Sep 2017

### Added

- Added `qualityOfService` property on Queuer class
- Added `ddChainedOperations(_ operations: Operation..., completionHandler:` convenience function on Queuer class

### Improved

- Improved the `init` function on Queuer class with `maxConcurrentOperationCount` and `qualityOfService` properties, both with a default value, so no changes are required
- Updated SwiftLint to 0.21.0

### Fixed

- Now `ConcurrentOperation` is subclassable with `open` instead of `public` Access Control [#2](https://github.com/FabrizioBrancati/Queuer/issues/2)
- Fixed tests that sometimes fails

## [1.0.0](https://github.com/FabrizioBrancati/Queuer/releases/tag/1.0.0) - First Queue

### 26 Jul 2017

### Added

- Added `ConcurrentOperation` to create asynchronous operations
- Added `Queuer` to handle a `shared` queue or create a custom one
- Added `RequestOperation` to create network request operations
- Added `Semaphore` to create a Dispath semaphore
- Added `SynchronousOperation` to create synchronous operations
