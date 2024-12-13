#!/bin/zsh

# The default execution directory of this script is the ci_scripts directory.
# change working directory to the root of your cloned repo.
cd "$CI_PRIMARY_REPOSITORY_PATH"

chmod +x ci_scripts/*.sh
. ci_scripts/ci_env.sh

cp -r ci_scripts "${PRODUCT_FOLDER}/"

cd "${PRODUCT_FOLDER}/"
. ci_scripts/ci_post_clone_common.sh