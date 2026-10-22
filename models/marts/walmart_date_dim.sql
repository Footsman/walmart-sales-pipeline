{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='date_id',
        merge_update_columns=['store_date', 'isholiday', 'update_date']
    )
}}

select
    date_id,
    store_date,
    max(isholiday)      as isholiday,
    current_timestamp() as insert_date,
    current_timestamp() as update_date
from {{ ref('stg_walmart') }}
group by date_id, store_date