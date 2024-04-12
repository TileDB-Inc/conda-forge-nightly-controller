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

# (temporary) Add azure-identity-cpp
mkdir -p tiledb-feedstock/recipe/tiledb-patches/system-ports/azure-identity-cpp
echo "set(VCPKG_POLICY_EMPTY_PACKAGE enabled)" \
  > tiledb-feedstock/recipe/tiledb-patches/system-ports/azure-identity-cpp/portfile.cmake
echo '{ "name": "azure-identity-cpp", "version-string": "system" }' \
  > tiledb-feedstock/recipe/tiledb-patches/system-ports/azure-identity-cpp/vcpkg.json

sed -i \
  s/host:/'host:\n    - azure-identity-cpp'/ \
  tiledb-feedstock/recipe/meta.yaml

# Use VS2022
cat >> tiledb-feedstock/recipe/conda_build_config.yaml << EOF
c_compiler:    # [win]
  - vs2022       # [win]
cxx_compiler:  # [win]
  - vs2022       # [win]
c_stdlib_version:    # [win]
  - 2022             # [win]
EOF


# Print differences
git -C tiledb-feedstock/ --no-pager diff recipe/meta.yaml
