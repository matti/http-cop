#!/usr/bin/env bash

set -Euo pipefail

# extract the protocol
proto="$(echo "$1" | grep :// | sed -e's,^\(.*://\).*,\1,g')"
# remove the protocol
url="${1/$proto/}"
# extract the user (if any)
user="$(echo "$url" | grep @ | cut -d@ -f1)"
# extract the host and port
hostport="$(echo "${url/$user@/}" | cut -d/ -f1)"
# by request host without port
host="$(echo "$hostport" | sed -e 's,:.*,,g')"
# by request - try to extract the port
port="$(echo "$hostport" | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
# extract the path (if any)
path="$(echo "$url" | grep / | cut -d/ -f2-)"

echo "url: $url"
echo "  proto: $proto"
echo "  user: $user"
echo "  host: $host"
echo "  port: $port"
echo "  path: $path"

slug="$host-${path//\//-}"
echo "slug: $slug"

timeout=${2:-15}
delay=${3:-5}

mkdir -p logs
while true; do
  >/dev/null 2>&1 rm "/tmp/http-cop.$slug.body" || true
  >/dev/null 2>&1 rm "/tmp/http-cop.$slug.headers" || true

  started_at=$SECONDS
  timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
  if >"/tmp/http-cop.$slug.headers" 2>&1 curl -o "/tmp/http-cop.$slug.body" --verbose --max-time "$timeout" -Lsf "$url"; then
    took=$((SECONDS - started_at))
    if [[ "$took" -gt 5 ]]; then
      echo "$timestamp; ok; $took"
    fi
  else
    took=$((SECONDS - started_at))
    echo "$timestamp; fail; $took"
    cp "/tmp/http-cop.$slug.body" "logs/$slug.$timestamp.body"
    cp "/tmp/http-cop.$slug.headers" "logs/$slug.$timestamp.headers"
  fi

  took=$((SECONDS - started_at))
  remaining=$((delay - took))
  if [[ "$remaining" -lt 1 ]]; then
    sleep 1
  else
    sleep "$remaining"
  fi
done
