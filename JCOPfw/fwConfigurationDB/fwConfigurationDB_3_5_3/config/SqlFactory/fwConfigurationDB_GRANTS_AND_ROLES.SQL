CREATE or replace FUNCTION fwConfigurationDB_grant(userOrRole varchar2,
						   what varchar2,
						   revokeMode number default 0 )   RETURN number 
is
    stmt1 varchar2(128);
    stmt2 varchar2(128);
    already_granted exception;
    grant_to_self exception;
    PRAGMA EXCEPTION_INIT(already_granted,-1927);
    PRAGMA EXCEPTION_INIT(grant_to_self,-1749);

begin
    if ( what != 'READER' AND what != 'WRITER' AND what != 'ALL') then
	raise_application_error(-20010,'fwConfigurationDB_grant: bad value for the WHAT parameter:'||what);
	return 1;
    end if;

    if ( revokeMode != 0) then
	stmt1 := ' REVOKE ';
	stmt2 := ' FROM ';
    else
	stmt1 := ' GRANT ';
	stmt2 := ' TO ';
    end if;

    -- whether the WHAT is READER,WRITERor ALL we grant all the read-related grants...
	execute immediate stmt1||'SELECT  ON HIERARCHIES            '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON DEVICE_TYPES           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON ITEMS                  '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON RECIPES                '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON RECIPE_VERSIONS        '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON RECIPE_DATA            '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON RECIPE_TAGS            '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON DEVICE_ELEMENTS        '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ITEMS_NEW       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ITEMPROPS       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_DESC            '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON REFERENCES             '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_VALUES          '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_VALUES_BIG      '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ADDRESSES       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ALERTS          '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_DPEALERTS       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_SUMALERTS       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ALERTS_MISC     '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ARCHIVING       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_DPFUNCTIONS     '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_CONVERSIONS     '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_PVRANGES        '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_SMOOTHING       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_UF              '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_GENERAL         '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_RECIPESALL           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_REFERENCES           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_CONFIG_ITEMS         '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_DEVICE_CONFIGS       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_DEVICE_CONFIGS_ALL   '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_ITEM_PROPERTIES      '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_CONFIG_ALERTS        '||stmt2||userOrRole;
	execute immediate stmt1||'ALL     ON CDB_API_PARAMS         '||stmt2||userOrRole;
	execute immediate stmt1||'ALL     ON TMP_ITEM_PROPS         '||stmt2||userOrRole;
	execute immediate stmt1||'EXECUTE ON fwConfigurationDB      '||stmt2||userOrRole;
	execute immediate stmt1||'EXECUTE ON lstAgg                 '||stmt2||userOrRole;
	execute immediate stmt1||'EXECUTE ON lstAggNum              '||stmt2||userOrRole;

    if ( what = 'WRITER' OR what = 'ALL' ) then 

	execute immediate stmt1||'INSERT,UPDATE         ON HIERARCHIES            '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON DEVICE_TYPES           '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON ITEMS                  '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE,DELETE  ON RECIPES                '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE,DELETE  ON RECIPE_VERSIONS        '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE,DELETE  ON RECIPE_DATA            '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE,DELETE  ON RECIPE_TAGS            '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON DEVICE_ELEMENTS        '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ITEMS_NEW       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ITEMPROPS      '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_DESC            '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON REFERENCES             '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_VALUES          '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_VALUES_BIG      '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ADDRESSES       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ALERTS          '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_DPEALERTS       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_SUMALERTS       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ALERTS_MISC     '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ARCHIVING       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_DPFUNCTIONS     '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_CONVERSIONS     '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_PVRANGES        '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_SMOOTHING       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_UF              '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_GENERAL         '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON CITEM_ID_SEQ           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON CONF_ID_SEQ            '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON DEVELEM_ID_SEQ         '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON DPT_ID_SEQ             '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON IPROP_ID_SEQ           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON ITEMS_ID_SEQ           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON RECIPES_RVER_SEQ       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON RECIPES_TAGID_SEQ      '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON RECIPE_DATA_PROPID_SEQ '||stmt2||userOrRole;

    end if;

    return 0;
exception
  when already_granted then
       -- we simply accept it
       return 0;
  when grant_to_self then
       -- we simply accept it
       return 0;
end;
/
