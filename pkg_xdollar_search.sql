CREATE OR REPLACE PACKAGE pkg_xdollar_search AS
  -- Created by Rodrigo Jorge - http://www.dbarj.com.br
  -- https://github.com/dbarj/pkg_xdollar_search/

  TYPE t_lin IS RECORD (
    TABLE_NAME VARCHAR2(30),   -- X$ TABLE NAME
    COLUMN_NAME VARCHAR2(30),  -- X$ COLUMN NAME
    ADDR RAW(8),               -- ADDR OF X$TABLE
    INDX NUMBER,               -- INDX OF X$TABLE
    CONTENTS VARCHAR2(4000),   -- CONTENT FOUND IN THE COLUMN, ALSO POPULATED IN DEBUG MODE WITH DEBUG MESSAGE.
    SEARCH_QRY VARCHAR2(1000), -- QUERY TO GET THE FOUND VALUE
    EXEC_TIME_SECS NUMBER      -- EXECUTION TIME IN SECONDS
  );

  TYPE t_tab IS TABLE OF t_lin;

  --------------------
  -- Search functions
  --------------------

  FUNCTION f_string (p_input IN VARCHAR2, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED;

  FUNCTION f_number (p_input IN NUMBER, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED;

  FUNCTION f_raw (p_input IN RAW, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED;

  FUNCTION f_date (p_input IN DATE, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED;

  FUNCTION f_timestamp (p_input IN TIMESTAMP, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED;

  FUNCTION f_timestampTZ (p_input IN TIMESTAMP WITH TIME ZONE, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED;

  FUNCTION f_clob (p_input IN CLOB, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED;

  --------------------
  -- Internal Function
  --------------------

  FUNCTION f_run (p_input IN ANYDATA, p_tab_name in VARCHAR2 DEFAULT 'X$%', p_col_name in VARCHAR2 DEFAULT '%')
    RETURN t_tab PIPELINED;

  DEBUG            BOOLEAN := FALSE;
  SKIP_DIAG        BOOLEAN := TRUE;
  SKIP_NONINDEXED  BOOLEAN := FALSE;

END pkg_xdollar_search;
/

CREATE OR REPLACE PACKAGE BODY pkg_xdollar_search AS
  -- Created by Rodrigo Jorge - http://www.dbarj.com.br
  -- https://github.com/dbarj/pkg_xdollar_search/

  -------------------
  -- Main cursor
  -------------------

  CURSOR l_cursor (p_tab_name varchar2, p_col_name varchar2, p_col_type number, p_skip_diag number, p_skip_nonindex number) is
  select
      t.kqftanam          table_name,
      c.kqfconam          column_name,
      c.kqfcodty          column_type_id,
      c.kqfcosiz,
      c.kqfcooff          offset,
      lpad('0x'||trim(to_char(c.kqfcooff,'XXXXXX')),8) xde_off_hex,
      to_number(decode(c.kqfcoidx,0,null,c.kqfcoidx)) xde_kqfcoidx,
      count(*) over (partition by t.kqftanam) total_columns
  from
      x$kqfta t,
      x$kqfco c
  where
      c.kqfcotab  = t.indx
  and (t.kqftanam like p_tab_name)
  and (p_skip_diag = 0 OR p_tab_name != 'X$%' OR t.kqftanam not like 'X$DIAG%') -- If SKIP_DIAG is true and table filter is unset: skip DIAG tables.
  and c.kqfconam like p_col_name
  and (p_skip_nonindex = 0 OR c.kqfcoidx > 0) -- If SKIP_NONINDEXED: skip non-indexed columns.
  and decode(c.kqfcodty,181,180,c.kqfcodty) = p_col_type -- GET BOTH "TIMESTAMP WITH TIME ZONE" AND "TIMESTAMP" TYPES
  order by table_name, column_name;

  l_row l_cursor%rowtype;

  --------------------
  -- Search functions
  --------------------

  FUNCTION f_string (p_input IN VARCHAR2, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED
  IS
  BEGIN
    FOR I IN (select * from table(f_run(SYS.ANYDATA.convertVarchar2(p_input),p_tab_name,p_col_name)))
    LOOP
      PIPE ROW (I);
    END LOOP;
  END f_string;

  FUNCTION f_number (p_input IN NUMBER, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED
  IS
  BEGIN
    FOR I IN (select * from table(f_run(SYS.ANYDATA.convertNumber(p_input),p_tab_name,p_col_name)))
    LOOP
      PIPE ROW (I);
    END LOOP;
  END f_number;

  FUNCTION f_raw (p_input IN RAW, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED
  IS
  BEGIN
    FOR I IN (select * from table(f_run(SYS.ANYDATA.convertRaw(p_input),p_tab_name,p_col_name)))
    LOOP
      PIPE ROW (I);
    END LOOP;
  END f_raw;

  FUNCTION f_date (p_input IN DATE, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED
  IS
  BEGIN
    FOR I IN (select * from table(f_run(SYS.ANYDATA.convertDate(p_input),p_tab_name,p_col_name)))
    LOOP
      PIPE ROW (I);
    END LOOP;
  END f_date;

  FUNCTION f_timestamp (p_input IN TIMESTAMP, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED
  IS
  BEGIN
    FOR I IN (select * from table(f_run(SYS.ANYDATA.convertTimestamp(p_input),p_tab_name,p_col_name)))
    LOOP
      PIPE ROW (I);
    END LOOP;
  END f_timestamp;

  FUNCTION f_timestampTZ (p_input IN TIMESTAMP WITH TIME ZONE, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED
  IS
  BEGIN
    FOR I IN (select * from table(f_run(SYS.ANYDATA.convertTimestampTZ(p_input),p_tab_name,p_col_name)))
    LOOP
      PIPE ROW (I);
    END LOOP;
  END f_timestampTZ;

  FUNCTION f_clob (p_input IN CLOB, p_tab_name in VARCHAR2 DEFAULT NULL, p_col_name in VARCHAR2 DEFAULT NULL)
    RETURN t_tab PIPELINED
  IS
  BEGIN
    FOR I IN (select * from table(f_run(SYS.ANYDATA.ConvertClob(p_input),p_tab_name,p_col_name)))
    LOOP
      PIPE ROW (I);
    END LOOP;
  END f_clob;

  --------------------
  -- Internal Function
  --------------------

  FUNCTION f_run (p_input IN ANYDATA, p_tab_name in VARCHAR2 DEFAULT 'X$%', p_col_name in VARCHAR2 DEFAULT '%')
    RETURN t_tab PIPELINED
  IS
    last_tab_name   VARCHAR2(30) := '-';
    last_tab_rows   INTEGER := 0;
    v_debug_lin     t_lin; -- Used for DEBUG only
    v_result_tab    t_tab; -- Used to store SEARCH result
    v_sql           CLOB;
    v_anydata_type  VARCHAR2(30);
    v_tab_name      VARCHAR2(30) := NVL(p_tab_name, 'X$%');
    v_col_name      VARCHAR2(30) := NVL(p_col_name, '%');
    v_col_type      NUMBER;
    v_skip_diag     NUMBER;
    v_skip_nonindex NUMBER;
    v_exec_start    NUMBER;
    v_exec_end      NUMBER;
  BEGIN
    -- Get Type of input param.
    v_anydata_type := SYS.ANYDATA.getTypeName(p_input);
    CASE v_anydata_type
      WHEN 'SYS.VARCHAR2'  THEN v_col_type := 1;
      WHEN 'SYS.NUMBER'    THEN v_col_type := 2;
      WHEN 'SYS.DATE'      THEN v_col_type := 12;
      WHEN 'SYS.RAW'       THEN v_col_type := 23;
      WHEN 'SYS.CLOB'      THEN v_col_type := 112;
      WHEN 'SYS.TIMESTAMP' THEN v_col_type := 180;
    END CASE;
    IF SKIP_DIAG THEN
       v_skip_diag := 1;
    ELSE
       v_skip_diag := 0;
    END IF;
    IF SKIP_NONINDEXED THEN
       v_skip_nonindex := 1;
    ELSE
       v_skip_nonindex := 0;
    END IF;
    BEGIN
      CLOSE l_cursor;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    FOR l_row in l_cursor(v_tab_name, v_col_name, v_col_type, v_skip_diag, v_skip_nonindex)
    LOOP
      v_debug_lin.table_name := l_row.table_name;
      v_debug_lin.column_name := '';
      v_debug_lin.exec_time_secs := '';
      v_debug_lin.search_qry := '';
      CONTINUE WHEN l_row.table_name = last_tab_name AND last_tab_rows = 0;
      -- If this table is not the same as last one in loop
      IF l_row.table_name != last_tab_name THEN
        last_tab_name := l_row.table_name;
        -- Only compute total rows if table has more than 1 column to be checked.
        IF l_row.total_columns>1 THEN
          IF DEBUG THEN
            v_debug_lin.exec_time_secs := '';
            v_debug_lin.contents := 'DEBUG: Checking number of rows in table ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.table_name) || '.';
            PIPE ROW (v_debug_lin);
          END IF;
          v_exec_start := dbms_utility.get_time;
          BEGIN
            EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.table_name)
              INTO last_tab_rows;
            IF DEBUG THEN
              v_debug_lin.contents := 'DEBUG: ' || last_tab_rows || ' row(s) in ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.table_name) || '.';
              v_exec_end := dbms_utility.get_time;
              v_debug_lin.exec_time_secs := (v_exec_end - v_exec_start)/100;
              PIPE ROW (v_debug_lin);
            END IF;
          -- On "EXECUTE IMMEDIATE" error
          EXCEPTION
            WHEN OTHERS THEN
              IF  SQLCODE <> -1306  -- dbms_logmnr.start_logmnr() must be invoked before selecting from v$logmnr_contents
              AND SQLCODE <> -1307  -- no LogMiner session is currently active
              AND SQLCODE <> -16525 -- The Oracle Data Guard broker is not yet available.
              THEN
                v_debug_lin.contents := 'DEBUG: ERROR in initial COUNT(*) - ' || SQLERRM;
                last_tab_rows := 1;
              ELSE
                v_debug_lin.contents := 'DEBUG: Initial COUNT(*) skipped as some features are not started.';
                last_tab_rows := 0;
              END IF;
              IF DEBUG THEN
                v_exec_end := dbms_utility.get_time;
                v_debug_lin.exec_time_secs := (v_exec_end - v_exec_start)/100;
                PIPE ROW (v_debug_lin);
              END IF;
          END;
        ELSE
          IF DEBUG THEN
            v_debug_lin.exec_time_secs := '';
            v_debug_lin.contents := 'DEBUG: Initial COUNT(*) skipped as only one column will be checked.';
            PIPE ROW (v_debug_lin);
          END IF;
          last_tab_rows:=1;
        END IF;
      END IF;
      -- If X$ table has rows
      IF last_tab_rows != 0 THEN
        v_debug_lin.column_name := l_row.column_name;
        BEGIN
        IF DEBUG THEN
          v_debug_lin.exec_time_secs := '';
          v_debug_lin.contents := 'DEBUG: Checking table ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.table_name) || ' column ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || '.';
          PIPE ROW (v_debug_lin);
        END IF;
        v_sql := 'SELECT ' || DBMS_ASSERT.ENQUOTE_LITERAL(l_row.table_name) || ',' ||  DBMS_ASSERT.ENQUOTE_LITERAL(l_row.column_name) || ',ADDR,INDX,' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || ',' ||
          '''SELECT * FROM ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.table_name) || ' WHERE "INDX"='' || INDX || '';'', NULL' ||
          ' FROM ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.table_name);
        v_exec_start := dbms_utility.get_time;
        -- Build query for each type
        IF v_anydata_type = 'SYS.VARCHAR2' AND l_row.column_type_id in (1) THEN
          v_sql := v_sql || ' WHERE ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || ' LIKE :1';
          EXECUTE IMMEDIATE v_sql
            BULK COLLECT INTO v_result_tab
            USING SYS.ANYDATA.accessVarchar2(p_input);
        ELSIF v_anydata_type = 'SYS.NUMBER' AND l_row.column_type_id in (2) THEN
          v_sql := v_sql || ' WHERE ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || ' = :1';
          EXECUTE IMMEDIATE v_sql
            BULK COLLECT INTO v_result_tab
            USING SYS.ANYDATA.accessNumber(p_input);
        ELSIF v_anydata_type = 'SYS.DATE' AND l_row.column_type_id in (12) THEN
          v_sql := v_sql || ' WHERE ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || ' = :1';
          EXECUTE IMMEDIATE v_sql
            BULK COLLECT INTO v_result_tab
            USING SYS.ANYDATA.accessDate(p_input);
        ELSIF v_anydata_type = 'SYS.RAW' AND l_row.column_type_id in (23) THEN
          -- Filter changed to use index.
          -- v_sql := v_sql || ' WHERE UTL_RAW.COMPARE(' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || ',:1) = 0';
          v_sql := v_sql || ' WHERE ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || ' = :1';
          EXECUTE IMMEDIATE v_sql
            BULK COLLECT INTO v_result_tab
            USING SYS.ANYDATA.accessRaw(p_input);
        ELSIF v_anydata_type = 'SYS.TIMESTAMP' AND l_row.column_type_id in (180) THEN
          v_sql := v_sql || ' WHERE ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || ' = :1';
          EXECUTE IMMEDIATE v_sql
            BULK COLLECT INTO v_result_tab
            USING SYS.ANYDATA.accessTimestamp(p_input);
        ELSIF v_anydata_type = 'SYS.TIMESTAMP' AND l_row.column_type_id in (181) THEN
          v_sql := v_sql || ' WHERE ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || ' = :1';
          EXECUTE IMMEDIATE v_sql
            BULK COLLECT INTO v_result_tab
            USING SYS.ANYDATA.accessTimestampTZ(p_input);
        ELSIF v_anydata_type = 'SYS.CLOB' AND l_row.column_type_id in (112) THEN
          v_sql := 'SELECT ' || DBMS_ASSERT.ENQUOTE_LITERAL(l_row.table_name) || ',' ||  DBMS_ASSERT.ENQUOTE_LITERAL(l_row.column_name) || ',ADDR,INDX,dbms_lob.substr(' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || ',4000,1),' ||
          '''SELECT * FROM ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.table_name) || ' WHERE "INDX"='' || INDX || '';'', NULL' ||
          ' FROM ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.table_name);
          v_sql := v_sql || ' WHERE DBMS_LOB.INSTR(' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || ',:1) > 0';
          EXECUTE IMMEDIATE v_sql
            BULK COLLECT INTO v_result_tab
            USING SYS.ANYDATA.accessClob(p_input);
        END IF;
        v_exec_end := dbms_utility.get_time;
        -- On "EXECUTE IMMEDIATE" error
        EXCEPTION
          WHEN OTHERS THEN
            IF  SQLCODE <> -1306  -- dbms_logmnr.start_logmnr() must be invoked before selecting from v$logmnr_contents
            AND SQLCODE <> -1307  -- no LogMiner session is currently active
            AND SQLCODE <> -16525 -- The Oracle Data Guard broker is not yet available.
            THEN
              v_debug_lin.contents := 'DEBUG: ERROR in COL SELECT - ' || SQLERRM;
            ELSE
              v_debug_lin.contents := 'DEBUG: COL SELECT not executed as some features are not started.';
            END IF;
            IF DEBUG THEN
              v_exec_end := dbms_utility.get_time;
              v_debug_lin.exec_time_secs := (v_exec_end - v_exec_start)/100;
              v_debug_lin.search_qry := dbms_lob.substr(v_sql,1000,1);
              PIPE ROW (v_debug_lin);
            END IF;
        END;
        -- Spool output.
        -- If result is not null
        IF v_result_tab IS NOT NULL
        THEN
          -- And if result has lines
          IF v_result_tab.COUNT > 0 THEN
            FOR I IN 1 .. v_result_tab.COUNT
            LOOP
              v_result_tab(I).exec_time_secs := (v_exec_end - v_exec_start)/100;
              PIPE ROW (v_result_tab(I));
            END LOOP;
          ELSE
            IF DEBUG THEN
              v_debug_lin.exec_time_secs := (v_exec_end - v_exec_start)/100;
              v_debug_lin.contents := 'DEBUG: Nothing found on ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.table_name) || ' column ' || DBMS_ASSERT.ENQUOTE_NAME(l_row.column_name) || '.';
              v_debug_lin.search_qry := dbms_lob.substr(v_sql,1000,1);
              PIPE ROW (v_debug_lin);
            END IF;
          END IF;
        END IF;
      END IF;
    END LOOP;
  END f_run;

END pkg_xdollar_search;
/
