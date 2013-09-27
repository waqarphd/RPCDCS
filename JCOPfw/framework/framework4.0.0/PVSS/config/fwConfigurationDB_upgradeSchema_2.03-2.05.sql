-- bring DPTYPE identifiers up to date for the ITEMS table:

begin
-- select the names of dptypes that have some history
for dpt in (select dptype from
(select dptype, count(dptype) cnt from device_types  group by dptype)
 where cnt>1)
loop
  update items set dpt_id=(select dpt_id from device_types where dptype=dpt.dptype and valid_to is null)
  where dpt_id in (select dpt_id from device_types where dptype=dpt.dptype and valid_to is not null);
end loop;
end;
/


-----------------------------------------------------------------------------
--
-- The PL/SQL package containing fwConfigurationDB functions
--
-- Unofficial documentation is at
-- https://twiki.cern.ch/twiki/bin/view/Controls/ConfigurationDBTool#PlSqlApi
-----------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE fwConfigurationDB
IS

PROCEDURE t_getSequenceNumbers(
	sequenceName      IN VARCHAR2,
	n                 IN NUMBER DEFAULT 1)
;

PROCEDURE getDevicesInRecipe(
	recipeName IN VARCHAR2,
	deviceFilter IN VARCHAR2 DEFAULT NULL,
	validAt IN DATE DEFAULT NULL)
;

PROCEDURE getDevicesInConfiguration(
	configurationName IN VARCHAR2,
	deviceFilter IN VARCHAR2 DEFAULT NULL)
;

PROCEDURE getRecipe(
	recipeName        IN VARCHAR2,
	validAt           IN DATE DEFAULT NULL)
;

PROCEDURE getRecipesList(
    recipeNameFilter IN varchar2 default null,
    deviceFilter IN varchar2 default null,
    recipeCommentFilter IN varchar2 default '*',
    recipeTypeFilter IN varchar2 default '*')
;

PROCEDURE getConfigurationsList(
    configurationNameFilter IN varchar2 default null)
;

PROCEDURE createRecipe(
	recipeName        IN VARCHAR2,
	recipeDescription IN VARCHAR2 default null)
;

PROCEDURE storeRecipe(
	recipeName        IN VARCHAR2,
	versionDescription IN VARCHAR2 DEFAULT NULL,
	userCreated IN VARCHAR2 DEFAULT NULL )
;


PROCEDURE getReferences(
	configurationName IN VARCHAR2,
	validAt IN DATE DEFAULT NULL)
;

PROCEDURE setReferences(
	configurationName IN VARCHAR2)
;

PROCEDURE getReferenceHistory(
	configurationName IN VARCHAR2,
	startDate IN DATE DEFAULT NULL,
	endDate IN DATE DEFAULT NULL)
;


-- this one is for private use
FUNCTION checkInputTable(checkS2 number default 1) RETURN NUMBER;

END fwConfigurationDB;
/


CREATE OR REPLACE PACKAGE BODY fwConfigurationDB

IS

TYPE recipeRecordType is RECORD (
	    device	v_recipesAll.dpname%type,
	    property  	v_recipesAll.property%type,
	    deviceId	v_recipesAll.item_id%type,
	    propId 	v_recipesAll.propid%type,
	    propType 	v_recipesAll.proptype%type,
	    recipeVer	v_recipesAll.recipe_Ver%type,
	    dpType	v_recipesAll.dptype%type,
	    deviceModel	v_recipesAll.detail%type,
	    validFrom 	v_recipesAll.valid_from%type,
	    validTo 	v_recipesAll.valid_to%type,
	    hasValue 	v_recipesAll.has_Value%type,
	    hasAlert 	v_recipesAll.has_Alert%type,
	    propValue 	v_recipesAll.propvalue%type,
	    hierarchy 	v_recipesAll.hierarchy%type,
	    alertType 	v_recipesAll.alert_Type%type,
	    alertActive v_recipesAll.alert_Active%type,
	    alertClasses v_recipesAll.alert_Classes%type,
	    alertTexts 	v_recipesAll.alert_Texts%type,
	    alertLimits v_recipesAll.alert_Limits%type

);

-----------------------------------------------
PROCEDURE t_getSequenceNumbers(
	sequenceName IN varchar2,
	n            IN NUMBER)
IS
	idx number:=1;
	val NUMBER;
	NoSuchSequence exception;
BEGIN
	EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';
	LOOP
	    EXECUTE IMMEDIATE 'SELECT '||sequenceName||'.NEXTVAL FROM DUAL' INTO val;
	    INSERT INTO cdb_api_params(i1) VALUES (val);
	    idx:=idx+1;
	    exit when idx>n;
	END LOOP;

	EXCEPTION
	    WHEN NoSuchSequence
	    THEN
		RAISE_APPLICATION_ERROR(-20001, 'Bad sequence name:'||TO_CHAR(sequenceName));
END t_getSequenceNumbers;


-----------------------------------------------------------------------------
-- This is a private function that checks the consistency of input in the  
-- CDB_API_PARAMS table. We assume that input data is only in column S1    
-- or - optionally if checkS2 parameter is  null - also in column S2.      
-- All other columns MUST be empty - otherwise we interpret this situation 
-- as the user forgot to cleanup the table after the previous use, and     
-- we report an error                                                      
-----------------------------------------------------------------------------
FUNCTION checkInputTable(checkS2 number default 1) RETURN NUMBER
IS
    numEntries NUMBER;
    checkStmt  varchar2(2000);
BEGIN

    checkStmt := 'SELECT count(*) from CDB_API_PARAMS
	where I1 is not null 
	OR i2 is not null
	OR i3 is not null
	OR i4 is not null
	OR i5 is not null
	OR i6 is not null
	OR i7 is not null
	OR i8 is not null
	OR s3 is not null
	OR s4 is not null
	OR s5 is not null
	OR s6 is not null
	OR s7 is not null
	OR s8 is not null
	OR s9 is not null
	OR s10 is not null
	OR d1 is not null
	OR d2 is not null
	OR b1 is not null';
		
    if (checkS2 is not null) then
	checkStmt := checkStmt || ' or S2 is not null';
    end if;

    execute immediate checkStmt INTO numEntries;

    if (numEntries > 0) THEN
	RAISE_APPLICATION_ERROR(-20001,'fwConfigurationDB: Input table CDB_API_PARAM not consistent. Forgot to TRUNC it before use?');
    END IF;
    
    -- count the number of data rows and return it
    SELECT count(*) INTO numEntries from CDB_API_PARAMS;


    RETURN numEntries;
END;


-----------------------------------------------------------
-- finds the devices that are present in a recipe        
-- note that it appends the result to CDB_API_PARAMS(s1) 
-- note also that is accepts "*" as wildcard character   
--   and not only the Oracle-specific "%"                
-----------------------------------------------------------
PROCEDURE getDevicesInRecipe(
	recipeName IN VARCHAR2,
	deviceFilter IN VARCHAR2 DEFAULT NULL,
	validAt IN DATE DEFAULT NULL)
IS

	num number;
	devFilter varchar2(128) := deviceFilter;
	TYPE recCurType IS REF CURSOR;
	recipesCur recCurType;

BEGIN
	-- check recipe name
	SELECT count(*)  INTO num from RECIPES WHERE name=recipeName;
	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.getDevicesInRecipe: no such recipe:'||recipeName);
	end if;

	-- verify that input table is correct (no entries apart from - maybe - S1)
	SELECT checkInputTable() INTO num from DUAL;    

	-- make sure the filter is right
	if devFilter = '' then devFilter:='%'; end if;
	if devFilter IS NULL then devFilter:='%'; end if;
	

	IF validAt IS NULL THEN 
	    insert into cdb_api_params(s1) select unique dpname from v_recipesAll r
		where r.tag=recipeName
		and r.valid_to is null
		and r.dpname like replace(devFilter,'*','%');		
	else 
	    insert into cdb_api_params(s1) select unique dpname from v_recipesAll r
		where r.tag=recipeName
		AND VALID_FROM <= validAt
		AND ( (VALID_TO IS NULL) OR (VALID_TO >= validAt ) )
		and r.dpname like replace(devFilter,'*','%');
	end if;
	


END;


PROCEDURE getRecipe(
	recipeName IN VARCHAR2,
	validAt IN DATE DEFAULT NULL)
IS

	num number;
	
	recipeData recipeRecordType;
	outTblReady NUMBER := NULL;

	TYPE recCurType IS REF CURSOR return recipeRecordType;
	recipesCur recCurType;

BEGIN

	-- check the recipe name 
	SELECT count(*)  INTO num from RECIPES WHERE name=recipeName;
	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.getRecipe: no such recipe:'||recipeName);
	end if;

	-- verify that the input in the CDB_API_PARAMS is right
	-- checkInputTable() will throw ORA -20001 if the table is not OK
	-- otherwise it will return the number of entries
	SELECT checkInputTable() INTO num from DUAL;
	
	-- prepare the cursor. If validTo is null the actual SELECT is much simpler...
	IF validAt IS NULL THEN 

	
	    if num = 0 then 
		--  no device list specified
		open recipesCur FOR 
		    select dpname,
			property,
			item_id,
			propid,
			proptype,
			recipe_Ver,
			dptype,
			detail,
			valid_from,
			valid_to,
			has_value,
			has_alert,
			propvalue,
			hierarchy,
			alert_Type,
			alert_Active,
			alert_Classes,
			alert_Texts,
		    alert_Limits 
		    from v_recipesAll
		    where tag=recipeName
		    and valid_to is null
		    ORDER BY ITEM_ID;
	    else 
		open recipesCur FOR 
		    select dpname,
			property,
			item_id,
			propid,
			proptype,
			recipe_Ver,
			dptype,
			detail,
			valid_from,
			valid_to,
			has_value,
			has_alert,
			propvalue,
			hierarchy,
			alert_Type,
			alert_Active,
			alert_Classes,
			alert_Texts,
			alert_Limits 
		    from v_recipesAll rec
		    where rec.tag=recipeName
		    and rec.valid_to is null
		    and rec.dpname in (select S1 from cdb_api_params)
		    ORDER BY rec.ITEM_ID;
	    end if;

	ELSE
	    if num = 0 then 
		--  no device list specified
		open recipesCur FOR 
		    select dpname,property,item_id,propid,proptype,recipe_Ver,
			dptype,
			detail,
			valid_from,valid_to,
			has_value,
			has_alert,
		    propvalue,hierarchy,alert_Type,alert_Active,alert_Classes,alert_Texts,alert_Limits 
		    from v_recipesAll 
		    where tag=recipeName
		    AND VALID_FROM <= validAt
		    AND ( (VALID_TO IS NULL) OR (VALID_TO >= validAt ) )
		    ORDER BY ITEM_ID;
	    else 
		open recipesCur FOR 
		    select dpname,property,item_id,propid,proptype,recipe_Ver,
			dptype,
			detail,
			valid_from,valid_to,
			has_value,
			has_alert,
		    propvalue,hierarchy,alert_Type,alert_Active,alert_Classes,alert_Texts,alert_Limits 
		    from v_recipesAll rec
		    where tag=recipeName
		    and dpname in (select s1 from cdb_api_params)
		    AND VALID_FROM <= validAt
		    AND ( (VALID_TO IS NULL) OR (VALID_TO >= validAt ) )
		    ORDER BY ITEM_ID;
	    end if;


	END IF;


	loop
		fetch recipesCur into recipeData;

		-- only here we should clean the input table! i.e. after the first fetch!
		if outTblReady IS NULL then
		    EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';
		    outTblReady:=1;
		end if;

		exit when recipesCur%notfound;

		 insert into CDB_API_PARAMS(
		    i1,i2,i3,i4,i5,i6,i7,i8,
		    s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,
		    d1,d2,b1
		 ) values( 
		    recipeData.propId, 		--i1
		    recipeData.propType, 	--i2
		    recipeData.recipeVer, 	--i3
		    recipeData.hasValue, 	--i4
		    recipeData.hasAlert, 	--i5
		    recipeData.alertType, 	--i6
		    recipeData.alertActive, 	--i7
		    recipeData.deviceId,	--i8
		    recipeData.device, 		--s1 (512)
		    recipeData.property,	--s2 (512)
		    recipeData.dpType, 	--s3 (256)
		    recipeData.deviceModel, 	--s4 (256)
		    recipeData.alertLimits, 	--s5 (256)
		    recipeData.alertClasses, 	--s6 (256)
		    recipeData.alertTexts, 	--s7 (4000)
		    recipeData.propValue,	--s8 (4000)
		    recipeData.hierarchy,       --s9 (16)
		    NULL,                       --s10 (16)
		    recipeData.validFrom, 	--d1
		    recipeData.validTo, 	--d2
		    NULL  			--b1
		 );

	end loop;

	close recipesCur;

END;

-------------------------------------
PROCEDURE createRecipe(
	recipeName        IN VARCHAR2,
	recipeDescription IN VARCHAR2 DEFAULT NULL)
IS
	num number;

BEGIN

	-- check the recipe name 
	SELECT count(tagid) INTO num from RECIPES WHERE name=recipeName;

	if (num > 0) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.createRecipe: recipe already exists:'||recipeName);
	end if;
	
	insert into recipes(tagid, name,hver,description,recipe_type)
	    values(RECIPES_TAGID_SEQ.NEXTVAL,recipeName,NULL,recipeDescription,NULL);


END;


-------------------------------------
PROCEDURE storeRecipe(
	recipeName        IN VARCHAR2,
	versionDescription IN VARCHAR2 DEFAULT NULL,
	userCreated	IN VARCHAR2 DEFAULT NULL)
IS
	num number;

	curTime cdb_api_params.d1%TYPE := SYSDATE;
	recipeId recipes.tagid%TYPE;

	rVer number;
	devName cdb_api_params.s1%TYPE;
	propName cdb_api_params.s2%TYPE;
	
	TYPE refCurType IS REF CURSOR;
	cur refCurType;

BEGIN

	-- check the recipe name 
	open cur for SELECT tagid from RECIPES WHERE name=recipeName;
	fetch cur into recipeId;

	if (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.storeRecipe: no such recipe:'||recipeName);
	end if;
	close cur;
	
	--complete datapoint ID's:
	update cdb_api_params c set i8=(
	    select i.id from items i where i.dpname=c.s1);


	-- make sure that all the devices were resolved - otherwise report an error
	open cur for 
	    select s1 from cdb_api_params where i8 is null;
	fetch cur into devName;
	if NOT (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20023, 'fwConfigurationDB.storeRecipe: Device not found in database:'||devName);
	end if;
	close cur;



	-- complete DpElement's ID
	update cdb_api_params c set i2=(
	    select vdc.develem_id from v_device_configs vdc, items i
		where vdc.elementname=c.s2
		AND vdc.dpt_id=i.dpt_id
		and i.id=i8
	    );

	-- make sure that all the properties were resolved - otherwise report an error
	open cur for 
	    select s1,s2 from cdb_api_params where i2 is null;
	fetch cur into devName,propName;
	if NOT (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20024, 'fwConfigurationDB.storeRecipe: Device element not found in database:'||devName||propName);
	end if;
	close cur;


	-- generate next ordinal numver for Recipe Version, and store new version
	EXECUTE IMMEDIATE 'SELECT RECIPES_RVER_SEQ.NEXTVAL FROM DUAL' INTO rVer;

	insert into recipe_versions(rver,description,user_created,date_created)
	    values(rver,versionDescription,userCreated,curTime);

	update cdb_api_params set i3=rVer;


	-- STEP 1: for the elements, for which we already have PropId passed in I1,
	-- we simply do the manipulation with tags, and do not store the data again!
	
	-- *) remove the entries from CDB_API_PARAMS which are already up to date
	--    we do not need to do anything there!

	delete from cdb_api_params 
	    where i1 in (select propid from recipe_tags where valid_to is null and tagid=recipeId);
	    
	-- *) invalidate previous tags
    	update recipe_tags rt set valid_to=curTime where
	    propid IN (SELECT i1 FROM CDB_API_PARAMS c where (c.i1 is not null) ) and tagid=recipeId;

	-- *) insert the new tags into the tags table
        insert into recipe_tags(tagid,propid,valid_from,valid_to)
            select REC_ID,cdb.i1,CUR_TIM,NULL
            from (select recipeId REC_ID, curtime CUR_TIM  from dual), CDB_API_PARAMS cdb
            where cdb.i1 is not null;


	-- *) HACK! We need to mark the devices, for which we do not need to invalidate
        --    all the elements; say, you only update one element out of 5, these remaining
        --    four are treated above, the fifth is treated below, and at the end
        --    the tags to the four are closed... We therefore mark the entries by setting
        --    i4 to 1; Then, in the final "tag closing" step we will need to invalidate
        --    only the properties being modified, and not all the properties that
        --    belong to the device...
	update cdb_api_params set i4=1
	    where i1 in (select propid from recipe_tags where valid_to is null and tagId=recipeId);
        

	-- *) already processed, so delete these entries
	delete from cdb_api_params where i1 is not null;



	-- STEP 2: process the entries that did not have I1
	--         i.e. the data "that has changed"

	-- assign property id's, drawing them from sequence
	-- note that we cannot group this update statement with other updates,
	-- due to use of sequence
	update cdb_api_params set i1=RECIPE_DATA_PROPID_SEQ.NEXTVAL;

	-- insert recipe data
	insert into recipe_data(
	    propid,
	    rver,
	    id,
	    develem_id,
	    has_value,
	    has_alert,
	    propvalue,
	    alert_type,
	    alert_active,
	    alert_classes,
	    alert_texts,
	    alert_limits
	    ) 
	select 	
	    i1,
	    i3,
	    i8,
	    i2,
	    i4,
	    i5,
	    s8,
	    i6,
	    i7,
	    s6,
	    s7,
	    s5
	 from cdb_api_params;


	-- invalidate existing recipe data
	-- *) at first all the things with i4 being NULL
	--    (i.e. invalidate the whole device) - see comments above
	update recipe_tags set valid_to=curTime where
	    propid IN (SELECT PROPID FROM V_RECIPESALL r, CDB_API_PARAMS c 
			WHERE r.TAG=recipeName 
			AND r.ITEM_ID=c.i8 
			AND c.i4 IS NULL
			and r.valid_to is null)
	    and tagId=recipeId;
	-- *) then all the ones that have i5 set to 1
	update recipe_tags set valid_to=curTime where
	    propid IN (SELECT PROPID FROM V_RECIPESALL r, CDB_API_PARAMS c 
			WHERE r.TAG=recipeName 
			AND r.ITEM_ID=c.i8 
			AND r.develem_id=c.i2
			AND c.i4 IS NOT NULL
			and r.valid_to is null)
	    and tagId=recipeId;
	

	-- insert the new tags into tags table
        insert into recipe_tags(tagid,propid,valid_from,valid_to)
            select REC_ID,cdb.i1,CUR_TIM,NULL
            from (select recipeId REC_ID, curtime CUR_TIM  from dual), CDB_API_PARAMS cdb;

END;

-------------------------------------
PROCEDURE getReferences(
	configurationName IN VARCHAR2,
	validAt IN DATE DEFAULT NULL)
IS


	num number;
	
	outTblReady NUMBER := NULL;

	TYPE cfgCurType IS REF CURSOR;
	configCur cfgCurType;

	devId references.id%TYPE;
	refId references.ref_id%TYPE;
	device items.dpname%TYPE;
	refdevice items.dpname%TYPE;
	
	hierarchy hierarchies.htype%TYPE;
	refhierarchy hierarchies.htype%TYPE;
	validFrom references.valid_from%TYPE;
	validTo references.valid_to%TYPE;
BEGIN

	-- check the configuration name 
	SELECT count(*)  INTO num FROM CONFIG_DESC WHERE conf_tag=configurationName;

	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20005, 'fwConfigurationDB.getReferences: no such configuration:'||configurationName);
	end if;


	-- verify that the input in the CDB_API_PARAMS is right
	-- checkInputTable() will throw ORA -20001 if the table is not OK
	-- otherwise it will return the number of entries
	SELECT checkInputTable() INTO num from DUAL;

	-- prepare the cursor. If validTo is null the actual SELECT is much simpler...
	IF validAt IS NULL THEN

	    if num = 0 then 
		open configCur FOR 
		    SELECT  r.id,r.ref_id,i.dpname, j.dpname, g.htype, h.htype, r.valid_from, r.valid_to
		    FROM config_desc cd,references r,items i, items j, hierarchies g,hierarchies h
		    WHERE  cd.conf_id=r.refver 
			AND r.id=i.id
			AND r.ref_id=j.id
			AND i.hver=g.hver
    			AND j.hver=h.hver
	    		AND cd.conf_tag=configurationName
			AND r.VALID_TO IS NULL;
	    else
		open configCur FOR 
		    SELECT   r.id,r.ref_id,i.dpname, j.dpname, g.htype, h.htype, r.valid_from, r.valid_to
		    FROM config_desc cd,references r,items i, items j, hierarchies g,hierarchies h
		    WHERE  cd.conf_id=r.refver 
			AND r.id=i.id
			AND r.ref_id=j.id
			AND i.hver=g.hver
    			AND j.hver=h.hver
	    		AND cd.conf_tag=configurationName
			AND r.VALID_TO IS NULL
			AND i.dpname in (select S1 from cdb_api_params);
	    end if;
	ELSE
	    if num = 0 then 

		open configCur FOR 
		    SELECT  r.id,r.ref_id,i.dpname, j.dpname, g.htype, h.htype, r.valid_from, r.valid_to
		    FROM config_desc cd,references r,items i, items j, hierarchies g,hierarchies h
		    WHERE 
			cd.conf_id=r.refver
			AND r.id=i.id
			AND r.ref_id=j.id
			AND i.hver=g.hver
    			AND j.hver=h.hver
	    		AND cd.conf_tag=configurationName
			AND r.VALID_FROM <= validAt
			AND ( (r.VALID_TO IS NULL) OR (r.VALID_TO >= validAt ) );
	    else
		open configCur FOR 
		    SELECT  r.id,r.ref_id,i.dpname, j.dpname, g.htype, h.htype, r.valid_from, r.valid_to
		    FROM config_desc cd,references r,items i, items j, hierarchies g,hierarchies h
		    WHERE 
			cd.conf_id=r.refver
			AND r.id=i.id
			AND r.ref_id=j.id
			AND i.hver=g.hver
    			AND j.hver=h.hver
	    		AND cd.conf_tag=configurationName
			AND r.VALID_FROM <= validAt
			AND ( (r.VALID_TO IS NULL) OR (r.VALID_TO >= validAt ) )
			AND i.dpname in (select S1 from cdb_api_params);
	    end if;
	END IF;

	loop
	    fetch configCur into devId,refId,device,refDevice,hierarchy,refHierarchy,validFrom,validTo;
	    -- only here we should clean the input table! i.e. after the first fetch!
	    if outTblReady IS NULL then
		EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';
		outTblReady:=1;
	    end if;

	    exit when configCur%notfound;

	    insert into CDB_API_PARAMS(i1,i2,s1,s2,s3,s4,d1,d2)
		 values( 
		    devId, --i1
		    refId, --i2
		    device, --s1
		    refdevice, --s2
		    hierarchy, --s3
		    refhierarchy, --s4
		    validFrom, --d1
		    validTo --d2
		 );

	end loop;

	close configCur;

END;

-------------------------------------
PROCEDURE setReferences(
	configurationName IN VARCHAR2)
IS

	num number;
	numDevs number;
	numRefs number;
	
	curTime cdb_api_params.d1%TYPE := SYSDATE;

	refName cdb_api_params.s1%TYPE;
	devName cdb_api_params.s2%TYPE;

	TYPE refCurType IS REF CURSOR;
	cur refCurType;

BEGIN
	-- check the configuration name 
	SELECT count(*)  INTO num FROM CONFIG_DESC WHERE conf_tag=configurationName;

	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20005, 'fwConfigurationDB.setReferences: no such configuration:'||configurationName);
	end if;

	-- device names are in S1, and corresponding references in S2
	-- make sure they are all correct...

	SELECT checkInputTable(NULL) INTO num from DUAL;
	SELECT count(unique(s1))  INTO numRefs FROM cdb_api_params where s1 is not null;
	SELECT count(unique(s2))  INTO numDevs FROM cdb_api_params where s2 is not null;
	
	if (num > numDevs) then
	    RAISE_APPLICATION_ERROR(-20021, 'fwConfigurationDB.setReferences: list of devices in S2 is not unique or contains NULLs');	
	end if;
	if (num > numRefs) then
	    RAISE_APPLICATION_ERROR(-20022, 'fwConfigurationDB.setReferences: list of references in S1 is not unique or contains NULLs');	
	end if;

	-- check if there are entries that match the mapping already in DB
	-- and remove them, if needed
	DELETE FROM (
	    select * from cdb_api_params 
	    where s1 in (
		select s1 from cdb_api_params c , v_references r where 
		    c.s1=r.dpname and c.s2=r.refdpname and r.config_tag=configurationName
	    )
	);
	
	-- resolve ID's of devices and references, set also the conf_id
	update cdb_api_params c set i1=(
	    select i.item_id from v_config_items i
		where i.dpname=c.s1 and tag=configurationName 
		and hver=(select hver from hierarchies where htype='LOGICAL' and valid_to is null)
	    );
		
	update cdb_api_params c set i2=(
	    select i.item_id from v_config_items i
		where i.dpname=c.s2 and tag=configurationName
		and hver=(select hver from hierarchies where htype='HARDWARE' and valid_to is null)		
		);

	update cdb_api_params set i3=(select CONF_ID from CONFIG_DESC where conf_tag=configurationName);
		
	
	-- make sure that all the devices were resolved - otherwise report an error
	
	-- firstly check the references
	open cur for 
	    select s1 from cdb_api_params where i1 is null;
	fetch cur into refName;
	if NOT (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20023, 'fwConfigurationDB.setReferences: Logical device not found in this configuration:'||refName);
	end if;
	close cur;

	-- then check the devices
	open cur for 
	    select s2 from cdb_api_params where i2 is null;
	fetch cur into devName;
	if NOT (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20024, 'fwConfigurationDB.setReferences: Device not found in this configuration:'||devName);
	end if;
	close cur;

	-- close the IOV for the previous mapping
	UPDATE REFERENCES SET VALID_TO=curTime
	     where (ref_id in (select i2 from cdb_api_params) 
	    	    or id in (select i1 from cdb_api_params) 
	    	    )
	    and valid_to is null
	    and refver=(select conf_id from config_desc where conf_tag=configurationName);

	insert into references(refver,id,ref_id,valid_from,valid_to) 
	    select i3,i1,i2,curTime,NULL from CDB_API_PARAMS ;
	

	EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';

END;

-------------------------------------
PROCEDURE getReferenceHistory(
	configurationName IN VARCHAR2,
	startDate IN DATE DEFAULT NULL,
	endDate IN DATE DEFAULT NULL)

IS

	outTblReady NUMBER := NULL;

	num number;
	queryStmt  varchar2(2000);
	whereClause varchar2(2000) := NULL;

BEGIN
	-- check the configuration name 
	SELECT count(*)  INTO num FROM CONFIG_DESC WHERE conf_tag=configurationName;

	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.getReferenceHistory: no such configuration:'||configurationName);
	end if;


	-- verify that input table is correct, check if there are devices specified
	SELECT checkInputTable() INTO num from DUAL;    

	queryStmt := 'insert into cdb_api_params(i1,i2,s1,s2,s3,s4,d1,d2)
			SELECT  r.id,r.ref_id,i.dpname, j.dpname, g.htype, h.htype, r.valid_from, r.valid_to
			FROM config_desc cd,references r,items i, items j, hierarchies g,hierarchies h
			WHERE  cd.conf_id=r.refver 
			AND r.id=i.id
			AND r.ref_id=j.id
			AND i.hver=g.hver
    			AND j.hver=h.hver
			AND cd.conf_tag='''||configurationName||''' ';

	if (num > 0) then  whereClause:=whereClause||' AND i.dpname in (select s1 from cdb_api_params) '; end if;
	if (startDate is not null) then 
	    whereClause:=whereClause||' AND ( r.valid_to >= TO_DATE('''||startDate||''') OR r.valid_to is null) '; 
	end if;
	if (endDate is not null) then 
	    whereClause:=whereClause||' AND r.valid_from <= TO_DATE('''||endDate||''')  '; 
	end if;

	if whereClause IS NOT NULL then queryStmt:=queryStmt||whereClause;end if;
	
	queryStmt:=queryStmt||' ORDER BY i.dpname, r.valid_from';
	execute immediate queryStmt;

	-- the input data (if present) is still in the table - clear it
	delete from cdb_api_params where s2 is null;
	

END;

-------------------------------------
PROCEDURE getDevicesInConfiguration(
	configurationName IN VARCHAR2,
	deviceFilter IN VARCHAR2 DEFAULT NULL)
IS

	num number;
	devFilter varchar2(128) := deviceFilter;
	TYPE cfgCurType IS REF CURSOR;
	configCur cfgCurType;


BEGIN
	-- cleanup i/o table
	EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';

	-- check the configuration name 
	SELECT count(*)  INTO num FROM CONFIG_DESC WHERE conf_tag=configurationName;

	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.getDevicesInConfiguration: no such configuration:'||configurationName);
	end if;

	-- verify that input table is correct (no entries apart from - maybe - S1)
	SELECT checkInputTable() INTO num from DUAL;    

	-- make sure the filter is right
	if devFilter = '' then devFilter:='%'; end if;
	if devFilter IS NULL then devFilter:='%'; end if;
	

	insert into cdb_api_params(s1) 
	    select unique i.dpname from items i, config_items ci, config_desc cd, config_tags ct
		where cd.conf_tag=configurationName
	            AND cd.conf_id=ct.conf_id
	            and ct.valid_to is null
	            and ct.citem_id=ci.citem_id
	            AND ci.item_id=i.id
	            and i.dpname like replace(devFilter,'*','%')
	            order by dpname;	


END;



PROCEDURE getRecipesList(recipeNameFilter IN varchar2 default null,
			 deviceFilter IN varchar2 default null,
			 recipeCommentFilter IN varchar2 default '*',
			 recipeTypeFilter IN varchar2 default '*')
IS

    nameFilter varchar2(128) := recipeNameFilter;
    devFilter varchar2(128) := deviceFilter;
    cmtFilter varchar2(512) := recipeCommentFilter;
    rtFilter  varchar2(128) := recipeTypeFilter;

    queryStmt  varchar2(2000);
    whereClause varchar2(2000) := NULL;

BEGIN
    -- cleanup i/o table
    EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';
    
    -- make sure the filter is right
    if nameFilter = '' then nameFilter:='%'; end if;
    if nameFilter IS NULL then nameFilter:='%'; end if;
    nameFilter:=replace(nameFilter,'*','%');


    queryStmt := 'insert into cdb_api_params(s1,s2,s3) 
	    select r.name ,r.description,r.recipe_type
		from recipes r where r.name like '''||nameFilter||''' ';

    if devFilter = '' then devFilter:=NULL; end if;
    if devFilter = '*' then devFilter:=NULL; end if;
    if devFilter is not null then
	devFilter:=replace(devFilter,'*','%');
	whereClause:=whereClause||' and r.name in (
		    select unique vra.tag from v_recipesall vra
			where dpname like '''||devFilter||'''
		    )';
    end if;

    if cmtFilter is null then
	whereClause:=whereClause||' and r.description is null ';
    else
	if cmtFilter!='*' then
	    cmtFilter:=replace(cmtFilter,'*','%');
	    whereClause:=whereClause||' and r.description like '''||cmtFilter||''' ';
	end if;
    end if;


    if rtFilter is null then
    	whereClause:=whereClause||' and r.recipe_type is null ';
    else 
	if rtFilter!='*' then
	    rtFilter:=replace(rtFilter,'*','%');
	    whereClause:=whereClause||' and r.recipe_type like '''||'Test'||''' ';
	end if;
    end if;

    

    if whereClause IS NOT NULL then queryStmt:=queryStmt||whereClause;end if;

    execute immediate queryStmt;


END;

PROCEDURE getConfigurationsList(configurationNameFilter IN varchar2 default null)
IS

    nameFilter varchar2(128) := configurationNameFilter;

BEGIN
    -- cleanup i/o table
    EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';
    
    -- make sure the filter is right
    if nameFilter = '' then nameFilter:='%'; end if;
    if nameFilter IS NULL then nameFilter:='%'; end if;

    insert into cdb_api_params(s1,s2) 
	select c.conf_tag, c.description 
	    from config_desc c
	    where c.conf_tag like replace(nameFilter,'*','%');


END;


END fwConfigurationDB;
/

----------------------------------------------------------------------------
-- as the last element we create our "internal" view, which
-- is used to determine if the schema exists.
----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_confdb (
    SCHEMA_VERSION,
    TABLES,
    VIEWS,
    SEQUENCES,
    INTERNAL)
AS SELECT
    '2.05',
    'HIERARCHIES,DEVICE_TYPES,ITEMS,RECIPES,RECIPE_VERSIONS,RECIPE_DATA,RECIPE_TAGS,DEVICE_ELEMENTS,CONFIG_ITEMS,CONFIG_ITEM_PROPERTIES,CONFIG_DESC,CONFIG_TAGS,REFERENCES,CONFIG_ADDRESSES,CONFIG_ALERTS,CONFIG_DPEALERTS,CONFIG_SUMALERTS,CONFIG_ALERTS_MISC,CONFIG_ARCHIVING,CONFIG_DPFUNCTIONS,CONFIG_CONVERSIONS,CONFIG_PVRANGES,CONFIG_SMOOTHING,CONFIG_UF',
    'V_ITEM_NAMES,V_ITEMS,V_RECIPESALL,V_REFERENCES,V_CONFIG_ITEMS,V_DEVICE_CONFIGS,V_ITEM_PROPERTIES,V_CONFIG_ALERTS',
    'CITEM_ID_SEQ,CONF_ID_SEQ,DEVELEM_ID_SEQ,DPT_ID_SEQ,IPROP_ID_SEQ,ITEMS_ID_SEQ,RECIPES_RVER_SEQ,RECIPES_TAGID_SEQ,RECIPE_DATA_PROPID_SEQ',
    'CDB_API_PARAMS,TMP_ITEM_PROPS' FROM DUAL;
