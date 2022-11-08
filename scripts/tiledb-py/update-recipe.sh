#!/bin/bash
set -eux

# Update version
version="$(cat version.txt).$(cat date.txt)"
sed -i \
  s/"{% set version = \".*\" %}"/"{% set version = \"$version\" %}"/ \
  tiledb-py-feedstock/recipe/meta.yaml

# Convert source from PyPI tarball to Git repo
commit="$(cat commit.txt)"
sed -i \
  s/"{% set sha256 = \".*\" %}"/"{% set sha1 = \"$commit\" %}"/ \
  tiledb-py-feedstock/recipe/meta.yaml
sed -i \
  s/"fn: {{ name }}-{{ version }}.tar.gz"/"git_depth: -1"/ \
  tiledb-py-feedstock/recipe/meta.yaml
sed -i \
  s/"url: https:\/\/pypi.io\/packages\/source\/{{ name\[0\] }}\/{{ name }}\/{{ name }}-{{ version }}.tar.gz"/"git_url: https:\/\/github.com\/TileDB-Inc\/TileDB-Py.git"/ \
  tiledb-py-feedstock/recipe/meta.yaml
sed -i \
  s/"sha256: {{ sha256 }}"/"git_rev: {{ sha1 }}"/ \
  tiledb-py-feedstock/recipe/meta.yaml

# Ensure build number is 0
sed -i \
  s/"  number: [0-9]\+"/"  number: 0"/ \
  tiledb-py-feedstock/recipe/meta.yaml

# Pin tiledb by the date
date="$(cat date.txt)"
sed -i \
  s/"- tiledb [0-9].\+"/"- tiledb \*.$date"/ \
  tiledb-py-feedstock/recipe/meta.yaml

# Print differences
git -C tiledb-py-feedstock/ --no-pager diff recipe/meta.yaml
