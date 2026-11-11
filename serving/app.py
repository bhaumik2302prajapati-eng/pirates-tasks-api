import json
import logging
import os
import sys
import threading
import time
from contextlib import asynccontextmanager

import mlflow
import mlflow.sklearn
from fastapi import FastAPI, HTTPException, Response
from mlflow import MlflowClient
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest
from pydantic import BaseModel

MODEL_NAME = os.environ.get("MODEL_NAME", "task-priority-classifier")
MODEL_ALIAS = os.environ.get("MODEL_ALIAS", "production")
POLL_SECONDS = int(os.environ.get("POLL_SECONDS", "60"))

# (model, version) is swapped as one tuple, so readers never see a mix of the two
state = {"model": None, "version": "none"}


class JsonFormatter(logging.Formatter):
    def format(self, record):
        entry = {
            "ts": self.formatTime(record, "%Y-%m-%dT%H:%M:%S"),
            "level": record.levelname,
            "msg": record.getMessage(),
            "model_version": state["version"],
            "model_alias": MODEL_ALIAS,
        }
        extra = getattr(record, "extra_fields", None)
        if extra:
            entry.update(extra)
        return json.dumps(entry)


handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
log = logging.getLogger("pirates-model-api")
log.setLevel(logging.INFO)
log.addHandler(handler)
log.propagate = False

REQUESTS = Counter("pirates_prediction_requests_total", "Prediction requests", ["status", "model_version"])
LATENCY = Histogram(
    "pirates_prediction_latency_seconds", "Prediction latency", ["model_version"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5),
)
PREDICTED = Counter("pirates_predicted_class_total", "Predicted classes (drift signal)", ["priority"])
TEXT_LEN = Histogram("pirates_input_text_length", "Input text length in characters",
                     buckets=(10, 25, 50, 100, 200, 500, 1000))
MODEL_INFO = Gauge("pirates_model_info", "Model version currently served", ["model_version"])


def load_alias():
    """Load the model behind the alias if it changed. Returns True if a load happened."""
    client = MlflowClient()
    mv = client.get_model_version_by_alias(MODEL_NAME, MODEL_ALIAS)
    if mv.version == state["version"]:
        return False
    model = mlflow.sklearn.load_model(f"models:/{MODEL_NAME}/{mv.version}")
    old = state["version"]
    state["model"], state["version"] = model, mv.version
    MODEL_INFO.clear()
    MODEL_INFO.labels(model_version=mv.version).set(1)
    log.info(f"model loaded (was {old})")
    return True


def poller():
    while True:
        try:
            load_alias()
        except Exception as exc:  # keep serving the old model if the registry is unreachable
            log.error(f"model refresh failed: {exc}")
        time.sleep(POLL_SECONDS)


@asynccontextmanager
async def lifespan(app):
    threading.Thread(target=poller, daemon=True).start()
    yield


app = FastAPI(title="pirates-model-api", lifespan=lifespan)


class Task(BaseModel):
    title: str
    description: str = ""


@app.post("/predict")
def predict(task: Task):
    model, version = state["model"], state["version"]
    if model is None:
        raise HTTPException(status_code=503, detail="model not loaded")
    text = f"{task.title} {task.description}"
    start = time.perf_counter()
    try:
        priority = str(model.predict([text])[0])
    except Exception as exc:
        REQUESTS.labels(status="error", model_version=version).inc()
        log.error(f"prediction failed: {exc}")
        raise HTTPException(status_code=500, detail="prediction failed")
    LATENCY.labels(model_version=version).observe(time.perf_counter() - start)
    REQUESTS.labels(status="success", model_version=version).inc()
    PREDICTED.labels(priority=priority).inc()
    TEXT_LEN.observe(len(text))
    log.info("prediction served", extra={"extra_fields": {"priority": priority}})
    return {"priority": priority, "model_version": version}


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    if state["model"] is None:
        raise HTTPException(status_code=503, detail="model not loaded")
    return {"status": "ready", "model_version": state["version"]}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
