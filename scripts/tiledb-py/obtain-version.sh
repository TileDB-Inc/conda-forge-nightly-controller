#!/bin/bash
set -eux

cd TileDB-Py
git tag --sort=-committerdate | head -n 1 > ../version.txt
cd -
cat version.txt
