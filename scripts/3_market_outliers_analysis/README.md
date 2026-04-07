#  💸 Market Outliers Analysis

## Analysis Overview

**Title**: Football Market Analytics - Elite Player Identification                               
**Database**: `PostgreSQL 16+`  
**Schema**: `gold.`  
**Target Audience**: Scouting Staff

--- 

## Objectives

1.  **Business Analysis**: Identify "Market Outliers" (Top 5%) within specific groups.

---

## 1. Methodology
This script builds a multi-layered analytical view to benchmark football player market values. It uses statistical percentiles (P5, Q1, Median, Q3, P95) to categorize players relative to their specific peer groups (League, Position, and Age Bucket).

## 2. SQL Implementation

### 1. VIEW DEFINITION: Market Benchmarking Layer

- This view prepares a comprehensive dataset where every player's value is compared against the statistical distribution of their specific peer group.

```sql
CREATE OR REPLACE VIEW gold.vw_market_benchmark AS
-- CTE 1: Data Preparation and Career-Stage Categorization
-- Extracts core player metadata and assigns players to specific "Age Buckets" 
-- representing different stages of a professional football career.
WITH cte_bucket AS
(SELECT
    p.player_id, 
    p.name, 
    p.last_season, 
    p.position,
    p.current_club_id,
    p.current_club_name,
    p.current_club_domestic_competition_id AS current_competition_id,
    v.valuation_age,
    CASE
        WHEN v.valuation_age <= 21 THEN '1. Prospect (<=21)'
        WHEN v.valuation_age <= 25 THEN '2. Rising Star (22-25)'
        WHEN v.valuation_age <= 30 THEN '3. Peak (26-30)'
        WHEN v.valuation_age <= 35 THEN '4. Mature (31-35)'
        ELSE '5. Veteran (35<)' END AS age_bucket,
    v.market_value_in_eur,
    v.competition_id_at_valuation,
    v.is_current
FROM gold.dim_players AS p
LEFT JOIN gold.fact_player_valuations AS v
ON p.player_id = v.player_id
WHERE p.position <> 'MISSING'),

-- CTE 2: Statistical Distribution Calculation
-- Calculate statistical benchmarks per peer group
-- Peer group defined by: League, Position, and Career Stage (Age Bucket)
cte_percentile AS
(SELECT
    competition_id_at_valuation,
    position,
    age_bucket,
    PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY market_value_in_eur) AS p5_value,
    PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY market_value_in_eur) AS q1_quartile,
    PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY market_value_in_eur) AS median_value,
    PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY market_value_in_eur) AS q3_quartile,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY market_value_in_eur) AS p95_value
FROM cte_bucket
GROUP BY competition_id_at_valuation, position, age_bucket)

-- OUTPUT: Final Assembly with Peer Metrics
-- Joins raw player data with group-level benchmarks for granular comparison.
SELECT
    cb.player_id,
    cb.name AS player_name,
    cb.last_season,
    cb.current_club_id,
    cb.current_club_name,
    cb.current_competition_id,
    cb.position,
    cb.age_bucket,
    cb.market_value_in_eur,
    cp.p5_value::NUMERIC(16,2),
    cp.q1_quartile::NUMERIC(16,2),
    cp.median_value::NUMERIC(16,2),
    cp.q3_quartile::NUMERIC(16,2),
    cp.p95_value::NUMERIC(16,2)
FROM cte_bucket AS cb
LEFT JOIN cte_percentile AS cp
ON cb.current_competition_id = cp.competition_id_at_valuation AND cb.position = cp.position AND cb.age_bucket = cp.age_bucket
WHERE cb.is_current = TRUE
ORDER BY cb.current_competition_id, cb.current_club_name, cb.position, cb.age_bucket;
```

### 2. BUSINESS USAGE:

#### **1. What are the 'Elite' players in current Bundesliga season (2025)?**
   - Purpose: Isolate players in the top 5% of the market (Outliers)
   - Logic: Filter for the active players (2025 season) and players exceeding the P95 threshold
```sql
SELECT
    player_name,
    current_club_name,
    current_competition_id,
    position,
    age_bucket,
    market_value_in_eur,
    p95_value
FROM gold.vw_market_benchmark
WHERE 
    last_season = 2025 AND
    current_competition_id = 'L1' AND
    market_value_in_eur >= p95_value
ORDER BY position, age_bucket;
```

---

## How to Use

1. **Clone the Repository**: Clone this project repository from GitHub.
2. **Set Up the Database**: Run the SQL scripts provided in the [0_database_initialization](./scripts/0_database_initialization) file to create and populate the database.
3. **Run the Queries**: Use the SQL queries provided in the `3_market_outliers_analysis.sql` file to perform your analysis.
4. **Explore and Modify**: Feel free to modify the queries to explore different aspects of the dataset or answer additional business questions.
