# 🏟️ Stadium Fill Rate Analysis Analysis

## Analysis Overview

**Title**: `2_stadium_fill_rate_analysis`                   
**Database**: `PostgreSQL 16+`  
**Schema**: `gold.`  
**Target Audience**: Sports Psychologists/Coaching Staff & Sports Betting Analysts

--- 

## Objectives

1.  **Business Analysis**: Investigating the "12th Man" Effect: Does stadium fill rate impact home team win probability?

---

## 1. Methodology
Used NTILE(5) partitioned by club_id to isolate the crowd effect from team quality. By comparing a club's performance  at their peak attendance vs. their own low-attendance games, we eliminate the bias of top-tier teams always having full stadiums.

## 2. SQL Implementation

This query calculate stadium fill rate and assign localized quintiles. 
Group games into 5 buckets PER CLUB to ensure fair comparison:
- Bucket 1: The club's highest-attended games.
- Bucket 5: The club's lowest-attended games.
  
```sql
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
        ) AS attendance_quintile -- assign quintiles
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
    attendance_quintile,
    ROUND(AVG(is_win::INT) * 100, 2) AS win_probability_pct, -- Win Probability: Average of boolean is_win converted to integer
    ROUND(AVG(points), 2) AS avg_points_per_game -- Points Performance: Average points earned per quintile
FROM cte_stadium_performance
GROUP BY attendance_quintile
ORDER BY attendance_quintile ASC;
```
  
**Findings:** 

| attendance_quintile_bucket | win_probability_pct | avg_points_per_game | 
| :--- | :--- | :--- |
| **1** | 37.35 | 1.36 | 
| **2** | 44.76 | 1.59 | 
| **3** | 47.79 | 1.69 | 
| **4** | 48.04 | 1.70 | 
| **5** | 47.40 | 1.68 | 
- The highest attendance quintile (Quintile 1) surprisingly shows the lowest win probability (37.35%) and the lowest average points per game (1.36).

---

## Conclusion
- **The "Opponent Quality" Bias:** High-attendance fixtures (Quintile 1) are strongly correlated with top-tier opponents. In these games, the home advantage might be statistically offset by the higher technical quality and tactical discipline of the visiting team (e.g., 'Big Six' matchups), leading to a lower win probability despite the crowd support.

---

## How to Use

1. **Clone the Repository**: Clone this project repository from GitHub.
2. **Set Up the Database**: Run the SQL scripts provided in the [0_database_initialization](./scripts/0_database_initialization) file to create and populate the database.
3. **Run the Queries**: Use the SQL queries provided in the `2_stadium_fill_rate_analysis.sql` file to perform your analysis.
4. **Explore and Modify**: Feel free to modify the queries to explore different aspects of the dataset or answer additional business questions.
