# Contributing

I'd love to see your ideas for improving this project.

## Pull Requests

The best way to contribute is by submitting a pull request.
I'll do my best to respond to you as soon as possible.
Remember to open the pull request against the `develop` branch.

## Issues

If you find a bug or you have a suggestion create an issue.

## Documentation

Every public method, property, class, struct, enum, protocol, etc. should be documented. The documentation should be written in the code, and in the README file (for features only).

You can generate the documentation by using the following command:

```bash
swift package \
  --allow-writing-to-directory docs \
  generate-documentation \
  --target Queuer \
  --disable-indexing \
  --transform-for-static-hosting \
  --hosting-base-path Queuer \
  --output-path docs \
  --enable-inherited-docs \
  --experimental-documentation-coverage \
  --level detailed \
```

If you find a typo or you think that something is not well explained, please open an issue or submit a pull request.

## Writing code

New API should follow the rules documented in Swift's [API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/). Comment every public methods, properties, classes. Make commits as atomic as possible with understandable comment. If you are developing feature or fixing a bug, please mention the issue number (e.g. #1) in commit text.

## Commit Messages

Please follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.

To make it easier, you can use `pre-commit` and configure it with the following command:

```bash
make pre-commit-install
```

This will install the `pre-commit` hooks that will check your commit messages.

## Changelog

Once your changes are ready, please add an entry to the [CHANGELOG.md](https://github.com/FabrizioBrancati/Queuer/blob/main/CHANGELOG.md) file.

## Tests

Add tests for every added function. The aim is to have 100% of code coverage.

Tests must be deterministic: never use `Thread.sleep` or fixed delays to wait for something to happen, as they make tests flaky on slow CI runners.
Use the utilities in `Tests/QueuerTests/Helpers/TestHelper.swift` instead: `Protected` for state shared between threads, `waitUntil(timeout:_:)` to poll a condition, `fulfill(_:when:)` to fulfill an expectation when a condition becomes true, and `DispatchSemaphore` to enforce an execution order between operations.

## Platform Support

This library supports every Apple platform (iOS, macOS, Mac Catalyst, tvOS, watchOS, and visionOS), Linux, Android, and Windows, with Swift from 5.9 to 6.3.
Please be sure that the feature you are adding is compatible with all of them.
If it can't be, due to platform limitations, please wrap the code with the appropriate condition, for example `#if !os(Linux)`, `#if !os(Android)`, `#if !os(Windows)`, or `#if canImport(Darwin)` for Apple only APIs.

Keep in mind that availability annotations like `@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)` are required when using APIs newer than the minimum deployment targets (iOS 12, macOS 10.13, Mac Catalyst 13, tvOS 12, watchOS 4, and visionOS 1), and that they are ignored on Linux, Android, and Windows.

> [!NOTE]
> Every pull request automatically runs the whole test suite on all the supported platforms and Swift versions with GitHub Actions.
> You don't need to set up every platform locally, but testing at least on one platform before pushing is recommended.

### Using Docker on macOS to Test for Linux

The easiest way to test this package on Linux is to use Docker. You can use the following steps to set up a Docker container that runs the Swift compiler and test suite:

1. Install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop).

2. Run the following command from the root of this repository to start a container:

    ```bash
    docker run --rm --privileged --interactive --tty \
    --volume "$(pwd):/src" \
    --workdir "/src" \
    swift:6.3
    ```

Also, you can use the following tags:

- Use `swift:6.3`, `swift:6.2`, `swift:6.1`, `swift:6.0`, `swift:5.10`, or `swift:5.9` to pick the Swift version.
  - Add the `-noble` suffix (e.g. `swift:6.3-noble`) to use Ubuntu 24.04.
  - Add the `-jammy` suffix (e.g. `swift:6.3-jammy`) to use Ubuntu 22.04.

> [!TIP]
> If you want to use the latest version, you can use `swift:latest`.

3. Run the following command to run the test suite:

    ```bash
    swift test
    ```

### Testing for Android

CI builds the package and runs the test suite on an Android emulator using the [Swift Android Action](https://github.com/marketplace/actions/swift-android-action), with the official [Swift SDK for Android](https://www.swift.org/blog/nightly-swift-sdk-for-android/).

If you want to build for Android locally, you can install the Swift SDK for Android by following the [official instructions](https://www.swift.org/android/), and then build with:

```bash
swift build --swift-sdk aarch64-unknown-linux-android28
```

Running the tests locally requires an Android emulator, so it is usually easier to let CI do it.

### Testing for Windows

CI builds the package and runs the test suite on Windows with the latest stable Swift release.

If you are on Windows, you can install Swift by following the [official instructions](https://www.swift.org/install/windows/), and then run the test suite as usual:

```bash
swift test
```
