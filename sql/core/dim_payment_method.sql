CREATE OR REPLACE TABLE `{{PROJECT_ID}}.core.dim_payment_method`
OPTIONS(description="Conformed payment-method dimension from accepted commerce orders.") AS
SELECT
  TO_HEX(SHA256(CONCAT('payment_method|', payment_method))) AS payment_method_key,
  payment_method
FROM `{{PROJECT_ID}}.staging.stg_orders`
WHERE payment_method IS NOT NULL
GROUP BY payment_method;
