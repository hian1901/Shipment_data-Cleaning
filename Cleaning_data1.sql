SELECT * FROM `practicesql-512804.Practice_SQL.cleaning_data` LIMIT 1000;

-- Remove Leading/trailing Whitespace
SELECT
  shipment_id,
  trim(origin_warehouse) AS origin_warehouse,
  trim(destination_city) AS destination_city,
  trim(destination_state) AS destination_state,
  trim(carrier) AS carrier,
  trim(shipment_status) AS shipment_status
FROM `practicesql-512804.Practice_SQL.cleaning_data`
LIMIT 1000;

-- Standarlize test
SELECT
  shipment_id,
  initcap(trim(origin_warehouse)) AS origin_warehouse,
  initcap(trim(destination_city)) AS destination_city,
  upper(trim(destination_state)) AS destination_state,
  initcap(trim(carrier)) AS carrier,
  initcap(trim(shipment_status)) AS shipment_status
FROM `practicesql-512804.Practice_SQL.cleaning_data`
LIMIT 1000;

-- replace null
CREATE OR REPLACE TABLE `practicesql-512804.Practice_SQL.cleaning_data`
AS
SELECT
  shipment_id,
  CASE
    WHEN damage_reported = 'null' THEN NULL
    ELSE initcap(trim(damage_reported))
    END AS damage_reported,
  coalesce(destination_city, 'unknown') AS destination_city,
  coalesce(delivery_date, 'not yet delivered') AS delivery_date
FROM `practicesql-512804.Practice_SQL.cleaning_data`
LIMIT 1000;

-- Remove duplicate
WITH
  duplicate_data AS (
    SELECT
      *,
      row_number() OVER (PARTITION BY shipment_id) AS rn
    FROM `practicesql-512804.Practice_SQL.cleaning_data`
  )
SELECT * EXCEPT (rn)
FROM duplicate_data
WHERE rn = 1;

-- fix negative & supicious numeric values
SELECT
  shipment_id,
  CASE
    WHEN weight_kg < 0 THEN abs(weight_kg)
    WHEN weight_kg = 0 THEN NULL
    ELSE weight_kg
    END AS weight_kg_cleaned
FROM `practicesql-512804.Practice_SQL.cleaning_data`;

-- validate date logic
SELECT
  shipment_id,
  ship_date,
  delivery_date,
  date_diff(
    safe.parse_date('%Y-%m-%d', delivery_date),
    safe.parse_date('%Y-%m-%d', ship_date),
    Day) AS transit_day,
  CASE
    WHEN
      safe.parse_date('%Y-%m-%d', delivery_date)
      < safe.parse_date('%Y-%m-%d', ship_date)
      THEN 'unvalid'
    WHEN
      safe.parse_date('%Y-%m-%d', delivery_date)
      = safe.parse_date('%Y-%m-%d', ship_date)
      THEN 'Same day delivery'
    ELSE 'Valid'
    END AS data_quality_flag
FROM `practicesql-512804.Practice_SQL.cleaning_data`;

-- detect & cap outliers using IQR method
WITH
  stats AS (
    SELECT
      approx_quantiles(freight_cost, 100)[offset(25)] AS Q1,
      approx_quantiles(freight_cost, 100)[offset(75)] AS Q3
    FROM `practicesql-512804.Practice_SQL.cleaning_data`
    WHERE freight_cost > 0
  )
SELECT
  shipment_id,
  freight_cost AS original_cost,
  CASE
    WHEN freight_cost > (SELECT Q3 + 1.5 * (Q3 - Q1) FROM stats)
      THEN (SELECT Q3 + 1.5 * (Q3 - Q1) FROM stats)
    WHEN freight_cost < (SELECT Q1 - 1.5 * (Q3 - Q1) FROM stats)
      THEN (SELECT Q1 - 1.5 * (Q3 - Q1) FROM stats)
    ELSE freight_cost
    END AS cleaned_cost,
  CASE
    WHEN
      freight_cost > (SELECT Q3 + 1.5 * (Q3 - Q1) FROM stats)
      OR freight_cost < (SELECT Q1 - 1.5 * (Q3 - Q1) FROM stats)
      THEN TRUE
    ELSE FALSE
    END AS was_outliers
FROM `practicesql-512804.Practice_SQL.cleaning_data`;
