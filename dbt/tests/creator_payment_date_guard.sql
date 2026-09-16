with check_dates as (
  select min(post_date) as min_date,
         max(post_date) as max_date,
         countif(extract(year from post_date) != 2026) as non_2026_rows
  from {{ ref('fact_creator_payment') }}
)
select * from check_dates
where min_date != date '2026-01-23'
   or max_date != date '2026-06-27'
   or non_2026_rows != 0
