#!/usr/bin/env bash
set -euo pipefail

find modules live \
  -type f \
  -name '*.tf' \
  -not -path '*/.terraform/*' \
  -print0 \
  | xargs -0 -n1 dirname \
  | sort -u
