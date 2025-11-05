#!/bin/bash
set -eux

# Update version
version="$(cat version.txt)$(cat date.txt)"
sed -i \
  s/"{% set version = \".*\" %}"/"{% set version = \"$version\" %}"/ \
  tiledb-feedstock/recipe/meta.yaml

# Update source URL
sed -i \
  s/"url: https:\/\/github.com\/TileDB-Inc\/{{ name }}\/archive\/{{ version }}.tar.gz"/"git_url: https:\/\/github.com\/TileDB-Inc\/{{ name }}.git"/ \
  tiledb-feedstock/recipe/meta.yaml

# Replace tarball SHA256 with Git SHA1
commit="$(cat commit.txt)"
sed -i \
  s/"sha256: .\+"/"git_rev: $commit\n  git_depth: 10"/ \
  tiledb-feedstock/recipe/meta.yaml

# Ensure build number is 0
sed -i \
  s/"  number: [0-9]\+"/"  number: 0"/ \
  tiledb-feedstock/recipe/meta.yaml

# (temporary) Remove azure patch
git -C tiledb-feedstock/ rm recipe/azure-fix.patch
sed -i \
  -e '/patches/d' -e '/azure-fix.patch/d' \
  tiledb-feedstock/recipe/meta.yaml

# (temporary) Add c-blosc2
mkdir -p tiledb-feedstock/recipe/tiledb-patches/system-ports/blosc2
echo "set(VCPKG_POLICY_EMPTY_PACKAGE enabled)" \
  > tiledb-feedstock/recipe/tiledb-patches/system-ports/blosc2/portfile.cmake
echo '{ "name": "blosc2", "version-string": "system" }' \
  > tiledb-feedstock/recipe/tiledb-patches/system-ports/blosc2/vcpkg.json

sed -i \
  s/host:/'host:\n    - c-blosc2'/ \
  tiledb-feedstock/recipe/meta.yaml

# Print differences
git -C tiledb-feedstock/ --no-pager diff recipe/
