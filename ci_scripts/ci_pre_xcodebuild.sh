#!/bin/sh

# The default execution directory of this script is the ci_scripts directory.
# change working directory to the root of your cloned repo.
cd "$CI_PRIMARY_REPOSITORY_PATH"

chmod +x "ci_scripts/ci_env.sh"
. "ci_scripts/ci_env.sh"

# Fail this script if any subcommand fails.
set -e

if [ "${CI_PRODUCT_PLATFORM}" = "macOS" ]; then
  echo "MacOS build..."
  flutter build macos --no-tree-shake-icons --release
else
  echo "iOS build..."
  flutter build ipa --no-tree-shake-icons --release
fi

cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "Current folder $(pwd)"

echo "Product folder ${PRODUCT_FOLDER}"
ls -ail "${PRODUCT_FOLDER}"

#echo "Start copying product folder out..."
#cp -r "${PRODUCT_FOLDER}/Flutter" ./
#cp -r "${PRODUCT_FOLDER}/Runner" ./
#cp -r "${PRODUCT_FOLDER}/Runner.xcworkspace" ./
#cp -r "${PRODUCT_FOLDER}/RunnerTests" ./
#cp -r "${PRODUCT_FOLDER}/Podfile" ./
#cp -r "${PRODUCT_FOLDER}/Podfile.lock" ./
#cp -r "${PRODUCT_FOLDER}/Pods" ./
#cp -r "${PRODUCT_FOLDER}/Flutter" ./
