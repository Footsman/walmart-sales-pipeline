{{ config(materialized='view')}}

with department as (
    select 
        TRY_TO_NUMBER(STORE)                AS store_id,
        TRY_TO_NUMBER(DEPT)                 AS dept_id, 
        TRY_TO_DATE(DATE)                 AS store_date, 
        TRY_TO_DECIMAL(WEEKLY_SALES,18,2)   AS store_weekly_sales,
        ISHOLIDAY                           AS ISHOLIDAY
    from {{source('raw', 'department')}}
),
features as (
    select
        TRY_TO_NUMBER(STORE)                AS store_id,
        TRY_TO_DATE(DATE)                 AS store_date,
        TRY_TO_DECIMAL(TEMPERATURE,10,2)    AS temperature,
        TRY_TO_DECIMAL(FUEL_PRICE,10,3)     AS fuel_price,
        TRY_TO_DECIMAL(MARKDOWN1,18,2)      AS markdown1,
        TRY_TO_DECIMAL(MARKDOWN2,18,2)      AS markdown2,
        TRY_TO_DECIMAL(MARKDOWN3,18,2)      AS markdown3,
        TRY_TO_DECIMAL(MARKDOWN4,18,2)      AS markdown4,
        TRY_TO_DECIMAL(MARKDOWN5,18,2)      AS markdown5,
        TRY_TO_DECIMAL(CPI, 18, 6)          AS cpi,
        TRY_TO_DECIMAL(UNEMPLOYMENT,10,3)   AS unemployment
    from {{source('raw', 'features')}}
),
stores as (
    select
        TRY_TO_NUMBER(STORE)                AS store_id,
        TYPE                                AS store_type,
        TRY_TO_NUMBER(SIZE)                 AS store_size 
    from {{source('raw', 'stores')}}
)

select
    d.store_id,
    d.dept_id,
    cast(to_char(d.store_date, 'YYYYMMDD') as integer) as date_id,
    d.store_date,
    d.isholiday,
    s.store_type,
    s.store_size,
    d.store_weekly_sales,
    f.fuel_price,
    f.temperature,
    f.unemployment,
    f.cpi,
    f.markdown1,
    f.markdown2,
    f.markdown3,
    f.markdown4,
    f.markdown5
from department d
left join features f
    on  d.store_id   = f.store_id
    and d.store_date = f.store_date
left join stores s
    on  d.store_id = s.store_id