#!/bin/sh

# The default execution directory of this script is the ci_scripts directory.
# change working directory to the root of your cloned repo.
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Fail this script if any subcommand fails.
set -e

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
if [ "${CI_PRODUCT_PLATFORM}" = "macOS" ]; then
  flutter precache --macos
else
  flutter precache --ios
fi

# Install Flutter dependencies.
flutter pub get

# Install CocoaPods using Homebrew.
# shellcheck disable=SC2034
HOMEBREW_NO_AUTO_UPDATE=1 # disable homebrew's automatic updates.
brew install cocoapods

# Install CocoaPods dependencies.
cd "${PRODUCT_FOLDER}"
pod install # run `pod install` in the `macos` directory.

cd "$CI_PRIMARY_REPOSITORY_PATH"

#cp -r "${PRODUCT_FOLDER}/Runner.xcodeproj" ./
