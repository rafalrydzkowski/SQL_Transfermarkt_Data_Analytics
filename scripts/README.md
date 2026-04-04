## 🚦 Getting Started
To initialize and populate the entire Data Warehouse, follow the execution order below:

1. **Create Schemas & Tables:** Run the DDL scripts for `bronze`, `silver`, and `gold`.
2. **Load Raw Data:**
   ```sql
   CALL bronze.sp_load_bronze();
3. **Transform to Silver:**
   ```sql
   CALL silver.sp_load_silver();
4. **Finalize Gold Schema:**
   ```sql
   CALL gold.sp_load_gold();

---
