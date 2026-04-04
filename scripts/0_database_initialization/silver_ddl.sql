/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================

Database Schema: Silver Layer (Standardized & Validated)

Purpose: 
    Defines the table structure for the Silver Layer. This schema 
    stores cleansed, typed, and validated data derived from the Bronze layer.

Indexing Strategy (Performance Optimization):
    Indexes are implemented to accelerate the Silver-to-Gold transformation 
    and support high-performance analytical queries.

Note: 
    This script drops existing 'silver' tables before re-creating them. 
    Use with caution.
===============================================================================
*/

-- ------------------------------------------------------------------
-- Table: silver.competitions
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS silver.competitions;

CREATE TABLE silver.competitions 
(
    competition_id              VARCHAR(20) NOT NULL,
    competition_code            VARCHAR(50) NOT NULL,
    name                        VARCHAR(100) NOT NULL,
    sub_type                    VARCHAR(50),
    type                        VARCHAR(50),
    country_id                  INT,
    country_name                VARCHAR(100),
    domestic_league_code        VARCHAR(20),
    confederation               VARCHAR(50),
    is_major_national_league    BOOLEAN,
    url                         VARCHAR(255),
    dwh_inserted_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_competitions PRIMARY KEY (competition_id)
);

-- ------------------------------------------------------------------
-- Table: silver.games
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS silver.games;

CREATE TABLE silver.games (
    game_id                 INT NOT NULL,
    competition_id          VARCHAR(20) NOT NULL,
    season                  INT NOT NULL,
    round                   VARCHAR(50),
    date                    DATE NOT NULL,
    home_club_id            INT NOT NULL,
    away_club_id            INT NOT NULL,
    home_club_goals         INT,
    away_club_goals         INT,
    home_club_position      INT,
    away_club_position      INT,
    home_club_manager_name  VARCHAR(50),
    away_club_manager_name  VARCHAR(50),
    stadium                 VARCHAR(150),
    attendance              INT,
    referee                 VARCHAR(100),
    url                     VARCHAR(255),
    home_club_formation     VARCHAR(50),
    away_club_formation     VARCHAR(50),
    home_club_name          VARCHAR(100),
    away_club_name          VARCHAR(100),
    aggregate               VARCHAR(20), 
    competition_type        VARCHAR(50),
    dwh_inserted_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_games PRIMARY KEY (game_id)
);

-- Indexes:
CREATE INDEX idx_games__competition_id ON silver.games (competition_id);
CREATE INDEX idx_games__home_club_id ON silver.games (home_club_id);
CREATE INDEX idx_games__away_club_id ON silver.games (away_club_id);

-- ------------------------------------------------------------------
-- Table: silver.clubs
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS silver.clubs;

CREATE TABLE silver.clubs (
    club_id                     INT NOT NULL,
    club_code                   VARCHAR(100) NOT NULL,
    name                        VARCHAR(100) NOT NULL,
    competition_id              VARCHAR(20) NOT NULL, -- Renamed from domestic_competition_id
    squad_size                  INT,
    average_age                 NUMERIC(4,2),
    foreigners_number           INT,
    foreigners_percentage       NUMERIC(5,2),
    national_team_players       INT,
    stadium_name                VARCHAR(100),
    stadium_seats               INT,
    net_transfer_record_eur     NUMERIC(15,2),
    coach_name                  VARCHAR(100),
    last_season                 INT,
    url                         VARCHAR(255),
    filename                    VARCHAR(255),
    dwh_inserted_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_clubs PRIMARY KEY (club_id)
);

-- Index:
CREATE INDEX idx_clubs__competition_id ON silver.clubs (competition_id);

-- ------------------------------------------------------------------
-- Table: silver.club_games
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS silver.club_games;

CREATE TABLE silver.club_games (
    game_id                 INT NOT NULL,
    club_id                 INT NOT NULL,
    own_goals               INT,
    own_position            INT,
    own_manager_name        VARCHAR(100),
    opponent_id             INT,
    opponent_goals          INT,
    opponent_position       INT,
    opponent_manager_name   VARCHAR(100),
    is_home                 BOOLEAN, -- Converted from 'hosting'
    is_win                  BOOLEAN, 
    dwh_inserted_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_club_games PRIMARY KEY (game_id, club_id)
);

-- Indexes:
CREATE INDEX idx_club_games__game_id ON silver.club_games (game_id);
CREATE INDEX idx_club_games__club_id ON silver.club_games (club_id);
CREATE INDEX idx_club_games__opponent_id ON silver.club_games (opponent_id);
-- Indexes prepared for joins in gold layer to create gold.fact_player_stats and gold.fact_team_stats
CREATE INDEX idx_club_games__game_club ON silver.club_games (game_id, club_id);

-- ------------------------------------------------------------------
-- Table: silver.players
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS silver.players;

CREATE TABLE silver.players (
    player_id                   INT NOT NULL,
    first_name                  VARCHAR(100),
    last_name                   VARCHAR(100),
    name                        VARCHAR(255),
    last_season                 INT,
    current_club_id             INT,
    current_club_name           VARCHAR(100),
    current_club_domestic_competition_id VARCHAR(20),
    player_code                 VARCHAR(100),
    country_of_birth            VARCHAR(100),
    city_of_birth               VARCHAR(100),
    country_of_citizenship      VARCHAR(100),
    date_of_birth               DATE,
    sub_position                VARCHAR(50),
    position                    VARCHAR(50),
    foot                        VARCHAR(20),
    height_in_cm                INT,
    market_value_in_eur         NUMERIC(15, 2),
    highest_market_value_in_eur NUMERIC(15, 2),
    contract_expiration_date    DATE,
    agent_name                  VARCHAR(150),
    image_url                   VARCHAR(255),
    url                         VARCHAR(255),
    dwh_inserted_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_players PRIMARY KEY (player_id)
);

-- Indexes:
CREATE INDEX idx_players__current_club_id ON silver.players (current_club_id);
CREATE INDEX idx_players__last_season ON silver.players (last_season);
CREATE INDEX idx_players__competition_id ON silver.players (current_club_domestic_competition_id);

-- ------------------------------------------------------------------
-- Table: silver.appearances
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS silver.appearances;

CREATE TABLE silver.appearances (
    appearance_id           VARCHAR(50) NOT NULL,
    game_id                 INT NOT NULL,
    date                    DATE,
    competition_id          VARCHAR(20) NOT NULL,
    player_id               INT NOT NULL,
    player_name             VARCHAR(255),
    club_id                 INT NOT NULL,
    goals                   INT,
    assists                 INT,
    yellow_cards            INT,
    red_cards               INT,
    minutes_played          INT,
    dwh_inserted_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_appearances PRIMARY KEY (appearance_id)
);

-- Indexes:
CREATE INDEX idx_appearances__game_id ON silver.appearances (game_id);
CREATE INDEX idx_appearances__player_id ON silver.appearances (player_id);
CREATE INDEX idx_appearances__club_id ON silver.appearances (club_id);

-- ------------------------------------------------------------------
-- Table: silver.game_events
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS silver.game_events;

CREATE TABLE silver.game_events
(
    game_event_id       VARCHAR(100) NOT NULL,
    date                DATE,
    game_id             INT NOT NULL,
    minute              INT,
    type                VARCHAR(50),
    club_id             INT NOT NULL,
    club_name           VARCHAR(100),
    player_id           INT NOT NULL,
    description         TEXT,
    player_in_id        INT,
    player_assist_id    INT,
    dwh_inserted_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_game_events PRIMARY KEY (game_event_id)
);

-- Indexes:
CREATE INDEX idx_events__game_id ON silver.game_events (game_id);
CREATE INDEX idx_events__player_id ON silver.game_events (player_id);
CREATE INDEX idx_events__club_id ON silver.game_events (club_id);

-- ------------------------------------------------------------------
-- Table: silver.game_lineups
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS silver.game_lineups;

CREATE TABLE silver.game_lineups (
    game_lineups_id         VARCHAR(50) NOT NULL,
    date                    DATE,
    game_id                 INT NOT NULL,
    player_id               INT NOT NULL,
    club_id                 INT NOT NULL,
    player_name             VARCHAR(100),
    number                  INT,
    position                VARCHAR(100),
    is_starting_lineup      BOOLEAN,
    is_captain              BOOLEAN,
    dwh_inserted_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_game_lineups PRIMARY KEY (game_lineups_id)
);

-- Indexes:
CREATE INDEX idx_lineups__game_id ON silver.game_lineups (game_id);
CREATE INDEX idx_lineups__player_id ON silver.game_lineups (player_id);
CREATE INDEX idx_lineups__club_id ON silver.game_lineups (club_id);

-- Indexes prepared for joins in gold layer to create gold.fact_player_stats
CREATE INDEX idx_lineups_game_player ON silver.game_lineups (game_id, player_id);

-- ------------------------------------------------------------------
-- Table: silver.player_valuations
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS silver.player_valuations;

CREATE TABLE silver.player_valuations (
    valuation_id                        BIGINT GENERATED ALWAYS AS IDENTITY,
    player_id                           INT NOT NULL,
    date                                DATE NOT NULL,
    market_value_in_eur                 NUMERIC(15, 2),
    current_club_name                   VARCHAR(100),
    current_club_id                     INT,
    player_club_domestic_competition_id VARCHAR(20),
    dwh_inserted_at                     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_player_valuations PRIMARY KEY (valuation_id)
);

-- Indexes:
CREATE INDEX idx_valuations__player_id ON silver.player_valuations (player_id);
CREATE INDEX idx_valuations__date ON silver.player_valuations (date);
CREATE INDEX idx_valuations__club_id ON silver.player_valuations (current_club_id);

-- ------------------------------------------------------------------
-- Table: silver.transfers
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS silver.transfers;

CREATE TABLE silver.transfers
(
    transfer_id         BIGINT GENERATED ALWAYS AS IDENTITY,
    player_id           INT NOT NULL,
    transfer_date       DATE,
    transfer_season     INT,
    from_club_id        INT,
    to_club_id          INT,
    from_club_name      VARCHAR(100),
    to_club_name        VARCHAR(100),
    transfer_fee        NUMERIC(15,2),
    market_value_in_eur NUMERIC(15,2),
    player_name         VARCHAR(255),
    dwh_inserted_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_transfers PRIMARY KEY (transfer_id)
);

-- Indexes:
CREATE INDEX idx_transfers__player_id ON silver.transfers (player_id);
CREATE INDEX idx_transfers__from_club_id ON silver.transfers (from_club_id);
CREATE INDEX idx_transfers__to_club_id ON silver.transfers (to_club_id);