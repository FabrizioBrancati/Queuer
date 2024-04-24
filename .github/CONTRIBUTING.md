# Contributing

I'd love to see your ideas for improving this project.

## Pull Requests

The best way to contribute is by submitting a pull request.
I'll do my best to respond to you as soon as possible.
Remember to open the pull request against the `develop` branch.

## Issues

If you find a bug or you have a suggestion create an issue.

## Comments

Every line of the project must to be commented.

## Writing code

New API should follow the rules documented in Swift's [API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/). Comment every public methods, properties, classes. Make commits as atomic as possible with understandable comment. If you are developing feature or fixing a bug, please mention the issue number (e.g. #1) in commit text.

## Changelog

Once your changes are ready, please add an entry to the [CHANGELOG.md](https://github.com/FabrizioBrancati/Queuer/blob/main/CHANGELOG.md) file.

## Tests

Add tests for every added function. The aim is to have 100% of code coverage.

## Linux

This library supports Linux, so please be sure that the feature that you are adding is compatible with it. If not, due to platform limitations, please wrap the code with `#if !os(Linux)`

### Using Docker on macOS to Test for Linux

The easiest way to test this package on Linux is to use Docker. You can use the following steps to set up a Docker container that runs the Swift compiler and test suite:

1. Install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop).

2. Run the following command from the root of this repository to build the
   Docker image:

    ```bash
    docker run --rm --privileged --interactive --tty \
    --volume "$(pwd):/src" \
    --workdir "/src" \
    swift:5.10
    ```

> [!TIP]
> Use `swift:5.10` to use a specific Swift version. If you want to use the latest version, you can use `swift:latest`.
>
> Use `swift:5.10-jammy` to use the Swift 5.10 version with Ubuntu 22.04 and `swift:5.10-focal` to use the Swift 5.10 version with Ubuntu 20.04.

1. Run the following command to run the test suite:

    ```bash
    swift test
    ```
