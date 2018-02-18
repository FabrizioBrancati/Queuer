#!/bin/bash

# Creates documentation using Jazzy.

FRAMEWORK_VERSION=1.3.0

jazzy \
  --clean \
  --author "Fabrizio Brancati" \
  --author_url https://www.fabriziobrancati.com \
  --github_url https://github.com/FabrizioBrancati/Queuer \
  --github-file-prefix https://github.com/FabrizioBrancati/Queuer/tree/$FRAMEWORK_VERSION \
  --module-version $FRAMEWORK_VERSION \
  --xcodebuild-arguments -scheme,"Queuer iOS" \
  --module Queuer \
  --root-url https://github.com/FabrizioBrancati/Queuer \
  --output Docs/
