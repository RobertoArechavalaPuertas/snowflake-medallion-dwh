// Paso 1: Cómputo y almacenamiento van por separado
// Computo --> WH: ejecuta queries, no almacena datos
//  - Puedo tener multiples WH corriendo a la vez
//  - Pausar cuando no lo necesite, no me cobra
//  - Scale up or down
//  - Ud coste: creditos, utilizacion del WH
// Almacenamiento --> capa de almacenamiento cloud segun el proveedor que se elija para la cuenta. AWS
//  - Ud coste: TB  
CREATE WAREHOUSE IF NOT EXISTS MI_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60 //si no hay actividad en 60 segundo, el WH se apaga. 
    AUTO_RESUME = TRUE;


// Paso 2: Crear Base de datos y schemas. Orden: DB --> Schema --> Tables --> Rows
CREATE DATABASE IF NOT EXISTS MI_PROYECTO;
CREATE SCHEMA IF NOT EXISTS "0_STAGING";    //Efimero: entran datos como vienen de origen 
CREATE SCHEMA IF NOT EXISTS "1_BRONZE";     //Permanente
CREATE SCHEMA IF NOT EXISTS "2_SILVER";
CREATE SCHEMA IF NOT EXISTS "3_GOLD";


// Paso 3: Vamos a utilizar datos que ya estan cargados en el scope de snowflake. Con esto se prueba Data Sharing: leo datos como si 
//         fuesen mios pero sin pagas almacenamiento
// Tabla: TPCH_SF1 --> simula una empresa distribuidora 
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER LIMIT 10;
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM LIMIT 10;
