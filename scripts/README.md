## 🚦 Getting Started
To initialize and populate the entire Data Warehouse, follow the execution order below:

1. **Create Schemas & Database:** Run the script: [0_database_initialization.sql](./0_database_initialization/0_database_initialization.sql)
2. scripts for `bronze`, `silver`, and `gold`.
3. **Load Raw Data:**
   ```sql
   CALL bronze.sp_load_bronze();
4. **Transform to Silver:**
   ```sql
   CALL silver.sp_load_silver();
5. **Finalize Gold Schema:**
   ```sql
   CALL gold.sp_load_gold();

---
