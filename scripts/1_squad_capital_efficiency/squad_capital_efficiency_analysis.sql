/*
--------------------------------------------------------------------------------
NAME:            Squad Capital Efficiency (SCE) Analysis
PURPOSE:         Investigating the capital efficiency for each club in season 2025
DESCRIPTION:     Calculates the 'Market Value Cost per Point' (ROI) for clubs 
                 during the 2025 season. This identifies "Moneyball" overperformers 
                 by measuring how efficiently a club converts market value into 
                 league points.
BUSINESS QUESTIONS:
    1. What are TOP 3 the best performing and the worst performing teams in Bundesliga?
    2. Are there any teams that have points average higher than the competition one 
        and they are in TOP 3 'Capital Efficient'?
--------------------------------------------------------------------------------
*/

-- =============================================================================
-- 1. VIEW DEFINITION: Squad Capital Efficiency Layer
-- =============================================================================
-- This view prepares a comprehensive dataset where every team's 
-- 'Market Value Cost per Point' (ROI) is compared against their league.

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

-- =============================================================================
-- 2. BUSINESS USAGE
-- =============================================================================

-- 1. What are TOP 3 the best performing and the worst performing teams in Bundesliga?
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

-- 2. Are there any teams that have points average higher than the competition one and they are in TOP 3 'Capital Efficient'?

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
