#!/bin/bash
set -eux

repo="$1"

conda smithy rerender --no-check-uptodate --commit auto --feedstock_directory "$repo"
