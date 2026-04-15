from utils.spark_session import get_spark_session
from utils.io_utils import read_df
import pyspark.sql.functions as sf
from utils.logging_utils import setup_logging
import logging
from load.utils import read_fact_data_for_overwrite

from datetime import datetime

dt_str = "2025-11-22 15:40:57.022736"
dt_obj = datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S.%f")

if __name__ == "__main__":
    setup_logging(log_to_file=False)

    spark = get_spark_session("Process Silver Pipeline Test")
    from delta.tables import DeltaTable

    flights = DeltaTable.forName(spark, "silver.fct_flights")
    flights.history().show(10, truncate=False)
    
    spark.stop()