#!/bin/bash
set -eux

repo="$1"

conda smithy rerender --commit auto --feedstock_directory "$repo"
