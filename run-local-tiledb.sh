#!/bin/bash
set -eu

# Attempt to locally replicate GitHub Actions workflow
#
# Usage: bash run-local-tiledb.sh [TRUE/FALSE]
#
# Pass argument TRUE to push changes to feedstocks
#
# Requires SSH keys for an account that has push access to feedstock repos
#
# Requires mamba
#
# Run from root of nightlies repo

PUSH="${1-FALSE}"
echo "Push to GitHub: $PUSH"
export TZ="America/New_York"

rm -rf tiledb-feedstock
git clone --quiet --depth 1 git@github.com:jdblischak/tiledb-feedstock.git tiledb-feedstock

rm -rf TileDB
git clone --quiet --depth 1 git@github.com:TileDB-Inc/TileDB.git TileDB

bash scripts/obtain-date.sh
bash scripts/tiledb/obtain-version.sh
bash scripts/obtain-commit.sh TileDB
bash scripts/pull-upstream-feedstock.sh tiledb-feedstock
bash scripts/tiledb/update-recipe.sh
bash scripts/update-channels.sh tiledb-feedstock
bash scripts/add-and-commit.sh tiledb-feedstock

if conda env list | grep -q "env-nightlies-tiledb\s"
then
  echo "Conda env already exists: env-nightlies-tiledb"
else
  echo "Installing conda env 'env-nightlies-tiledb'"
  mamba create --yes --quiet -n env-nightlies-tiledb \
    -c conda-forge --override-channels \
    conda-smithy
fi
source activate env-nightlies-tiledb
mamba update --yes --quiet conda-smithy

bash scripts/rerender-feedstock.sh tiledb-feedstock
source deactivate

if [[ "$PUSH" == "TRUE" || "$PUSH" == "True" || "$PUSH" == "true" ]]
then
  echo "Pushing to GitHub"
  bash scripts/push-update.sh tiledb-feedstock
else
  echo "Did **not** push to GitHub"
fi
