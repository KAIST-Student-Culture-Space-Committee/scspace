#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

MAX_CLOCK_OFFSET_SECONDS="${MAX_CLOCK_OFFSET_SECONDS:-1}"

NUMBER_PATTERN='^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$'

if ! [[ "$MAX_CLOCK_OFFSET_SECONDS" =~ $NUMBER_PATTERN ]]; then
  echo "[time-check] MAX_CLOCK_OFFSET_SECONDS must be a non-negative number" >&2
  exit 1
fi

if ! awk -v limit="$MAX_CLOCK_OFFSET_SECONDS" 'BEGIN { exit !(limit >= 0) }'; then
  echo "[time-check] MAX_CLOCK_OFFSET_SECONDS must be a non-negative number" >&2
  exit 1
fi

if ! command -v timedatectl >/dev/null 2>&1; then
  echo "[time-check] timedatectl is required on the deployment host" >&2
  exit 1
fi

NTP_SYNCHRONIZED="$(timedatectl show --property=NTPSynchronized --value)"
HOST_TIMEZONE="$(timedatectl show --property=Timezone --value)"

if [[ "$NTP_SYNCHRONIZED" != "yes" ]]; then
  echo "[time-check] host clock is not synchronized with NTP" >&2
  exit 1
fi

echo "[time-check] utc=$(date -u +'%Y-%m-%dT%H:%M:%SZ') timezone=$HOST_TIMEZONE ntp=yes"

if ! command -v chronyc >/dev/null 2>&1; then
  echo "[time-check] chronyc is required on the deployment host" >&2
  exit 1
fi

if ! CHRONY_TRACKING="$(chronyc tracking 2>/dev/null)"; then
  echo "[time-check] chrony tracking is unavailable" >&2
  exit 1
fi

SYSTEM_OFFSET_SECONDS="$(awk -F: '/^System time/ { gsub(/^[[:space:]]+/, "", $2); print $2 }' <<< "$CHRONY_TRACKING" | awk '{ print $1 }')"
LEAP_STATUS="$(awk -F: '/^Leap status/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2 }' <<< "$CHRONY_TRACKING")"

if [[ "$LEAP_STATUS" != "Normal" ]]; then
  echo "[time-check] chrony is not synchronized: ${LEAP_STATUS:-unknown}" >&2
  exit 1
fi

if ! [[ "$SYSTEM_OFFSET_SECONDS" =~ $NUMBER_PATTERN ]]; then
  echo "[time-check] could not read chrony system offset" >&2
  exit 1
fi

if ! awk -v offset="$SYSTEM_OFFSET_SECONDS" -v limit="$MAX_CLOCK_OFFSET_SECONDS" 'BEGIN {
  if (offset < 0) offset = -offset
  exit !(offset <= limit)
}'; then
  echo "[time-check] clock offset ${SYSTEM_OFFSET_SECONDS}s exceeds ${MAX_CLOCK_OFFSET_SECONDS}s" >&2
  exit 1
fi

echo "[time-check] chrony_offset=${SYSTEM_OFFSET_SECONDS}s limit=${MAX_CLOCK_OFFSET_SECONDS}s"
