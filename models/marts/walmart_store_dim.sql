{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['store_id', 'dept_id'],
        merge_update_columns=['store_type', 'store_size', 'update_date']
    )
}}

select
    store_id,
    dept_id,
    max(store_type)     as store_type,
    max(store_size)     as store_size,
    current_timestamp() as insert_date,
    current_timestamp() as update_date
from {{ ref('stg_walmart') }}
group by store_id, dept_id