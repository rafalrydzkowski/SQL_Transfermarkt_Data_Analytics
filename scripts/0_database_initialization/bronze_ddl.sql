/*
===============================================================================

Database Schema: Bronze Layer

Purpose: 
    This script initializes the 'bronze' schema by creating raw landing tables 
    for football-related data (players, clubs, games, events, etc.). 
    The Bronze layer acts as a Landing Zone where data is ingested in its 
    original format with minimal transformations to ensure data lineage.

===============================================================================
*/

-- ------------------------------------------------------------------
-- Table: bronze.appearances
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.appearances;

CREATE TABLE bronze.appearances 
(
    appearance_id           TEXT,
    game_id                 INT,
    player_id               INT,
    player_club_id          INT,
    player_current_club_id  INT,
    date                    DATE,
    player_name             TEXT,
    competition_id          TEXT,
    yellow_cards            INT,
    red_cards               INT,
    goals                   INT,
    assists                 INT,
    minutes_played          INT
);

-- ------------------------------------------------------------------
-- Table: bronze.club_games
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.club_games;

CREATE TABLE bronze.club_games
(
    game_id                 INT,
    club_id                 INT,
    own_goals               INT,
    own_position            INT,
    own_manager_name        TEXT,
    opponent_id             INT,
    opponent_goals          INT,
    opponent_position       INT,
    opponent_manager_name   TEXT,
    hosting                 TEXT,
    is_win                  INT
);

-- ------------------------------------------------------------------
-- Table: bronze.clubs
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.clubs;

CREATE TABLE bronze.clubs
(
    club_id                 INT,
    club_code               TEXT,
    name                    TEXT,
    domestic_competition_id TEXT,
    total_market_value      NUMERIC,
    squad_size              INT,
    average_age             NUMERIC,
    foreigners_number       INT,
    foreigners_percentage   NUMERIC,
    national_team_players   INT,
    stadium_name            TEXT,
    stadium_seats           INT,
    net_transfer_record     TEXT,
    coach_name              TEXT,
    last_season             TEXT,
    filename                TEXT,
    url                     TEXT
);

-- ------------------------------------------------------------------
-- Table: bronze.competitions
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.competitions;

CREATE TABLE bronze.competitions
(
    competition_id          TEXT,
    competition_code        TEXT,
    name                    TEXT,
    sub_type                TEXT,
    type                    TEXT,
    country_id              INT,
    country_name            TEXT,
    domestic_league_code    TEXT,
    confederation           TEXT,
    url                     TEXT,
    is_major_national_league TEXT
);

-- ------------------------------------------------------------------
-- Table: bronze.game_events
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.game_events;

CREATE TABLE bronze.game_events
(
    game_event_id       TEXT,
    date                DATE,
    game_id             INT,
    minute              INT,
    type                TEXT,
    club_id             INT,
    club_name           TEXT,
    player_id           INT,
    description         TEXT,
    player_in_id        INT,
    player_assist_id    INT
);

-- ------------------------------------------------------------------
-- Table: bronze.game_lineups
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.game_lineups;

CREATE TABLE bronze.game_lineups
(
    game_lineups_id TEXT,
    date            DATE,
    game_id         INT,
    player_id       INT,
    club_id         INT,
    player_name     TEXT,
    type            TEXT,
    position        TEXT,
    number          TEXT,
    team_captain    INT
);

-- ------------------------------------------------------------------
-- Table: bronze.games
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.games;

CREATE TABLE bronze.games
(
    game_id                 INT,
    competition_id          TEXT,
    season                  INT,
    round                   TEXT,
    date                    DATE,
    home_club_id            INT,
    away_club_id            INT,
    home_club_goals         INT,
    away_club_goals         INT,
    home_club_position      INT,
    away_club_position      INT, 
    home_club_manager_name  TEXT,
    away_club_manager_name  TEXT,
    stadium                 TEXT,
    attendance              INT,
    referee                 TEXT,
    url                     TEXT,
    home_club_formation     TEXT,
    away_club_formation     TEXT,
    home_club_name          TEXT,
    away_club_name          TEXT,
    aggregate               TEXT,
    competition_type        TEXT
);

-- ------------------------------------------------------------------
-- Table: bronze.player_valuations
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.player_valuations;

CREATE TABLE bronze.player_valuations
(
    player_id                           INT,
    date                                DATE,
    market_value_in_eur                 NUMERIC,
    current_club_name                   TEXT,
    current_club_id                     INT,
    player_club_domestic_competition_id TEXT
);

-- ------------------------------------------------------------------
-- Table: bronze.players
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.players;

CREATE TABLE bronze.players
(
    player_id                           INT,
    first_name                          TEXT,
    last_name                           TEXT,
    name                                TEXT,
    last_season                         INT,
    current_club_id                     INT,
    player_code                         TEXT,
    country_of_birth                    TEXT,
    city_of_birth                       TEXT,
    country_of_citizenship              TEXT,
    date_of_birth                       DATE,
    sub_position                        TEXT,
    position                            TEXT,
    foot                                TEXT,
    height_in_cm                        INT,
    contract_expiration_date            DATE,
    agent_name                          TEXT,
    image_url                           TEXT,
    url                                 TEXT,
    current_club_domestic_competition_id TEXT,
    current_club_name                   TEXT,
    market_value_in_eur                 NUMERIC,
    highest_market_value_in_eur         NUMERIC
);

-- ------------------------------------------------------------------
-- Table: bronze.transfers
-- ------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.transfers;

CREATE TABLE bronze.transfers
(
   player_id            INT,
   transfer_date        DATE,
   transfer_season      TEXT,
   from_club_id         INT,
   to_club_id           INT,
   from_club_name       TEXT,
   to_club_name         TEXT,
   transfer_fee         NUMERIC,
   market_value_in_eur  NUMERIC,
   player_name          TEXT
);