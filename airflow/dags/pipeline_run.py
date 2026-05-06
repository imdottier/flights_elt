import sys, os
import logging
import contextlib
import yaml
from airflow.providers.apache.spark.operators.spark_submit import (
    SparkSubmitOperator,
)
from airflow.providers.standard.operators.trigger_dagrun import TriggerDagRunOperator

from datetime import datetime, timedelta, timezone

from airflow.sdk import dag, task
import socket

airflow_ip = socket.gethostbyname(socket.gethostname())

# def load_config() -> dict:
#     with open("/app/configs/config.yaml", "r") as f:
#         return yaml.safe_load(f)
    
# config_dict = load_config()

# from process.bronze_pipeline import run_bronze_pipeline
# from process.silver_pipeline import run_silver_pipeline, run_ourairports_pipeline

# from load.publish_pipeline import run_publish_pipeline


@dag(
    schedule="0 2,14 * * *", 
    start_date=datetime(2020, 11, 25, 2, tzinfo=timezone.utc),
    is_paused_upon_creation=True,
    catchup=False,
    tags=["example"],
    render_template_as_native_obj=True
)
def pipeline_run():
    # 1. Logic to determine arguments based on DAG context
    @task
    def get_ingestion_args(**context):
        conf = context["dag_run"].conf
        args = [
            "--raw-base-path", "s3a://data",
            "--workspace-path", "/app"
        ]
        
        # Date Logic
        ingestion_hours = conf.get("ingestion_hours")
        if not ingestion_hours:
            # Scheduled: get 2 hours ago from logical date
            exec_time = context["logical_date"] - timedelta(hours=2)
            args.extend(["--dates", exec_time.strftime("%Y-%m-%d-%H")])
        else:
            args.extend(["--dates"] + (ingestion_hours if isinstance(ingestion_hours, list) else [ingestion_hours]))

        flags = {
            "--skip-crawl": conf.get("skip_crawl", False),
            "--process-details": conf.get("process_detailed_dims", False),
            "--run-ourairports": conf.get("run_ourairports", False),
            "--run-aerodatabox": conf.get("run_aerodatabox", True) # Defaults to True
        }

        for flag, is_active in flags.items():
            if is_active:
                args.append(flag)
                
        return args
    
    spark_args = get_ingestion_args()

    spark_task = SparkSubmitOperator(
        task_id="run_pipeline",
        application="/app/main.py",
        conn_id="spark_default",
        application_args=spark_args,
        conf={
            "spark.driver.host": airflow_ip,
            "spark.driver.bindAddress": "0.0.0.0",
        }
    )

    trigger_dbt = TriggerDagRunOperator(
        task_id="trigger_dbt_transform",
        trigger_dag_id="dbt_transform",
        wait_for_completion=False,   # Set True if you want A to wait for B
        conf={
            "run_staging": True,
        },
    )

    spark_task >> trigger_dbt


pipeline_run()