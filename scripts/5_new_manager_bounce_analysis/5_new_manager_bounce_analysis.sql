/*
--------------------------------------------------------------------------------
NAME:            New Manager Bounce Effect Analysis
PURPOSE:         Determine if changing a manager mid-season results in a 
                 statistically significant performance improvement ("The Bounce").
DESCRIPTION:     This script identifies manager changes within a season,
                 calculates the Points Per Game (PPG) for the 5 matches 
                 immediately preceding and following the change, and 
                 categorizes the outcome.
LOGIC:
    1. Detects transitions where own_manager_name changes.
    2. Uses double-LAG validation to ignore temporary absences (e.g., illness).
    3. Requires the new manager to have coached at least 5 games.
    4. Calculates 5-game rolling averages for pre- and post-change performance.
--------------------------------------------------------------------------------
*/

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

-- FINAL OUTPUT:
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
