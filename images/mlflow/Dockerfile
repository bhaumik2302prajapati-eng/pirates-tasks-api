FROM python:3.12-slim
RUN pip install --no-cache-dir mlflow==2.22.5 "sqlalchemy==2.0.30" psycopg2-binary azure-storage-blob azure-identity
RUN useradd -m -u 10001 mlflow
USER 10001
WORKDIR /home/mlflow
EXPOSE 5000
