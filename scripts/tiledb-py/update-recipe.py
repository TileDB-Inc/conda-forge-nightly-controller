# Update the conda recipe for the nightly build
#
# Parses recipe with ruamel.yaml
#
# Reads values for version, date, and commit from plain-text files

recipe = "tiledb-py-feedstock/recipe/meta.yaml"

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

# Remove `script` field in meta.yaml. It is duplicated for "not win" and "win",
# and the latter gets deleted during the round-trip of importing and exporting
# the YAML. For now write to build scripts below
del updated["build"]["script"]

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
        f"set \"TILEDB_PATH=%LIBRARY_PREFIX%\" "
        "&& %PYTHON% -m pip install "
        f"-Cskbuild.cmake.define.TILEDB_REMOVE_DEPRECATIONS={remove_deprecations_value} "
        "--no-build-isolation --no-deps --ignore-installed -v ."
    )
