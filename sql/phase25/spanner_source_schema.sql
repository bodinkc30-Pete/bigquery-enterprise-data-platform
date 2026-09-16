CREATE TABLE cdc_orders (
  order_id STRING(36) NOT NULL,
  order_status STRING(32) NOT NULL,
  order_amount NUMERIC NOT NULL,
  payment_status STRING(32) NOT NULL,
  event_version INT64 NOT NULL,
  updated_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true)
) PRIMARY KEY (order_id);

CREATE CHANGE STREAM phase25_cdc_changes
FOR cdc_orders
OPTIONS (
  value_capture_type = 'NEW_ROW',
  retention_period = '1d'
);
