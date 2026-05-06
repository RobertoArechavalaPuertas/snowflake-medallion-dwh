// CU1: Evolucion de los ingresos a lo largo del tiempo
CREATE OR REPLACE VIEW MI_PROYECTO."3_GOLD".CU1_VENTAS_TEMPORAL AS
SELECT
    d.anio,
    d.trimestre_nombre,
    d.mes_nombre,
    d.inicio_mes,
    COUNT(DISTINCT f.order_id)          AS num_pedidos,
    COUNT(DISTINCT f.customer_id)       AS num_clientes,
    ROUND(SUM(f.net_amount), 2)         AS ingresos_netos,
    ROUND(AVG(f.net_amount), 2)         AS ticket_medio
FROM MI_PROYECTO."3_GOLD".FCT_VENTAS f
JOIN MI_PROYECTO."3_GOLD".DIM_DATE d
    ON f.date_id = d.date_id
GROUP BY 1, 2, 3, 4
ORDER BY 4;


// CU2: Regiones y paises que generan mas ingresos
CREATE OR REPLACE VIEW MI_PROYECTO."3_GOLD".CU2_VENTAS_GEOGRAFICO AS
SELECT
    c.region_name,
    c.nation_name,
    c.market_segment,
    COUNT(DISTINCT f.order_id)          AS num_pedidos,
    COUNT(DISTINCT f.customer_id)       AS num_clientes,
    ROUND(SUM(f.net_amount), 2)         AS ingresos_netos,
    ROUND(SUM(f.net_amount) * 100.0 /
        SUM(SUM(f.net_amount)) OVER (), 2) AS pct_sobre_total
FROM MI_PROYECTO."3_GOLD".FCT_VENTAS f
JOIN MI_PROYECTO."3_GOLD".DIM_CUSTOMER c
    ON f.customer_id = c.customer_id
GROUP BY 1, 2, 3
ORDER BY 6 DESC;


// CU3: Productos y proveedores que mueven más volumen
CREATE OR REPLACE VIEW MI_PROYECTO."3_GOLD".CU3_PRODUCTOS_PROVEEDORES AS
SELECT
    p.brand,
    p.type,
    p.container,
    s.supplier_name,
    s.nation_name                           AS supplier_nation,
    COUNT(DISTINCT f.order_id)              AS num_pedidos,
    ROUND(SUM(f.quantity), 0)               AS unidades_vendidas,
    ROUND(SUM(f.net_amount), 2)             AS ingresos_netos,
    ROUND(AVG(f.discount) * 100, 2)        AS descuento_medio_pct
FROM MI_PROYECTO."3_GOLD".FCT_VENTAS f
JOIN MI_PROYECTO."3_GOLD".DIM_PART p
    ON f.part_id = p.part_id
JOIN MI_PROYECTO."3_GOLD".DIM_SUPPLIER s
    ON f.supplier_id = s.supplier_id
GROUP BY 1, 2, 3, 4, 5
ORDER BY 8 DESC;


// CU5: 
CREATE OR REPLACE VIEW MI_PROYECTO."3_GOLD".CU5_SEGMENTACION_CLIENTES AS
SELECT
    c.customer_id,
    c.customer_name,
    c.market_segment,
    c.nation_name,
    c.region_name,
    COUNT(DISTINCT f.order_id)              AS num_pedidos,
    ROUND(SUM(f.net_amount), 2)             AS ingresos_totales,
    ROUND(AVG(f.net_amount), 2)             AS ticket_medio,
    MIN(f.date_id)                          AS primera_compra,
    MAX(f.date_id)                          AS ultima_compra,
    DATEDIFF('day',
        MIN(f.date_id),
        MAX(f.date_id))                     AS dias_como_cliente,
    CASE
        WHEN SUM(f.net_amount) > 500000 THEN 'PREMIUM'
        WHEN SUM(f.net_amount) > 200000 THEN 'ALTO'
        WHEN SUM(f.net_amount) > 100000 THEN 'MEDIO'
        ELSE 'BAJO'
    END                                     AS segmento_valor
FROM MI_PROYECTO."3_GOLD".FCT_VENTAS f
JOIN MI_PROYECTO."3_GOLD".DIM_CUSTOMER c
    ON f.customer_id = c.customer_id
GROUP BY 1, 2, 3, 4, 5
ORDER BY 7 DESC;




/*
1. Entender qué quiere el cliente en lenguaje de negocio
2. Traducirlo a métricas y dimensiones concretas: sum(net_amount) actual y año anterior con LAG, diferencia, %. 
3. Identificar qué tablas de tu proyecto lo resuelven: FCT_Ventas y dim_date
4. Escribir el SQL
5. Crear la vista en Gold con nombre de negocio (CU6_VENTAS_YOY, etc.)
*/

// Peticion 1: "Necesito saber si estamos vendiendo mejor este año que el anterior. No me des todos los datos, solo dime si vamos bien o mal respecto al mismo periodo."
CREATE OR REPLACE VIEW MI_PROYECTO."3_GOLD".CU6_VENTAS_YOY AS

WITH base AS (
    SELECT
        d.anio,
        ROUND(SUM(f.net_amount), 2)     AS ingresos_netos
    FROM MI_PROYECTO."3_GOLD".FCT_VENTAS f
    JOIN MI_PROYECTO."3_GOLD".DIM_DATE d
        ON f.date_id = d.date_id
    GROUP BY 1
),

yoy AS (
    SELECT
        anio,
        ingresos_netos,
        LAG(ingresos_netos, 1) OVER (ORDER BY anio)     AS ingresos_anio_anterior,
        ingresos_netos - LAG(ingresos_netos, 1)
            OVER (ORDER BY anio)                         AS diferencia,
        ROUND((ingresos_netos - LAG(ingresos_netos, 1)
            OVER (ORDER BY anio)) * 100.0 /
            LAG(ingresos_netos, 1) OVER (ORDER BY anio), 2) AS pct_cambio
    FROM base
),

final AS (
    SELECT
        *,
        CASE
            WHEN pct_cambio > 0     THEN 'CRECIMIENTO'
            WHEN pct_cambio < 0     THEN 'DECRECIMIENTO'
            WHEN pct_cambio IS NULL THEN 'SIN DATO'
            ELSE 'ESTABLE'
        END                                              AS tendencia
    FROM yoy
)

SELECT * FROM final;




// Petición 2: "Tenemos un problema con los envíos. Algunos clientes se quejan de que tardan demasiado. Quiero saber qué modo de envío es el más lento y en qué países pasa más."
/**
Problema: no tenemos esos campos en fct ventas
Opcion A: añadir los campos a fct --> Esto se hace solo si son metricas que cualquier analisis de gold va a necesitar.
Opcion B: crear una vista especifica que coja los datos desde silver --> solo si es un caso de uso concreto.

Solución: En nuestro caso ship_mode, ship_date y receipt_date son campos operacionales relevantes para muchos análisis — rendimiento de proveedores, logística, satisfacción de cliente. Tiene sentido en FCT_VENTAS. dias_entrega en cambio es una métrica calculada específica — podría vivir en la vista del caso de uso.
**/
CREATE OR REPLACE VIEW MI_PROYECTO."3_GOLD".CU7_ANALISIS_ENVIOS AS
WITH base AS (
    SELECT
        f.ship_mode,
        c.nation_name,
        c.region_name,
        DATEDIFF('day', f.ship_date, f.receipt_date) AS dias_entrega
    FROM MI_PROYECTO."3_GOLD".FCT_VENTAS f
    JOIN MI_PROYECTO."3_GOLD".DIM_CUSTOMER c
        ON f.customer_id = c.customer_id
),
agregado AS (
    SELECT
        ship_mode,
        nation_name,
        region_name,
        ROUND(AVG(dias_entrega), 1)     AS dias_entrega_medio,
        MAX(dias_entrega)               AS dias_entrega_maximo,
        MIN(dias_entrega)               AS dias_entrega_minimo,
        COUNT(*)                        AS num_envios
    FROM base
    GROUP BY 1, 2, 3
)
SELECT * FROM agregado
ORDER BY dias_entrega_medio DESC;