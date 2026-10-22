{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='fact_sk',
        on_schema_change='fail'
    )
}}

with src as (
    select
        store_id,
        dept_id,
        date_id,
        store_size,
        store_weekly_sales,
        fuel_price,
        temperature,
        unemployment,
        cpi,
        markdown1, markdown2, markdown3, markdown4, markdown5,
        md5(concat_ws('|',
            coalesce(cast(store_size         as varchar), '~'),
            coalesce(cast(store_weekly_sales as varchar), '~'),
            coalesce(cast(fuel_price         as varchar), '~'),
            coalesce(cast(temperature        as varchar), '~'),
            coalesce(cast(unemployment       as varchar), '~'),
            coalesce(cast(cpi                as varchar), '~'),
            coalesce(cast(markdown1          as varchar), '~'),
            coalesce(cast(markdown2          as varchar), '~'),
            coalesce(cast(markdown3          as varchar), '~'),
            coalesce(cast(markdown4          as varchar), '~'),
            coalesce(cast(markdown5          as varchar), '~')
        )) as hash_diff
    from {{ ref('stg_walmart') }}
)


{% if is_incremental() %}

, open_versions as (
    select * from {{ this }} where is_current
),

closed as (
    select
        o.fact_sk,
        o.store_id, o.dept_id, o.date_id,
        o.store_size, o.store_weekly_sales, o.fuel_price, o.temperature,
        o.unemployment, o.cpi,
        o.markdown1, o.markdown2, o.markdown3, o.markdown4, o.markdown5,
        o.hash_diff,
        o.vrsn_start_date,
        current_timestamp()  as vrsn_end_date,
        false                as is_current,
        o.insert_date,
        current_timestamp()  as update_date
    from open_versions o
    join src s
      on  o.store_id = s.store_id
      and o.dept_id  = s.dept_id
      and o.date_id  = s.date_id
    where o.hash_diff <> s.hash_diff
),

new_versions as (
    select
        md5(concat_ws('|',
            cast(s.store_id as varchar),
            cast(s.dept_id  as varchar),
            cast(s.date_id  as varchar),
            cast(current_timestamp() as varchar)
        ))                                   as fact_sk,
        s.store_id, s.dept_id, s.date_id,
        s.store_size, s.store_weekly_sales, s.fuel_price, s.temperature,
        s.unemployment, s.cpi,
        s.markdown1, s.markdown2, s.markdown3, s.markdown4, s.markdown5,
        s.hash_diff,
        current_timestamp()                  as vrsn_start_date,
        to_timestamp_ltz('9999-12-31 00:00:00')   as vrsn_end_date,
        true                                 as is_current,
        current_timestamp()                  as insert_date,
        current_timestamp()                  as update_date
    from src s
    left join open_versions o
      on  o.store_id = s.store_id
      and o.dept_id  = s.dept_id
      and o.date_id  = s.date_id
    where o.fact_sk is null
       or o.hash_diff <> s.hash_diff
)

select * from closed
union all
select * from new_versions

{% else %}
    select
    md5(concat_ws('|',
        cast(store_id as varchar),
        cast(dept_id  as varchar),
        cast(date_id  as varchar),
        cast(current_timestamp() as varchar)
    ))                                    as fact_sk,
    store_id, dept_id, date_id,
    store_size, store_weekly_sales, fuel_price, temperature,
    unemployment, cpi,
    markdown1, markdown2, markdown3, markdown4, markdown5,
    hash_diff,
    current_timestamp()                   as vrsn_start_date,
    to_timestamp_ltz('9999-12-31 00:00:00')   as vrsn_end_date,
    true                                  as is_current,
    current_timestamp()                   as insert_date,
    current_timestamp()                   as update_date
    from src
{% endif %}