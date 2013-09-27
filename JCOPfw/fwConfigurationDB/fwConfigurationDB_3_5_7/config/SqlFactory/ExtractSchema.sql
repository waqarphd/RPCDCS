SET ECHO OFF NEWP 0 SPA 0 PAGES 0 FEED OFF HEAD OFF TRIMS ON
-- to make the whole contents print
set long 100000;
set linesize 1000;
set longc 100000;
set wrap on;

create global temporary table API(objectName varchar2(128),
		 objectType varchar2(32),
		 objectCode clob);

set serveroutput on;


DECLARE

    csv VARCHAR2(4000);
    numTables NUMBER;
    numSequences NUMBER;
    numViews NUMBER;
    numInternals NUMBER;

    cdb_views DBMS_UTILITY.UNCL_ARRAY;
    cdb_sequences DBMS_UTILITY.UNCL_ARRAY;
    cdb_tables DBMS_UTILITY.UNCL_ARRAY;
    cdb_internals DBMS_UTILITY.UNCL_ARRAY;

    objname varchar2(128);
    
    -- we need to catch the exception when there is no index/constraint on a table
    no_object_detected exception;
    PRAGMA EXCEPTION_INIT(no_object_detected, -31608);
    
BEGIN
--   dbms_output.enable(1000000); -- not needed from 10gR2

   select views into csv from V_CONFDB;
   DBMS_UTILITY.COMMA_TO_TABLE (csv, numViews, cdb_views);
   DBMS_OUTPUT.PUT_LINE('Views parsed OK');
      
   select tables into csv from V_CONFDB;
   DBMS_UTILITY.COMMA_TO_TABLE (csv, numTables, cdb_tables);
   DBMS_OUTPUT.PUT_LINE('Tables parsed OK');

   select sequences into csv from V_CONFDB;
   DBMS_UTILITY.COMMA_TO_TABLE (csv, numSequences, cdb_sequences);
   DBMS_OUTPUT.PUT_LINE('Sequences parsed OK');

   select internal into csv from V_CONFDB;
   DBMS_UTILITY.COMMA_TO_TABLE (csv, numInternals, cdb_internals);
   DBMS_OUTPUT.PUT_LINE('Internals parsed OK');



   -- firstly extract tables, with their indices   
   FOR rownum IN 1 .. numTables
      LOOP
        objname:=ltrim(rtrim(cdb_tables(rownum)));
--        DBMS_OUTPUT.PUT_LINE('Processing TABLE:'||objname);
        insert into API(objectName,objectType,objectCode)  
    		(SELECT objname,'TABLE',DBMS_METADATA.GET_DDL('TABLE', objname)||';' from dual);
  END LOOP;

   -- add table's indices
   FOR rownum IN 1 .. numTables
      LOOP
        begin
        objname:=ltrim(rtrim(cdb_tables(rownum)));
        insert into API(objectName,objectType,objectCode)  
	    	(SELECT objname,'INDEX',DBMS_METADATA.GET_DEPENDENT_DDL('INDEX', objname)||';' from dual);
	EXCEPTION
	    WHEN NO_OBJECT_DETECTED then 
		null;
	end;
  END LOOP;

   -- extract views
   FOR rownum IN 1 .. numViews
      LOOP
        objname:=ltrim(rtrim(cdb_views(rownum)));
        DBMS_OUTPUT.PUT_LINE('Processing VIEW:'||objname);
        insert into API(objectName,objectType,objectCode)  
    		(SELECT objname,'VIEW',DBMS_METADATA.GET_DDL('VIEW', objname)||';' from dual);
  END LOOP;

  -- extract table constraints
   FOR rownum IN 1 .. numTables
      LOOP
        begin
        objname:=ltrim(rtrim(cdb_tables(rownum)));
        insert into API(objectName,objectType,objectCode)  
		(SELECT objname,'CONSTRAINT',DBMS_METADATA.GET_DEPENDENT_DDL('REF_CONSTRAINT', objname)||';' from dual);

	EXCEPTION
	    WHEN NO_OBJECT_DETECTED then 
		null;
	end;
  END LOOP;

   -- extract sequences
   FOR rownum IN 1 .. numSequences
      LOOP
        objname:=ltrim(rtrim(cdb_sequences(rownum)));
        DBMS_OUTPUT.PUT_LINE('Processing sequence:'||objname);
        insert into API(objectName,objectType,objectCode)  
    		(SELECT objname,'SEQUENCE',DBMS_METADATA.GET_DDL('SEQUENCE', objname)||';' from dual);
  END LOOP;


  -- extract special ones...
   FOR rownum IN 1 .. numInternals
      LOOP
        objname:=ltrim(rtrim(cdb_internals(rownum)));
        DBMS_OUTPUT.PUT_LINE('Processing INTERNAL TABLE:'||objname);
        insert into API(objectName,objectType,objectCode)  
    		(SELECT objname,'INTERNAL TABLE',DBMS_METADATA.GET_DDL('TABLE', objname)||';' from dual);
  END LOOP;

END;
/

spool ExtractedTables.sql;
--SELECT '--'||objectType||':'||objectName,objectCode FROM API;
SELECT objectCode FROM API;
Spool off;
DROP TABLE API;

spool ExtractedAPI.sql;
SELECT DBMS_METADATA.GET_DDL('PACKAGE','FWCONFIGURATIONDB') FROM dual;
--SELECT DBMS_METADATA.GET_DDL('PACKAGE_BODY','FWCONFIGURATIONDB') FROM dual;
Spool off;



QUIT;
