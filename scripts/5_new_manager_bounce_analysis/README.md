# ⚽️💶 New Manager Bounce Effect Analysis 

## Analysis Overview

**Title**: `5_new_manager_bounce_effect_analysis.sql`  
**Database**: `PostgreSQL 16+`  
**Schema**: `gold.`  
**Target Audience**: Club Sporting Directors

--- 

## Objectives

1. Determine if changing a manager mid-season results in a statistically significant performance improvement ("The Bounce").

---

## Analysis Structure

### 1. Methodology
This script identifies manager changes within a season, calculates the Points Per Game (PPG) for the 5 matches immediately preceding and following the change, and categorizes the outcome.
#### Logic:
1. Detects transitions where own_manager_name changes.
2. Uses double-LAG validation to ignore temporary absences (e.g., illness).
3. Requires the new manager to have coached at least 5 games.
4. Calculates 5-game rolling averages for pre- and post-change performance.
    
### 2. SQL Implementation



#### 1. VIEW DEFINITION: 

- This VIEW prepares a data-driven framework to evaluate if mid-season manager change lead to genuine statistical improvement

```sql
CREATE OR REPLACE VIEW gold.vw_manager_bounce_effect AS
-- CTE 1:
WITH cte_manager AS
(SELECT
    game_id,
	competition_id,
	club_id,
	season,
	date,
	own_manager_name AS new_manager,
	-- Identify the previous manager
	LAG(own_manager_name,1) OVER(PARTITION BY club_id, season ORDER BY date) AS previous_manager,
	-- Manager tenure validation (must have at least 5 games in the season)
	COUNT(own_manager_name) OVER(PARTITION BY club_id, season, own_manager_name) AS manager_games_in_season,
	-- Change Detection Flags
    -- is_new_manager: Simple change detection
    -- is_real_change: Validates against a 2-game lag to ensure it wasn't a temporary stand-in
	own_manager_name != LAG(own_manager_name,1) OVER(PARTITION BY club_id, season ORDER BY date) AS is_new_manager,
	own_manager_name != LAG(own_manager_name,2) OVER(PARTITION BY club_id, season ORDER BY date) AS is_real_change,
	-- Pre-Change Performance: Average points of the 5 games BEFORE the new manager took over
	ROUND(AVG(points) OVER(PARTITION BY club_id, season ORDER BY date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING)::NUMERIC,2) AS ppg_last_5_pre_change,
	-- Post-Change Performance: Average points of the FIRST 5 games under the new manager
	ROUND(AVG(points) OVER(PARTITION BY club_id, season ORDER BY date ROWS BETWEEN CURRENT ROW AND 4 FOLLOWING)::NUMERIC,2) AS ppg_first_5_post_change
FROM gold.fact_team_stats)

-- VIEW FINAL OUTPUT:
SELECT
	competition_id,
	club_id,
	season,
	date AS first_game_date,
	new_manager,
	previous_manager,
	ppg_first_5_post_change,
	ppg_last_5_pre_change,
	(ppg_first_5_post_change - ppg_last_5_pre_change) AS ppg_diff,
	-- Statistical significance: identifies how a specific manager's impact ranks 
	-- against historical transitions (e.g., a 95.00 rank indicates a top 5% bounce)
	ROUND((PERCENT_RANK() OVER(ORDER BY (ppg_first_5_post_change - ppg_last_5_pre_change)))::NUMERIC, 4) * 100 AS bounce_percentile_rank,
	-- Categorization of the "Bounce Effect"
	-- Classifies ppg_diff into 'Success - Significant Bounce', 'No Effect - Neutral' or 'Failure - Performance Decline' based on a +/- 0.5 PPG threshold.
    CASE 
        WHEN (ppg_first_5_post_change - ppg_last_5_pre_change) > 0.5 THEN 'Success - Significant Bounce'
        WHEN (ppg_first_5_post_change - ppg_last_5_pre_change) BETWEEN -0.5 AND 0.5 THEN 'No Effect - Neutral'
        ELSE 'Failure - Performance Decline' END AS bounce_category
FROM cte_manager
WHERE 
	is_new_manager = TRUE AND
	is_real_change = TRUE AND
	manager_games_in_season >= 5
ORDER BY competition_id, season DESC, first_game_date DESC;
```

#### 2. BUSINESS USAGE: The following SQL queries were developed to answer specific business questions

1. Does the 'New Manager Bound Effect' actually works?
```sql
SELECT
	'New Manager' AS type,
	ROUND(AVG(ppg_first_5_post_change),3) AS avg_ppg_post_change,
	ROUND(AVG(ppg_last_5_pre_change),3) AS avg_ppg_pre_change,
	ROUND(AVG(ppg_first_5_post_change) - AVG(ppg_last_5_pre_change),3) AS ppg_diff
FROM gold.vw_manager_bounce_effect;
```
**Findings:**
| type | avg_ppg_post_change | avg_ppg_pre_change | ppg_diff |
| :--- | :--- | :--- | :--- |
| New Manager | 1.246 | 0.766 | 0.479 |
- Following a managerial change, clubs experience a substantial performance increase, with average points per game rising from 0.766 to 1.246 (0.479 ppg diff)

2. In which leagues (e.g., Premier League vs La Liga vs Bundesliga VS Serie A) does a manager change most often result in the “Success - Significant Bounce” category?
```sql
SELECT
	competition_id,
	ROUND((success_count::NUMERIC/total_count::NUMERIC)*100,2) AS success_percentage,
	ROUND((no_effect_count::NUMERIC/total_count::NUMERIC)*100,2) AS no_effect_percentage,
	ROUND((failure_count::NUMERIC/total_count::NUMERIC)*100,2) AS failure_percentage
FROM
(SELECT
	competition_id,
	COUNT(CASE WHEN bounce_category = 'Success - Significant Bounce' THEN 1 END) AS success_count,
	COUNT(CASE WHEN bounce_category = 'No Effect - Neutral' THEN 1 END) AS no_effect_count,
	COUNT(CASE WHEN bounce_category = 'Failure - Performance Decline' THEN 1 END) AS failure_count,
	COUNT(*) AS total_count
FROM gold.vw_manager_bounce_effect
WHERE competition_id IN('L1','GB1','ES1','IT1')
GROUP BY competition_id)
ORDER BY success_percentage DESC;
```
**Findings:** 
| competition_id | success_percentage | no_effect_percentage | failure_percentage |
| :--- | :--- | :--- | :--- |
| L1 | 65.38 | 31.73 | 2.88 |
| IT1 | 54.61 | 36.17 | 9.22 |
| GB1 | 53.27 | 39.25 | 7.48 |
| ES1 | 51.91 | 38.93 | 9.16 |
- The German Bundesliga (L1) exhibits the highest responsiveness to coaching changes, with 65.38% success rate for "Significant Bounce" and the lowest failure rate in the sample (2.88%).
- The Spanish LaLiga (ES1) exhibits the lowest responsiveness to coaching changes, with 51.91% success rate for "Significant Bounce" and the second highest failure rate in the sample (9.16%).

3. 3. Which specific managers (managed at least 3 times) have historically achieved the highest average ppg_diff in their careers?
```sql
SELECT
	new_manager,
	ROUND(AVG(ppg_diff),3) AS avg_ppg_diff,
	COUNT(*) AS new_manager_count
FROM gold.vw_manager_bounce_effect
GROUP BY new_manager
HAVING COUNT(*) >= 3
ORDER BY avg_ppg_diff DESC
LIMIT 10;
```
**Findings:** 
| new_manager | avg_ppg_diff | new_manager_count |
| :--- | :--- | :--- |
| Burak Yılmaz | 1.400 | 3 |
| Luís Castro | 1.333 | 3 |
| Eugenio Corini | 1.250 | 4 |
| Aurelio Andreazzoli | 1.200 | 3 |
| Mesut Bakkal | 1.163 | 9 |
| Sami Uğurlu | 1.150 | 4 |
| Voro | 1.133 | 3 |
| Claude Puel | 1.133 | 3 |
| Javi Gracia | 1.133 | 3 |
| Pascal Dupraz | 1.117 | 3 |
-


4. What are TOP 5 "Firefighters" (managed at least 3 times) in Bundesliga?
```sql
SELECT
	competition_id,
	new_manager,
	ROUND(AVG(ppg_diff),3) AS avg_ppg_diff,
	COUNT(*) AS new_manager_count
FROM gold.vw_manager_bounce_effect
WHERE competition_id = 'L1'
GROUP BY competition_id, new_manager
HAVING COUNT(*) >= 3
ORDER BY avg_ppg_diff DESC, new_manager_count DESC
LIMIT 5;
```
**Findings:** 
| competition_id | new_manager | avg_ppg_diff | new_manager_count |
| :--- | :--- | :--- | :--- |
| L1 | Dieter Hecking | 0.733 | 3 |
| L1 | Tayfun Korkut | 0.650 | 4 |
| L1 | Huub Stevens | 0.600 | 4 |
| L1 | Manuel Baum | 0.600 | 3 |
| L1 | Markus Gisdol | 0.467 | 3 |
-

---

## Conclusion
-
---

## How to Use

1. **Clone the Repository**: Clone this project repository from GitHub.
2. **Set Up the Database**: Run the SQL scripts provided in the [0_database_initialization](./scripts/0_database_initialization) file to create and populate the database.
3. **Run the Queries**: Use the SQL queries provided in the `1_squad_capital_efficiency_analysis.sql` file to perform your analysis.
4. **Explore and Modify**: Feel free to modify the queries to explore different aspects of the dataset or answer additional business questions.
