# SQL Data Analytics: Transfermarkt Football Insights ⚽📊

> [!IMPORTANT]
> **This project is a continuation of the Transfermarkt project. If you’d like to learn more about the data warehouse and the Medallion architecture approach I used, see the link below:**
[SQL_Transfermarkt_Data_Warehouse - Github Repository](https://github.com/rafalrydzkowski/SQL_Transfermarkt_Data_Warehouse)

## Project Overview
This repository contains a series of advanced SQL analytical case studies based on football data (inspired by Transfermarkt). The project aims to bridge the gap between raw sports data and actionable business insights, focusing on team efficiency, market valuations, and performance psychological factors.

As a **Junior Data Analyst**, I developed these scripts to demonstrate proficiency in complex data transformations, statistical benchmarking, and identifying trends that help football clubs or betting agencies make data-driven decisions.

---

## 🗂️ Data Source & Raw Dataset

The project utilizes the **Complete Transfermarkt Dataset** sourced from [Kaggle (David Cariboo)](https://www.kaggle.com/datasets/davidcariboo/player-scores). This dataset provides a comprehensive look at European football dynamics from 2012 to the present.

---

## 🔑 Key SQL Concepts Implemented

### 🧠 Advanced Analytics & Window Functions
* **Ranking & Tiering:** `RANK()` for league efficiency and `ROW_NUMBER()` for time-sensitive valuation matching.
* **Statistical Bucketing:** `NTILE(5)` used to eliminate team-quality bias by analyzing performance across localized attendance quintiles.
* **Trend & Change Detection:** `LAG()` with multi-step offset validation to detect manager transitions and filter out temporary stand-ins.
* **Percentile Distributions:** `PERCENTILE_CONT` and `PERCENT_RANK()` to establish market benchmarks (P5, Q1, Median, Q3, P95) and score individual performance impact.

### 🛠 Data Engineering & Architecture
* **Modular SQL (CTEs):** Heavily layered Common Table Expressions to transform raw event data into structured analytical layers.
* **Dynamic Rolling Averages:** `ROWS BETWEEN` frames to calculate 5-game PPG (Points Per Game) momentum shifts.
* **Defensive Programming:** Implementation of `NULLIF` to prevent zero-division errors in ROI calculations and strict data cleaning for competition-specific anomalies.

### 📈 Business Logic & ROI Metrics
* **Capital Efficiency (ROI):** Calculated 'Cost per Point' metrics by joining multi-million euro market valuations with league performance stats.
* **Categorical Performance Modeling:** Created custom business logic using complex `CASE` statements to classify outcomes (e.g., "Success - Significant Bounce" vs "Performance Decline").
* **Peer Group Benchmarking:** Multi-key joins (League + Position + Age Bucket) to ensure players are only compared to their relevant market peers.

---

## 📈 Business & Analytical Use Cases

### 1. Squad Capital Efficiency (The "Moneyball" Analysis)
**Purpose:** Identifying "overperformers" by calculating the **Market Value Cost per Point (ROI)** for the 2025 season.
* **Insight:** Compares how much a club "paid" (in squad market value) for every league point earned.
* **Key SQL Features:** Joins across fact and dimension tables, ranking efficiency within specific leagues.

### 2. The "12th Man" Effect (Stadium Fill Rate)
**Purpose:** Investigating whether a full stadium actually increases the probability of winning.
* **Insight:** Uses `NTILE(5)` to bucket games by relative attendance. Interestingly, it tests the hypothesis that high-stakes games (full stadiums) might increase pressure, sometimes leading to lower win rates compared to average attendance games.

### 3. Market Outliers & Elite Benchmarking
**Purpose:** Using statistical distributions to identify the top 5% of players ("Elite" category) based on age, position, and league.
* **Insight:** Categorizes players into life-cycle buckets (Prospect, Rising Star, Peak, etc.) and uses `PERCENTILE_CONT` to establish market benchmarks (Median, Q1, Q3, P95).

### 4. Home vs. Away Advantage & Referee Bias
**Purpose:** Quantifying the statistical gap between playing at home versus away.
* **Insight:** Analyzes not only points and goals but also the "disciplinary gap" (yellow/red cards) to see if home crowds influence refereeing decisions.

### 5. New Manager Bounce Effect
**Purpose:** Determining if changing a manager mid-season results in a statistically significant performance improvement.
* **Insight:** Uses `LAG` and rolling averages to compare the 5 games *before* and 5 games *after* a managerial change, categorizing the outcome as "Significant Bounce," "Neutral," or "Decline."

---

## 📂 Project Structure
* `1_squad_capital_efficiency_analysis.sql` - ROI and team efficiency metrics.
* `2_stadium_fill_rate_analysis.sql` - Attendance impact on win probability.
* `3_market_outliers_analysis.sql` - Statistical player valuation benchmarking.
* `4_home_advantage_analysis.sql` - Comparative home/away performance and referee bias.
* `5_new_manager_bounce_effect_analysis.sql` - Pre/Post manager change performance tracking.

---

## 💡 Key Business Questions Answered
* Which Bundesliga teams are the most "Capital Efficient"?
* Does a manager change actually work, or is it just a "regression to the mean"?
* Who are the top 5% market outliers in the 2025 season?
* In which leagues is the home-field advantage most prominent?

---

## 🚦 Getting Started

1. **Create Schemas & Database:** Run the script: [0_database_initialization.sql](./scripts/0_database_initialization/0_database_initialization.sql)
2. **Create Tables:** Run scripts respectively:
   - [1_bronze_ddl.sql](./scripts/0_database_initialization/1_bronze_ddl.sql)
   - [2_silver_ddl.sql](./scripts/0_database_initialization/2_silver_ddl.sql)
   - [3_gold_ddl.sql](./scripts/0_database_initialization/3_gold_ddl.sql)
4. **Create Stored Procedures:** Run scripts respectively:
   - [1_bronze_data_load_procedure.sql](./scripts/0_database_initialization/1_bronze_data_load_procedure.sql)
   - [2_silver_data_load_procedure.sql](./scripts/0_database_initialization/2_silver_data_load_procedure.sql)
   - [3_gold_data_load_procedure.sql](./scripts/0_database_initialization/3_gold_data_load_procedure.sql)
5. **Load Raw Data:**
   ```sql
   CALL bronze.sp_load_bronze();
6. **Transform to Silver:**
   ```sql
   CALL silver.sp_load_silver();
7. **Finalize Gold Schema:**
   ```sql
   CALL gold.sp_load_gold();
8. **🎉 Explore my analysis:**
   - [1_squad_capital_efficiency_analysis](./scripts/1_squad_capital_efficiency)
   - [2_stadium_fill_rate_analysis](./scripts/2_stadium_fill_rate_analysis)
   - [3_market_outliers_analysis](./scripts/3_market_outliers_analysis)
   - [4_home_advantage_analysis](./scripts/4_home_advantage_analysis)
   - [5_new_manager_bounce_analysis](./scripts/5_new_manager_bounce_analysis)

---


## 🌟 About Me
I am a **Data Analytics Enthusiast** focused on transforming complex sports datasets into actionable business intelligence. My expertise lies in leveraging **PostgreSQL 16** to architect end-to-end analytical solutions—from raw data ingestion to high-level KPI reporting.

* **Looking for:** Junior Data Analyst roles.
* **Tech I love:** SQL (PostgreSQL), Excel, Tableau
* **Fun Fact:** I chose the Transfermarkt dataset because I believe sports analytics is the ultimate test for handling temporal data and complex relational integrity.

📫 **Let's connect:** https://www.linkedin.com/in/rafal-rydzkowski-data/ | RafalRydzkowskiJ@gmail.com
