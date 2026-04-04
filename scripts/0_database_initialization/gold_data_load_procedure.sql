/*
===============================================================================
Stored Procedure: gold.sp_load_gold()
===============================================================================

Database Schema: Gold Layer

Data Source: Silver Layer tables

Purpose:
    Transforms and loads cleansed data from Silver layer into Gold (Star Schema), 
    filtering for Top 14 domestic leagues.

Usage: CALL gold.sp_load_gold();

===============================================================================
*/

CREATE OR REPLACE PROCEDURE gold.sp_load_gold()
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
    RAISE NOTICE '🚀 INGESTION START: GOLD LAYER DATA LOAD';
    RAISE NOTICE '------------------------------------------------------------';

    -- ---------------------------------------------------------
    -- DIMENSION TABLES:
    -- ---------------------------------------------------------

    -- ---------------------------------------------------------
    -- TABLE: gold.dim_competitions
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [1/8]: Processing table: gold.dim_competitions...';
    

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO gold.dim_competitions
    (
    competition_id, name, type, country_name, url
    )
    SELECT
        competition_id,
        name,
        type,
        country_name,
        url
    FROM silver.competitions
    WHERE type = 'domestic_league'
    ON CONFLICT (competition_id) DO UPDATE SET
        name = EXCLUDED.name,
        type = EXCLUDED.type,
        country_name = EXCLUDED.country_name,
        url = EXCLUDED.url;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: gold.dim_competitions loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: gold.dim_games
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [2/8]: Processing table: gold.dim_games...';

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO gold.dim_games 
    (
    game_id, competition_id, competition_type, season, round, date, home_club_id, 
    home_club_name, away_club_id, away_club_name, aggregate, home_club_manager_name,
    away_club_manager_name, home_club_formation, away_club_formation, stadium,
    attendance, referee, url
    )
    SELECT
        g.game_id,
        c.competition_id,
        c.type,
        g.season,
        g.round,
        g.date,
        g.home_club_id,
        g.home_club_name,
        g.away_club_id,
        g.away_club_name,
        g.aggregate,
        g.home_club_manager_name,
        g.away_club_manager_name,
        g.home_club_formation,
        g.away_club_formation,
        g.stadium,
        g.attendance,
        g.referee,
        g.url
    FROM silver.games AS g
    INNER JOIN gold.dim_competitions AS c ON g.competition_id = c.competition_id
    ON CONFLICT (game_id) DO UPDATE SET
        competition_id = EXCLUDED.competition_id,
        competition_type = EXCLUDED.competition_type,
        season = EXCLUDED.season,
        round = EXCLUDED.round,
        date = EXCLUDED.date,
        home_club_id = EXCLUDED.home_club_id,
        home_club_name = EXCLUDED.home_club_name,
        away_club_id = EXCLUDED.away_club_id,
        away_club_name = EXCLUDED.away_club_name,
        aggregate = EXCLUDED.aggregate,
        home_club_manager_name = EXCLUDED.home_club_manager_name,
        away_club_manager_name = EXCLUDED.away_club_manager_name,
        home_club_formation = EXCLUDED.home_club_formation,
        away_club_formation = EXCLUDED.away_club_formation,
        stadium = EXCLUDED.stadium,
        attendance = EXCLUDED.attendance,
        referee = EXCLUDED.referee,
        url = EXCLUDED.url;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: gold.dim_games loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: gold.dim_clubs
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [3/8]: Processing table: gold.dim_clubs...';

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO gold.dim_clubs
    (
    club_id, club_code, name, competition_id, stadium_name,
    stadium_seats, last_season, url
    )
    SELECT 
        cl.club_id,
        cl.club_code,
        cl.name,
        c.competition_id, 
        cl.stadium_name,
        cl.stadium_seats,
        cl.last_season,
        cl.url
    FROM silver.clubs AS cl
    INNER JOIN gold.dim_competitions AS c ON cl.competition_id = c.competition_id
    ON CONFLICT (club_id) DO UPDATE SET
        club_code = EXCLUDED.club_code,
        name = EXCLUDED.name,
        competition_id = EXCLUDED.competition_id,
        stadium_name = EXCLUDED.stadium_name,
        stadium_seats = EXCLUDED.stadium_seats,
        last_season = EXCLUDED.last_season,
        url = EXCLUDED.url;
    

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: gold.dim_clubs loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: gold.dim_players
    -- ---------------------------------------------------------
    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [4/8]: Processing table: gold.dim_players...';

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO gold.dim_players 
    (
    player_id, first_name, last_name, name, last_season, current_club_id, current_club_name,
    current_club_domestic_competition_id, country_of_birth, city_of_birth, country_of_citizenship,
    date_of_birth, sub_position, position, foot, height_in_cm, market_value_in_eur, highest_market_value_in_eur,
    contract_expiration_date, agent_name, image_url, url
    )
    SELECT
        p.player_id, 
        p.first_name, 
        p.last_name, 
        p.name, 
        p.last_season,
        c.club_id, 
        c.name AS current_club_name, 
        c.competition_id AS current_club_domestic_competition_id,
        p.country_of_birth, 
        p.city_of_birth, 
        p.country_of_citizenship,
        p.date_of_birth, 
        p.sub_position, 
        p.position, 
        p.foot, 
        p.height_in_cm,
        p.market_value_in_eur, 
        p.highest_market_value_in_eur,
        p.contract_expiration_date, 
        p.agent_name, 
        p.image_url, 
        p.url
    FROM silver.players AS p
    INNER JOIN gold.dim_clubs AS c ON p.current_club_id = c.club_id
    ON CONFLICT (player_id) DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        name = EXCLUDED.name,
        last_season = EXCLUDED.last_season,
        current_club_id = EXCLUDED.current_club_id,
        current_club_name = EXCLUDED.current_club_name,
        current_club_domestic_competition_id = EXCLUDED.current_club_domestic_competition_id,
        sub_position = EXCLUDED.sub_position,
        position = EXCLUDED.position,
        market_value_in_eur = EXCLUDED.market_value_in_eur,
        highest_market_value_in_eur = EXCLUDED.highest_market_value_in_eur,
        contract_expiration_date = EXCLUDED.contract_expiration_date,
        agent_name = EXCLUDED.agent_name,
        url = EXCLUDED.url;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: gold.dim_players loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- FACT TABLES:
    -- ---------------------------------------------------------

    -- ---------------------------------------------------------
    -- TABLE: gold.fact_player_valuations
    -- ---------------------------------------------------------
    
    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [5/8]: Processing table: gold.fact_player_valuations...';

    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE gold.fact_player_valuations;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO gold.fact_player_valuations
    (
    valuation_id, player_id, valuation_age, date_of_valuation, club_id_at_valuation, 
    competition_id_at_valuation, market_value_in_eur, valuation_change_prev, is_current, is_highest_ever
    )
    SELECT
        pv.valuation_id,
        p.player_id,
        EXTRACT(YEAR FROM AGE(pv.date, p.date_of_birth))::INTEGER AS valuation_age,
        pv.date,
        c.club_id,
        c.competition_id,
        pv.market_value_in_eur,
        pv.market_value_in_eur - (LAG(pv.market_value_in_eur) OVER(PARTITION BY p.player_id ORDER BY pv.date)),
        pv.date = (MAX(pv.date) OVER(PARTITION BY p.player_id)) AS is_current,
        pv.market_value_in_eur = (MAX(pv.market_value_in_eur) OVER(PARTITION BY p.player_id)) AS is_highest_ever
    FROM silver.player_valuations AS pv
    INNER JOIN gold.dim_players AS p ON pv.player_id = p.player_id
    LEFT JOIN gold.dim_clubs AS c ON pv.current_club_id = c.club_id;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: gold.fact_player_valuations loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM(v_job_end_time - v_job_start_time))::NUMERIC,2);

    -- ---------------------------------------------------------
    -- TABLE: gold.fact_transfers
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [6/8]: Processing table: gold.fact_transfers...';

    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE gold.fact_transfers;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO gold.fact_transfers 
    (
    transfer_id, player_id, transfer_date, transfer_season, from_club_id,
    from_competition_id, to_club_id, to_competition_id, transfer_fee,
    market_value_at_transfer, is_non_cash_transfer, is_latest_transfer, is_record_breaking_for_player
    )
    SELECT
        t.transfer_id,
        p.player_id,
        t.transfer_date,
        t.transfer_season,
        c1.club_id,
        c1.competition_id,
        c2.club_id,
        c2.competition_id,
        t.transfer_fee,
        t.market_value_in_eur,
        COALESCE(t.transfer_fee,0) = 0 AS is_non_cash_transfer,
        (ROW_NUMBER() OVER (PARTITION BY p.player_id ORDER BY t.transfer_date DESC, t.transfer_id DESC) = 1) AS is_latest_transfer,
        (t.transfer_fee = MAX(t.transfer_fee) OVER(PARTITION BY p.player_id) AND t.transfer_fee > 0) AS is_record_breaking_for_player
    FROM silver.transfers AS t
    INNER JOIN gold.dim_players AS p ON t.player_id = p.player_id
    LEFT JOIN gold.dim_clubs AS c1 ON t.from_club_id = c1.club_id
    LEFT JOIN gold.dim_clubs AS c2 ON t.to_club_id = c2.club_id;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: gold.fact_transfers loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM(v_job_end_time - v_job_start_time))::NUMERIC,2);


    -- ---------------------------------------------------------
    -- TABLE: gold.fact_player_stats
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [7/8]: Processing table: gold.fact_player_stats...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE gold.fact_player_stats;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO gold.fact_player_stats
    (
    appearance_id, game_id, competition_id, season, date, player_id, club_id,
    opponent_id, is_clean_sheet, goals, assists, yellow_cards, red_cards, minutes_played,
    player_number, position, is_starting_lineup, is_captain, is_home, is_win
    )
    SELECT
        CONCAT(gl.game_id,'_',gl.player_id) AS appearance_id,
        g.game_id,
        g.competition_id,
        g.season,
        g.date,
        p.player_id,
        cl.club_id,
        cl2.club_id AS opponent_id,
        cg.opponent_goals = 0 AS is_clean_sheet,
        COALESCE(a.goals,0),
        COALESCE(a.assists,0),
        COALESCE(a.yellow_cards,0),
        COALESCE(a.red_cards,0),
        COALESCE(a.minutes_played,0),
        gl.number,
        gl.position, 
        gl.is_starting_lineup,
        gl.is_captain,
        cg.is_home,
        cg.is_win
    FROM silver.game_lineups AS gl
    INNER JOIN gold.dim_games AS g ON gl.game_id = g.game_id
    INNER JOIN gold.dim_players AS p ON gl.player_id = p.player_id
    INNER JOIN gold.dim_clubs AS cl ON gl.club_id = cl.club_id
    LEFT JOIN silver.appearances AS a ON gl.game_id = a.game_id AND gl.player_id = a.player_id
    LEFT JOIN silver.club_games AS cg ON gl.game_id = cg.game_id AND gl.club_id = cg.club_id
    LEFT JOIN gold.dim_clubs AS cl2 ON cg.opponent_id = cl2.club_id;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: gold.fact_player_stats loaded.';
    RAISE NOTICE '📊 Records: % rows', v_row_count;
    RAISE NOTICE '⏱️ Duration: %s', ROUND(EXTRACT(EPOCH FROM (v_job_end_time - v_job_start_time))::NUMERIC, 2);

    -- ---------------------------------------------------------
    -- TABLE: gold.fact_team_stats
    -- ---------------------------------------------------------

    v_job_start_time := clock_timestamp();
    RAISE NOTICE 'STEP [8/8]: Processing table: gold.fact_team_stats...';
    
    RAISE NOTICE '  > Truncating table...';
    TRUNCATE TABLE gold.fact_team_stats;

    RAISE NOTICE '  > Inserting data into...';
    INSERT INTO gold.fact_team_stats
    (
    game_id, date, season, competition_id, club_id, opponent_id, own_manager_name, opponent_manager_name, own_goals, 
    opponent_goals, goal_difference, own_position, opponent_position, position_diff, attendance,
    is_home, is_clean_sheet, is_win, is_draw, is_loss, points
    )
    SELECT
        g.game_id,
        g.date,
        g.season,
        g.competition_id,
        c.club_id,
        c2.club_id AS opponent_id,
        cg.own_manager_name,
        cg.opponent_manager_name,
        cg.own_goals,
        cg.opponent_goals,
        (cg.own_goals - cg.opponent_goals) AS goal_difference,
        cg.own_position,
        cg.opponent_position,
        (cg.opponent_position - cg.own_position) AS position_diff,
        g.attendance,
        cg.is_home,
        cg.opponent_goals = 0 AS is_clean_sheet,
        cg.own_goals > cg.opponent_goals AS is_win,
        cg.own_goals = cg.opponent_goals AS is_draw,
        cg.own_goals < cg.opponent_goals AS is_loss,
        CASE
            WHEN cg.own_goals > cg.opponent_goals THEN 3
            WHEN cg.own_goals = cg.opponent_goals THEN 1
        ELSE 0 END AS points
    FROM silver.club_games AS cg
    INNER JOIN gold.dim_games AS g ON cg.game_id = g.game_id
    INNER JOIN gold.dim_clubs AS c ON cg.club_id = c.club_id
    LEFT JOIN gold.dim_clubs AS c2 ON cg.opponent_id = c2.club_id;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_job_end_time := clock_timestamp();

    RAISE NOTICE '✅ Success: gold.fact_team_stats loaded.';
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
    RAISE NOTICE '❌ ERROR OCCURED DURING LOADING gold LAYER!';
    RAISE NOTICE 'Error State: %', SQLSTATE;
    RAISE NOTICE 'Error Message: %', SQLERRM;
    RAISE NOTICE '------------------------------------------------------------';
END;
$$;

-- To execute the procedure:
-- CALL gold.sp_load_gold();