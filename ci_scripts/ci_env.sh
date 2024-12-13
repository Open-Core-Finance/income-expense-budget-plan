#!/bin/sh

echo "Running platform: ${CI_PRODUCT_PLATFORM}"

if [ "${CI_PRODUCT_PLATFORM}" = "macOS" ]; then
  # cp -r macos/* ./
  export PRODUCT_FOLDER=macos
else
  # cp -r ios/* ./
  export PRODUCT_FOLDER=ios
fi

if [ -f "${PRODUCT_FOLDER}/Flutter/ephemeral/Flutter-Generated.xcconfig" ]; then
  chmod +x ${PRODUCT_FOLDER}/Flutter/ephemeral/Flutter-Generated.xcconfig
  . ${PRODUCT_FOLDER}/Flutter/ephemeral/Flutter-Generated.xcconfig
fi

export FLUTTER_ROOT="$HOME/flutter"
export PATH="$PATH:${FLUTTER_ROOT}/bin"