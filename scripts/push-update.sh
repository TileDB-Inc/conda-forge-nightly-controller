#!/bin/bash
set -eux

repo="$1"

git -C "$repo" push --force origin nightly-build
