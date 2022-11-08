#!/bin/bash
set -eux

repo="$1"

version="$(cat version.txt)$(cat date.txt)"
git -C "$repo" config --local user.name "GitHub Actions"
git -C "$repo" config --local user.email "runneradmin@github.com"
git -C "$repo" checkout --quiet -B nightly-build main
git -C "$repo" add conda-forge.yml recipe/conda_build_config.yaml recipe/meta.yaml
git -C "$repo" commit --quiet -m "Nightly build for $version"
