/*
===============================================================================
Stored Procedure: bronze.sp_load_bronze()
===============================================================================

Database Schema: Bronze Layer (Raw, Immutable Data)

Purpose:
    This procedure automates the ingestion process from flat CSV files 
    into the Bronze (Landing) layer of the Data Warehouse.

Process:
    1. Records the batch start time.
    2. Iteratively truncates each target table.
    3. Uses the COPY command to load raw data from the filesystem.
    4. Captures and logs the number of rows processed per table.
    5. Measures and logs performance metrics (duration).
    6. Handles exceptions by logging SQLSTATE and SQLERRM.

Data Source:
    CSV files located in '/Users/Shared/postgres_data/transfermarkt/'

Usage: CALL bronze.sp_load_bronze();

===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.sp_load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE 
    v_job_start_time TIMESTAMP;
    v_job_end_time TIMESTAMP;
    v_batch_start_time TIMESTAMP;
    v_batch_end_time TIMESTAMP;
    v_row_count INT;
BEGIN
    v_batch_start_time := clock_timestamp();

    RAISE NOTICE '------------------------------------------------------------';
    RAISE NOTICE '🚀 INGESTION START: BRONZE LAYER DATA LOAD';
    RAISE NOTICE '------------------------------------------------------------';

    -- ---------------------------------------------------------
    -- TABLE: bronze.appearances
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [1/10]: Processing table: bronze.appearances...';

    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE bronze.appearances;

    RAISE NOTICE '  > Copying data from CSV...';
    COPY bronze.appearances
    FROM '/Users/Shared/postgres_data/transfermarkt/appearances.csv' 
    WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: bronze.appearances loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM(v_job_end_time - v_job_start_time))::NUMERIC,2);

    -- ---------------------------------------------------------
    -- TABLE: bronze.club_games
    -- ---------------------------------------------------------
    
    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [2/10]: Processing table: bronze.club_games...';

    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE bronze.club_games;

    RAISE NOTICE '  > Copying data from CSV';
    COPY bronze.club_games
    FROM '/Users/Shared/postgres_data/transfermarkt/club_games.csv' 
    WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: bronze.club_games loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM(v_job_end_time - v_job_start_time))::NUMERIC,2);

    -- ---------------------------------------------------------
    -- TABLE: bronze.clubs
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [3/10]: Processing table: bronze.clubs...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE bronze.clubs;

    RAISE NOTICE '  > Copying data from CSV...';
    COPY bronze.clubs
    FROM '/Users/Shared/postgres_data/transfermarkt/clubs.csv' 
    WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: bronze.clubs loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: bronze.competitions
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [4/10]: Processing table: bronze.competitions...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE bronze.competitions;

    RAISE NOTICE '  > Copying data from CSV...';
    COPY bronze.competitions
    FROM '/Users/Shared/postgres_data/transfermarkt/competitions.csv' 
    WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: bronze.competitions loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️  Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: bronze.game_events
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [5/10]: Processing table: bronze.game_events...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE bronze.game_events;

    RAISE NOTICE '  > Copying data from CSV...';
    COPY bronze.game_events
    FROM '/Users/Shared/postgres_data/transfermarkt/game_events.csv' 
    WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: bronze.game_events loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: bronze.game_lineups
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [6/10]: Processing table: bronze.game_lineups...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE bronze.game_lineups;

    RAISE NOTICE '  > Copying data from CSV...';
    COPY bronze.game_lineups
    FROM '/Users/Shared/postgres_data/transfermarkt/game_lineups.csv' 
    WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: bronze.game_lineups loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️  Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: bronze.games
    -- ---------------------------------------------------------
    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [7/10]: Processing table: bronze.games...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE bronze.games;

    RAISE NOTICE '  > Copying data from CSV...';
    COPY bronze.games
    FROM '/Users/Shared/postgres_data/transfermarkt/games.csv' 
    WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: bronze.games loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: bronze.player_valuations
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [8/10]: Processing table: bronze.player_valuations...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE bronze.player_valuations;

    RAISE NOTICE '  > Copying data from CSV...';
    COPY bronze.player_valuations
    FROM '/Users/Shared/postgres_data/transfermarkt/player_valuations.csv' 
    WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: bronze.player_valuations loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: bronze.players
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [9/10]: Processing table: bronze.players...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE bronze.players;

    RAISE NOTICE '  > Copying data from CSV...';
    COPY bronze.players
    FROM '/Users/Shared/postgres_data/transfermarkt/players.csv' 
    WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: bronze.players loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: bronze.transfers
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [10/10]: Processing table: bronze.transfers...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE bronze.transfers;

    RAISE NOTICE '  > Copying data from CSV...';
    COPY bronze.transfers
    FROM '/Users/Shared/postgres_data/transfermarkt/transfers.csv' 
    WITH (FORMAT CSV, HEADER, DELIMITER ',', ENCODING 'UTF8');

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: bronze.transfers loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- Batch Finalization
    -- ---------------------------------------------------------

    v_batch_end_time := clock_timestamp();

    RAISE NOTICE '------------------------------------------------------------';
    RAISE NOTICE '🏁 BATCH COMPLETED SUCCESSFULLY';
    RAISE NOTICE '⏱️ Total Processing Time: %s', ROUND(EXTRACT(EPOCH FROM (v_batch_end_time - v_batch_start_time))::NUMERIC, 2);
    RAISE NOTICE '------------------------------------------------------------';

    EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '------------------------------------------------------------';
    RAISE NOTICE '❌ ERROR OCCURED DURING LOADING BRONZE LAYER!';
    RAISE NOTICE 'Error State: %', SQLSTATE;
    RAISE NOTICE 'Error Message: %', SQLERRM;
    RAISE NOTICE '------------------------------------------------------------';
END;
$$;

-- To execute the procedure: 
-- CALL bronze.sp_load_bronze();
