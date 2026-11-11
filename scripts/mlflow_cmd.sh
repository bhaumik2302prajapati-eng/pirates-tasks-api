#!/usr/bin/env bash
# Opens a temporary port-forward to MLflow, runs scripts/mlops.py, closes it.
set -euo pipefail
kubectl -n pirates-mlops port-forward svc/pirates-mlflow 5001:5000 >/dev/null 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null || true' EXIT
for i in $(seq 1 20); do curl -sf localhost:5001/health >/dev/null && break; sleep 2; done
export MLFLOW_TRACKING_URI=http://127.0.0.1:5001
python scripts/mlops.py "$@"
