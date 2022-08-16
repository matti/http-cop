#!/usr/bin/env bash

set -Euo pipefail

url=$1

mkdir -p logs
while true; do
  started_at=$SECONDS
  timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
  if >/tmp/http-cop.headers 2>&1 curl -o /tmp/http-cop.body --verbose --max-time 15 -Lsf "$url"; then
    took=$((SECONDS - started_at))
    if [[ "$took" -gt 5 ]]; then
      echo "$timestamp; ok; $took"
    fi
  else
    took=$((SECONDS - started_at))
    echo "$timestamp; fail; $took"
    cp /tmp/http-cop.body "logs/$timestamp.body"
    cp /tmp/http-cop.headers "logs/$timestamp.headers"
  fi

  sleep 5
done