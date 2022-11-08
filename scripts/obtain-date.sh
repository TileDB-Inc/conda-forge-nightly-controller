#!/bin/bash
set -eux

echo "TZ: $TZ"
echo "date: $(date)"
echo "$(date +%Y_%m_%d)" > date.txt
cat date.txt
