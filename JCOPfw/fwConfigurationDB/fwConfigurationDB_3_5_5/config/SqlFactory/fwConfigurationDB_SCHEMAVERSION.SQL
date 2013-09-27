----------------------------------------------------------------------------
-- as the last element we create our "internal" view, which
-- is used to determine if the schema exists.
----------------------------------------------------------------------------

#ifndef _SCHEMA_VERSION_
#error macro _SCHEMA_VERSION_ not defined
#endif

DECLARE
    NOW VARCHAR2(32);
    VERS VARCHAR(32);
BEGIN
NOW:=TO_CHAR(SYSTIMESTAMP,'YYYY-MM-DD HH24:MI:SS');
VERS:=TO_CHAR(_SCHEMA_VERSION_,'9.99');
EXECUTE IMMEDIATE ' CREATE OR REPLACE VIEW v_confdb (SCHEMA_VERSION,SCHEMA_CREATED)'||
    ' AS SELECT '''||VERS||''', '''||NOW||''' FROM DUAL';
END;
/

GRANT SELECT  ON V_CONFDB TO PUBLIC;
