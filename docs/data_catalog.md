# 📖 Data Catalog: Gold Layer (Star Schema)

This document provides a detailed description of the tables in the **Gold Layer**, which follows a Star Schema design optimized for football analytics and business intelligence.

---

## 🏗️ Dimension Tables

### 1. `gold.dim_competitions`
* **Purpose:** Stores master records for football competitions and leagues, providing metadata for tournament classification.
> **NOTE:** In the Gold Layer, the scope is strictly limited to **domestic league matches** from the **Top 14 leagues**. Domestic cups and European competitions (e.g., Champions League, Europa League) are excluded to ensure statistical consistency and focus on league performance.

* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **competition_id** | VARCHAR(20) | **Primary Key**. Unique identifier for the competition (e.g., 'L1', 'GB1'). |
| **name** | VARCHAR(100) | Official name of the league or tournament. |
| **type** | VARCHAR(50) | Competition category (e.g., 'domestic_league'). |
| **country_name** | VARCHAR(100) | The name of the country associated with the competition. |
| **url** | VARCHAR(255) | Direct source link to the competition profile on Transfermarkt. |

---

### 2. `gold.dim_clubs`
* **Purpose:** Stores comprehensive metadata for football clubs, including infrastructure details and competition affiliation.
> **NOTE:** In the Gold Layer, the scope is strictly limited to **domestic league matches** from the **Top 14 leagues** for the period from **2012 to the present**. The `last_season` column indicates the most recent year the club participated in a Top 14 league (e.g., a club that was relegated in 2019 and has not returned to the top league since will show 2019 as its `last_season`).

* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **club_id** | INT | **Primary Key**. Unique numerical identifier for each football club. |
| **club_code** | VARCHAR(100) | Alphanumeric short code representing the club. |
| **name** | VARCHAR(100) | Official name of the football club. |
| **competition_id** | VARCHAR(20) | **Foreign Key**. Unique ID of the domestic league (links to `gold.dim_competitions`). |
| **stadium_name** | VARCHAR(100) | Name of the club's home stadium. |
| **stadium_seats** | INT | Total spectator capacity of the stadium. |
| **last_season** | INT | The last season the club competed in a Top 14 domestic league (Range: 2012–Present). |
| **url** | VARCHAR(255) | Direct source link to the club profile on Transfermarkt. |

---

### 3. `gold.dim_games`
* **Purpose:** Provides detailed context for individual match fixtures, including technical setups and match-day metadata.
> **NOTE:** In the Gold Layer, the scope is strictly limited to **domestic league matches** from the **Top 14 leagues**. Domestic cups and European competitions (e.g., Champions League, Europa League) are excluded to ensure statistical consistency and focus on league performance.

* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **game_id** | INT | **Primary Key**. Unique identifier for the match fixture. |
| **competition_id** | VARCHAR(20) | **Foreign Key**. Unique ID of the competition (links to `gold.dim_competitions`). |
| **competition_type** | VARCHAR(50) | Type of competition (e.g., 'domestic_league'). |
| **season** | INT | Calendar year the season started (e.g., 2023). |
| **round** | VARCHAR(50) | Standardized matchday or round name (e.g., 'Matchday 05'). |
| **date** | DATE | The date the match was played. |
| **home_club_id** | INT | Unique identifier for the home team. |
| **home_club_name** | VARCHAR(100) | Official name of the home club. |
| **away_club_id** | INT | Unique identifier for the away team. |
| **away_club_name** | VARCHAR(100) | Official name of the away club. |
| **aggregate** | VARCHAR(20) | Aggregate score (used primarily in specific league formats). |
| **home_club_manager_name** | VARCHAR(50) | Name of the home team manager. |
| **away_club_manager_name** | VARCHAR(50) | Name of the away team manager. |
| **home_club_formation** | VARCHAR(50) | Tactical lineup used by the home team (e.g., '4-3-3'). |
| **away_club_formation** | VARCHAR(50) | Tactical lineup used by the away team. |
| **stadium** | VARCHAR(150) | Name of the stadium where the match took place. |
| **attendance** | INT | Total number of spectators present. |
| **referee** | VARCHAR(100) | Full name of the match official. |
| **url** | VARCHAR(255) | Direct source link to the match report on Transfermarkt. |

---

### 4. `gold.dim_players`
* **Purpose:** Comprehensive master data for football players, enriched with demographic attributes and technical profiles.
> **NOTE:** In the Gold Layer, the scope is strictly limited to **domestic league matches** from the **Top 14 leagues** for the period from **2012 to the present**. The `last_season` column indicates the most recent year the player was active in a Top 14 league.

* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **player_id** | INT | **Primary Key**. Unique identifier assigned to each player. |
| **first_name** | VARCHAR(100) | Player's given name. |
| **last_name** | VARCHAR(100) | Player's family name. |
| **name** | VARCHAR(255) | Full display name (Combined first and last name). |
| **last_season** | INT | The last season the player was registered in a Top 14 league. |
| **current_club_id** | INT | **Foreign Key**. Links to `gold.dim_clubs` (Current or last club from TOP14 Leagues). |
| **current_club_name** | VARCHAR(100) | Denormalized name of the player's current/last club for easier querying. |
| **current_club_domestic_competition_id** | VARCHAR(20) | ID of the domestic league where the player's club competes. |
| **country_of_birth** | VARCHAR(100) | Standardized name of the country where the player was born. |
| **city_of_birth** | VARCHAR(100) | City of birth. |
| **country_of_citizenship** | VARCHAR(100) | Primary nationality of the player. |
| **date_of_birth** | DATE | Player's birthday (YYYY-MM-DD). |
| **sub_position** | VARCHAR(50) | Specific tactical position (e.g., 'Centre-Forward', 'Left-Back'). |
| **position** | VARCHAR(50) | General field position (e.g., 'Attack', 'Defender'). |
| **foot** | VARCHAR(20) | Preferred kicking foot (Left, Right, Both). |
| **height_in_cm** | INT | Player's height measured in centimeters. |
| **market_value_in_eur** | NUMERIC(15,2) | Most recent estimated market value in Euros. |
| **highest_market_value_in_eur** | NUMERIC(15,2) | The peak market value achieved during the player's career. |
| **contract_expiration_date** | DATE | Expiry date of the current professional contract. |
| **agent_name** | VARCHAR(150) | Name of the agency or agent representing the player. |
| **image_url** | VARCHAR(255) | Link to the player's profile picture. |
| **url** | VARCHAR(255) | Direct source link to the player profile on Transfermarkt. |

---

## 📊 Fact Tables

### 1. `gold.fact_player_valuations`
* **Purpose:** A fact table tracking the historical evolution of player market values over time, allowing for trend analysis and career growth modeling.
> **NOTE:** In the Gold Layer, the scope is strictly limited to **domestic league matches** from the **Top 14 leagues** for the period from **2012 to the present**. Only valuation records associated with players active in these leagues during the specified timeframe are included.

* **Columns:**

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **valuation_id** | INT | **Primary Key**. Unique identifier assigned to each valuation. |
| **player_id** | INT | **Foreign Key**. Unique ID of the player (links to `gold.dim_players`). |
| **date_of_valuation** | DATE | The specific date when the market value was updated. |
| **valuation_age** | INT | The age of the player at the moment of valuation. |
| **club_id_at_valuation** | INT | The club the player was representing at the time of valuation (possibly Club outside TOP14 Leagues). |
| **competition_id_at_valuation** | VARCHAR(20) | The league the player was competing in at the time of valuation (possibly Competition outside TOP14). |
| **market_value_in_eur** | NUMERIC(15,2) | The estimated market value in Euros at that specific point in time. |
| **valuation_change_prev** | NUMERIC(15,2) | The numerical difference (increase/decrease) compared to the previous valuation. |
| **is_current** | BOOLEAN | Flag indicating if this is the most recent valuation for the player. |
| **is_highest_ever** | BOOLEAN | Flag identifying the peak career market value for the player. |

---

### 2. `gold.fact_transfers`
* **Purpose:** A fact table logging all professional transfer activities and loan moves, capturing financial details and movement between clubs/leagues.
> **NOTE:** This table includes transfers of players where player's last season in TOP14 leagues is current season (2025).

* **Columns:**
  
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **transfer_id** | INT | **Primary Key**. Unique identifier for the specific transfer event. |
| **player_id** | INT | **Foreign Key**. Unique ID of the player involved (links to `gold.dim_players`). |
| **transfer_date** | DATE | The official date the transfer was completed. |
| **transfer_season** | INT | The football season associated with the transfer (e.g., 2022). |
| **from_club_id** | INT | The selling/releasing club. |
| **from_competition_id** | VARCHAR(20) | The league of the origin club |
| **to_club_id** | INT | The buying/receiving club |
| **to_competition_id** | VARCHAR(20) | The league of the destination club |
| **transfer_fee** | NUMERIC(15,2) | The monetary value of the transfer in Euros. |
| **market_value_at_transfer** | NUMERIC(15,2) | The player's estimated market value at the time of the move. |
| **is_non_cash_transfer** | BOOLEAN | Flag indicating if the move was a free transfer, loan, or swap (Fee = 0). |
| **is_latest_transfer** | BOOLEAN | Flag identifying the most recent transfer record for the player. |
| **is_record_breaking_for_player** | BOOLEAN | Indicates if this fee is the highest ever paid for this specific player. |

---

### 3. `gold.fact_player_stats`
* **Purpose:** A highly granular fact table capturing individual player performance metrics for every match appearance. It serves as the foundation for player productivity and impact analysis.
> **NOTE:** In the Gold Layer, the scope is strictly limited to **domestic league matches** from the **Top 14 leagues** for the period from **2012 to the present**. This table contains over **1.4 million records**, representing every individual player "stint" on the pitch.

* **Columns:**
  
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **appearance_id** | VARCHAR(50) | **Primary Key**. Unique identifier for the specific player appearance in a game. |
| **game_id** | INT | **Foreign Key**. Links to `gold.dim_games`. |
| **competition_id** | VARCHAR(20) | **Foreign Key**. Links to `gold.dim_competitions`. |
| **season** | INT | The football season when the match occurred (e.g., 2023). |
| **date** | DATE | The date of the match. |
| **player_id** | INT | **Foreign Key**. Links to `gold.dim_players`. |
| **club_id** | INT | **Foreign Key**. The club the player represented in this match (links to `gold.dim_clubs`). |
| **opponent_id** | INT | **Foreign Key**. The ID of the opposing club. |
| **is_clean_sheet** | BOOLEAN | Indicates if the player's team conceded zero goals during the match. |
| **goals** | INT | Number of goals scored by the player in this match. |
| **assists** | INT | Number of assists provided by the player. |
| **yellow_cards** | INT | Number of yellow cards received (0, 1, or 2). |
| **red_cards** | INT | Number of red cards received (0 or 1). |
| **minutes_played** | INT | Total time spent on the pitch (capped/validated during ETL). |
| **player_number** | INT | The jersey number worn by the player in this game. |
| **position** | VARCHAR(50) | The specific tactical position played in this match. |
| **is_starting_lineup** | BOOLEAN | Flag: `TRUE` if the player started in the first XI. |
| **is_captain** | BOOLEAN | Flag: `TRUE` if the player wore the captain's armband. |
| **is_home** | BOOLEAN | Flag: `TRUE` if the player's club was the home team. |
| **is_win** | BOOLEAN | Flag: `TRUE` if the player's team won the match. |

---

### 4. `gold.fact_team_stats`
* **Purpose:** An aggregated fact table focusing on team-level performance per match. It simplifies the analysis of league tables, managerial head-to-heads, and stadium utilization.
> **NOTE:** In the Gold Layer, the scope is strictly limited to **domestic league matches** from the **Top 14 leagues** for the period from **2012 to the present**. This table provides a dual-entry grain (two rows per `game_id`), allowing for direct filtering by `club_id`.

* **Columns:**
  
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **game_id** | INT | **Composite Primary Key / Foreign Key**. Links to `gold.dim_games`. |
| **club_id** | INT | **Composite Primary Key / Foreign Key**. Links to `gold.dim_clubs`. |
| **date** | DATE | The date the match was played. |
| **season** | INT | The football season (e.g., 2023). |
| **competition_id** | VARCHAR(20) | Unique ID of the competition's league. |
| **opponent_id** | INT | Unique ID of the opposing club. |
| **own_manager_name** | VARCHAR(50) | Name of the manager leading the team in this match. |
| **opponent_manager_name** | VARCHAR(50) | Name of the manager leading the opposing team. |
| **own_goals** | INT | Goals scored by the team. |
| **opponent_goals** | INT | Goals conceded by the team. |
| **goal_difference** | INT | Calculated as `own_goals - opponent_goals`. |
| **own_position** | INT | League table position of the team before the match. |
| **opponent_position** | INT | League table position of the opponent before the match. |
| **position_diff** | INT | The gap in league standings between the two teams. |
| **attendance** | INT | Number of spectators in the stadium. |
| **is_home** | BOOLEAN | Flag: `TRUE` if the team was playing at their home stadium. |
| **is_clean_sheet** | BOOLEAN | Flag: `TRUE` if the team conceded zero goals. |
| **is_win** | BOOLEAN | Flag: `TRUE` if the team won the match. |
| **is_draw** | BOOLEAN | Flag: `TRUE` if the match ended in a draw. |
| **is_loss** | BOOLEAN | Flag: `TRUE` if the team lost the match. |
| **points** | INT | Points earned from the match (3 for Win, 1 for Draw, 0 for Loss). |

---
