#!/bin/bash
set -eu

# Attempt to locally replicate GitHub Actions workflow
#
# Usage: bash run-local-tiledb-py.sh [TRUE/FALSE]
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

rm -rf tiledb-py-feedstock
git clone --quiet --depth 1 git@github.com:TileDB-Inc/tiledb-py-feedstock.git tiledb-py-feedstock

rm -rf TileDB-Py
git clone --quiet git@github.com:TileDB-Inc/TileDB-Py.git TileDB-Py

bash scripts/obtain-date.sh

if conda env list | grep -q "env-nightlies-tiledb-py"
then
  echo "Conda env already exists: env-nightlies-tiledb-py"
else
  echo "Installing conda env 'env-nightlies-tiledb-py'"
  mamba create --yes --quiet -n env-nightlies-tiledb-py \
    -c conda-forge --override-channels \
    conda-smithy \
    cmake \
    cython \
    numpy \
    pybind11 \
    ruamel.yaml \
    ruamel.yaml.jinja2 \
    setuptools \
    setuptools-scm \
    wheel
fi
source activate env-nightlies-tiledb-py
mamba update --yes --quiet conda-smithy

bash scripts/tiledb-py/obtain-version.sh
bash scripts/obtain-commit.sh TileDB-Py
bash scripts/pull-upstream-feedstock.sh tiledb-py-feedstock
python scripts/tiledb-py/update-recipe.py
bash scripts/update-channels.sh tiledb-py-feedstock
bash scripts/add-and-commit.sh tiledb-py-feedstock

bash scripts/rerender-feedstock.sh tiledb-py-feedstock
source deactivate

if [[ "$PUSH" == "TRUE" || "$PUSH" == "True" || "$PUSH" == "true" ]]
then
  echo "Pushing to GitHub"
  bash scripts/push-update.sh tiledb-py-feedstock
else
  echo "Did **not** push to GitHub"
fi
