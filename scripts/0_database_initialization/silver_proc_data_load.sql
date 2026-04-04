/*
===============================================================================
Stored Procedure: silver.sp_load_silver()
===============================================================================

Database Schema: Silver Layer

Data Source: Bronze Layer tables

Purpose: 
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.

Usage: CALL silver.sp_load_silver();

===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.sp_load_silver()
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
    RAISE NOTICE '🚀 INGESTION START: SILVER LAYER DATA LOAD';
    RAISE NOTICE '------------------------------------------------------------';

    -- ---------------------------------------------------------
    -- TABLE: silver.competitions
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [1/10]: Processing table: silver.competitions...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE silver.competitions;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO silver.competitions 
    (
        competition_id,
        competition_code,
        name,
        sub_type,
        type,
        country_id,
        country_name,
        domestic_league_code,
        confederation,
        is_major_national_league,
        url
    )
    SELECT 
        UPPER(TRIM(competition_id)),
        LOWER(TRIM(competition_code)),
        UPPER(TRIM(REPLACE(regexp_replace(name,'-qualif.*$','-qualification'),'-',' '))),
        regexp_replace(LOWER(TRIM(sub_type)),'_qualif(iers|ying|ication|ied|y)$','_qualifying') AS sub_type,
        LOWER(TRIM(type)),
        country_id,
        INITCAP(TRIM(country_name)),
        UPPER(TRIM(domestic_league_code)),
        INITCAP(TRIM(confederation)),
        CAST(is_major_national_league AS BOOLEAN),
        TRIM(url)
    FROM bronze.competitions;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: silver.competitions loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: silver.clubs
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [2/10]: Processing table: silver.clubs...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE silver.clubs;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO silver.clubs 
    (
        club_id, 
        club_code, 
        name, 
        competition_id, 
        squad_size, 
        average_age, 
        foreigners_number, 
        foreigners_percentage, 
        national_team_players, 
        stadium_name, 
        stadium_seats, 
        net_transfer_record_eur, 
        coach_name, 
        last_season,
        filename, 
        url
    )
    SELECT 
        club_id,
        LOWER(TRIM(club_code)),
        TRIM(name),
        UPPER(TRIM(domestic_competition_id)) AS competition_id,
        NULLIF(squad_size, 0),
        NULLIF(average_age,0),
        foreigners_number,
        foreigners_percentage,
        national_team_players,
        TRIM(stadium_name),
        stadium_seats,
        CASE 
            WHEN LOWER(net_transfer_record) ~ 'm' 
                THEN CAST(regexp_replace(net_transfer_record, '[^0-9.-]', '', 'g') AS NUMERIC) * 1000000
            WHEN LOWER(net_transfer_record) ~ 'k' 
                THEN CAST(regexp_replace(net_transfer_record, '[^0-9.-]', '', 'g') AS NUMERIC) * 1000
            ELSE CAST(regexp_replace(net_transfer_record, '[^0-9.-]', '', 'g') AS NUMERIC) 
            END AS net_transfer_record_eur,
        TRIM(coach_name),
        CAST(last_season AS INT),
        TRIM(filename),
        TRIM(url)
    FROM bronze.clubs;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: silver.clubs loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: silver.players
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [3/10]: Processing table: silver.players...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE silver.players;

    RAISE NOTICE '  > Inserting data into...';
    
    INSERT INTO silver.players 
    (
        player_id ,
        first_name,
        last_name,
        name, -- Combined name from source
        last_season,
        current_club_id,
        current_club_name, -- Denormalized as requested
        current_club_domestic_competition_id,
        player_code,
        country_of_birth,
        city_of_birth,
        country_of_citizenship,
        date_of_birth,
        sub_position,
        position,
        foot,
        height_in_cm,
        market_value_in_eur,
        highest_market_value_in_eur,
        contract_expiration_date,
        agent_name,
        image_url,
        url
    )
    SELECT 
        player_id,
        TRIM(first_name),
        TRIM(last_name),
        TRIM(name),
        last_season,
        current_club_id,
        TRIM(current_club_name),
        UPPER(TRIM(current_club_domestic_competition_id)),
        TRIM(player_code),
        CASE LOWER(TRIM(country_of_birth))
            WHEN 'türkiye' THEN 'Turkey'
            WHEN 'turkiye' THEN 'Turkey'
            WHEN 'the gambia' THEN 'Gambia'
            WHEN 'cote d''ivoire' THEN 'Ivory Coast'
            WHEN 'curaçao' THEN 'Curacao'
            WHEN 'neukaledonien' THEN 'New Caledonia'
            WHEN 'southern sudan' THEN 'South Sudan'
            WHEN 'chinese taipei' THEN 'Taiwan'
            WHEN 'jugoslawien (sfr)' THEN 'Yugoslavia (SFR)'
            WHEN 'crimea' THEN 'Ukraine'
            WHEN 'zaire' THEN 'Democratic Republic of the Congo'
            WHEN 'dr congo' THEN 'Democratic Republic of the Congo'
            WHEN 'people''s republic of the congo' THEN 'Congo'
            WHEN 'swaziland' THEN 'Eswatini'
            WHEN '' THEN NULL
            ELSE TRIM(country_of_birth) END AS country_of_birth,
        TRIM(city_of_birth),
        CASE LOWER(TRIM(country_of_citizenship))
            WHEN 'türkiye' THEN 'Turkey'
            WHEN 'turkiye' THEN 'Turkey'
            WHEN 'the gambia' THEN 'Gambia'
            WHEN 'cote d''ivoire' THEN 'Ivory Coast'
            WHEN 'curaçao' THEN 'Curacao'
            WHEN 'neukaledonien' THEN 'New Caledonia'
            WHEN 'southern sudan' THEN 'South Sudan'
            WHEN 'chinese taipei' THEN 'Taiwan'
            WHEN 'jugoslawien (sfr)' THEN 'Yugoslavia (SFR)'
            WHEN 'crimea' THEN 'Ukraine'
            WHEN 'zaire' THEN 'Democratic Republic of the Congo'
            WHEN 'dr congo' THEN 'Democratic Republic of the Congo'
            WHEN 'people''s republic of the congo' THEN 'Congo'
            WHEN 'swaziland' THEN 'Eswatini'
            WHEN '' THEN NULL
            ELSE TRIM(country_of_citizenship) END AS country_of_citizenship,
        date_of_birth,
        UPPER(TRIM(sub_position)),
        UPPER(TRIM(position)),
        UPPER(TRIM(foot)),
        CASE 
            WHEN height_in_cm < 120 THEN NULL 
            ELSE height_in_cm END AS height_in_cm,
        CAST(market_value_in_eur AS NUMERIC(15, 2)),
        CAST(highest_market_value_in_eur AS NUMERIC(15, 2)),
        contract_expiration_date,
        TRIM(agent_name),
        TRIM(image_url),
        TRIM(url)
    FROM bronze.players;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: silver.players loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: silver.games
    -- ---------------------------------------------------------
    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [4/10]: Processing table: silver.games...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE silver.games;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO silver.games 
    (
        game_id,
        competition_id,
        season,
        round,
        date,
        home_club_id,
        away_club_id,
        home_club_goals,
        away_club_goals,
        home_club_position,
        away_club_position,
        home_club_manager_name,
        away_club_manager_name,
        stadium,
        attendance,
        referee,
        url,
        home_club_formation,
        away_club_formation,
        home_club_name,
        away_club_name,
        aggregate,
        competition_type
    )
    WITH cte_base_clean AS 
    (
        SELECT 
            *,
            UPPER(TRIM(round)) AS r
        FROM bronze.games
    ),
    cte_round_standardized AS 
    (
    SELECT 
        *,
        CASE 
            -- 1. Matchdays (We use LPAD for better sorting abilities)
            WHEN r ~ '^[0-9]+\.\sMATCHDAY$' THEN 'MATCHDAY ' || LPAD(SPLIT_PART(r, '.', 1), 2, '0')
            -- 2. Preliminary Rounds
            WHEN r IN ('2.VORRUNDE', 'SECOND PRELIMINARY ROUND') THEN '2ND PRELIMINARY ROUND'
            WHEN r = 'FIRST PRELIMINARY ROUND' THEN '1ST PRELIMINARY ROUND'
            -- 3. Standard Rounds
            WHEN r LIKE 'FIRST ROUND%' OR r ~ '^1(ST|RD|TH) ROUND' THEN '1ST ROUND'
            WHEN r LIKE 'SECOND ROUND%' OR r ~ '^2(ND|RD|TH) ROUND' THEN '2ND ROUND'
            WHEN r LIKE 'THIRD ROUND%' OR r ~ '^3(RD|TH) ROUND' THEN '3RD ROUND'
            WHEN r LIKE 'FOURTH ROUND%' OR r ~ '^4(TH) ROUND' THEN '4TH ROUND'
            WHEN r LIKE 'FIFTH ROUND%' OR r ~ '^5(TH) ROUND' THEN '5TH ROUND'
            WHEN r LIKE 'SIXTH ROUND%' OR r ~ '^6(TH) ROUND' THEN '6TH ROUND'
            -- 4. Group Stage
            WHEN r ~ '^GROUP\s[0-9].*' THEN 'GROUP ' || LPAD(SPLIT_PART(r, ' ', 2), 2, '0')
            WHEN r ~ '^GROUP\s[A-Z].*' THEN r
            -- 5. Knockout Stage
            WHEN r LIKE 'LAST 16%' OR r LIKE 'ROUND OF 16%' THEN 'ROUND OF 16'
            WHEN r LIKE 'QUARTER-FINALS%' THEN 'QUARTER-FINALS'
            WHEN r LIKE 'SEMI-FINALS%' THEN 'SEMI-FINALS'
            WHEN r LIKE 'FINAL%' THEN 'FINAL'
            -- 6. Others
            WHEN r ~ '^QUALIF(IERS|YING|ICATION|Y)\sROUND' THEN 'QUALIFICATION ROUND'
            WHEN r LIKE 'INTERMEDIATE STAGE%' THEN 'INTERMEDIATE STAGE'
            WHEN r IN ('|', '', ' ') THEN NULL        
            ELSE r
        END AS round_standardized
    FROM cte_base_clean
    )

    SELECT 
        game_id,
        UPPER(TRIM(competition_id)),
        season,
        round_standardized,
        date,
        home_club_id,
        away_club_id,
        home_club_goals,
        away_club_goals,
        home_club_position,
        away_club_position,
        TRIM(home_club_manager_name),
        TRIM(away_club_manager_name),
        TRIM(stadium),
        attendance,
        TRIM(referee),
        TRIM(url),
        regexp_replace(UPPER(TRIM(home_club_formation)),'^STARTING LINE-UP: ','','g') AS home_club_formation,
        regexp_replace(UPPER(TRIM(away_club_formation)),'^STARTING LINE-UP: ','','g') AS away_club_formation,
        TRIM(home_club_name),
        TRIM(away_club_name),
        TRIM(aggregate),
        LOWER(TRIM(competition_type))
    FROM cte_round_standardized;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: silver.games loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: silver.club_games
    -- ---------------------------------------------------------
    
    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [5/10]: Processing table: silver.club_games...';

    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE silver.club_games;

    RAISE NOTICE '  > Inserting data into';
    INSERT INTO silver.club_games 
    (
        game_id,
        club_id,
        own_goals,
        own_position,
        own_manager_name,
        opponent_id,
        opponent_goals,
        opponent_position,
        opponent_manager_name,
        is_home,
        is_win
    )
    SELECT 
        game_id,
        club_id,
        own_goals,
        own_position,
        TRIM(own_manager_name),
        opponent_id,
        opponent_goals,
        opponent_position,
        TRIM(opponent_manager_name),
        -- Hosting string to boolean
        CASE 
            WHEN LOWER(TRIM(hosting)) = 'home' THEN TRUE 
            WHEN LOWER(TRIM(hosting)) = 'away' THEN FALSE 
            ELSE NULL END AS is_home,
        CAST(is_win AS BOOLEAN)
    FROM bronze.club_games;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: silver.club_games loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM(v_job_end_time - v_job_start_time))::NUMERIC,2);

    -- ---------------------------------------------------------
    -- TABLE: silver.appearances
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [6/10]: Processing table: silver.appearances...';

    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE silver.appearances;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO silver.appearances 
    (
        appearance_id,
        game_id,
        date,
        competition_id,
        player_id,
        player_name,
        club_id,
        goals,
        assists,
        yellow_cards,
        red_cards,
        minutes_played
    )
    SELECT 
        a.appearance_id,
        a.game_id,
        a.date,
        UPPER(TRIM(a.competition_id)),
        a.player_id,
        TRIM(a.player_name),
        a.player_club_id,
        a.goals,
        a.assists,
        a.yellow_cards,
        a.red_cards,
        CASE
            WHEN c.type = 'domestic_league' AND a.minutes_played > 90 THEN 90
            WHEN c.type IS NOT NULL AND a.minutes_played > 120 THEN 120
            ELSE a.minutes_played END AS minutes_played
    FROM bronze.appearances AS a
    INNER JOIN silver.players AS p ON a.player_id = p.player_id
    LEFT JOIN silver.competitions AS c ON a.competition_id = c.competition_id;
    

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: silver.appearances loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM(v_job_end_time - v_job_start_time))::NUMERIC,2);


    -- ---------------------------------------------------------
    -- TABLE: silver.game_events
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [7/10]: Processing table: silver.game_events...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE silver.game_events;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO silver.game_events
    (
        game_event_id,
        date,
        game_id,
        minute,
        type,
        club_id,
        club_name,
        player_id,
        description,
        player_in_id,
        player_assist_id
    )
    SELECT
        TRIM(game_event_id),
        date,
        game_id,
        minute,
        UPPER(TRIM(type)),
        club_id,
        TRIM(club_name),
        player_id,
        UPPER(TRIM(description)),
        CASE
            WHEN UPPER(TRIM(type)) = 'SUBSTITUTIONS' AND player_id = player_in_id THEN NULL
            ELSE player_in_id END AS player_in_id,
        CASE 
            WHEN UPPER(TRIM(type)) = 'GOALS' AND player_id = player_assist_id THEN NULL
            ELSE player_assist_id END AS player_assist_id
    FROM bronze.game_events;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: silver.game_events loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: silver.game_lineups
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [8/10]: Processing table: silver.game_lineups...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE silver.game_lineups;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO silver.game_lineups 
    (
        game_lineups_id,
        date,
        game_id,
        player_id,
        club_id,
        player_name,
        number,
        position,
        is_starting_lineup,
        is_captain 
    )
    SELECT 
        TRIM(game_lineups_id),
        date,
        game_id,
        player_id,
        club_id,
        TRIM(player_name),
        CASE
            WHEN TRIM(number) IN ('','0','-') THEN NULL
            ELSE LEFT(TRIM(number),2)::INT END AS number,
        NULLIF(UPPER(TRIM(position)), '') AS position,
        CASE 
            WHEN LOWER(TRIM(type)) = 'starting_lineup' THEN TRUE
            WHEN LOWER(TRIM(type)) = 'substitutes' THEN FALSE
            ELSE NULL END AS is_starting_lineup,
        CAST(team_captain AS BOOLEAN) AS is_captain
    FROM bronze.game_lineups;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: silver.game_lineups loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️  Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);


    -- ---------------------------------------------------------
    -- TABLE: silver.player_valuations
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [9/10]: Processing table: silver.player_valuations...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE silver.player_valuations;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO silver.player_valuations 
    (
        player_id, 
        date, 
        market_value_in_eur, 
        current_club_name,
        current_club_id, 
        player_club_domestic_competition_id
    )
    SELECT 
        player_id,
        date,
        NULLIF(CAST(market_value_in_eur AS NUMERIC(15, 2)), 0) AS market_value_in_eur,
        TRIM(current_club_name),
        current_club_id,
        UPPER(TRIM(player_club_domestic_competition_id)) AS player_club_domestic_competition_id
    FROM bronze.player_valuations;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: silver.player_valuations loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);


    -- ---------------------------------------------------------
    -- TABLE: silver.transfers
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [10/10]: Processing table: silver.transfers...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE silver.transfers;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO silver.transfers 
    (
        player_id,
        transfer_date,
        transfer_season,
        from_club_id,
        to_club_id,
        from_club_name,
        to_club_name,
        transfer_fee,
        market_value_in_eur,
        player_name
    )
    SELECT
        player_id,
        transfer_date,
        CASE 
        WHEN LEFT(transfer_season,2)::INT > 50 THEN CONCAT('19',LEFT(transfer_season,2))::INT
        ELSE CONCAT('20',LEFT(transfer_season,2))::INT END AS transfer_season,
        from_club_id,
        to_club_id,
        TRIM(from_club_name),
        TRIM(to_club_name),
        CAST(transfer_fee AS NUMERIC(15, 2)),
        CAST(market_value_in_eur AS NUMERIC(15, 2)),
        TRIM(player_name)
    FROM bronze.transfers;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: silver.transfers loaded.';
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
    RAISE NOTICE '❌ ERROR OCCURED DURING LOADING SILVER LAYER!';
    RAISE NOTICE 'Error State: %', SQLSTATE;
    RAISE NOTICE 'Error Message: %', SQLERRM;
    RAISE NOTICE '------------------------------------------------------------';
END;
$$;

-- To execute the procedure:
-- CALL silver.sp_load_silver();