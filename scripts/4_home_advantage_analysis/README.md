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

- 

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

#### 2. 

-

```sql

```

**Findings:** 


---

## Conclusion
- 
---

## How to Use

1. **Clone the Repository**: Clone this project repository from GitHub.
2. **Set Up the Database**: Run the SQL scripts provided in the [0_database_initialization](./scripts/0_database_initialization) file to create and populate the database.
3. **Run the Queries**: Use the SQL queries provided in the `4_home_advantage_analysis.sql` file to perform your analysis.
4. **Explore and Modify**: Feel free to modify the queries to explore different aspects of the dataset or answer additional business questions.
