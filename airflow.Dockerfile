FROM apache/airflow:3.1.3

USER root

# Install system deps (apt-get can be cached too!)
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y default-jdk-headless procps

# Set JAVA_HOME so PySpark can find the JVM
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV PATH="$JAVA_HOME/bin:$PATH"

# 1. Create a dedicated folder for the dbt virtual environment
RUN mkdir -p /opt/airflow/dbt_venv && chown -R airflow: /opt/airflow/dbt_venv

USER airflow

RUN python -m venv /opt/airflow/dbt_venv && \
    /opt/airflow/dbt_venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/airflow/dbt_venv/bin/pip install --no-cache-dir "dbt-core==1.10.15" "dbt-postgres==1.9.1"

# Install Python dependencies
COPY requirements.txt /app/
ARG PYTHON_VERSION=3.12
ARG AIRFLOW_VERSION=3.1.3
RUN --mount=type=cache,id=pip_cache_airflow,target=/home/airflow/.cache/pip \
    pip install -r /app/requirements.txt && \
    pip install apache-airflow-providers-fab && \
    pip install apache-airflow-providers-apache-spark
