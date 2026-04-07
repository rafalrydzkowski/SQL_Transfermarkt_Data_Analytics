#  Market Outliers Analysis

## Analysis Overview

**Title**: Football Market Analytics - Elite Player Identification 
**Database**: `PostgreSQL 16+`  
**Schema**: `gold.`  
**Target Audience**: Scouting Staff

--- 

## Objectives

1.  **Business Analysis**: Identify "Market Outliers" (Top 5%) within specific groups.

---

## Analysis Structure

### 1. Methodology
This script builds a multi-layered analytical view to benchmark football player market values. It uses statistical percentiles (P5, Q1, Median, Q3, P95) to categorize players relative to their specific peer groups (League, Position, and Age Bucket).

### 2. SQL Implementation

#### 1. VIEW DEFINITION: Market Benchmarking Layer

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

#### 2. BUSINESS USAGE: The following SQL queries were developed to answer specific business questions

1. What are the 'Elite' players in current Bundesliga season (2025)?
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
**Findings:** 
| player_name | current_club_name | current_competition_id | position | age_bucket | market_value_in_eur | p95_value |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Said El Mala | 1. Fußball-Club Köln | L1 | ATTACK | 1. Prospect (<=21) | 40000000.00 | 17400000.00 |
| Bazoumana Touré | Turn- und Sportgemeinschaft 1899 Hoffenheim Fußball-Spielbetriebs | L1 | ATTACK | 1. Prospect (<=21) | 25000000.00 | 17400000.00 |
| Jean-Mattéo Bahoya | Eintracht Frankfurt Fußball AG | L1 | ATTACK | 1. Prospect (<=21) | 25000000.00 | 17400000.00 |
| Yan Diomande | RasenBallsport Leipzig | L1 | ATTACK | 1. Prospect (<=21) | 45000000.00 | 17400000.00 |
| Conrad Harder | RasenBallsport Leipzig | L1 | ATTACK | 1. Prospect (<=21) | 24000000.00 | 17400000.00 |
| Christian Kofane | Bayer 04 Leverkusen Fußball | L1 | ATTACK | 1. Prospect (<=21) | 22000000.00 | 17400000.00 |
| Antonio Nusa | RasenBallsport Leipzig | L1 | ATTACK | 1. Prospect (<=21) | 32000000.00 | 17400000.00 |
| Eliesse Ben Seghir | Bayer 04 Leverkusen Fußball | L1 | ATTACK | 1. Prospect (<=21) | 24000000.00 | 17400000.00 |
| Ernest Poku | Bayer 04 Leverkusen Fußball | L1 | ATTACK | 1. Prospect (<=21) | 20000000.00 | 17400000.00 |
| Nicolas Jackson | FC Bayern München | L1 | ATTACK | 2. Rising Star (22-25) | 45000000.00 | 28000000.00 |
| Michael Olise | FC Bayern München | L1 | ATTACK | 2. Rising Star (22-25) | 130000000.00 | 28000000.00 |
| Mohamed Amoura | Verein für Leibesübungen Wolfsburg | L1 | ATTACK | 2. Rising Star (22-25) | 32000000.00 | 28000000.00 |
| Fisnik Asllani | Turn- und Sportgemeinschaft 1899 Hoffenheim Fußball-Spielbetriebs | L1 | ATTACK | 2. Rising Star (22-25) | 30000000.00 | 28000000.00 |
| Fábio Silva | Borussia Dortmund | L1 | ATTACK | 2. Rising Star (22-25) | 28000000.00 | 28000000.00 |
| Karim Adeyemi | Borussia Dortmund | L1 | ATTACK | 2. Rising Star (22-25) | 60000000.00 | 28000000.00 |
| Maximilian Beier | Borussia Dortmund | L1 | ATTACK | 2. Rising Star (22-25) | 30000000.00 | 28000000.00 |
| Rômulo | RasenBallsport Leipzig | L1 | ATTACK | 2. Rising Star (22-25) | 30000000.00 | 28000000.00 |
| Jonathan Burkardt | Eintracht Frankfurt Fußball AG | L1 | ATTACK | 2. Rising Star (22-25) | 35000000.00 | 28000000.00 |
| Serhou Guirassy | Borussia Dortmund | L1 | ATTACK | 3. Peak (26-30) | 40000000.00 | 25000000.00 |
| Ritsu Doan | Eintracht Frankfurt Fußball AG | L1 | ATTACK | 3. Peak (26-30) | 25000000.00 | 25000000.00 |
| Patrik Schick | Bayer 04 Leverkusen Fußball | L1 | ATTACK | 3. Peak (26-30) | 25000000.00 | 25000000.00 |
| Luis Díaz | FC Bayern München | L1 | ATTACK | 3. Peak (26-30) | 70000000.00 | 25000000.00 |
| Harry Kane | FC Bayern München | L1 | ATTACK | 4. Mature (31-35) | 65000000.00 | 7000000.00 |
| Nnamdi Collins | Eintracht Frankfurt Fußball AG | L1 | DEFENDER | 1. Prospect (<=21) | 15000000.00 | 13000000.00 |
| Leopold Querfeld | 1. Fußballclub Union Berlin | L1 | DEFENDER | 1. Prospect (<=21) | 18000000.00 | 13000000.00 |
| El Chadaille Bitshiabu | RasenBallsport Leipzig | L1 | DEFENDER | 1. Prospect (<=21) | 15000000.00 | 13000000.00 |
| Noahkai Banks | Fußball-Club Augsburg 1907 | L1 | DEFENDER | 1. Prospect (<=21) | 15000000.00 | 13000000.00 |
| Luka Vuskovic | Hamburger Sport Verein | L1 | DEFENDER | 1. Prospect (<=21) | 40000000.00 | 13000000.00 |
| Finn Jeltsch | Verein für Bewegungsspiele Stuttgart 1893 | L1 | DEFENDER | 1. Prospect (<=21) | 25000000.00 | 13000000.00 |
| Karim Coulibaly | Sportverein Werder Bremen von 1899 | L1 | DEFENDER | 1. Prospect (<=21) | 20000000.00 | 13000000.00 |
| Loïc Badé | Bayer 04 Leverkusen Fußball | L1 | DEFENDER | 2. Rising Star (22-25) | 28000000.00 | 25000000.00 |
| Castello Lukeba | RasenBallsport Leipzig | L1 | DEFENDER | 2. Rising Star (22-25) | 45000000.00 | 25000000.00 |
| Alphonso Davies | FC Bayern München | L1 | DEFENDER | 2. Rising Star (22-25) | 50000000.00 | 25000000.00 |
| Konstantinos Koulierakis | Verein für Leibesübungen Wolfsburg | L1 | DEFENDER | 2. Rising Star (22-25) | 25000000.00 | 25000000.00 |
| Josip Stanisic | FC Bayern München | L1 | DEFENDER | 2. Rising Star (22-25) | 32000000.00 | 25000000.00 |
| Jarell Quansah | Bayer 04 Leverkusen Fußball | L1 | DEFENDER | 2. Rising Star (22-25) | 40000000.00 | 25000000.00 |
| Nathaniel Brown | Eintracht Frankfurt Fußball AG | L1 | DEFENDER | 2. Rising Star (22-25) | 35000000.00 | 25000000.00 |
| Alejandro Grimaldo | Bayer 04 Leverkusen Fußball | L1 | DEFENDER | 3. Peak (26-30) | 24000000.00 | 18000000.00 |
| Edmond Tapsoba | Bayer 04 Leverkusen Fußball | L1 | DEFENDER | 3. Peak (26-30) | 35000000.00 | 18000000.00 |
| Nico Schlotterbeck | Borussia Dortmund | L1 | DEFENDER | 3. Peak (26-30) | 55000000.00 | 18000000.00 |
| Julian Ryerson | Borussia Dortmund | L1 | DEFENDER | 3. Peak (26-30) | 20000000.00 | 18000000.00 |
| Waldemar Anton | Borussia Dortmund | L1 | DEFENDER | 3. Peak (26-30) | 18000000.00 | 18000000.00 |
| Hiroki Ito | FC Bayern München | L1 | DEFENDER | 3. Peak (26-30) | 18000000.00 | 18000000.00 |
| Min-jae Kim | FC Bayern München | L1 | DEFENDER | 3. Peak (26-30) | 25000000.00 | 18000000.00 |
| Dayot Upamecano | FC Bayern München | L1 | DEFENDER | 3. Peak (26-30) | 70000000.00 | 18000000.00 |
| Konrad Laimer | FC Bayern München | L1 | DEFENDER | 3. Peak (26-30) | 32000000.00 | 18000000.00 |
| Jonathan Tah | FC Bayern München | L1 | DEFENDER | 3. Peak (26-30) | 30000000.00 | 18000000.00 |
| David Raum | RasenBallsport Leipzig | L1 | DEFENDER | 3. Peak (26-30) | 20000000.00 | 18000000.00 |
| Maximilian Mittelstädt | Verein für Bewegungsspiele Stuttgart 1893 | L1 | DEFENDER | 3. Peak (26-30) | 18000000.00 | 18000000.00 |
| Emre Can | Borussia Dortmund | L1 | DEFENDER | 4. Mature (31-35) | 6000000.00 | 4250000.00 |
| Raphaël Guerreiro | FC Bayern München | L1 | DEFENDER | 4. Mature (31-35) | 6000000.00 | 4250000.00 |
| Matthias Ginter | Sport-Club Freiburg | L1 | DEFENDER | 4. Mature (31-35) | 6000000.00 | 4250000.00 |
| Willi Orbán | RasenBallsport Leipzig | L1 | DEFENDER | 4. Mature (31-35) | 6000000.00 | 4250000.00 |
| Mio Backhaus | Sportverein Werder Bremen von 1899 | L1 | GOALKEEPER | 1. Prospect (<=21) | 10000000.00 | 2500000.00 |
| Jonas Urbig | FC Bayern München | L1 | GOALKEEPER | 2. Rising Star (22-25) | 12000000.00 | 8000000.00 |
| Maarten Vandevoordt | RasenBallsport Leipzig | L1 | GOALKEEPER | 2. Rising Star (22-25) | 8000000.00 | 8000000.00 |
| Noah Atubolu | Sport-Club Freiburg | L1 | GOALKEEPER | 2. Rising Star (22-25) | 20000000.00 | 8000000.00 |
| Gregor Kobel | Borussia Dortmund | L1 | GOALKEEPER | 3. Peak (26-30) | 40000000.00 | 10000000.00 |
| Alexander Nübel | Verein für Bewegungsspiele Stuttgart 1893 | L1 | GOALKEEPER | 3. Peak (26-30) | 12000000.00 | 10000000.00 |
| Kamil Grabara | Verein für Leibesübungen Wolfsburg | L1 | GOALKEEPER | 3. Peak (26-30) | 12000000.00 | 10000000.00 |
| Finn Dahmen | Fußball-Club Augsburg 1907 | L1 | GOALKEEPER | 3. Peak (26-30) | 12000000.00 | 10000000.00 |
| Mark Flekken | Bayer 04 Leverkusen Fußball | L1 | GOALKEEPER | 4. Mature (31-35) | 8000000.00 | 5000000.00 |
| Manuel Neuer | FC Bayern München | L1 | GOALKEEPER | 5. Veteran (35<) | 4000000.00 | 4000000.00 |
| Can Uzun | Eintracht Frankfurt Fußball AG | L1 | MIDFIELD | 1. Prospect (<=21) | 45000000.00 | 15075000.00 |
| Jobe Bellingham | Borussia Dortmund | L1 | MIDFIELD | 1. Prospect (<=21) | 25000000.00 | 15075000.00 |
| Ezechiel Banzuzi | RasenBallsport Leipzig | L1 | MIDFIELD | 1. Prospect (<=21) | 18000000.00 | 15075000.00 |
| Brajan Gruda | RasenBallsport Leipzig | L1 | MIDFIELD | 1. Prospect (<=21) | 28000000.00 | 15075000.00 |
| Assan Ouédraogo | RasenBallsport Leipzig | L1 | MIDFIELD | 1. Prospect (<=21) | 28000000.00 | 15075000.00 |
| Lennart Karl | FC Bayern München | L1 | MIDFIELD | 1. Prospect (<=21) | 60000000.00 | 15075000.00 |
| Johan Manzambi | Sport-Club Freiburg | L1 | MIDFIELD | 1. Prospect (<=21) | 30000000.00 | 15075000.00 |
| Aleksandar Pavlovic | FC Bayern München | L1 | MIDFIELD | 1. Prospect (<=21) | 65000000.00 | 15075000.00 |
| Leon Avdullahu | Turn- und Sportgemeinschaft 1899 Hoffenheim Fußball-Spielbetriebs | L1 | MIDFIELD | 1. Prospect (<=21) | 17000000.00 | 15075000.00 |
| Ibrahim Maza | Bayer 04 Leverkusen Fußball | L1 | MIDFIELD | 1. Prospect (<=21) | 25000000.00 | 15075000.00 |
| Hugo Larsson | Eintracht Frankfurt Fußball AG | L1 | MIDFIELD | 1. Prospect (<=21) | 40000000.00 | 15075000.00 |
| Bilal El Khannouss | Verein für Bewegungsspiele Stuttgart 1893 | L1 | MIDFIELD | 1. Prospect (<=21) | 32000000.00 | 15075000.00 |
| Tom Bischof | FC Bayern München | L1 | MIDFIELD | 1. Prospect (<=21) | 40000000.00 | 15075000.00 |
| Kaishu Sano | 1. Fußball- und Sportverein Mainz 05 | L1 | MIDFIELD | 2. Rising Star (22-25) | 25000000.00 | 23000000.00 |
| Felix Nmecha | Borussia Dortmund | L1 | MIDFIELD | 2. Rising Star (22-25) | 45000000.00 | 23000000.00 |
| Carney Chukwuemeka | Borussia Dortmund | L1 | MIDFIELD | 2. Rising Star (22-25) | 25000000.00 | 23000000.00 |
| Malik Tillman | Bayer 04 Leverkusen Fußball | L1 | MIDFIELD | 2. Rising Star (22-25) | 35000000.00 | 23000000.00 |
| Equi Fernández | Bayer 04 Leverkusen Fußball | L1 | MIDFIELD | 2. Rising Star (22-25) | 25000000.00 | 23000000.00 |
| Jamal Musiala | FC Bayern München | L1 | MIDFIELD | 2. Rising Star (22-25) | 130000000.00 | 23000000.00 |
| Angelo Stiller | Verein für Bewegungsspiele Stuttgart 1893 | L1 | MIDFIELD | 2. Rising Star (22-25) | 45000000.00 | 23000000.00 |
| Exequiel Palacios | Bayer 04 Leverkusen Fußball | L1 | MIDFIELD | 3. Peak (26-30) | 30000000.00 | 22500000.00 |
| Joshua Kimmich | FC Bayern München | L1 | MIDFIELD | 3. Peak (26-30) | 40000000.00 | 22500000.00 |
| Marcel Sabitzer | Borussia Dortmund | L1 | MIDFIELD | 4. Mature (31-35) | 7000000.00 | 6500000.00 |
| Robert Andrich | Bayer 04 Leverkusen Fußball | L1 | MIDFIELD | 4. Mature (31-35) | 7000000.00 | 6500000.00 |
2. 
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
