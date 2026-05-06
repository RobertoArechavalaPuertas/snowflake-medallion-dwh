# Data Warehouse — Medallion Architecture on Snowflake

End-to-end Data Warehouse project built on Snowflake following the Medallion architecture pattern (Staging → Bronze → Silver → Gold), connected to Power BI for analytical consumption.

## Stack

- **Snowflake** — storage, compute and data sharing
- **SQL** — all transformations written in pure SQL
- **Power BI** — dashboards and analytical visualizations
- **Git + GitHub** — version control

## Data Source — TPC-H via Snowflake Data Sharing

Data is sourced from the **TPC-H benchmark dataset**, accessed through `SNOWFLAKE_SAMPLE_DATA`, a shared database provided by Snowflake using its native **Data Sharing** feature.

This means the data is not physically stored in our account — Snowflake grants read access to the dataset through a share, which is one of its key differentiating features for data collaboration. No ingestion pipeline or file transfer is required to access the shared data.

The TPC-H dataset simulates a distribution company with the following entities:

| Table | Description |
|---|---|
| `ORDERS` | Order headers |
| `LINEITEM` | Order line details |
| `CUSTOMER` | Customers |
| `PART` | Product catalog |
| `SUPPLIER` | Suppliers |
| `PARTSUPP` | Part-supplier relationships |
| `NATION` | Countries |
| `REGION` | Regions |

## Architecture

```
SNOWFLAKE_SAMPLE_DATA (Snowflake Share)
          ↓
    0_STAGING    →  Raw data landing zone. Volatile, reloadable.
          ↓
    1_BRONZE     →  Immutable historical layer. Lineage metadata added (_LOADED_AT, _SOURCE_TABLE).
          ↓
    2_SILVER     →  Cleaned, typed and validated E/R model. Business rules applied.
          ↓
    3_GOLD       →  Star Schema optimized for analytical consumption.
```

## Data Modeling

### Silver Layer — E/R Model

Normalized relational model with explicit FK relationships:

```
REGION (1) → NATION (N) → CUSTOMER (1) → ORDERS (N) → LINEITEM
                    ↓
               SUPPLIER (1) → PARTSUPP (N) ← PART
```

### Gold Layer — Star Schema

```
              DIM_DATE
                 |
DIM_CUSTOMER — FCT_VENTAS — DIM_PART
                 |
            DIM_SUPPLIER
```

| Table | Source | Description |
|---|---|---|
| `DIM_CUSTOMER` | SLV_CUSTOMERS + SLV_NATIONS + SLV_REGIONS | Customer with full geographic context |
| `DIM_SUPPLIER` | SLV_SUPPLIER + SLV_NATIONS + SLV_REGIONS | Supplier with full geographic context |
| `DIM_PART` | SLV_PART | Product catalog |
| `DIM_DATE` | SLV_ORDERS | Date dimension generated from real order dates |
| `FCT_VENTAS` | SLV_LINEITEM + SLV_ORDERS | Central fact table with sales metrics |

## Analytical Use Cases (Gold Views)

| View | Business Question |
|---|---|
| `CU1_VENTAS_TEMPORAL` | How do revenues evolve over time? |
| `CU2_VENTAS_GEOGRAFICO` | Which regions and countries generate the most revenue? |
| `CU3_PRODUCTOS_PROVEEDORES` | Which products and suppliers move the most volume? |
| `CU4_COMPORTAMIENTO_PEDIDOS` | How are orders distributed by priority, status and shipping mode? |
| `CU5_SEGMENTACION_CLIENTES` | Who are the most valuable customers? (RFM-based segmentation) |
| `CU6_VENTAS_YOY` | Are we performing better than last year? (Year-over-Year comparison) |
| `CU7_ANALISIS_ENVIOS` | Which shipping mode is the slowest and in which countries? |

## Key Snowflake Concepts Applied

- **Separation of storage and compute** — Virtual Warehouse sized independently from data
- **Data Sharing** — accessed TPC-H dataset via Snowflake native share (zero-copy, no ingestion)
- **Columnar storage and micro-partitions** — OLAP-optimized architecture
- **Time Travel** — historical data recovery capability
- **CTAS (Create Table As Select)** — used across all layers for table materialization
- **Window functions** — RANK(), LAG() applied in analytical use cases
- **QUALIFY clause** — Snowflake-native filtering on window function results