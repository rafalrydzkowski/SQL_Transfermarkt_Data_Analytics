# ⚽️ Squad Capital Efficiency Analysis 💶

## Analysis Overview

**Title**: Squad Capital Efficiency (SCE) - Season 2025  
**Database**: `PostgreSQL 16+`  
**Schema**: `gold.`  
**Target Audience**: Club Sporting Directors & Financial Analysts  

--- 

## Objectives

1.  **Business Analysis**: Evaluate the **Capital Efficiency (ROI)** of football clubs for the 2025 season.
2.  **Financial KPI**: Identify overperformers by calculating the **Cost per Point** (Market Value in M€ / Total League Points).

---

## Analysis Structure

### 1. Methodology
We join player-level valuations with match-day performance metrics. To ensure accuracy, we don't just take the , latest,  valuation; we use a window function to find the valuation record closest to the player's first appearance in the 2025 season for that specific club to avoid market volatility bias.

### 2. SQL Implementation

The following production-grade query identifies which clubs are most efficient at converting market value into league points.

#### 1. VIEW DEFINITION: Squad Capital Efficiency Layer

- This view prepares a comprehensive dataset where every team's 'Market Value Cost per Point' (ROI) is compared against their league.

```sql
CREATE OR REPLACE VIEW gold.vw_squad_capital_efficiency AS
-- CTE 1: Calculates the current squad for the 2025 season
-- Filters out specific competitions (e.g., 'RU1') per business requirements
WITH cte_stats AS (
    SELECT
        club_id,
        player_id,
        MIN(date) AS first_game
    FROM gold.fact_player_stats
    WHERE 
        season = 2025 AND 
        competition_id <> 'RU1'
    GROUP BY club_id, player_id
),

-- CTE 2: It calculates a player's market value and ranks which valuation 
-- is closest to the date of the player's first match (player in the lineup for the game, doesn't need to play a minute) for the club that season
-- rank_date = 1: the most accurate player valuation
cte_rank AS (
    SELECT 
        s.club_id,
        s.player_id,
        ROW_NUMBER() OVER(PARTITION BY s.club_id, s.player_id ORDER BY ABS(s.first_game - v.date_of_valuation) ASC, v.date_of_valuation ASC) AS rank_date, -- We provide a ranking based on the player's rating closest to their first game of the season with the team
        v.market_value_in_eur
    FROM cte_stats AS s
    LEFT JOIN gold.fact_player_valuations AS v
    ON s.player_id = v.player_id
),

-- CTE 3: Aggregate total points earned per club
-- Filters out specific competitions (e.g., 'RU1') per business requirements
cte_points AS
(
SELECT
    club_id,
    SUM(points) AS total_points
FROM gold.fact_team_stats
WHERE 
    season = 2025 AND 
    competition_id <> 'RU1'
GROUP BY club_id
),

-- CTE 4: Calculate total market value for club in season 2025
cte_market_value AS
(SELECT
    p.club_id,
    p.total_points,
    SUM(r.market_value_in_eur) AS total_market_value
FROM cte_points AS p
LEFT JOIN cte_rank AS r
ON p.club_id = r.club_id
WHERE r.rank_date = 1
GROUP BY p.club_id, p.total_points)

-- VIEW Final Output: Which clubs manage thier capital the most efficient comparing to league?
SELECT
    c.competition_id,
    c.name AS league_name,
    RANK() OVER(PARTITION BY c.competition_id ORDER BY ((v.total_market_value/1000000)/NULLIF(v.total_points,0)) ASC) AS efficiency_rank,
    cl.club_code AS club_name,
    v.total_points,
    ROUND(v.total_market_value/1000000,2) AS total_market_value_in_mln,
    ROUND((v.total_market_value/1000000)/NULLIF(v.total_points,0),2) AS cost_per_point_in_mln,
    ROUND(AVG(v.total_points) OVER(PARTITION BY c.competition_id),2) AS avg_league_total_points
FROM cte_market_value AS v
LEFT JOIN gold.dim_clubs AS cl
ON v.club_id = cl.club_id
LEFT JOIN gold.dim_competitions AS c
ON cl.competition_id = c.competition_id
ORDER BY c.competition_id, efficiency_rank;
```

#### 2. BUSINESS USAGE: The following SQL queries were developed to answer specific business questions

1. What are TOP 3 the best performing and the worst performing teams in Bundesliga?
```sql
(SELECT
    league_name,
    'TOP 3 BEST PERFORMERS' AS type,
    efficiency_rank,
    club_name,
    cost_per_point_in_mln
FROM gold.vw_squad_capital_efficiency
WHERE 
    competition_id = 'L1'
ORDER BY efficiency_rank
LIMIT 3)

UNION ALL

(SELECT
    league_name,
    'TOP 3 WORST PERFORMERS' AS type,
    efficiency_rank,
    club_name,
    cost_per_point_in_mln
FROM gold.vw_squad_capital_efficiency
WHERE 
    competition_id = 'L1'
ORDER BY efficiency_rank DESC
LIMIT 3)
ORDER BY efficiency_rank;
```
**Findings:** 
- TOP 3 best performing teams are: FC St. Pauli (2.6 mln € per point), TSG 1899 Hoffenheim (3.43 mln € per point) & Hamburger SV (4.16 mln € per point)
- TOP 3 worst performing teams are: Eintracht Frankfurt (12.23 mln € per point), FC Bayern Munchen (14.44 mln € per point) & VFL Wolfsburg (14.62 mln € per point)
  
2. Are there any teams that have points average higher than the competition one and they are in TOP 3 'Capital Efficient'?
```sql
SELECT
    league_name,
    'TOP 3 BEST PERFORMERS' AS type,
    efficiency_rank,
    club_name,
    total_points,
    avg_league_total_points,
    cost_per_point_in_mln
FROM gold.vw_squad_capital_efficiency
WHERE
    efficiency_rank <= 3 AND
    total_points > avg_league_total_points;
```
**Findings:** 

| league_name | type | efficiency_rank | club_name | total_points | avg_league_total_points | cost_per_point_in_mln | 
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| JUPILER PRO LEAGUE | TOP 3 BEST PERFORMERS | 3 | vv-st-truiden | 57 | 38.25 | 0.61 | 
| SUPERLIGAEN | TOP 3 BEST PERFORMERS | 1 | sonderjyske | 36 | 30.75 | 0.40 | 
| PREMIER LEAGUE | TOP 3 BEST PERFORMERS | 1 | afc-sunderland | 40 | 39.85 | 8.70 | 
| PREMIER LEAGUE | TOP 3 BEST PERFORMERS | 2 | fc-brentford | 44 | 39.85 | 9.63 | 
| PREMIER LEAGUE | TOP 3 BEST PERFORMERS | 3 | fc-everton | 43 | 39.85 | 10.25 | 
| SUPER LEAGUE 1 | TOP 3 BEST PERFORMERS | 1 | apo-levadiakos | 39 | 33.00 | 0.32 | 
| BUNDESLIGA | TOP 3 BEST PERFORMERS | 2 | tsg-1899-hoffenheim | 49 | 34.50 | 3.43 | 
| LIGA PORTUGAL BWIN | TOP 3 BEST PERFORMERS | 1 | gil-vicente-fc | 41 | 34.11 | 0.75 | 
| LIGA PORTUGAL BWIN | TOP 3 BEST PERFORMERS | 2 | moreirense-fc | 35 | 34.11 | 0.76 | 
| SCOTTISH PREMIERSHIP | TOP 3 BEST PERFORMERS | 1 | falkirk-fc | 42 | 39.25 | 0.12 | 
| SCOTTISH PREMIERSHIP | TOP 3 BEST PERFORMERS | 2 | motherwell-fc | 53 | 39.25 | 0.18 | 
| SUPER LIG | TOP 3 BEST PERFORMERS | 1 | goztepe | 42 | 33.56 | 0.94 | 

---

## Conclusion
- **Valuation Precision:** Standard yearly averages in football data often suffer from "valuation drift." By implementing a closest-date matching logic via ABS(s.first_game - v.date_of_valuation), this model ensures that the ROI is calculated based on the most accurate market sentiment at the moment a player actually impacts the squad.
- **The "Efficiency Gap":** In the Bundesliga, the difference between the most and least efficient clubs is staggering. FC St. Pauli (2.6M €/pt) vs. VfL Wolfsburg (14.6M €/pt) demonstrates that capital alone does not guarantee points; Wolfsburg pays nearly 6x more for the same result on the pitch.
- **Moneyball Candidates:** Query #2 identifies the "Golden Subset"—clubs that are not only financially efficient (Top 3 in CpP) but also competitively superior (Total Points > League Average). Teams like FC Brentford (Premier League) and Gil Vicente (Liga Portugal) represent the peak of modern football management: high sporting output with low capital risk.
- **Risk Mitigation:** This framework allows Sporting Directors to set a "Target CpP" for their league. If a club's CpP is significantly higher than the league average (e.g., Bayern München at 14.44M €/pt), they must justify it through Champions League revenue or global brand equity; otherwise, it signals a high-risk financial model.

---

## How to Use

1. **Clone the Repository**: Clone this project repository from GitHub.
2. **Set Up the Database**: Run the SQL scripts provided in the [0_database_initialization](./scripts/0_database_initialization) file to create and populate the database.
3. **Run the Queries**: Use the SQL queries provided in the `1_squad_capital_efficiency_analysis.sql` file to perform your analysis.
4. **Explore and Modify**: Feel free to modify the queries to explore different aspects of the dataset or answer additional business questions.
