SELECT
  TO_HEX(SHA256(CONCAT('creator|', creator_token))) AS creator_key,
  creator_token,
  follower_count,
  engagement_rate,
  synthetic_budget,
  historical_sales_band,
  audience_gender_segment,
  audience_age_segment,
  pet_segment
FROM {{ source('staging', 'stg_creator') }}
