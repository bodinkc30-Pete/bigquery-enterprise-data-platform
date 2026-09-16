-- Phase 13 automated DQ gates. Portfolio-safe aggregate checks only.
SELECT 'DQ_CMP_001' AS rule_id,
       CAST(COUNTIF(order_item_key IS NULL) AS STRING) AS observed_value,
       COUNTIF(order_item_key IS NULL) AS affected_rows
FROM `core.fact_order_item`
UNION ALL
SELECT 'DQ_CMP_002', CAST(COUNTIF(payment_key IS NULL) AS STRING),
       COUNTIF(payment_key IS NULL)
FROM `core.fact_creator_payment`
UNION ALL
SELECT 'DQ_UNQ_001', CAST(COUNT(*) AS STRING), COUNT(*)
FROM (SELECT order_item_key FROM `core.fact_order_item` GROUP BY 1 HAVING COUNT(*) > 1)
UNION ALL
SELECT 'DQ_UNQ_002', CAST(COUNT(*) AS STRING), COUNT(*)
FROM (SELECT payment_key FROM `core.fact_creator_payment` GROUP BY 1 HAVING COUNT(*) > 1)
UNION ALL
SELECT 'DQ_VAL_001', CAST(COUNTIF(quantity IS NULL OR quantity <= 0) AS STRING),
       COUNTIF(quantity IS NULL OR quantity <= 0)
FROM `core.fact_order_item`
UNION ALL
SELECT 'DQ_CON_001', CAST(COUNTIF(ABS(subtotal_after_discount -
       (subtotal_before_discount - total_discount)) > 0.01) AS STRING),
       COUNTIF(ABS(subtotal_after_discount - (subtotal_before_discount - total_discount)) > 0.01)
FROM `core.fact_order_item`
UNION ALL
SELECT 'DQ_RI_001', CAST(COUNT(*) AS STRING), COUNT(*)
FROM `core.fact_order_item` f
LEFT JOIN `core.dim_sku` d USING (sku_key)
WHERE d.sku_key IS NULL
UNION ALL
SELECT 'DQ_RI_002', CAST(COUNT(*) AS STRING), COUNT(*)
FROM `core.fact_creator_payment` f
LEFT JOIN `core.dim_creator` d USING (creator_key)
WHERE d.creator_key IS NULL
UNION ALL
SELECT 'DQ_FRE_001',
       IF((SELECT MAX(date) FROM `mart.mart_commerce_daily`) = GREATEST(
          (SELECT MAX(order_date) FROM `core.fact_order_item`),
          (SELECT MAX(date) FROM `core.fact_shop_daily`)), 'aligned', 'misaligned'),
       IF((SELECT MAX(date) FROM `mart.mart_commerce_daily`) = GREATEST(
          (SELECT MAX(order_date) FROM `core.fact_order_item`),
          (SELECT MAX(date) FROM `core.fact_shop_daily`)), 0, 1)
UNION ALL
SELECT 'DQ_FRE_002',
       IF((SELECT MAX(date) FROM `mart.mart_marketing_daily`) = GREATEST(
          (SELECT MAX(date) FROM `core.fact_campaign_daily`),
          (SELECT MAX(date) FROM `core.fact_live_daily`),
          (SELECT MAX(date) FROM `core.fact_product_card_daily`)), 'aligned', 'misaligned'),
       IF((SELECT MAX(date) FROM `mart.mart_marketing_daily`) = GREATEST(
          (SELECT MAX(date) FROM `core.fact_campaign_daily`),
          (SELECT MAX(date) FROM `core.fact_live_daily`),
          (SELECT MAX(date) FROM `core.fact_product_card_daily`)), 0, 1)
UNION ALL
SELECT 'DQ_FRE_003',
       IF((SELECT MAX(post_date) FROM `mart.mart_payment_daily`) =
          (SELECT MAX(post_date) FROM `core.fact_creator_payment`), 'aligned', 'misaligned'),
       IF((SELECT MAX(post_date) FROM `mart.mart_payment_daily`) =
          (SELECT MAX(post_date) FROM `core.fact_creator_payment`), 0, 1)
UNION ALL
SELECT 'DQ_REC_001',
       CAST(ABS((SELECT SUM(order_item_count) FROM `mart.mart_commerce_daily`) -
                (SELECT COUNT(*) FROM `core.fact_order_item`)) AS STRING),
       CAST(ABS((SELECT SUM(order_item_count) FROM `mart.mart_commerce_daily`) -
                (SELECT COUNT(*) FROM `core.fact_order_item`)) AS INT64)
UNION ALL
SELECT 'DQ_REC_002',
       CAST(ABS((SELECT SUM(units_ordered) FROM `mart.mart_commerce_daily`) -
                (SELECT SUM(quantity) FROM `core.fact_order_item`)) AS STRING),
       CAST(ABS((SELECT SUM(units_ordered) FROM `mart.mart_commerce_daily`) -
                (SELECT SUM(quantity) FROM `core.fact_order_item`)) AS INT64)
UNION ALL
SELECT 'DQ_REC_003',
       CAST(ABS((SELECT SUM(payment_count) FROM `mart.mart_payment_daily`) -
                (SELECT COUNT(*) FROM `core.fact_creator_payment`)) AS STRING),
       CAST(ABS((SELECT SUM(payment_count) FROM `mart.mart_payment_daily`) -
                (SELECT COUNT(*) FROM `core.fact_creator_payment`)) AS INT64)
UNION ALL
SELECT 'DQ_REC_004',
       CAST(ABS((SELECT SUM(total_payment_amount) FROM `mart.mart_payment_daily`) -
                (SELECT SUM(payment_amount) FROM `core.fact_creator_payment`)) AS STRING),
       IF(ABS((SELECT SUM(total_payment_amount) FROM `mart.mart_payment_daily`) -
              (SELECT SUM(payment_amount) FROM `core.fact_creator_payment`)) <= 0.01, 0, 1)
