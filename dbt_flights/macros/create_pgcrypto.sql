{% macro create_pgcrypto() %}
    {% do run_query("CREATE EXTENSION IF NOT EXISTS pgcrypto;") %}
{% endmacro %}