FROM python:3.12-slim
RUN pip install --no-cache-dir mlflow==2.22.5 "sqlalchemy==2.0.30" \
    pandas scikit-learn psycopg2-binary
RUN useradd -m -u 10001 trainer
WORKDIR /app
COPY --chown=10001 . /app
USER 10001
