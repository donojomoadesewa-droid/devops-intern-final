#!/bin/sh
set -euo pipefail
URL="${1:-http://localhost:8080}"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || echo "000")
if [ "$STATUS" = "200" ]; then
    echo "Health check passed: $URL returned 200"
    exit 0
else 
    echo "Health check failed: $URL returned $STATUS"
    exit 1
fi