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

#### 1. 

- 

```sql

```

#### 2. 

-

```sql

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
- 
---

## How to Use

1. **Clone the Repository**: Clone this project repository from GitHub.
2. **Set Up the Database**: Run the SQL scripts provided in the [0_database_initialization](./scripts/0_database_initialization) file to create and populate the database.
3. **Run the Queries**: Use the SQL queries provided in the `1_squad_capital_efficiency_analysis.sql` file to perform your analysis.
4. **Explore and Modify**: Feel free to modify the queries to explore different aspects of the dataset or answer additional business questions.
