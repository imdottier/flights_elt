# Flights Data ELT Pipeline & Lakehouse

This project ingests flights and airport data from **Aerodatabox API** and **OurAirports CSV**, processes it into a Delta Lakehouse. The final transformations are done with **dbt-spark** to produce aggregated **Gold tables** for analysis. The entire workflow is automated with **Airflow** and containerized via **Docker**.

---

## Core Idea & Architecture

The main goal is to build a reliable, automated data platform that transforms sources into clean, standardized, and aggregated datasets, ready for analysis.

### Layers

1. **Bronze Layer:**  
   - Aerodatabox mini-batch API data is ingested into raw Delta tables.  
   - Basic schema applied to raw JSON.  

2. **Silver Layer:**  
   - Merge all sources into a single source of truth (SSOT).  
   - OurAirports CSV is loaded here and merged with Aerodatabox data.  
   - Cleans, flattens, standardizes, and creates atomic Delta tables.    

3. **Gold Layer:**  
   - dbt-spark transforms silver tables into final analytical tables.  
   - Aggregations, derived metrics, and business-ready views are created.  

---

## Key Technologies

* **Apache Spark & Delta Lake:** For batch processing and reliable Delta Lakehouse storage.  
* **PostgreSQL:** For Hive metastore and Airflow.  
* **dbt-spark:** For transforming silver tables into final Gold tables.  
* **Airflow:** Orchestration of the full ELT pipeline.  
* **MinIO:** Object storage for Lakehouse storage.
* **Hive Metastore:** Stores metadata for lakehouse.
* **Docker & Docker Compose:** Containerization of all services (Spark, Postgres, Airflow).  
* **Python:** For ELT logic, API crawling, and utility scripts. 
* **Trino:** Query engine for Lakehouse tables. 

---

## Setup & Instructions

### 1. Prerequisites

Before you begin, ensure you have the following installed on your system:

* **Docker & Docker Compose** – For containerizing Spark, Postgres, and Airflow.  
* **Python 3.10+** – For ELT scripts and utilities.  

---

### 2. Initial Setup

Follow these steps to configure the project on your local machine.

1. **Clone the Repository**

```bash
git clone github.com/dottier/flights_elt
cd flights-data
```

2. **Configure Environment Variables**

Copy the template file to create your local configuration, then edit paths and credentials as needed.

```bash
cp .env.example .env
vi .env
```

3. **Download OurAirports Data**

You need the CSV files from OurAirports. Download them from:

[https://github.com/davidmegginson/ourairports-data](https://github.com/davidmegginson/ourairports-data)

Copy the following files into the project `local_data/csv/` folder:

* `airports.csv`
* `countries.csv`
* `regions.csv`
* `runways.csv`

> This is a one-time download.

4. **Start Services**

Launch all necessary containers from the project root:

```bash
docker-compose up -d
```

5. **Run the Pipeline via Airflow**

Airflow orchestrates the full workflow. Access the Airflow UI to trigger DAGs or monitor execution:

```
http://localhost:8081
```

From the UI, run pipeline_run with this configuration JSON:
```json
{
   "process_detailed_dims": true,
   "skip_crawl": true,
   "run_aerodatabox": true,
   "run_ourairports": true
}
```

Subsequent runs will be automated by Airflow