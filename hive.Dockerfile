FROM apache/hive:4.0.0

USER root

RUN apt-get update && \
    apt-get install -y wget && \
    rm -rf /var/lib/apt/lists/*

RUN rm -f /opt/hive/lib/guava-*.jar && \
    cp /opt/hadoop/share/hadoop/common/lib/guava-*.jar /opt/hive/lib/

RUN rm -f /opt/hive/lib/hadoop-aws-*.jar /opt/hive/lib/aws-java-sdk-bundle-*.jar

# 1. Postgres Driver
RUN wget -O /opt/hive/lib/postgresql-42.7.3.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.3/postgresql-42.7.3.jar

# 2. Hadoop AWS 
RUN wget -O /opt/hive/lib/hadoop-aws-3.3.6.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar

# 3. AWS SDK V1 
RUN wget -O /opt/hive/lib/aws-java-sdk-bundle-1.12.367.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.367/aws-java-sdk-bundle-1.12.367.jar

RUN cp /opt/hive/lib/hadoop-aws-3.3.6.jar /opt/hadoop/share/hadoop/common/lib/ && \
    cp /opt/hive/lib/aws-java-sdk-bundle-1.12.367.jar /opt/hadoop/share/hadoop/common/lib/ && \
    chown -R hive:hive /opt/hadoop/share/hadoop/common/lib/

# Return permissions to the hive user for security
RUN chown -R hive:hive /opt/hive/lib/

USER hive

# FROM apache/hive:3.1.3

# USER root

# # 1. Install wget and clean up apt cache to keep image small
# RUN apt-get update && \
#     apt-get install -y wget && \
#     rm -rf /var/lib/apt/lists/*

# # 2. THE FIX: Create the missing beeline directory to stop the crash loop
# RUN mkdir -p /home/hive/.beeline && chown -R hive:hive /home/hive

# # 1. The Lifesaver: Fix the notorious Hive 3.1.3 Guava version mismatch
# RUN rm -f /opt/hive/lib/guava-*.jar && \
#     cp /opt/hadoop/share/hadoop/common/lib/guava-*.jar /opt/hive/lib/

# # 2. Modern Postgres Driver (Fixes Postgres 15 SCRAM crash)
# RUN wget -O /opt/hive/lib/postgresql-42.7.3.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.3/postgresql-42.7.3.jar

# # 3. Hadoop AWS (Matches Hive 3.1.3's native Hadoop 3.1.0)
# RUN rm -f /opt/hive/lib/hadoop-aws-*.jar && \
#     wget -O /opt/hive/lib/hadoop-aws-3.1.0.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.1.0/hadoop-aws-3.1.0.jar

# # 4. AWS SDK V1 Bundle (Required for Hadoop 3.1.0)
# RUN rm -f /opt/hive/lib/aws-java-sdk-bundle-*.jar && \
#     wget -O /opt/hive/lib/aws-java-sdk-bundle-1.11.271.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.271/aws-java-sdk-bundle-1.11.271.jar

# RUN cp /opt/hive/lib/hadoop-aws-3.1.0.jar /opt/hadoop/share/hadoop/common/lib/ && \
#     cp /opt/hive/lib/aws-java-sdk-bundle-1.11.271.jar /opt/hadoop/share/hadoop/common/lib/ && \
#     chown -R hive:hive /opt/hadoop/share/hadoop/common/lib/

# RUN chown -R hive:hive /opt/hive/lib/

# USER hive