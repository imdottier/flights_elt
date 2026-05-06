FROM apache/spark:4.0.2

USER root

RUN apt-get update && apt-get install -y wget zip && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN --mount=type=cache,id=pip_cache_root,target=/root/.cache/pip \
    python3 -m pip install -r /app/requirements.txt
    
RUN wget -O /opt/spark/jars/hadoop-aws-3.4.1.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.4.1/hadoop-aws-3.4.1.jar && \
    wget -O /opt/spark/jars/bundle-2.24.6.jar https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/2.24.6/bundle-2.24.6.jar && \
    # Ensure Spark's netty jars win; AWS bundle may embed conflicting netty classes.
    zip -q -d /opt/spark/jars/bundle-2.24.6.jar 'io/netty/*' || true && \
    wget -O /opt/spark/jars/delta-spark_2.13-4.0.1.jar https://repo1.maven.org/maven2/io/delta/delta-spark_2.13/4.0.1/delta-spark_2.13-4.0.1.jar && \
    wget -O /opt/spark/jars/delta-storage-4.0.1.jar https://repo1.maven.org/maven2/io/delta/delta-storage/4.0.1/delta-storage-4.0.1.jar

RUN chown -R spark:spark /opt/spark/jars/

USER spark