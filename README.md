# pkg_xdollar_search

This package is useful when you need to scan in some X$ table for a given value but don't know exactly in which X$ table or column this value is.

So this package will scan in ALL X$ and print in which table and column the given value was located.

Remember that more scans on the memory means more CPU assumption, more latch acquisition and potential concurrency problem. So it's **NOT** recommended to run this package in **PRODUCTION** environment.

## Installation ##

1. Download and unzip pkg_xdollar_search_master.zip, navigate to the root pkg_xdollar_search_master directory, and connect as SYS to deploy the package:

```
  $ wget -O pkg_xdollar_search.zip https://github.com/dbarj/pkg_xdollar_search/archive/master.zip  
  $ unzip pkg_xdollar_search.zip  
  $ cd pkg_xdollar_search-master  
  $ sqlplus / as sysdba @pkg_xdollar_search.sql
```

2. Execute the package:

```
  SQL> select * from table(pkg_xdollar_search.f_string('DBARJ','X$KQ%'));  

  TABLE_NAME COLUMN_NAME   ADDR             INDX CONTENTS SEARCH_QRY                                  EXEC_TIME_SECS
  ---------- ------------- ---------------- ---- -------- ------------------------------------------- --------------
  X$KQLFBC   KQLFBC_STRVAL 00007F5E2B2CEA98   37 DBARJ    SELECT * FROM "X$KQLFBC" WHERE "INDX"=37;              .06
  X$KQLFBC   KQLFBC_STRVAL 00007F5E2B3739B8  918 DBARJ    SELECT * FROM "X$KQLFBC" WHERE "INDX"=918;             .06
  X$KQLFBC   KQLFBC_STRVAL 00007F5E2B58FEC8 3543 DBARJ    SELECT * FROM "X$KQLFBC" WHERE "INDX"=3543;            .06
  X$KQLFBC   KQLFBC_STRVAL 00007F5E2B41DB80 9853 DBARJ    SELECT * FROM "X$KQLFBC" WHERE "INDX"=9853;            .06
```

## Documentation ##

The package has basically 7 functions and 3 variables:

### FUNCTIONS: ###

* **F_STRING** : Search for a string value in VARCHAR2 X$ columns.
* **F_NUMBER** : Search for a numeric value in NUMBER X$ columns.
* **F_RAW** : Search for a raw value in RAW X$ columns.
* **F_DATE** : Search for a date value in DATE X$ columns.
* **F_TIMESTAMP** : Search for a timestamp value in TIMESTAMP X$ columns.
* **F_TIMESTAMPTZ** : Search for a timestamp with time zone value in TIMESTAMP WITH TIME ZONE X$ columns.
* **F_CLOB** : Search for a clob value in CLOB X$ columns.

### FUNCTION PARAMETERS: ###

All functions above accept up to 3 parameters:

* 1st param: **p_input** (mandatory) - The value that you are searching. For F_STRING, wild cards '%' are accepted. For F_CLOB, the value will always be searched as substr. For others, will do an exact match.
* 2nd param: **p_tab_name** (optional) - You can optionally filter what X$ tables will be included in the search also using wild cards. By default, all are included: 'X$%'
* 3rd param: **p_col_name** (optional) - You can optionally filter what X$ columns will be included in the search also using wild cards. By default, all are included: '%'

### VARIABLES: ###

You can also change some package variables to change the default behaviour of the program:

* **SKIP_DIAG** (default TRUE) : By default the search functions will skip X$ tables starting with X$DIAG. Change to FALSE to include all.
* **SKIP_NONINDEXED** (default FALSE) : By default the search functions will scan all X$ columns, including the non-indexed. Change to TRUE to skip them.
* **DEBUG** (default FALSE) : Change to TRUE to enable DEBUG mode and see execution step by step in the query output.

## Instructions ##

For documentation and sample, check [sample.sql](https://github.com/dbarj/pkg_xdollar_search/blob/master/sample.sql) file or http://www.dbarj.com.br/en/pkg_xdollar_search/

### Output format: ###

All functions return a pipelined table in the following format:

Column Name | Type | Description
----------- | ---- | -----------
TABLE_NAME | VARCHAR2(30) | X$ table where value was found.
COLUMN_NAME | VARCHAR2(30) | X$ column where value was found.
ADDR | RAW(8) | ADDR of X$ table.
INDX | NUMBER | INDX of X$ table.
CONTENTS | VARCHAR2(4000) | Content found in the column.
SEARCH_QRY | VARCHAR2(1000) | Query to retrieve the entire row for the found value.
EXEC_TIME_SECS | NUMBER | Executed time in seconds.