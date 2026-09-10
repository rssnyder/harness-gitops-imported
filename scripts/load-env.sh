#!/usr/bin/env bash
# usage: source ./scripts/load-env.sh
#
# ./.env uses HARNESS_ACCOUNT_ID and (typo'd) HARNESS_PLAFORM_API_KEY. the
# harness terraform/opentofu provider auto-detects credentials from
# HARNESS_ACCOUNT_ID and HARNESS_PLATFORM_API_KEY (correct spelling), so this
# just sources .env and re-exports the corrected name.
set -a
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.env"
set +a

export HARNESS_PLATFORM_API_KEY="${HARNESS_PLATFORM_API_KEY:-$HARNESS_PLAFORM_API_KEY}"

if [ -z "$HARNESS_ACCOUNT_ID" ] || [ -z "$HARNESS_PLATFORM_API_KEY" ]; then
  echo "warning: HARNESS_ACCOUNT_ID or HARNESS_PLATFORM_API_KEY is empty" >&2
fi
