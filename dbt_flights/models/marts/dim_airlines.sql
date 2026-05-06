{{ config(
    materialized='incremental',
    unique_key='airline_bk',
    file_format='delta' 
) }}


WITH airlines AS (
    SELECT * FROM {{ source('silver', 'dim_airlines') }}

    {% if is_incremental() %}
        WHERE _inserted_at > (SELECT MAX(_inserted_at) FROM {{ this }})
    {% endif %}
)

SELECT * FROM airlines