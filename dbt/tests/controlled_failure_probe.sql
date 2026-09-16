{% if var('phase09_force_failure', false) %}
select 1 as failure
{% else %}
select 1 as failure from unnest([1]) where false
{% endif %}
