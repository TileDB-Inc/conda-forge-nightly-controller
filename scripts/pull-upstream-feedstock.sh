#!/bin/bash
set -eux

repo="$1"

git -C "$repo" remote add upstream "git@github.com:conda-forge/$repo.git"
git -C "$repo" pull --quiet upstream main
git -C "$repo" push --quiet origin main
