#!/bin/zsh

# The default execution directory of this script is the ci_scripts directory.
# change working directory to the root of your cloned repo.
cd "$CI_PRIMARY_REPOSITORY_PATH"

chmod +x "ci_scripts/ci_env.sh"
. "ci_scripts/ci_env.sh"

"${FLUTTER_ROOT}"/packages/flutter_tools/bin/macos_assemble.sh