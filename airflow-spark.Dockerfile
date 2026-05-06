FROM apache/airflow:3.1.3

USER root

# Keep apt cache and install system deps + wget/tar for Spark
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y default-jdk-headless procps wget tar zip && \
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME so PySpark can find the JVM
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV PATH="$JAVA_HOME/bin:$PATH"

# Install a lightweight Spark client (prebuilt binary)
ARG SPARK_VERSION=4.0.2
ARG SPARK_PACKAGE=spark-${SPARK_VERSION}-bin-hadoop3
RUN wget -O /tmp/${SPARK_PACKAGE}.tgz https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz && \
    mkdir -p /opt/spark && \
    tar -xzf /tmp/${SPARK_PACKAGE}.tgz -C /opt/spark --strip-components=1 && \
    rm /tmp/${SPARK_PACKAGE}.tgz && \
    # Jars for S3 and Delta Lake support
    wget -O /opt/spark/jars/hadoop-aws-3.4.1.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.4.1/hadoop-aws-3.4.1.jar && \
    wget -O /opt/spark/jars/bundle-2.24.6.jar https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/2.24.6/bundle-2.24.6.jar && \
    # Ensure Spark's netty jars win; AWS bundle may embed conflicting netty classes.
    zip -q -d /opt/spark/jars/bundle-2.24.6.jar 'io/netty/*' || true && \
    wget -O /opt/spark/jars/delta-spark_2.13-4.0.1.jar https://repo1.maven.org/maven2/io/delta/delta-spark_2.13/4.0.1/delta-spark_2.13-4.0.1.jar && \
    wget -O /opt/spark/jars/delta-storage-4.0.1.jar https://repo1.maven.org/maven2/io/delta/delta-storage/4.0.1/delta-storage-4.0.1.jar && \
    # Chown everything    
    chown -R airflow: /opt/spark

ENV SPARK_HOME=/opt/spark
ENV PATH="$SPARK_HOME/bin:$PATH"

# 1. Create a dedicated folder for the dbt virtual environment
RUN mkdir -p /opt/airflow/dbt_venv && chown -R airflow: /opt/airflow/dbt_venv

USER airflow

RUN python -m venv /opt/airflow/dbt_venv && \
    /opt/airflow/dbt_venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/airflow/dbt_venv/bin/pip install --no-cache-dir "dbt-spark["PyHive"]==1.10.1"

# Install Python dependencies
COPY requirements.txt /app/
ARG PYTHON_VERSION=3.12
ARG AIRFLOW_VERSION=3.1.3
RUN --mount=type=cache,id=pip_cache_airflow,target=/home/airflow/.cache/pip \
    pip install -r /app/requirements.txt && \
    pip install apache-airflow-providers-fab && \
    pip install apache-airflow-providers-apache-spark
