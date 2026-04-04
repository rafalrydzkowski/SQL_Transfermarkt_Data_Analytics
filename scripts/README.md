## 🚦 Getting Started
To initialize and populate the entire Data Warehouse, follow the execution order below:

1. **Create Schemas & Database:** Run the script: [0_database_initialization.sql](./0_database_initialization/0_database_initialization.sql)
2. **Create Tables:** Run scripts respectively: [1_bronze_ddl.sql](./0_database_initialization/1_bronze_ddl.sql), [2_silver_ddl.sql](./0_database_initialization/2_silver_ddl.sql), [3_gold_ddl.sql](./0_database_initialization/3_gold_ddl.sql)
3. **Create Stored Procedures:** Run scripts respectively: [1_bronze_proc_data_load.sql](./0_database_initialization/1_bronze_proc_data_load.sql), [2_silver_proc_data_load.sql](./0_database_initialization/2_silver_proc_data_load.sql), [3_gold_proc_data_load.sql](./0_database_initialization/3_gold_proc_data_load.sql)
4. **Load Raw Data:**
   ```sql
   CALL bronze.sp_load_bronze();
5. **Transform to Silver:**
   ```sql
   CALL silver.sp_load_silver();
6. **Finalize Gold Schema:**
   ```sql
   CALL gold.sp_load_gold();

---
