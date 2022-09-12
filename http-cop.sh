#!/usr/bin/env bash

set -Euo pipefail

url=$(urlparse parse "$1")
slug=$(urlparse slug "$url")

echo "url: $url"
echo "slug: $slug"

timeout=${2:-15}
delay=${3:-5}
slow=${4:-5}

echo "timeout: $timeout"
echo "delay: $delay"
echo "slow: $slow"

while true; do
  >/dev/null 2>&1 rm "/tmp/http-cop.$slug.body" || true
  >/dev/null 2>&1 rm "/tmp/http-cop.$slug.headers" || true

  started_at=$SECONDS
  timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
  if >"/tmp/http-cop.$slug.headers" 2>&1 curl -o "/tmp/http-cop.$slug.body" --verbose --max-time "$timeout" -Lsf "$url"; then
    took=$((SECONDS - started_at))
    if [[ "$took" -ge "$slow" ]]; then
      echo "$timestamp; slow; $took"
    fi
  else
    took=$((SECONDS - started_at))
    echo "$timestamp; fail; $took"
    if [ -f "/tmp/http-cop.$slug.body" ]; then
      mkdir -p logs
      cp "/tmp/http-cop.$slug.body" "logs/$slug.$timestamp.body"
    fi

    if [ -f "/tmp/http-cop.$slug.headers" ]; then
      mkdir -p logs
      cp "/tmp/http-cop.$slug.headers" "logs/$slug.$timestamp.headers"
    fi
  fi

  if [[ "$delay" == "0" ]]; then
    continue
  fi

  took=$((SECONDS - started_at))
  remaining=$((delay - took))
  if [[ "$remaining" -lt 1 ]]; then
    sleep 1
  else
    sleep "$remaining"
  fi
done
