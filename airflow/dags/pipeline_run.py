import sys, os
import logging
import contextlib
from airflow.providers.standard.operators.trigger_dagrun import TriggerDagRunOperator

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

DOCKER_ROOT = "/app"
if os.path.exists(DOCKER_ROOT) and DOCKER_ROOT not in sys.path:
    sys.path.insert(0, DOCKER_ROOT)

from datetime import datetime, timedelta, timezone

from airflow.sdk import dag, task

from crawler.run_crawl_pipeline import run_crawl_pipeline

from main import run_full_pipeline

# 
# from process.bronze_pipeline import run_bronze_pipeline
# from process.silver_pipeline import run_silver_pipeline, run_ourairports_pipeline

# from load.publish_pipeline import run_publish_pipeline


def run_pipeline_airflow(**context):
    conf = context["dag_run"].conf
    logging.info(f"Received DAG run conf: {conf}")

    ingestion_hours = conf.get("ingestion_hours", None)

    if ingestion_hours == "all":
        ingestion_hours = None  # interpret "all" as full load
        logging.info("Ingestion hours set to 'all': running full load.")
    elif ingestion_hours is None:
        # Scheduled run: calculate ingestion_hours based on execution time
        exec_time = context["logical_date"] - timedelta(hours=2)
        ingestion_hours = [exec_time.strftime("%Y-%m-%d-%H")]
        logging.info(f"Running scheduled run at: {ingestion_hours}")
    else:
        # Manual run with specific ingestion_hours list
        logging.info(f"Manual run with provided ingestion_hours: {ingestion_hours}")
    
    run_full_pipeline(
        ingestion_hours = ingestion_hours,
        process_detailed_dims = conf.get("process_detailed_dims", False),
        skip_crawl = conf.get("skip_crawl", False),
        run_aerodatabox = conf.get("run_aerodatabox", True),
        run_ourairports = conf.get("run_ourairports", False),
    )

@dag(
    schedule="0 2,14 * * *", 
    start_date=datetime(2025, 11, 25, 2, tzinfo=timezone.utc),
    is_paused_upon_creation=True,
    catchup=False,
    tags=["example"],
)
def pipeline_run():
    trigger_dbt = TriggerDagRunOperator(
        task_id="trigger_dbt_transform",
        trigger_dag_id="dbt_transform",
        wait_for_completion=False,   # Set True if you want A to wait for B
        conf={"run_staging": True},
    )

    @task()
    def run(**context):     
        logging.info("Task started")

        # redirect spark stderr to stdout
        with contextlib.redirect_stderr(sys.stdout):
            run_pipeline_airflow(**context)

        logging.info("Task finished")

    pipeline = run()
    pipeline >> trigger_dbt

pipeline_run()