set -euo pipefail

# Search for and delete old nightlies
#
# Usage:
#   export ANACONDA_TOKEN="<api-token>"
#   ACCOUNT=tiledb DAYS=7 scripts/delete-old-nightlies.sh
#
# Variables that must be defined outside of this script:
#
# ANACONDA_TOKEN: (string) API token for anaconda.org
# ACCOUNT: (string) The main account/channel on anaconda.org. The actual channel
#          to be searched will be "ACCOUNT/label/nightlies"
# DAYS: (integer) Number of days to keep nightlies (ie nightlies uploaded more
#       than $DAYS days ago will be removed)
#
# Variables that can be defined outside of this script:
#
# SUBDIR: linux-64 (default), linux-aarch64, linux-ppc64le, osx-64, osx-arm64, win-64
# DRY_RUN: (integer) Exit without actually removing packages. Default is 0. Set
#          to 1 for dry run

# optional variables
SUBDIR="${SUBDIR:-linux-64}"
DRY_RUN="${DRY_RUN:-0}"

channel="$ACCOUNT/label/nightlies"
echo "Removing $SUBDIR nightlies more than $DAYS days old from the channel $channel"

conda search -v --json --override-channels -c "$channel" --subdir "$SUBDIR" > nightlies.json

total=$(jq 'flatten | length' nightlies.json)
echo "Total nightlies: $total"

# in milliseconds since the epoch
cutoff=$(expr $(date --date="$DAYS days ago" +%s) \* 1000)

jq -r --argjson cutoff $cutoff \
  'flatten | .[] | select(.timestamp < $cutoff) | .name + "/" + .version + "/" + .subdir + "/" + .fn' \
  nightlies.json > nightlies-to-remove.txt

total_to_be_removed=$(cat nightlies-to-remove.txt | wc -l)
echo "Total to be removed: $total_to_be_removed"

if [[ "$DRY_RUN" -eq 1 ]]
then
  echo "Dry run: exit early"
  exit 0
else
  echo "Removing packages"
fi

for nightly in `cat nightlies-to-remove.txt`
do
  echo "$ACCOUNT/$nightly"
  anaconda --token "$ANACONDA_TOKEN" remove --force "$ACCOUNT/$nightly"
  sleep 0.1
done
