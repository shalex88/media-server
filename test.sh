#!/bin/bash

set -euo pipefail

API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:9997}"
PATH_NAME="${1:-camera0}"
ENDPOINT="${API_BASE_URL%/}/v3/paths/get/${PATH_NAME}"

if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required" >&2
    exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required" >&2
    exit 2
fi

tmp_body="$(mktemp)"
trap 'rm -f "$tmp_body"' EXIT

http_code="$(curl --silent --show-error --output "$tmp_body" --write-out '%{http_code}' "$ENDPOINT" || true)"

case "$http_code" in
    200)
        python3 - "$PATH_NAME" "$tmp_body" <<'PY'
import json
import sys

path_name = sys.argv[1]
body_path = sys.argv[2]

with open(body_path, "r", encoding="utf-8") as handle:
    payload = json.load(handle)

available = bool(payload.get("available", False))
online = bool(payload.get("online", False))
source = payload.get("source") or {}
tracks = payload.get("tracks2") or []

if online:
    status = "online"
    exit_code = 0
elif available:
    status = "available"
    exit_code = 1
else:
    status = "offline"
    exit_code = 2

source_type = source.get("type", "unknown")
track_list = ", ".join(track.get("codec", "unknown") for track in tracks) or "none"

print(f"path={path_name} status={status} available={str(available).lower()} online={str(online).lower()} source={source_type} tracks={track_list}")
sys.exit(exit_code)
PY
        ;;
    404)
        echo "path=${PATH_NAME} status=missing" >&2
        exit 3
        ;;
    000)
        echo "MediaMTX API is unreachable at ${API_BASE_URL}. Confirm that api: true is set in mediamtx.yml." >&2
        exit 4
        ;;
    *)
        echo "MediaMTX API request failed with HTTP ${http_code}" >&2
        cat "$tmp_body" >&2
        exit 5
        ;;
esac