"""
This script creates Prefect secrets for database credentials.
These credentials will be used by the Prefect flow to connect to the database.
"""

import os

from prefect.blocks.system import Secret

print("Attempting to create Prefect secrets...")
Secret(value=os.environ["DB_USERNAME"]).save("db-username", overwrite=True)
Secret(value=os.environ["DB_PASSWORD"]).save("db-password", overwrite=True)
Secret(value=os.environ["DB_ENDPOINT"]).save("db-endpoint", overwrite=True)
Secret(value=os.environ["AWS_REGION"]).save("aws-region", overwrite=True)
Secret(value=os.environ["MLFLOW_TRACKING_URI"]).save(
    "mlflow-tracking-uri", overwrite=True
)
Secret(value=os.environ["EVIDENTLY_UI_URL"]).save("evidently-url", overwrite=True)
Secret(value=os.environ["GRAFANA_ADMIN_USER"]).save(
    "grafana-admin-user", overwrite=True
)
Secret(value=os.environ["CHURN_MODEL_ALERTS_TOPIC_ARN"]).save(
    "churn-model-alerts-topic-arn", overwrite=True
)
print("✅ Prefect secrets successfully stored.")
