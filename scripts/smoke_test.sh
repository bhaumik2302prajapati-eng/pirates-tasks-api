#!/usr/bin/env bash
# Usage: smoke_test.sh <namespace> <expected-model-version>
# Calls /predict until the API reports the expected model version.
set -uo pipefail
NS="$1"; VERSION="$2"; PORT=$((18000 + RANDOM % 1000))
kubectl -n "$NS" port-forward svc/pirates-model-api "$PORT":80 >/dev/null 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null || true' EXIT
sleep 5
for i in $(seq 1 30); do
  R=$(curl -s -m 5 -X POST "localhost:$PORT/predict" -H 'Content-Type: application/json' \
      -d '{"title":"Production server down","description":"customers cannot log in"}' || true)
  echo "attempt $i: $R"
  if echo "$R" | grep -q "\"model_version\":\"$VERSION\""; then echo "smoke test passed"; exit 0; fi
  sleep 10
done
echo "smoke test FAILED"; exit 1
