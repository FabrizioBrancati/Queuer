#!/bin/bash

# Creates documentation using Jazzy.

FRAMEWORK_VERSION=2.1.1

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
  --output Docs/ \
  --theme jony \
  --docset-icon Resources/Icon-32.png \
  --root-url https://github.fabriziobrancati.com/documentation/Queuer/ \
  --dash_url https://github.fabriziobrancati.com/documentation/Queuer/docsets/Queuer.xml

cp -r Resources Docs/Resources
