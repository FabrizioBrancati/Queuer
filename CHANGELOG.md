Changelog
=========

---

All notable changes to this project will be documented in this file.<br>
`Queuer` adheres to [Semantic Versioning](http://semver.org/).

---

### 1.x Releases
- `1.0.x` Releases - [1.0.0](#100---first-queue)

---

## Master
### Added
- Added `qualityOfService` property on Queuer class

### Improved
- Improved the `init` function on Queuer class with `maxConcurrentOperationCount` and `qualityOfService` properties, both with a default value, so no changes are required

### Fixed
- Nothing

---

## Swift 4
### Added
- Added support to Swift 4 and Xcode 9

### Improved
- Nothing

### Fixed
- Nothing

### Changed
- Nothing

---

## [1.0.0](https://github.com/FabrizioBrancati/Queuer/releases/tag/v1.0.0) - First Queue
### 26 Jul 2017
### Added
- Added `ConcurrentOperation` to create asynchronous operations
- Added `Queuer` to handle a `shared` queue or create a custom one
- Added `RequestOperation` to create network request operations
- Added `Semaphore` to create a Dispath semaphore
- Added `SynchronousOperation` to create synchronous operations
