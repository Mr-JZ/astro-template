#!/usr/bin/env bash
# Usage: scripts/check-site-image.sh <image>
# Starts the production image and checks the nginx behavior visitors and search engines rely on.
set -euo pipefail

image="${1:?Usage: check-site-image.sh <image>}"
engine="$(command -v docker || command -v podman)"
port=18080
name="site-check-$$"

"$engine" run -d --rm --name "$name" -p "$port:8080" "$image" >/dev/null
trap '"$engine" rm -f "$name" >/dev/null 2>&1' EXIT
sleep 2

base="http://127.0.0.1:$port"
failures=0

expect() { # description expected actual
	if [ "$2" = "$3" ]; then
		echo "ok   $1"
	else
		echo "FAIL $1: expected '$2', got '$3'"
		failures=$((failures + 1))
	fi
}

header() { # header-name curl-args...
	local name="$1"
	shift
	curl -s -o /dev/null -D - "$@" | tr -d '\r' | awk -v h="$name" 'tolower($1) == tolower(h) ":" { $1 = ""; sub(/^ /, ""); print }'
}

status() { curl -s -o /dev/null -w '%{http_code}' "$@"; }

expect "home page loads" 200 "$(status "$base/")"
expect "home page is gzipped" gzip "$(header Content-Encoding -H 'Accept-Encoding: gzip' "$base/")"
expect "pages revalidate on every visit" "public, max-age=0, must-revalidate" "$(header Cache-Control "$base/")"
expect "explicit index.html redirects" "/?x=1" "$(header Location "$base/index.html?x=1")"
expect "missing page is a 404" 404 "$(status "$base/does-not-exist/")"
expect "sitemap is served" 200 "$(status "$base/sitemap-index.xml")"
expect "server version is hidden" nginx "$(header Server "$base/")"

asset="$(curl -s "$base/" | grep -oE '/_astro/[^"]+\.(css|js)' | head -1)"
expect "fingerprinted assets are cached for a year" "public, max-age=31536000, immutable" \
	"$(header Cache-Control "$base$asset")"

[ "$failures" -eq 0 ] && echo "All checks passed." || { echo "$failures check(s) failed."; exit 1; }
