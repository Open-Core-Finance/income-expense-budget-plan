#!/bin/zsh

chmoc +x ./macos/Flutter/ephemeral/Flutter-Generated.xcconfig
. ./macos/Flutter/ephemeral/Flutter-Generated.xcconfig

export FLUTTER_ROOT=$HOME/flutter
export PATH="$PATH:${FLUTTER_ROOT}/bin"