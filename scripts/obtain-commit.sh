#!/bin/bash
set -eux

repo="$1"

git -C "$repo" log -n 1 --format=format:%H > commit.txt
cat commit.txt
