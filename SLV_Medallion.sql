// SLV_CUSTOMERS
CREATE OR REPLACE TABLE SLV_CUSTOMERS AS
WITH bronze AS (
    SELECT * FROM MI_PROYECTO."1_BRONZE".BRZ_CUSTOMERS
),
limpieza AS (
    SELECT
        C_CUSTKEY       AS customer_id,
        C_NAME          AS customer_name,
        C_ADDRESS       AS address,
        C_NATIONKEY     AS nation_id,
        C_PHONE         AS phone,
        C_ACCTBAL       AS account_balance,
        C_MKTSEGMENT    AS market_segment,
        C_COMMENT       AS comments
    FROM bronze
    WHERE C_CUSTKEY IS NOT NULL
    AND   C_NAME IS NOT NULL
    AND   C_NATIONKEY IS NOT NULL
)
SELECT * FROM limpieza;

// SLV_LINEITEM
CREATE OR REPLACE TABLE SLV_LINEITEM AS
WITH bronze AS (
    SELECT * FROM MI_PROYECTO."1_BRONZE".BRZ_LINEITEM
),
limpieza AS (
    SELECT
        L_ORDERKEY                                              AS order_id,
        L_PARTKEY                                               AS part_id,
        L_SUPPKEY                                               AS supplier_id,
        L_LINENUMBER                                            AS line_number,
        L_QUANTITY                                              AS quantity,
        L_EXTENDEDPRICE::NUMBER(12,2)                           AS extended_price,
        L_DISCOUNT::NUMBER(4,2)                                 AS discount,
        L_TAX::NUMBER(4,2)                                      AS tax,
        CASE L_RETURNFLAG
            WHEN 'R' THEN 'RETURNED'
            WHEN 'A' THEN 'ACCEPTED'
            WHEN 'N' THEN 'NONE'
            ELSE 'UNKNOWN'
        END                                                     AS return_flag,
        CASE L_LINESTATUS
            WHEN 'F' THEN 'FULFILLED'
            WHEN 'O' THEN 'OPEN'
            ELSE 'UNKNOWN'
        END                                                     AS line_status,
        L_SHIPDATE::DATE                                        AS ship_date,
        L_COMMITDATE::DATE                                      AS commit_date,
        L_RECEIPTDATE::DATE                                     AS receipt_date,
        L_SHIPINSTRUCT                                          AS ship_instruct,
        L_SHIPMODE                                              AS ship_mode,
        L_COMMENT                                               AS comments,
        ROUND(L_EXTENDEDPRICE * (1 - L_DISCOUNT), 2)           AS net_amount,
        ROUND(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX), 2) AS net_amount_with_tax
    FROM bronze
    WHERE L_ORDERKEY IS NOT NULL
    AND   L_PARTKEY IS NOT NULL
    AND   L_SUPPKEY IS NOT NULL
    AND   L_QUANTITY > 0
    AND   L_EXTENDEDPRICE > 0
)
SELECT * FROM limpieza;

// SLV_NATIONS
CREATE OR REPLACE TABLE SLV_NATIONS AS
WITH bronze AS (
    SELECT * FROM MI_PROYECTO."1_BRONZE".BRZ_NATIONS
),
limpieza AS (
    SELECT
        N_NATIONKEY     AS nation_id,
        N_NAME          AS nation_name,
        N_REGIONKEY     AS region_id,
        N_COMMENT       AS comments
    FROM bronze
    WHERE N_NATIONKEY IS NOT NULL
    AND   N_NAME IS NOT NULL
    AND   N_REGIONKEY IS NOT NULL
)
SELECT * FROM limpieza;

// SLV_ORDERS
CREATE OR REPLACE TABLE SLV_ORDERS AS
WITH bronze AS (
    SELECT * FROM MI_PROYECTO."1_BRONZE".BRZ_ORDERS
),
limpieza AS (
    SELECT
        O_ORDERKEY                          AS order_id,
        O_CUSTKEY                           AS customer_id,
        CASE O_ORDERSTATUS
            WHEN 'O' THEN 'OPEN'
            WHEN 'F' THEN 'FULFILLED'
            WHEN 'P' THEN 'PENDING'
            ELSE 'UNKNOWN'
        END                                 AS order_status,
        O_TOTALPRICE::NUMBER(12,2)          AS total_price,
        O_ORDERDATE::DATE                   AS order_date,
        O_ORDERPRIORITY                     AS order_priority,
        LEFT(O_ORDERPRIORITY, 1)::NUMBER    AS priority_rank,
        O_CLERK                             AS clerk,
        O_COMMENT                           AS comments
    FROM bronze
    WHERE O_ORDERKEY IS NOT NULL
    AND   O_CUSTKEY IS NOT NULL
    AND   O_ORDERDATE IS NOT NULL
    AND   O_TOTALPRICE > 0
)
SELECT * FROM limpieza;

// SLV_PART
CREATE OR REPLACE TABLE SLV_PART AS
WITH bronze AS (
    SELECT * FROM MI_PROYECTO."1_BRONZE".BRZ_PART
),
limpieza AS (
    SELECT
        P_PARTKEY                   AS part_id,
        P_NAME                      AS part_name,
        P_MFGR                      AS manufacturer,
        P_BRAND                     AS brand,
        P_TYPE                      AS type,
        P_SIZE                      AS size,
        P_CONTAINER                 AS container,
        P_RETAILPRICE::NUMBER(12,2) AS retail_price,
        P_COMMENT                   AS comments
    FROM bronze
    WHERE P_PARTKEY IS NOT NULL
    AND   P_NAME IS NOT NULL
)
SELECT * FROM limpieza;

// SLV_PARTSUPP
CREATE OR REPLACE TABLE SLV_PARTSUPP AS
WITH bronze AS (
    SELECT * FROM MI_PROYECTO."1_BRONZE".BRZ_PARTSUPP
),
limpieza AS (
    SELECT
        PS_PARTKEY                  AS part_id,
        PS_SUPPKEY                  AS supplier_id,
        PS_AVAILQTY                 AS availqty,
        PS_SUPPLYCOST::NUMBER(12,2) AS supplycost,
        PS_COMMENT                  AS comments
    FROM bronze
    WHERE PS_PARTKEY IS NOT NULL
    AND   PS_SUPPKEY IS NOT NULL
)
SELECT * FROM limpieza;

// SLV_REGIONS
CREATE OR REPLACE TABLE SLV_REGIONS AS
WITH bronze AS (
    SELECT * FROM MI_PROYECTO."1_BRONZE".BRZ_REGIONS
),
limpieza AS (
    SELECT
        R_REGIONKEY     AS region_id,
        R_NAME          AS region_name,
        R_COMMENT       AS comments
    FROM bronze
    WHERE R_REGIONKEY IS NOT NULL
    AND   R_NAME IS NOT NULL
)
SELECT * FROM limpieza;

// SLV_SUPPLIER
CREATE OR REPLACE TABLE SLV_SUPPLIER AS
WITH bronze AS (
    SELECT * FROM MI_PROYECTO."1_BRONZE".BRZ_SUPPLIER
),
limpieza AS (
    SELECT
        S_SUPPKEY                   AS supplier_id,
        S_NAME                      AS supplier_name,
        S_ADDRESS                   AS address,
        S_NATIONKEY                 AS nation_id,
        S_PHONE                     AS phone,
        S_ACCTBAL::NUMBER(12,2)     AS account_balance,
        S_COMMENT                   AS comments
    FROM bronze
    WHERE S_SUPPKEY IS NOT NULL
    AND   S_NAME IS NOT NULL
    AND   S_NATIONKEY IS NOT NULL
)
SELECT * FROM limpieza;
