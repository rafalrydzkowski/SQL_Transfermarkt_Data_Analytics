/*
--------------------------------------------------------------------------------
NAME:            Home Advantage & Stadium Fill Rate Analysis
PURPOSE:         Investigating the "12th Man" Effect: Does stadium fill rate 
                 impact home team win probability?
DESCRIPTION:     Used NTILE(5) partitioned by club_id to isolate the crowd 
                 effect from team quality. By comparing a club's performance 
                 at their peak attendance vs. their own low-attendance games, 
                 we eliminate the bias of top-tier teams always having full 
                 stadiums.
--------------------------------------------------------------------------------
*/

-- CTE: Calculate stadium fill rate and assign localized quintiles
-- Group games into 5 buckets PER CLUB to ensure fair comparison.
--      Bucket 1: The club's highest-attended games.
--      Bucket 5: The club's lowest-attended games.
WITH cte_stadium_performance AS (
    SELECT
        t.game_id,
        t.club_id,
        t.is_win,
        t.points,
        ROUND(t.attendance::NUMERIC / NULLIF(c.stadium_seats, 0)::NUMERIC, 3) AS fill_rate, -- Calculate the percentage of stadium capacity utilized
        NTILE(5) OVER (
            PARTITION BY t.club_id 
            ORDER BY (t.attendance::NUMERIC / NULLIF(c.stadium_seats, 0)::NUMERIC) DESC
        ) AS attendance_quintile_bucket -- assign quintiles
    FROM gold.fact_team_stats AS t
    INNER JOIN gold.dim_clubs AS c ON t.club_id = c.club_id
    WHERE
        t.is_home = TRUE 
        AND t.competition_id NOT IN ('RU1', 'UKR1') -- Excluded due to high data anomalies
        AND c.stadium_seats > 0 
        AND t.attendance <= c.stadium_seats -- Filters out data errors or neutral venue outliers
)

-- FINAL AGGREGATION: Analyzing win probability and average points per attendance quintile
SELECT
    attendance_quintile_bucket,
    ROUND(AVG(is_win::INT) * 100, 2) AS win_probability_pct, -- Win Probability: Average of boolean is_win converted to integer
    ROUND(AVG(points), 2) AS avg_points_per_game -- Points Performance: Average points earned per quintile
FROM cte_stadium_performance
GROUP BY attendance_quintile_bucket
ORDER BY attendance_quintile_bucket ASC;
/*
Findings: 
        The highest attendance quintile (Quintile 1) surprisingly shows 
        the lowest win probability (37.35%) and the lowest average points per game (1.36).
Hypothesis for these Findings: 
                Extremely high attendance (Quintile 1) might represent "high-stakes" games 
                Derbies, title deciders) where the home team faces immense psychological pressure 
                or plays against equally strong/stronger opponents who are also highly motivated.
*/
