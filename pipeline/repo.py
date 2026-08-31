import os
import boto3
import dagster as dg

@dg.asset
def start_dummy_process():
    return {"status": "ok", "value": 100}

@dg.asset
def transform_dummy_data(start_dummy_process: dict):
    return start_dummy_process["value"] * 2

@dg.asset
def simulate_sns_alert(transform_dummy_data: int):
    raise Exception(f"Intentional failure to test SNS! Last value was: {transform_dummy_data}")

dummy_job = dg.define_asset_job(name="dummy_sns_pipeline", selection="*")

@dg.run_failure_sensor
def sns_email_alert_sensor(context: dg.RunFailureSensorContext):
    sns_client = boto3.client('sns', region_name=os.getenv('AWS_REGION', 'us-east-1'))
    topic_arn = os.getenv('SNS_ALERTS_TOPIC_ARN')

    message = (
        f"CRITICAL ALERT: Dagster Pipeline Failure\n\n"
        f"Job: {context.dagster_run.job_name}\n"
        f"Run ID: {context.dagster_run.run_id}\n"
        f"Technical Error: {context.failure_event.message}"
    )

    sns_client.publish(
        TopicArn=topic_arn,
        Subject="[Dagster] Pipeline Failure Alert",
        Message=message
    )

defs = dg.Definitions(
    assets=[start_dummy_process, transform_dummy_data, simulate_sns_alert],
    jobs=[dummy_job],
    sensors=[sns_email_alert_sensor]
)
