# 📑 Naming Conventions - Transfermarkt DW Project

> This document defines the mandatory standards for all database objects. Strict adherence ensures a production-grade Data Warehouse environment and seamless collaboration.

## 📌 Table of Contents
1. [General Principles](#1-general-principles)
2. [Schema Namespaces](#2-schema-namespaces)
3. [Object Prefixes & Naming](#3-object-prefixes--naming)
4. [Column Standards](#4-column-standards)
5. [Constraint & Index Naming Pattern](#5-constraint--index-naming-pattern)
6. [SQL Formatting Style](#6-sql-formatting-style)

---

## 1. ⚙️ General Principles
* **Case:** `snake_case` for all identifiers (tables, columns, schemas).
* **Clarity:** Full descriptive names are mandatory. No abbreviations (e.g., use `competition_id` instead of `comp_id`).
* **Language:** English for all metadata and object names.

## 2. 🏗️ Schema Namespaces
The project implements a 3-tier Medallion Architecture:
* 🥉`bronze`: Raw, immutable staging data directly from source files.
* 🥈`silver`: Cleaned, typed, and normalized data (3rd Normal Form).
* 🥇`gold`: Business-ready Dimensional Model (Star Schema).



## 3. 🏷️ Object Prefixes & Naming
| Object Type | Schema | Prefix | Example | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Raw Table** | `bronze` | none | `bronze.players` | Raw ingestion (Landing). |
| **Base Table** | `silver` | none | `silver.players` | Cleaned & Normalized data. |
| **Fact Table** | `gold` | `fact_` | `gold.fact_transfers` | Quantitative events (Facts). |
| **Dimension Table**| `gold` | `dim_` | `gold.dim_clubs` | Descriptive attributes. |
| **Standard View** | any | `vw_` | `gold.vw_top_scorers` | Virtual/Dynamic query. |
| **Materialized View**| any | `mvw_` | `gold.mvw_market_trends`| Physically stored query. |
| **Stored Procedure**| any | `sp_` | `silver.sp_load_players` | ETL logic. |
| **Function** | any | `fn_` | `silver.fn_calculate_age` | Logic returning a value. |
| **Temporary Table**| any | `tmp_` | `bronze.tmp_players_dedup` | Session/Ephemeral data. |
| **Index** | any | `idx_` | `gold.idx_players__name` | Performance optimization. |


## 4. 📋 Column Standards
* **🗝️ Primary Keys:** Named as `[singular_table_name]_id` (e.g., `player_id`).
* **🔗 Foreign Keys:** Must mirror the name of the referenced Primary Key.
* **💰 Financials:** All currency-based columns must end with `_eur` (e.g., `market_value_eur`).
* **✅ Booleans:** Must start with `is_` or `has_` (e.g., `is_win`).
* **🛠️ Technical Metadata:** System-generated columns must start with `dwh_`:
    * `dwh_inserted_at`: Timestamp of record creation.
    * `dwh_updated_at`: Timestamp of the last update.
    * `dwh_source_file`: Name of the source file.

## 5. 🔏 Constraint & Index Naming Pattern
All constraints and indexes must follow the pattern: `[type_prefix]_[table_name]__[column_name]`

| Type | Prefix | Example |
| :--- | :--- | :--- |
| **Primary Key** | `pk_` | `pk_players` |
| **Foreign Key** | `fk_` | `fk_players__clubs` |
| **Unique Constraint**| `uq_` | `uq_players__player_code` |
| **Index** | `idx_` | `idx_players__last_name` |

## 6. 💎 SQL Formatting Style
* **Keywords:** Always UPPERCASE (e.g., `SELECT`, `FROM`).
* **Indentation:** 4 spaces (no tabs).
* **Joins:** Always use explicit `JOIN` syntax.
* **Aliases:** Always use the `AS` keyword.
