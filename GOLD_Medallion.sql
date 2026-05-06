// DIM_CUSTOMER
CREATE OR REPLACE TABLE DIM_CUSTOMER AS
WITH customers AS (
    SELECT * FROM MI_PROYECTO."2_SILVER".SLV_CUSTOMERS
),
nations AS (
    SELECT * FROM MI_PROYECTO."2_SILVER".SLV_NATIONS
),
regions AS (
    SELECT * FROM MI_PROYECTO."2_SILVER".SLV_REGIONS
),
enriquecido AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.address,
        c.phone,
        c.account_balance,
        c.market_segment,
        n.nation_id,
        n.nation_name,
        r.region_id,
        r.region_name
    FROM customers c
    LEFT JOIN nations n ON c.nation_id = n.nation_id
    LEFT JOIN regions r ON n.region_id = r.region_id
)
SELECT * FROM enriquecido;

// DIM_SUPPLIER
CREATE OR REPLACE TABLE DIM_SUPPLIER AS
WITH suppliers AS (
    SELECT * FROM MI_PROYECTO."2_SILVER".SLV_SUPPLIER
),
nations AS (
    SELECT * FROM MI_PROYECTO."2_SILVER".SLV_NATIONS
),
regions AS (
    SELECT * FROM MI_PROYECTO."2_SILVER".SLV_REGIONS
),
enriquecido AS (
    SELECT
        s.supplier_id,
        s.supplier_name,
        s.address,
        s.phone,
        s.account_balance,
        s.nation_id,
        n.nation_name,
        r.region_id,
        r.region_name
    FROM suppliers s
    LEFT JOIN nations n ON s.nation_id = n.nation_id
    LEFT JOIN regions r ON n.region_id = r.region_id
)
SELECT * FROM enriquecido;

// DIM_DATE
CREATE OR REPLACE TABLE DIM_DATE AS
WITH fechas_reales AS (
    SELECT DISTINCT order_date AS date_id
    FROM MI_PROYECTO."2_SILVER".SLV_ORDERS
),
enriquecido AS (
    SELECT
        date_id,
        YEAR(date_id)                                           AS anio,
        MONTH(date_id)                                          AS mes,
        DAY(date_id)                                            AS dia,
        QUARTER(date_id)                                        AS trimestre,
        'Q' || QUARTER(date_id)                                 AS trimestre_nombre,
        DAYOFWEEK(date_id)                                      AS dia_semana_num,
        DAYNAME(date_id)                                        AS dia_semana_nombre,
        MONTHNAME(date_id)                                      AS mes_nombre,
        CASE WHEN DAYOFWEEK(date_id) IN (0, 6)
             THEN TRUE ELSE FALSE END                           AS es_fin_de_semana,
        CASE WHEN DAYOFWEEK(date_id) NOT IN (0, 6)
             THEN TRUE ELSE FALSE END                           AS es_dia_laborable,
        DATE_TRUNC('week',    date_id)::DATE                    AS inicio_semana,
        DATE_TRUNC('month',   date_id)::DATE                    AS inicio_mes,
        DATE_TRUNC('quarter', date_id)::DATE                    AS inicio_trimestre
    FROM fechas_reales
)
SELECT * FROM enriquecido;

// FCT_VENTAS
CREATE OR REPLACE TABLE MI_PROYECTO."3_GOLD".FCT_VENTAS AS
WITH lineitem AS (
    SELECT * FROM MI_PROYECTO."2_SILVER".SLV_LINEITEM
),
orders AS (
    SELECT * FROM MI_PROYECTO."2_SILVER".SLV_ORDERS
),
fact AS (
    SELECT
        -- Claves foráneas
        l.order_id,
        o.customer_id,
        o.order_date                AS date_id,
        l.part_id,
        l.supplier_id,
        l.line_number,
        -- Métricas
        l.quantity,
        l.extended_price,
        l.discount,
        l.tax,
        l.net_amount,
        l.net_amount_with_tax,
        -- Campos de envío
        l.ship_mode,
        l.ship_date,
        l.receipt_date
    FROM lineitem l
    JOIN orders o ON l.order_id = o.order_id
)
SELECT * FROM fact;

// DIM_PART
CREATE OR REPLACE TABLE DIM_PART AS(
    SELECT * FROM MI_PROYECTO."2_SILVER".SLV_PART
)





