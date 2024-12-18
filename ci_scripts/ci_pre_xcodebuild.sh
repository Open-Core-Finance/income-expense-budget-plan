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
  inputFile="macos/Runner.xcodeproj/project.pbxproj"
  tmpFile="${inputFile}.bak"
  cp "${inputFile}" "${tmpFile}"
#  sed -i '' 's/CODE_SIGN_IDENTITY = "Apple Development"/"CODE_SIGN_IDENTITY[sdk=macosx*]" = "-"/g' "${inputFile}"
  echo "Creating temp proj file for flutter build..."
  sed -i '' '/CODE_SIGN_IDENTITY = "Apple Development"/d' "${inputFile}"
  sed -i '' '/CODE_SIGN_STYLE = Automatic/d' "${inputFile}"
  echo "Running flutter build..."
  flutter build macos --no-tree-shake-icons --debug
  echo "Remove generated project file"
  rm -rfv "${inputFile}"
  echo "Remove generated build folder"
  rm -rfv "build/macos/Build"
  echo "Restore original project file"
  cp "${tmpFile}" "${inputFile}"
  echo "Mac OS prebuilt completed!"
else
  echo "iOS build..."
  # flutter build ipa --no-tree-shake-icons --no-codesign
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
