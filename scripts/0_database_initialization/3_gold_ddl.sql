/*
===============================================================================

Database Schema: Gold Layer

DDL Script: Create Gold Tables

Script Purpose:
    This script creates tables for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each table performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

League-Only Focus: 
    The Gold Layer aggregates league data only. 
    Domestic cup matches are excluded to avoid statistical noise and ensure that 
    all player/club metrics are derived from a consistent level of competition.

Structure:
    1. DIMENSION Tables:
        - dim_players
        - dim_clubs
        - dim_competitions
        - dim_games
    2. FACT Tables:
        - fact_player_stats
        - fact_team_stats
        - fact_player_valuations
        - fact_transfers

Usage:
    - These tables can be queried directly for analytics and reporting.

===============================================================================
*/

--------------------------------------------------------------------
-- Create Dimension: gold.dim_competitions
--------------------------------------------------------------------

DROP TABLE IF EXISTS gold.dim_competitions;

CREATE TABLE gold.dim_competitions 
(
    competition_id  VARCHAR(20) NOT NULL,
    name            VARCHAR(100) NOT NULL,
    type            VARCHAR(50),
    country_name    VARCHAR(100),
    url             VARCHAR(255),
    
    CONSTRAINT pk_competitions PRIMARY KEY (competition_id)
);

--------------------------------------------------------------------
-- Create Dimension: gold.dim_games
--------------------------------------------------------------------

DROP TABLE IF EXISTS gold.dim_games;

CREATE TABLE gold.dim_games (
    game_id                 INT NOT NULL,
    competition_id          VARCHAR(20) NOT NULL,
    competition_type        VARCHAR(50),
    season                  INT NOT NULL,
    round                   VARCHAR(50),
    date                    DATE NOT NULL,
    home_club_id            INT NOT NULL,
    home_club_name          VARCHAR(100),
    away_club_id            INT NOT NULL,
    away_club_name          VARCHAR(100),
    aggregate               VARCHAR(20),
    home_club_manager_name  VARCHAR(50),
    away_club_manager_name  VARCHAR(50),
    home_club_formation     VARCHAR(50),
    away_club_formation     VARCHAR(50),
    stadium                 VARCHAR(150),
    attendance              INT,
    referee                 VARCHAR(100),
    url                     VARCHAR(255),
    
    CONSTRAINT pk_games PRIMARY KEY (game_id),
    CONSTRAINT fk_gold_games_competitions 
        FOREIGN KEY (competition_id) 
        REFERENCES gold.dim_competitions (competition_id)
        ON DELETE RESTRICT
);

-- Indexes:
CREATE INDEX idx_games__competition_id ON gold.dim_games (competition_id);
CREATE INDEX idx_games__home_club_id ON gold.dim_games (home_club_id);
CREATE INDEX idx_games__away_club_id ON gold.dim_games (away_club_id);

--------------------------------------------------------------------
-- Create Dimension: gold.dim_clubs
--------------------------------------------------------------------

DROP TABLE IF EXISTS gold.dim_clubs;

CREATE TABLE gold.dim_clubs (
    club_id                     INT NOT NULL,
    club_code                   VARCHAR(100) NOT NULL,
    name                        VARCHAR(100) NOT NULL,
    competition_id              VARCHAR(20) NOT NULL, 
    stadium_name                VARCHAR(100),
    stadium_seats               INT,
    last_season                 INT,
    url                         VARCHAR(255),
    
    CONSTRAINT pk_clubs PRIMARY KEY (club_id),
    CONSTRAINT fk_gold_clubs_competition 
        FOREIGN KEY (competition_id) 
        REFERENCES gold.dim_competitions (competition_id)
        ON DELETE RESTRICT
);

-- Index:
CREATE INDEX idx_clubs__competition_id ON gold.dim_clubs (competition_id);

--------------------------------------------------------------------
-- Create Dimension: gold.dim_players
--------------------------------------------------------------------

DROP TABLE IF EXISTS gold.dim_players;

CREATE TABLE gold.dim_players (
    player_id                   INT NOT NULL,
    first_name                  VARCHAR(100),
    last_name                   VARCHAR(100),
    name                        VARCHAR(255),
    last_season                 INT,
    current_club_id             INT,
    current_club_name           VARCHAR(100),
    current_club_domestic_competition_id VARCHAR(20),
    country_of_birth            VARCHAR(100),
    city_of_birth               VARCHAR(100),
    country_of_citizenship      VARCHAR(100),
    date_of_birth               DATE,
    sub_position                VARCHAR(50),
    position                    VARCHAR(50),
    foot                        VARCHAR(20),
    height_in_cm                INT,
    market_value_in_eur         NUMERIC(15,2),
    highest_market_value_in_eur NUMERIC(15,2),
    contract_expiration_date    DATE,
    agent_name                  VARCHAR(150),
    image_url                   VARCHAR(255),
    url                         VARCHAR(255),
    
    CONSTRAINT pk_players PRIMARY KEY (player_id),
    CONSTRAINT fk_gold_players_clubs
        FOREIGN KEY (current_club_id) 
        REFERENCES gold.dim_clubs (club_id)
        ON DELETE RESTRICT
);

-- Indexes:
CREATE INDEX idx_players__current_club_id ON gold.dim_players (current_club_id);
CREATE INDEX idx_players__position ON gold.dim_players (position);
CREATE INDEX idx_players__last_season ON gold.dim_players (last_season);
CREATE INDEX idx_players__competition_id ON gold.dim_players (current_club_domestic_competition_id);

--------------------------------------------------------------------
-- Create Fact Table: gold.fact_player_valuations
--------------------------------------------------------------------

DROP TABLE IF EXISTS gold.fact_player_valuations;

CREATE TABLE gold.fact_player_valuations (
    valuation_id                INT NOT NULL,
    player_id                   INT NOT NULL,
    valuation_age               INT,
    date_of_valuation           DATE NOT NULL,
    club_id_at_valuation        INT,
    competition_id_at_valuation VARCHAR(20),
    market_value_in_eur         NUMERIC(15, 2),
    valuation_change_prev       NUMERIC(15,2),
    is_current                  BOOLEAN,
    is_highest_ever             BOOLEAN,
    
    CONSTRAINT pk_player_valuations PRIMARY KEY (valuation_id),
    CONSTRAINT fk_gold_player_valuations_players
        FOREIGN KEY (player_id) 
        REFERENCES gold.dim_players (player_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_gold_player_valuations_clubs
        FOREIGN KEY (club_id_at_valuation) 
        REFERENCES gold.dim_clubs (club_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_gold_player_valuations_competitions
        FOREIGN KEY (competition_id_at_valuation) 
        REFERENCES gold.dim_competitions (competition_id)
        ON DELETE RESTRICT
);

-- Indexes:
CREATE INDEX idx_valuations__player_id ON gold.fact_player_valuations (player_id);
CREATE INDEX idx_valuations__date ON gold.fact_player_valuations (date_of_valuation);
CREATE INDEX idx_valuations__club_id ON gold.fact_player_valuations (club_id_at_valuation);

--------------------------------------------------------------------
-- Create Fact Table: gold.fact_transfers
--------------------------------------------------------------------

DROP TABLE IF EXISTS gold.fact_transfers;

CREATE TABLE gold.fact_transfers
(
    transfer_id                     INT NOT NULL,
    player_id                       INT NOT NULL,
    transfer_date                   DATE,
    transfer_season                 INT,
    from_club_id                    INT,
    from_competition_id             VARCHAR(20),
    to_club_id                      INT,
    to_competition_id               VARCHAR(20),
    transfer_fee                    NUMERIC(15,2),
    market_value_at_transfer        NUMERIC(15,2),
    is_non_cash_transfer            BOOLEAN,
    is_latest_transfer              BOOLEAN,
    is_record_breaking_for_player   BOOLEAN,

    CONSTRAINT pk_transfers PRIMARY KEY (transfer_id),
    CONSTRAINT fk_gold_transfers_players
        FOREIGN KEY (player_id) 
        REFERENCES gold.dim_players (player_id)
        ON DELETE RESTRICT
);

-- Indexes:
CREATE INDEX idx_fact_transfers__player_id ON gold.fact_transfers (player_id);
CREATE INDEX idx_fact_transfers__from_club_id ON gold.fact_transfers (from_club_id);
CREATE INDEX idx_fact_transfers__to_club_id ON gold.fact_transfers (to_club_id);
CREATE INDEX idx_fact_transfers__transfer_season ON gold.fact_transfers (transfer_season);

--------------------------------------------------------------------
-- Create Fact Table: gold.fact_player_stats
--------------------------------------------------------------------

DROP TABLE IF EXISTS gold.fact_player_stats;

CREATE TABLE gold.fact_player_stats
(
    appearance_id           VARCHAR(50) NOT NULL,
    game_id                 INT NOT NULL,
    competition_id          VARCHAR(20) NOT NULL,
    season                  INT,
    date                    DATE,
    player_id               INT NOT NULL,
    club_id                 INT NOT NULL,
    opponent_id             INT,
    is_clean_sheet          BOOLEAN,
    goals                   INT,
    assists                 INT,
    yellow_cards            INT,
    red_cards               INT,
    minutes_played          INT,
    player_number           INT,
    position                VARCHAR(50), 
    is_starting_lineup      BOOLEAN,
    is_captain              BOOLEAN,
    is_home                 BOOLEAN,
    is_win                  BOOLEAN,

    CONSTRAINT pk_player_stats PRIMARY KEY (appearance_id),
    CONSTRAINT fk_gold_player_stats_players
        FOREIGN KEY (player_id) 
        REFERENCES gold.dim_players (player_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_gold_player_stats_games
        FOREIGN KEY (game_id) 
        REFERENCES gold.dim_games (game_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_gold_player_stats_clubs
        FOREIGN KEY (club_id) 
        REFERENCES gold.dim_clubs (club_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_gold_player_stats_competitions
        FOREIGN KEY (competition_id) 
        REFERENCES gold.dim_competitions(competition_id)
        ON DELETE RESTRICT
);

-- Indexes:
CREATE INDEX idx_gold_player_stats__season ON gold.fact_player_stats (season);
CREATE INDEX idx_gold_player_stats__player_id ON gold.fact_player_stats (player_id);
CREATE INDEX idx_gold_player_stats__club_id ON gold.fact_player_stats (club_id);
CREATE INDEX idx_gold_player_stats__competition_id ON gold.fact_player_stats (competition_id);

--------------------------------------------------------------------
-- Create Fact Table: gold.fact_team_stats
--------------------------------------------------------------------

DROP TABLE IF EXISTS gold.fact_team_stats;

CREATE TABLE gold.fact_team_stats
(
    game_id                 INT NOT NULL,
    date                    DATE,
    season                  INT,
    competition_id          VARCHAR(20),
    club_id                 INT NOT NULL,
    opponent_id             INT NOT NULL,
    own_manager_name        VARCHAR(50),
    opponent_manager_name   VARCHAR(50),
    own_goals               INT,
    opponent_goals          INT,
    goal_difference         INT,
    own_position            INT,
    opponent_position       INT,
    position_diff           INT,
    attendance              INT,
    is_home                 BOOLEAN,
    is_clean_sheet          BOOLEAN,
    is_win                  BOOLEAN,
    is_draw                 BOOLEAN,
    is_loss                 BOOLEAN,
    points                  INT,

    CONSTRAINT pk_team_stats PRIMARY KEY (game_id,club_id),
    CONSTRAINT fk_gold_team_stats_games
        FOREIGN KEY (game_id) 
        REFERENCES gold.dim_games (game_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_gold_team_stats_clubs
        FOREIGN KEY (club_id) 
        REFERENCES gold.dim_clubs (club_id)
        ON DELETE RESTRICT
);

-- Indexes:
CREATE INDEX idx_gold_team_stats__season ON gold.fact_team_stats (season);
CREATE INDEX idx_gold_team_stats__competition_id ON gold.fact_team_stats (competition_id);
CREATE INDEX idx_gold_team_stats__game_id ON gold.fact_team_stats (game_id);
CREATE INDEX idx_gold_team_stats__club_id ON gold.fact_team_stats (club_id);
