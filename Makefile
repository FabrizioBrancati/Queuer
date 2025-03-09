# Variables
SRC_NAME=Queuer

# Default target
.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*#"} /^[a-zA-Z_-]+:.*?#/ { printf "  %-20s - %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: dependencies
dependencies: # Install packages using SwiftPM
	@echo "Installing $(SRC_NAME) dependencies..."
	@swift package resolve

.PHONY: clean
clean: # Clean up generated files
	@echo "Cleaning up build files..."
	@rm -rf .build

.PHONY: open
open: # Open the project in Xcode
	@echo "Opening $(SRC_NAME) project..."
	@open Package.swift

.PHONY: lint
lint: # Lint the project using swift-format
	@echo "Linting $(SRC_NAME) project..."
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-format lint ./ --recursive --configuration swift-format-config.json

.PHONY: format
format: # Format the project using swift-format
	@echo "Formatting $(SRC_NAME) project..."
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-format format ./ --recursive --configuration swift-format-config.json --in-place

.PHONY: pre-commit-install
pre-commit-install: # Install pre-commit hooks
	@echo "Installing pre-commit hooks..."
	@pip install pre-commit
	@pre-commit install --hook-type commit-msg

.PHONY: setup
setup: # Setup the project
	@echo "Setting up $(SRC_NAME) project..."
	@make clean
	@make pre-commit-install
	@make dependencies

.PHONY: test
test: # Run tests
	@echo "Running tests..."
	@swift test

.PHONY: build
build: # Build the project
	@echo "Building and uploading beta version..."
	@swift build
