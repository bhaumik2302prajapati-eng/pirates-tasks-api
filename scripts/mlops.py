#!/usr/bin/env python3
"""Small helper for the Pirates pipeline: talks to the MLflow model registry."""
import argparse
import os
import sys

from mlflow import MlflowClient

MODEL = os.environ.get("MODEL_NAME", "task-priority-classifier")


def emit(key, value):
    print(f"{key}={value}")
    out = os.environ.get("GITHUB_OUTPUT")
    if out:
        with open(out, "a") as f:
            f.write(f"{key}={value}\n")


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("latest", help="print the newest model version")
    g = sub.add_parser("gate", help="fail if the model metric is below a threshold")
    g.add_argument("--version", required=True)
    g.add_argument("--metric", default="f1_macro")
    g.add_argument("--min", type=float, default=0.7)
    s = sub.add_parser("set-alias", help="point an alias at a model version")
    s.add_argument("--alias", required=True)
    s.add_argument("--version", required=True)
    a = p.parse_args()

    c = MlflowClient()
    if a.cmd == "latest":
        versions = c.search_model_versions(f"name='{MODEL}'")
        emit("version", max(int(v.version) for v in versions))
    elif a.cmd == "gate":
        mv = c.get_model_version(MODEL, a.version)
        metrics = c.get_run(mv.run_id).data.metrics
        value = metrics.get(a.metric)
        if value is None:
            print(f"metric '{a.metric}' not found. Available: {sorted(metrics)}")
            sys.exit(1)
        print(f"version {a.version}: {a.metric}={value} (minimum {a.min})")
        if value < a.min:
            print("QUALITY GATE FAILED")
            sys.exit(1)
        print("quality gate passed")
    elif a.cmd == "set-alias":
        c.set_registered_model_alias(MODEL, a.alias, a.version)
        print(f"alias '{a.alias}' -> version {a.version}")


if __name__ == "__main__":
    main()
