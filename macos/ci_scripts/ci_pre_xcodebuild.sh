#!/bin/zsh

# The default execution directory of this script is the ci_scripts directory.
cd "$CI_PRIMARY_REPOSITORY_PATH" # change working directory to the root of your cloned repo.

chmod +x macos/ci_scripts/ci_env.sh
. macos/ci_scripts/ci_env.sh

# Fail this script if any subcommand fails.
set -e

flutter build macos --no-tree-shake-icons --release
