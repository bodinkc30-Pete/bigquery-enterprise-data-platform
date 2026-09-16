{% macro phase11_incremental_start_date(target_date_column) -%}
  {% set explicit_backfill = var('phase11_backfill_start_date', '') %}
  {% if explicit_backfill %}
    DATE('{{ explicit_backfill }}')
  {% else %}
    COALESCE(
      DATE_SUB(
        (SELECT MAX({{ target_date_column }}) FROM {{ this }}),
        INTERVAL {{ var('phase11_lookback_days', 7) }} DAY
      ),
      DATE('1900-01-01')
    )
  {% endif %}
{%- endmacro %}
