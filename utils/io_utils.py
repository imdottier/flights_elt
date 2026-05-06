import os
import json
from pathlib import Path
import logging
from dotenv import load_dotenv
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.functions import col, lit
from datetime import datetime
import fsspec

load_dotenv()

base = Path(os.getenv("WORKSPACE_BASE", "./"))
BRONZE_RAW_BASE = base / "bronze_raw"


def write_json_to_bronze(data: dict, full_path: str):
    """Safely writes JSON data to the bronze layer now with fsspec"""
    try:
        with fsspec.open(full_path, "w") as f:
            json.dump(data, f, ensure_ascii=False)
        logging.info(f"Successfully wrote data to {full_path}")

    except Exception as e:
        logging.error(f"Failed to write JSON to {full_path}. Error: {e}", exc_info=True)
        raise


def read_df(
    spark: SparkSession, layer: str, table_name: str,
    last_watermark: datetime = None, optional: bool = False, **kwargs
) -> DataFrame:
    full_table_name = f"{layer}.{table_name}"

    try:
        df = spark.read.table(full_table_name)
        if last_watermark:
            df = df.filter(col("_inserted_at") > lit(last_watermark))
        else:
            if "where" in kwargs:
                df = df.where(kwargs["where"])
        
        logging.info(f"Successfully read {full_table_name}")
        return df
    
    except Exception as e:
        if optional:
            logging.warning(f"Optional table {full_table_name} not found or unreadable: {e}")
            return None
        else:
            logging.error(f"Error reading {full_table_name}: {e}", exc_info=True)
            raise