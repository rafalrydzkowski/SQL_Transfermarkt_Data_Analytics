#  🏠🏟️ Home Advantage Analysis 

## Analysis Overview

**Title**: Home vs Away Advantage Analysis                                    
**Database**: `PostgreSQL 16+`  
**Schema**: `gold.`  
**Target Audience**: Match Analysts, Coaching Staff & Sports Betting Analysts

--- 

## Objectives

1. **Quantify the Home/Away Delta:** Calculate the statistical difference in Win Probability, Goal Difference and Points Per Game (PPG) between home and away matches.
2. **League-Wide Benchmarking:** Determine which leagues (e.g., Premier League vs. La Liga) exhibit the strongest "Home Advantage" effect to identify regional trends in football dynamics.
3. **Identify "Home Strongholds" vs. "Away Specialists":** Rank clubs based on their reliance on home performance to identify which teams' success is most (or least) dependent on their own stadium environment.

---

## Analysis Structure

### 1. Methodology
Aggregating performance metrics (Win Rate, PPG, Goals) across all leagues, grouped by the 'is_home' flag.

### 2. SQL Implementation

#### 1. Do teams perform better at their home games than on the away games?

```sql
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
```

**Findings:** 
  
| match_location | win_rate_pct | avg_points | avg_goals_scored | avg_goals_conceded | avg_goal_diff |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Home** | 44.60 | 1.59 | 1.54 | 1.21 | 0.32 |
| **Away** | 30.37 | 1.16 | 1.21 | 1.54 | -0.32 |

- **Significant Performance Gap:** Home teams demonstrate a clear competitive advantage, with a win rate of 44.60% compared to 30.37% for away teams—a substantial spread of 14.23 percentage points.
- **Goal Efficiency:** On average, playing at home team has 0.32 more goals scored per match while reducing goals conceded by the same margin, resulting in a positive goal differential (+0.32) vs. a defensive deficit away (-0.32).
- **Points Per Game (PPG):** The home advantage translates into an average of 1.59 points per game, which is 37% higher than the away average of 1.16 PPG, highlighting the critical role of stadium environment in season-long standings.

#### 2. Are there any teams that perform better at away games than at home games?

```sql
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
```

**Findings:** 
- There are 15 teams in the dataset that perform better away than home (e.g. Ipswich Town in Premier League: home avg ppg = 0.27, away avg ppg = 0.9)

#### 3. What are the 3 “strongest home fortress” (percentage of home games with no losses) for each league?

```sql
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
```

**Findings:** 
- For example TOP 3 “strongest home fortress” in Spain are: 1. Atletico Madrid (no_loss_pct = 91.57%), 2. Real Madrid (no_loss_pct = 91.15%), 3. FC Barcelona (no_loss_pct = 90.77%)

#### 4. Do referees struggle to handle the pressure from the crowd and tend to show fewer cards to the home team than to the away team?

```sql
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
```

**Findings:** 
| match_location | avg_yellow_cards_received | avg_red_cards_received |
| :--- | :--- | :--- |
| Home Team | 1.89 | 0.050 |
| Away Team | 2.18 | 0.057 |
- Home Teams receive on average 0.29 yellow cards less and 0.007 red cards less than away teams

---

## Conclusion
- 
---

## How to Use

1. **Clone the Repository**: Clone this project repository from GitHub.
2. **Set Up the Database**: Run the SQL scripts provided in the [0_database_initialization](./scripts/0_database_initialization) file to create and populate the database.
3. **Run the Queries**: Use the SQL queries provided in the `4_home_advantage_analysis.sql` file to perform your analysis.
4. **Explore and Modify**: Feel free to modify the queries to explore different aspects of the dataset or answer additional business questions.
