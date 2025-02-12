#!/bin/bash
set -eux

repo="$1"

# Disable conda-forge validation
echo "conda_forge_output_validation: False" >> "$repo/conda-forge.yml"

# Always upload binaries from branch "nightly-build"
echo "upload_on_branch: nightly-build" >> "$repo/conda-forge.yml"
# No need to substitute existing value. When a duplicated is duplicated,
# conda-smithy uses the latest

# Add tiledb as source channel
echo -e "channel_sources:\n  - tiledb/label/nightlies,conda-forge" >> "$repo/recipe/conda_build_config.yaml"

# Change upload channel
echo -e "channel_targets:\n  - tiledb nightlies" >> "$repo/recipe/conda_build_config.yaml"

# Print differences
git -C "$repo" --no-pager diff conda-forge.yml recipe/conda_build_config.yaml
