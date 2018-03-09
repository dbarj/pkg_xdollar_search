-------------
-- EXAMPLE --
-------------

SQL> col contents for a30
SQL> col search_qry for a100

-- Searching in all X$ tables any column containing 'DBARJ'.
SQL> select * from table(pkg_xdollar_search.f_string('%DBARJ%'));

-- Searching in X$KQLFBC table any column with the exactly text 'DBARJ'.
SQL> select * from table(pkg_xdollar_search.f_string('DBARJ','X$KQLFBC'));

-- Searching for raw in all X$ tables starting with X$KC any column containing value '00000000B715CCB8'.
SQL> select * from table(pkg_xdollar_search.f_raw('00000000B715CCB8','X$KC%'));

-- Searching for CLOB value.
SQL> var myclob clob;
SQL> exec :myclob := 'Bind UACs mismatch';
SQL> select * from table(pkg_xdollar_search.f_clob(:myclob));
-- OR
SQL> select * from table(pkg_xdollar_search.f_clob('Bind UACs mismatch'));

-- By default X$DIAG tables are skipped. To include them, change SKIP_DIAG variable to FALSE.
SQL> exec pkg_xdollar_search.SKIP_DIAG := FALSE;
SQL> select * from table(pkg_xdollar_search.f_string('%DBARJ%'));

-- Note that SKIP_DIAG variable is also ignored when table filters are used.
SQL> exec pkg_xdollar_search.SKIP_DIAG := TRUE;
SQL> select * from table(pkg_xdollar_search.f_string('%DBARJ%','X$DIAG%'));

-- It's also possible to filter by column name instead of table name, using 3rd parameter.
SQL> select * from table(pkg_xdollar_search.f_number(1234,NULL,'%INDX%'));

-- By default, all X$ columns (indexed and non indexed) will be included in the output. However, if you wish to scan only on indexed columns, change SKIP_NONINDEXED to TRUE.
-- Note that indexed columns performs an "FIXED TABLE FIXED INDEX" vs "FIXED TABLE FULL"  which generates less latches and thus less impact in the environment.
SQL> exec pkg_xdollar_search.SKIP_NONINDEXED := TRUE;
SQL> select * from table(pkg_xdollar_search.f_raw('00000000B715CCB8','X$KC%'));

-----------
-- DEBUG --
-----------

-- To debug the execution, change DEBUG variable to TRUE. Please note that all steps of package will be spooled.
SQL> exec pkg_xdollar_search.DEBUG := TRUE;
SQL> select * from table(pkg_xdollar_search.f_clob('Bind UACs mismatch'));

----------
-- MISC --
----------

-- All column types of X$ tables:
SYS> select kqfcodty,count(*) from x$kqfco group by kqfcodty order by 2 desc;

   KQFCODTY    COUNT(*)
----------- -----------
          2       13853 -- NUMBER
          1        2906 -- VARCHAR2
         23        1891 -- RAW
         12         282 -- DATE
        181         189 -- TIMESTAMP WITH TIME ZONE
        180          40 -- TIMESTAMP
        112          25 -- CLOB