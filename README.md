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

## 🛠 Tech Stack
* **Language:** SQL (PostgreSQL/Standard SQL)
* **Key Techniques:** * Common Table Expressions (CTEs) for modular logic.
    * Advanced Window Functions (`RANK`, `NTILE`, `PERCENT_RANK`, `LAG`).
    * Statistical Aggregations (`PERCENTILE_CONT` for quartiles and outliers).
    * Data Cleaning & Normalization (handling NULLs, filtering anomalies).

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

## 🔑 Key SQL Concepts Implemented

This project showcases a wide range of SQL techniques, transitioning from basic data retrieval to advanced analytical engineering:

### 1. Advanced Window Functions
* **Ranking & Row Identification:** Utilized `RANK()` to identify top/bottom performers and `ROW_NUMBER()` with `PARTITION BY` to select the most relevant player valuations closest to specific match dates.
* **Statistical Bucketing:** Implemented `NTILE(5)` to distribute stadium attendance into quintiles, allowing for an unbiased comparison across clubs of different sizes.
* **Analytical Offsets:** Leveraged `LAG()` to detect manager changes by comparing current rows with previous match records.
* **Relative Distribution:** Used `PERCENT_RANK()` to calculate the statistical significance (percentile) of the "Manager Bounce" effect relative to historical data.

### 2. Complex Data Transformations & Aggregations
* **Common Table Expressions (CTEs):** Heavily utilized `WITH` clauses to create modular, readable, and maintainable code structures, breaking down complex logic into logical steps.
* **Window Frames (Rolling Averages):** Applied `ROWS BETWEEN` to calculate 5-game rolling averages (Points Per Game) for pre- and post-managerial change analysis.
* **Conditional Aggregation:** Embedded `CASE WHEN` logic inside `AVG()` and `SUM()` functions to calculate specific metrics like "No Loss Rate" or "Home Win Percentage" within a single scan.

### 3. Statistical Analysis & Benchmarking
* **Continuous Percentiles:** Employed `PERCENTILE_CONT(...) WITHIN GROUP (ORDER BY ...)` to calculate Median, Q1, Q3, and P95 values, establishing rigorous market benchmarks for player valuations.
* **Outlier Detection:** Created logic to isolate "Market Outliers" (top 5%) by comparing individual player values against calculated P95 thresholds within specific peer groups.

### 4. Data Quality & Defensive Coding
* **Anomaly Handling:** Explicitly filtered out data anomalies (e.g., excluding specific leagues like 'RU1' or 'UKR1' during conflict periods) to ensure analysis integrity.
* **Zero-Division Prevention:** Used `NULLIF(..., 0)` to prevent runtime errors in ROI calculations (Market Value / Points).
* **Schema Orchestration:** Designed reusable analytical layers using `CREATE OR REPLACE VIEW` to separate raw data processing from business-facing reporting.

### 5. Advanced Joins & Filtering
* **Multi-Condition Joins:** Performed complex joins on multiple keys (e.g., joining on Competition, Position, and Age Bucket simultaneously) to map players to their specific statistical peer groups.
* **Self-Join Logic:** Indirectly implemented through Window Functions (`LAG`) to validate "real" manager changes and exclude temporary stand-ins.

---

## 🚦 Getting Started


---


## 🌟 About Me
I am a **Data Analytics Enthusiast** focused on transforming complex sports datasets into actionable business intelligence. My expertise lies in leveraging **PostgreSQL 16** to architect end-to-end analytical solutions—from raw data ingestion to high-level KPI reporting.

* **Looking for:** Junior Data Analyst roles.
* **Tech I love:** SQL (PostgreSQL), Excel, Tableau
* **Fun Fact:** I chose the Transfermarkt dataset because I believe sports analytics is the ultimate test for handling temporal data and complex relational integrity.

📫 **Let's connect:** https://www.linkedin.com/in/rafal-rydzkowski-data/ | RafalRydzkowskiJ@gmail.com
