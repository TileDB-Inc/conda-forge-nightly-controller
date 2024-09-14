# Update the conda recipe for the nightly build
#
# Parses recipe with ruamel.yaml
#
# Reads values for version, date, and commit from plain-text files

recipe = "tiledb-py-feedstock/recipe/meta.yaml"
conda_build_config = "tiledb-py-feedstock/recipe/conda_build_config.yaml"

import os
from ruamel.yaml import YAML
from yaml.constructor import ConstructorError
from yaml.scanner import ScannerError
from datetime import datetime

# Read values from plain-text files -------------------------------------------

with open("date.txt") as f:
    date = f.read().strip()

with open("version.txt") as f:
    version = f.read().strip()

with open("commit.txt") as f:
    commit = f.read().strip()

# Parse and update YAML recipe ------------------------------------------------

yaml = YAML(typ="jinja2")
# Note: allow_duplicate_keys suppresses error due to duplicate keys, but it does
# not preserve them. It only keeps the first instance of the field. This is a
# problem whenever we use jinja2 preprocessing selectors to provide more than
# one instance of field.
yaml.allow_duplicate_keys = True
yaml.indent(sequence=4, offset=2)
yaml.preserve_quotes = True
with open(recipe) as f:
    data = yaml.load(f)

updated = data

# Erase global jinja variables that aren't needed for the nightly build
updated.yaml_set_start_comment("# nightly build")

# Update version
updated["package"]["version"] = "%s.%s" % (version, date)

# Convert source from PyPI tarball to Git repo
del updated["source"]["fn"]
del updated["source"]["url"]
del updated["source"]["sha256"]
updated["source"]["git_url"] = "https://github.com/TileDB-Inc/TileDB-Py.git"
updated["source"]["git_rev"] = commit
updated["source"]["git_depth"] = -1

# Ensure build number is 0
updated["build"]["number"] = 0

# Pin tiledb by the date
for i in range(len(updated["requirements"]["host"])):
    if updated["requirements"]["host"][i].startswith("tiledb"):
        updated["requirements"]["host"][i] = "tiledb *.%s" % (date)

with open(recipe, "w") as f:
    yaml.dump(updated, f)

# Run with deprecation warnings on Mondays for forward-looking alerts.
remove_deprecations_value = "ON" if datetime.today().weekday() == 0 else "OFF"

# Create OS-specific build scripts
with open("tiledb-py-feedstock/recipe/build.sh", "w") as f:
    f.write(
        f"TILEDB_PATH=${{PREFIX}} "
        "${PYTHON} -m pip install "
        f"-Cskbuild.cmake.define.TILEDB_REMOVE_DEPRECATIONS={remove_deprecations_value} "
        "--no-build-isolation --no-deps --ignore-installed -v ."
    )

with open("tiledb-py-feedstock/recipe/bld.bat", "w") as f:
    f.write(
        f'set "TILEDB_PATH=%LIBRARY_PREFIX%" '
        "&& %PYTHON% -m pip install "
        f"-Cskbuild.cmake.define.TILEDB_REMOVE_DEPRECATIONS={remove_deprecations_value} "
        "--no-build-isolation --no-deps --ignore-installed -v ."
    )

# Update conda build config ---------------------------------------------------

with open(conda_build_config) as f:
    config = yaml.load(f)

# Limit CI and storage requirements by only building the oldest and newest
# Python versions supported by conda-forge. Will need to be occasionally updated
# as old Python versions are dropped and new ones are added
#
# https://github.com/conda-forge/conda-forge-pinning-feedstock/blob/main/recipe/conda_build_config.yaml

config["python"] = ["3.9.* *_cpython", "3.12.* *_cpython"]
config["python_impl"] = ["cpython", "cpython"]
config["numpy"] = ["2.0", "2.0"]

with open(conda_build_config, "w") as f:
    yaml.dump(config, f)

# Have to remove numpy2 migration file to rerender with subset of Python
# variants
numpy2_migration = "tiledb-py-feedstock/.ci_support/migrations/numpy2.yaml"
if os.path.isfile(numpy2_migration):
    os.remove(numpy2_migration)
