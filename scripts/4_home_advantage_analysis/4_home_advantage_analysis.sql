/*
--------------------------------------------------------------------------------
NAME:            Home vs Away Advantage Analysis
PURPOSE:         Quantifying the statistical gap between playing at home 
                 versus playing away (The "Home Field Advantage" effect).
DESCRIPTION:     Aggregating performance metrics (Win Rate, PPG, Goals) 
                 across all leagues, grouped by the 'is_home' flag.
--------------------------------------------------------------------------------
*/

-- Do teams perform better at their home games than on the away games?

SELECT
    CASE WHEN is_home = TRUE THEN 'Home' ELSE 'Away' END AS match_location,
    Round(AVG(is_win::INT)*100,2) AS win_rate_pct,
    ROUND(AVG(points),2) AS avg_points,
    ROUND(AVG(own_goals),2) AS avg_goals_scored,
    ROUND(AVG(opponent_goals),2) AS avg_goals_conceded,
    ROUND(AVG(own_goals - opponent_goals), 2) AS avg_goal_diff
FROM gold.fact_team_stats
WHERE competition_id <> 'UKR1' -- Filter out anomalies (e.g., Ukraine League: many home games played at neutral/away venues)
GROUP BY is_home
ORDER BY win_rate_pct DESC;

-- In which league home game advantage is the biggest?

SELECT
    c.competition_id AS competition_id,
    c.name AS league_name,
    c.country_name AS league_country,
    ROUND(AVG(CASE WHEN ts.is_home = TRUE THEN ts.is_win::INT END)*100,2) AS home_win_rate_pct,
    ROUND(AVG(CASE WHEN ts.is_home = FALSE THEN ts.is_win::INT END)*100,2) AS away_win_rate_pct,
    ROUND(AVG(CASE WHEN ts.is_home = TRUE THEN ts.points END) - AVG(CASE WHEN ts.is_home = FALSE THEN ts.points END),2) AS avg_points_diff
FROM gold.fact_team_stats AS ts
LEFT JOIN gold.dim_competitions AS c
ON ts.competition_id = c.competition_id
WHERE ts.competition_id <> 'UKR1' -- Filter out anomalies (e.g., Ukraine League: many home games played at neutral/away venues)
GROUP BY c.competition_id, c.country_name, c.name
ORDER BY avg_points_diff DESC
LIMIT 3;

-- Are there any teams that perform better at away games than at home games?

SELECT
    ts.club_id,
    cl.club_code AS club_name,
    ROUND(AVG(CASE WHEN ts.is_home = TRUE THEN ts.points END),2) AS home_avg_points,
    ROUND(AVG(CASE WHEN ts.is_home = FALSE THEN ts.points END),2) AS away_avg_points,
    ROUND(AVG(CASE WHEN ts.is_home = FALSE THEN ts.points END) - AVG(CASE WHEN ts.is_home = TRUE THEN ts.points END),2) AS avg_points_diff
FROM gold.fact_team_stats AS ts
LEFT JOIN gold.dim_clubs AS cl
ON ts.club_id = cl.club_id
WHERE ts.competition_id <> 'UKR1' -- Filter out anomalies (e.g., Ukraine League: many home games played at neutral/away venues)
GROUP BY ts.club_id, cl.club_code
HAVING (AVG(CASE WHEN ts.is_home = FALSE THEN ts.points END) - AVG(CASE WHEN ts.is_home = TRUE THEN ts.points END)) > 0
ORDER BY avg_points_diff DESC;

-- What are the 3 “strongest home fortress” (percentage of home games with no losses) for each league?

WITH cte_rate AS
(
SELECT
    ts.competition_id,
    ts.club_id,
    cl.club_code AS club_name,
    AVG(CASE WHEN ts.is_home = TRUE THEN ts.is_win::INT END) + AVG(CASE WHEN ts.is_home = TRUE THEN ts.is_draw::INT END) AS no_loss_rate,
    COUNT(CASE WHEN ts.is_home = TRUE THEN ts.is_home::INT END) AS home_games_count
FROM gold.fact_team_stats AS ts
LEFT JOIN gold.dim_clubs AS cl
ON ts.club_id = cl.club_id
WHERE ts.competition_id <> 'UKR1' -- Filters anomalies (e.g., Ukraine League: many home games played at neutral/away venues)
GROUP BY ts.competition_id, ts.club_id, cl.club_code
HAVING COUNT(CASE WHEN ts.is_home = TRUE THEN ts.is_home::INT END) >= 10 -- Filters teams that have played at least 10 home games
)
SELECT
    fortress_rank,
    competition_id,
    club_name,
    ROUND(no_loss_rate*100,2) AS no_loss_pct,
    home_games_count
FROM 
    (SELECT
        *,
        RANK() OVER(PARTITION BY competition_id ORDER BY no_loss_rate DESC) AS fortress_rank
    FROM cte_rate) AS sub_rank
WHERE fortress_rank <= 3
ORDER BY competition_id, fortress_rank;

-- Do referees struggle to handle the pressure from the crowd and tend to show fewer cards to the home team than to the away team?

WITH cte_cards AS
(
SELECT
    game_id,
    club_id,
    SUM(yellow_cards) AS total_yellow_cards,
    SUM(red_cards) AS total_red_cards
FROM gold.fact_player_stats
WHERE competition_id <> 'UKR1' -- Filter out anomalies
GROUP BY game_id, club_id
)
SELECT
    CASE WHEN ts.is_home = TRUE THEN 'Home Team' ELSE 'Away Team' END AS match_location,
    ROUND(AVG(c.total_yellow_cards),2) AS avg_yellow_cards_received,
    ROUND(AVG(c.total_red_cards),3) AS avg_red_cards_received
FROM gold.fact_team_stats AS ts
LEFT JOIN cte_cards AS c
ON ts.game_id = c.game_id AND ts.club_id = c.club_id
WHERE ts.competition_id <> 'UKR1' -- Filter out anomalies
GROUP BY ts.is_home
ORDER BY ts.is_home DESC;
