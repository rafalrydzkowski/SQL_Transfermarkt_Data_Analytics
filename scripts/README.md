## 🚦 Getting Started
To initialize and populate the entire Data Warehouse, follow the execution order below:

1. **Create Schemas & Database:** Run the script: [0_database_initialization.sql](./0_database_initialization/0_database_initialization.sql)
2. **Create Tables:** Run scripts respectively:
   - [1_bronze_ddl.sql](./0_database_initialization/1_bronze_ddl.sql)
   - [2_silver_ddl.sql](./0_database_initialization/2_silver_ddl.sql)
   - [3_gold_ddl.sql](./0_database_initialization/3_gold_ddl.sql)
4. **Create Stored Procedures:** Run scripts respectively:
   - [1_bronze_data_load_procedure.sql](./0_database_initialization/1_bronze_data_load_procedure.sql)
   - [2_silver_data_load_procedure.sql](./0_database_initialization/2_silver_data_load_procedure.sql)
   - [3_gold_data_load_procedure.sql](./0_database_initialization/3_gold_data_load_procedure.sql)
5. **Load Raw Data:**
   ```sql
   CALL bronze.sp_load_bronze();
6. **Transform to Silver:**
   ```sql
   CALL silver.sp_load_silver();
7. **Finalize Gold Schema:**
   ```sql
   CALL gold.sp_load_gold();
8. **Explore my analysis!**
   - [1_squad_capital_efficiency_analysis](./1_squad_capital_efficiency)
   - [2_stadium_fill_rate_analysis](./2_stadium_fill_rate_analysis)
   - [3_market_outliers_analysis](./3_market_outliers_analysis)
   - [4_home_advantage_analysis](./4_home_advantage_analysis)
   - [5_new_manager_bounce_analysis](./5_new_manager_bounce_analysis)
