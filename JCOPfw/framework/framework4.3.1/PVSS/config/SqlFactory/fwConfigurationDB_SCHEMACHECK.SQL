#ifndef _fwConfigurationDB_SCHEMACHECK_SQL_
#define _fwConfigurationDB_SCHEMACHECK_SQL_
#ifndef _SCHEMA_VERSION_
#error _SCHEMA_VERSION_ macro not defined!
#endif

---------------------------------------------------------------
--
-- fwConfigurationDB upgrade script to version _SCHEMA_VERSION_
--
-- Author: Piotr Golonka, CERN EN/ICE-SCD
---------------------------------------------------------------

-- These are for SQLPLUS...
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

declare
    rc number;
    cnt number;
    lockhandle varchar2(128);
begin
    DBMS_OUTPUT.new_line();
    DBMS_OUTPUT.put_line('-------------------------------------------------------------');
    DBMS_OUTPUT.put_line('  fwConfigurationDB schema upgrade to version '||_SCHEMA_VERSION_);
    DBMS_OUTPUT.put_line('-------------------------------------------------------------');
    DBMS_OUTPUT.new_line();
    DBMS_OUTPUT.new_line();
    DBMS_OUTPUT.new_line();
    DBMS_OUTPUT.new_line();
    DBMS_OUTPUT.new_line();
    DBMS_OUTPUT.new_line();
    DBMS_OUTPUT.new_line();

-- Check if we run from schema owner account

    if user!=sys_context('USERENV', 'CURRENT_SCHEMA') then
	raise_application_error(-20101,'fwConfigurationDB: schema upgrade must be performed from schema owner account');
    end if;

    DBMS_OUTPUT.put_line(' [OK] running from schema owner account:'||USER);

-- Try to obtain the lock
    dbms_lock.allocate_unique('fwConfigurationDB_SchemaUpdateLock', LOCKHANDLE);
    rc:=dbms_lock.request(lockhandle,dbms_lock.X_MODE,3,true);
    if (rc!=0) then
	case rc
	    when 1 then raise_application_error(-20102,'fwConfigurationDB: Could not obtain schema upgrade lock (timeout)');
	    when 2 then raise_application_error(-20103,'fwConfigurationDB: Could not obtain schema upgrade lock (deadlock)');
	    when 3 then raise_application_error(-20104,'fwConfigurationDB: Could not obtain schema upgrade lock (parameter error)');
	    when 4 then raise_application_error(-20105,'fwConfigurationDB: Could not obtain schema upgrade lock (already owns the lock)');
	    when 5 then raise_application_error(-20106,'fwConfigurationDB: Could not obtain schema upgrade lock (illegal lock handle)');
	    else raise_application_error(-20200-rc,'fwConfigurationDB: Could not obtain schema upgrade lock: unknown err='||rc||' from DBMS_LOCK.REQUEST()');
	end case;
    end if;

    DBMS_OUTPUT.put_line(' [OK] obtained the lock' );

-- Check if we have the schema at all...
    select count(*) into cnt from cat where TABLE_NAME='V_CONFDB';

    if ( cnt < 1) then 
	raise_application_error(-20110,'fwConfigurationDB: schema not present');
    end if;

    DBMS_OUTPUT.put_line(' [OK] confirmed schema is there' );

    execute immediate 'select schema_version from v_confdb' into cnt;

    if (cnt = _SCHEMA_VERSION_) then
	raise_application_error(-20120,'fwConfigurationDB: schema already at version '||_SCHEMA_VERSION_);
    elsif (cnt > _SCHEMA_VERSION_) then
	raise_application_error(-20121,'fwConfigurationDB: schema at version '||cnt||', newer than required '||_SCHEMA_VERSION_);
    end if;

    DBMS_OUTPUT.put_line(' [OK] current schema version is '||cnt||', will upgrade to version '||_SCHEMA_VERSION_);

-- remember to release the lock at the end!
--    rc:=DBMS_LOCK.RELEASE(lockhandle);


end;;
/

#endif
