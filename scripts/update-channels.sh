#!/bin/bash
set -eux

repo="$1"

# Disable conda-forge validation
echo "conda_forge_output_validation: False" >> "$repo/conda-forge.yml"

# Add tiledb as source channel
echo -e "channel_sources:\n  - conda-forge,tiledb/label/nightlies,jdblischak/label/nightlies" >> "$repo/recipe/conda_build_config.yaml"

# Change upload channel
echo -e "channel_targets:\n  - jdblischak nightlies" >> "$repo/recipe/conda_build_config.yaml"

# Print differences
git -C "$repo" --no-pager diff conda-forge.yml recipe/conda_build_config.yaml
