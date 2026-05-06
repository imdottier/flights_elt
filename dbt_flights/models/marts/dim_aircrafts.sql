{{ config(
    materialized='incremental',
    unique_key='aircraft_bk',
    file_format='delta' 
) }}

WITH aircrafts AS (
    SELECT * FROM {{ source('silver', 'dim_aircrafts') }}

    {% if is_incremental() %}
        WHERE _inserted_at > (SELECT MAX(_inserted_at) FROM {{ this }})
    {% endif %}
)

SELECT * FROM aircrafts