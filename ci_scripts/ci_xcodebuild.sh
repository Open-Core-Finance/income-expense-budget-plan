#!/bin/sh

# The default execution directory of this script is the ci_scripts directory.
cd "$CI_PRIMARY_REPOSITORY_PATH" # change working directory to the root of your cloned repo.

chmod +x "ci_scripts/ci_env.sh"
. "ci_scripts/ci_env.sh"

# Fail this script if any subcommand fails.
set -e

if [ "${CI_PRODUCT_PLATFORM}" = "macOS" ]; then
  echo "MacOS build..."
  echo "$PRODUCT_NAME.app" > "${PRODUCT_FOLDER}/Flutter/ephemeral/.app_filename"
  # && "$FLUTTER_ROOT"/packages/flutter_tools/bin/macos_assemble.sh embed

  flutter build macos --no-tree-shake-icons --release
else
  echo "iOS build..."
fi
