



-- Fix for ENS-1065: the data describing branches in the logical view is moved to REFERENCES table
insert into references(refver,id,ref_id,valid_from, valid_to)
    select ci.tag_id refver,i.id id,i.id ref_id,ci.valid_from valid_from, ci.valid_to valid_to
    from config_items_new ci, items i
    where i.id=ci.item_id and i.hver=2
    and i.id not in (select id from references where refver=ci.tag_id);

delete from config_items_new ci where ci.item_id in (select id from items i where i.hver=2);

-----------------------------------------------------------------------------
--
-- The PL/SQL package containing fwConfigurationDB functions
--
-- Unofficial documentation is at
-- https://twiki.cern.ch/twiki/bin/view/Controls/ConfigurationDBTool#PlSqlApi
-----------------------------------------------------------------------------
 
----- PREPARE OBJECT TYPES ----------
-- replacing of object types is not trivial, if they depend on each other...
-- We get: ORA-02303: cannot drop or replace a type with type or table dependents
-- we do the cleanup inside the PL/SQL code block...
declare
 num number;
begin
    SELECT count(*) into num from USER_TYPES WHERE TYPE_NAME='SUMALERTTABLETYPE';
    if num>0 then
	execute immediate 'drop type sumalerttabletype';
    end if;

    SELECT count(*) into num from USER_TYPES WHERE TYPE_NAME='SUMALERTOBJECT';
    if num>0 then
	execute immediate 'drop type sumalertobject';
    end if;

    SELECT count(*) into num from USER_TYPES WHERE TYPE_NAME='LIST_AGG_TYPE';
    if num>0 then
	execute immediate 'drop type LIST_AGG_TYPE';
    end if;
end;
/

-- now re-create the types
create or replace type sumAlertObject
as object
(
    iprop_id NUMBER,
    isPattern NUMBER,
    sumdpelist varchar2(4000)
);
/

create or replace type sumAlertTableType as table of sumAlertObject;
/


-- implementation of custom aggregation function allowing to collapse a set or rows
-- into a |-separated string is based on STRAGG function implementation published at
-- http://asktom.oracle.com/pls/asktom/f?p=100:11:0::NO::P11_QUESTION_ID:2196162600402
CREATE OR REPLACE type list_agg_type as object
  (
     total varchar2(4000),
     static function
          ODCIAggregateInitialize(sctx IN OUT list_agg_type )
          return number,
  
     member function
          ODCIAggregateIterate(self IN OUT list_agg_type ,
                               value IN varchar2 )
          return number,

     member function
          ODCIAggregateIterate(self IN OUT list_agg_type ,
                               value IN number )
          return number,
  
     member function
          ODCIAggregateTerminate(self IN list_agg_type,
                                 returnValue OUT  varchar2,
                                 flags IN number)
          return number,
  
     member function
          ODCIAggregateMerge(self IN OUT list_agg_type,
                             ctx2 IN list_agg_type)
          return number
  );
/


CREATE OR REPLACE type body list_agg_type
  is
  
  static function ODCIAggregateInitialize(sctx IN OUT list_agg_type)
  return number
  is
  begin
      sctx := list_agg_type( null );
      return ODCIConst.Success;
  end;
  member function ODCIAggregateIterate(self IN OUT list_agg_type,
                                       value IN varchar2 )
  return number
  is
  begin
      self.total := self.total || '|' || value;
      return ODCIConst.Success;
  end;
  
  member function ODCIAggregateIterate(self IN OUT list_agg_type,
                                       value IN number )
  return number
  is
  begin
      self.total := self.total || '|' || value;
      return ODCIConst.Success;
  end;
  
  member function ODCIAggregateTerminate(self IN list_agg_type,
                                         returnValue OUT varchar2,
                                         flags IN number)
  return number
  is
  begin
      returnValue := ltrim(self.total,'|');
      return ODCIConst.Success;
  end;
  
  member function ODCIAggregateMerge(self IN OUT list_agg_type,
                                     ctx2 IN list_agg_type)
  return number
  is
  begin
      self.total := self.total || ctx2.total;
      return ODCIConst.Success;
  end;

end;
/

CREATE or replace FUNCTION lstagg   (input varchar2 ) RETURN varchar2 PARALLEL_ENABLE AGGREGATE USING list_agg_type;
/

CREATE or replace FUNCTION lstaggnum(input number )   RETURN varchar2 PARALLEL_ENABLE AGGREGATE USING list_agg_type;
/

----------- MAIN PACKAGE --------------

CREATE OR REPLACE PACKAGE fwConfigurationDB
AUTHID CURRENT_USER
IS

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

PROCEDURE getRecipe2(
	recipeName        IN VARCHAR2,
	validAt           IN DATE DEFAULT NULL,
	dataIntoClob      IN NUMBER DEFAULT 1)
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
	userCreated IN VARCHAR2 DEFAULT NULL)
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
FUNCTION checkInputTable(checkS2 number default 1) RETURN NUMBER;

PROCEDURE saveItems( hierarchyType IN VARCHAR2)
;
PROCEDURE saveStaticConfiguration(configurationName IN VARCHAR2,
	hierarchyType IN VARCHAR2)
;

FUNCTION getSummaryAlerts  return sumAlertTableType pipelined
;

FUNCTION checkSaveDpTypes  return number
;

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
	OR c1 is not null';
		
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


-- Backward compatible function: returns the recipe data
-- in the S8 column, rather than C1
-----------------------------------------------
PROCEDURE getRecipe(
	recipeName IN VARCHAR2,
	validAt IN DATE DEFAULT NULL)
IS
BEGIN
    getRecipe2(recipeName,validAt,0);
END;

-----------------------------------------------
PROCEDURE getRecipe2(
	recipeName        IN VARCHAR2,
	validAt           IN DATE DEFAULT NULL,
	dataIntoClob      IN NUMBER DEFAULT 1)
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
		    delete from CDB_API_PARAMS;
		    outTblReady:=1;
		end if;

		exit when recipesCur%notfound;
		if dataIntoClob IS NULL OR dataIntoClob=0 THEN
		  insert into CDB_API_PARAMS(
		    i1,i2,i3,i4,i5,i6,i7,i8,
		    s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,
		    d1,d2
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
		    SUBSTR(recipeData.propValue,1,4000),	-- s8 (4000)
		    recipeData.hierarchy,       --s9 (16)
		    NULL,                       --s10 (16)
		    recipeData.validFrom, 	--d1
		    recipeData.validTo  	--d2
		  );
		 ELSE
		  insert into CDB_API_PARAMS(
		    i1,i2,i3,i4,i5,i6,i7,i8,
		    s1,s2,s3,s4,s5,s6,s7,c1,s9,s10,
		    d1,d2
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
		    recipeData.propValue,	-- c1(!)
		    recipeData.hierarchy,       --s9 (16)
		    NULL,                       --s10 (16)
		    recipeData.validFrom, 	--d1
		    recipeData.validTo  	--d2
		 );
		 
		 END IF;

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
	
	-- we check if one can do insert into recipes...
	-- note the use of SYS_CONTEXT to get the currently used schema!
	IF SYS_CONTEXT('USERENV','CURRENT_SCHEMA') != USER THEN
	    SELECT count(*) into num from ALL_TAB_PRIVS WHERE TABLE_NAME='RECIPES' 
		AND TABLE_SCHEMA=SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AND PRIVILEGE='INSERT';
	    if (num=0) then
		RAISE_APPLICATION_ERROR(-20020, 'fwConfigurationDB.createRecipe: Your DB account: '||USER||' does not allow to create recipes in schema '||SYS_CONTEXT('USERENV','CURRENT_SCHEMA'));
	    end if;

	    -- we also check if he 'sees' the sequence that we are going to use..
	    SELECT count(*) into num from ALL_SEQUENCES WHERE SEQUENCE_NAME='RECIPES_TAGID_SEQ' 
		AND SEQUENCE_OWNER=SYS_CONTEXT('USERENV','CURRENT_SCHEMA');
	    
	    if (num=0) then
		RAISE_APPLICATION_ERROR(-20020, 'fwConfigurationDB.createRecipe: Cannot draw numbers from sequences in schema '||SYS_CONTEXT('USERENV','CURRENT_SCHEMA'));
	    end if;
	END IF;
	
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
	-- check if the current user is allowed to store recipes in this schema...
	IF SYS_CONTEXT('USERENV','CURRENT_SCHEMA') != USER THEN
	    SELECT count(*) into num from ALL_TAB_PRIVS WHERE TABLE_NAME='RECIPES' 
		AND TABLE_SCHEMA=SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AND PRIVILEGE='INSERT';
	    if (num=0) then
		RAISE_APPLICATION_ERROR(-20020, 'fwConfigurationDB.storeRecipe: Your DB account: '||USER||' does not allow to modify recipes in schema '||SYS_CONTEXT('USERENV','CURRENT_SCHEMA'));
	    end if;
	END IF;

	-- check the recipe name 
	open cur for SELECT tagid from RECIPES WHERE name=recipeName;
	fetch cur into recipeId;

	if (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.storeRecipe: no such recipe:'||recipeName);
	end if;
	close cur;
	
	-- get rid of the ones that are already OK...
	delete from CDB_API_PARAMS where I1 in 
	    (SELECT PROPID from RECIPE_TAGS where VALID_TO is NULL and TAGID=recipeId);


	--complete datapoint ID's:
	update cdb_api_params c set i8=(
	    select i.id from items i where i.dpname=c.s1)
	    where c.i1 is null;


	-- make sure that all the devices were resolved - otherwise report an error
	open cur for 
	    select s1 from cdb_api_params where i8 is null and i1 is null;
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
	    )
	    where c.i1 is null;

	-- make sure that all the properties were resolved - otherwise report an error
	open cur for 
	    select s1,s2 from cdb_api_params where i2 is null and i1 is null;
	fetch cur into devName,propName;
	if NOT (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20024, 'fwConfigurationDB.storeRecipe: Device element not found in database:'||devName||propName);
	end if;
	close cur;


	-- generate next ordinal number for Recipe Version, and store new version
	EXECUTE IMMEDIATE 'SELECT RECIPES_RVER_SEQ.NEXTVAL FROM DUAL' INTO rVer;

	insert into recipe_versions(rver,description,user_created,date_created)
	    values(rver,versionDescription,userCreated,curTime);

	update cdb_api_params set i3=rVer;


	-- STEP 1: for the elements, for which we already have PropId passed in I1,
	-- we simply do the manipulation with tags, and do not store the data again!


        -- *) firstly, let's check if we have some "roll-backs" to previous versions
        -- of the data.
        -- close the IOVs
    	update recipe_tags 
    	    set valid_to=curTime 
    	    where propid in (
    		select rd2.propid 
    		from recipe_data rd1, recipe_tags rt1, recipe_data rd2, recipe_tags rt2,
    		     cdb_api_params cdb
    		where cdb.i1=rd1.propid -- this implies cdb.i1 NOT NULL
    		and rd1.propid=rt1.propid 
    		and rt1.valid_to is not null
    		and rd1.id=rd2.id
    		and rd1.develem_id=rd2.develem_id
    		and rd2.propid=rt2.propid
    		and rt2.valid_to is null
    		and rt1.tagid=recipeId
    		and rt1.tagid=rt2.tagid
    		);

    	-- reopen IOVs for the case of no-copy;
		-- mark it by I7=99 (we do not need I7 anymore anyway...)
		update cdb_api_params c set c.i7=99 where
		c.i1 in (select cdb.i1 from cdb_api_params cdb,recipe_tags rt
	    where cdb.i1 is not null
	    and rt.propid=cdb.i1 
	    and rt.valid_to is not null
	    and rt.tagid=recipeId);
		
				
	insert into recipe_tags (tagid,rver,propid,VALID_FROM,VALID_TO) 
	    select recipeId,rver,i1,curTime,NULL 
	    from cdb_api_params cdb where i7=99;
		
	delete from cdb_api_params where i7=99;
		
	-- repen IOVs for the case of recipe-copy
	insert into recipe_tags (tagid,rver,propid,VALID_FROM,VALID_TO) 
	    select recipeId,rver,i1,curTime,NULL 
	    from cdb_api_params cdb
	    where cdb.i1 is not null
	    and cdb.i1 not in (select propid from recipe_tags where valid_to is null and tagid=recipeId);

	delete from cdb_api_params where i1 is not null;

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


	-- if the user used the old convention to pass property value in the S8
	-- column, rather that in C1, move the data appropriately
	update CDB_API_PARAMS SET C1=S8 WHERE C1 IS NULL and S8 IS NOT NULL;


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
	    c1,
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
		delete from CDB_API_PARAMS;
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
	myConfId number;
	errMsg VARCHAR2(2000);
	now cdb_api_params.d1%TYPE := SYSTIMESTAMP;
BEGIN
	

	-- check if the current user is allowed to set references
	IF SYS_CONTEXT('USERENV','CURRENT_SCHEMA') != USER THEN
	    SELECT count(*) into num from ALL_TAB_PRIVS WHERE TABLE_NAME='REFERENCES' 
		AND TABLE_SCHEMA=SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AND PRIVILEGE='INSERT';
	    if (num=0) then
		RAISE_APPLICATION_ERROR(-20020, 'fwConfigurationDB.setReferences: Your DB account: '||USER||' does not allow to modify references in schema '||SYS_CONTEXT('USERENV','CURRENT_SCHEMA'));
	    end if;
	END IF;

	-- check the configuration name, retrieve its ID
	BEGIN
	SELECT CONF_ID INTO myConfId FROM CONFIG_DESC WHERE CONF_TAG=configurationName;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
	    RAISE_APPLICATION_ERROR(-20005, 'fwConfigurationDB.setReferences: no such configuration:'||configurationName);
	END;

	-- device names are in S1, and corresponding references in S2
	-- make sure they are all correct...
	-- note: if called from saveStaticConfiguration, we should have item IDs already filled in
	SELECT count(unique(s1))  INTO numRefs FROM cdb_api_params where s1 is not null;
	SELECT count(unique(s2))  INTO numDevs FROM cdb_api_params where s2 is not null;
	
	if (num > numDevs) then
	    RAISE_APPLICATION_ERROR(-20021, 'fwConfigurationDB.setReferences: list of devices in S2 is not unique or contains NULLs');	
	end if;
	if (num > numRefs) then
	    RAISE_APPLICATION_ERROR(-20022, 'fwConfigurationDB.setReferences: list of references in S1 is not unique or contains NULLs');	
	end if;

	-- resolve ID's, if there are still unresolved ones...
	UPDATE CDB_API_PARAMS CDB SET cdb.i1=(SELECT i.ID FROM ITEMS i where i.dpname=cdb.s1) where cdb.i1 is null;
	-- check if all IDs resolved...
	errMsg:=null;
	for rec in ( select s1 DPNAME, s2 REFDPNAME FROM CDB_API_PARAMS where I1 is null) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';REFDP='||rec.refdpname;
		exit when length(errMsg)>1900;
	end loop;
	if (errMsg is not null) then
		raise_application_error(-20014,'fwConfigurationDB.setReferences:Could not resolve devices:'||errMsg);
	end if;
	
	-- resolve RefIDs for all things of type FwNode: they should point to themselves
	UPDATE CDB_API_PARAMS CDB SET cdb.i5=cdb.i1, cdb.i3=myConfId, cdb.d1=now where cdb.s3='FwNode';
	-- resolve IDs of other referred DPs
	UPDATE CDB_API_PARAMS CDB SET cdb.i5=(SELECT i.ID FROM ITEMS i where i.dpname=cdb.s2),cdb.i3=MyConfId,cdb.d1=now where cdb.i5 is null;
		
	-- check if all references resolved...
	errMsg:=null;
	for rec in ( select s1 DPNAME, s2 REFDPNAME FROM CDB_API_PARAMS where I5 is null) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';REFDP='||rec.refdpname;
		exit when length(errMsg)>1900;
	end loop;
	if (errMsg is not null) then
		raise_application_error(-20014,'fwConfigurationDB.setReferences:Could not resolve referenced devices:'||errMsg);
	end if;

	-- remove the ones for which mapping has not changed
	delete from CDB_API_PARAMS CDB
		where I1 IN (SELECT C1.I1 FROM REFERENCES rf,CDB_API_PARAMS c1 where rf.refver=myConfId
		and c1.i1=rf.id and c1.i5=rf.ref_id);

	-- close IOVs for the existing logical devices
	UPDATE REFERENCES SET VALID_TO=now 
		where valid_to is null and refver=myConfId 
		and id in (SELECT I1 FROM CDB_API_PARAMS);
		-- close IOVS for referenced devices
		UPDATE REFERENCES SET VALID_TO=now 
		where valid_to is null and refver=myConfId
		and ref_id in (SELECT I5 FROM CDB_API_PARAMS);

		-- insert new ones
		INSERT INTO REFERENCES(refver,id,ref_id,valid_from,valid_to) 
			(select myConfId,i1,i5,now,null from cdb_api_params);
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
	delete from CDB_API_PARAMS;

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
	    select unique i.dpname from items i, config_items_new ci, config_desc cd
		where cd.conf_tag=configurationName
	            AND cd.conf_id=ci.tag_id
	            and ci.valid_to is null
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
    delete from CDB_API_PARAMS;
    
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
	    whereClause:=whereClause||' and r.recipe_type like '''||rtFilter||''' ';
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
    delete from CDB_API_PARAMS;
    
    -- make sure the filter is right
    if nameFilter = '' then nameFilter:='%'; end if;
    if nameFilter IS NULL then nameFilter:='%'; end if;

    insert into cdb_api_params(s1,s2) 
	select c.conf_tag, c.description 
	    from config_desc c
	    where c.conf_tag like replace(nameFilter,'*','%');


END;

---------------------------------------------
-- Input/Output is through the CDB_API_PARAMS table
-- the layout is:
--   I1 -> ITEM_ID
--    I2 -> CITEM_ID
--    I3 -> PARENT_ID
--    I4 -> DPID (Hardware hierarchy)
--   I5 -> REF ID (Logical hierarchy)
--    I7 -> DPType ID
--    I8 -> Flags that a device is new
--
--    S1 -> DEVICE DPNAME
--    S2 -> REF DPNAME (Logical hierarchy)
--    S3 -> TYPE (DPTYPE)
--    S4 -> DETAIL (MODEL)
--    S5 -> DEVICE NAME (short)
--    S6 -> PARENT DPNAME
--    S7 -> COMMENT
-----------------------------------------------
PROCEDURE saveItems( hierarchyType IN VARCHAR2)
IS
 myhver NUMBER;
 cnt NUMBER;
 errMsg VARCHAR2(2000);
BEGIN
	-- resolve hierarchyType into hver
	BEGIN
	SELECT HVER INTO myhver  FROM HIERARCHIES WHERE HTYPE=hierarchyType AND VALID_TO IS NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(-20009,'Unknown hierarchy type:'||hierarchyType);
	END;

	-- check that we have complete information about devices...
	errMsg:=null;
	if (hierarchyType='HARDWARE') then
	for rec in (
		select s1 DPNAME, s3 DPTYPE,  S4 MODEL,  S5 NAME,  S6 PARENT,  I4 DPID FROM CDB_API_PARAMS
			where s1 is null or s3 is null or  s5 is null or s6 is null or I4 is null
	) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';DPTYPE='||rec.dptype||';MODEL='||rec.model;
		errMsg:=errMsg||';NAME='||rec.name||';PARENT='||rec.parent||';DPID='||rec.DPID;
			exit when length(errMsg)>1900;
	end loop;
	elsif (hierarchyType='LOGICAL') then
		for rec in (
			select s1 DPNAME, s2 REFDPNAME, s3 DPTYPE,  S4 MODEL,  S5 NAME,  S6 PARENT  FROM CDB_API_PARAMS
			where s1 is null or s2 is null or s3 is null or s5 is null
		) loop
			errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';REFDPNAME='||rec.refdpname||';DPTYPE='||rec.dptype||';MODEL='||rec.model;
			errMsg:=errMsg||';NAME='||rec.name||';PARENT='||rec.parent;
			exit when length(errMsg)>1900;
		end loop;
	else
		RAISE_APPLICATION_ERROR(-20009,'Unsupported hierarchy type:'||hierarchyType);
	end if;
	if (errMsg is not null) then
         raise_application_error(-20010,'Incomplete information about new devices:'||errMsg);
	end if;

	-- check that there is no repeated entries (dp name is unique)
	errMsg:=null;
	for rec in (
		SELECT DPNAME, CNT FROM (
			select s1 DPNAME, count(*) CNT FROM CDB_API_PARAMS GROUP BY S1
		) WHERE CNT>1
	) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||'  Occurences='||rec.CNT;
		exit when length(errMsg)>1900;
	end loop;
	if (errMsg is not null) then
         raise_application_error(-20010,'Some of devices listed more than once:'||errMsg);
	end if;
	

	-- complete the DPType identifier into I7
	UPDATE CDB_API_PARAMS CDB 
		SET CDB.I7=(SELECT DPT_ID FROM DEVICE_TYPES DPT WHERE CDB.S3=DPT.dptype AND DPT.valid_to is null);

	-- check that we have all dptypes resolved...
	errMsg:=null;
	for rec in ( select s1 DPNAME, s3 DPTYPE FROM CDB_API_PARAMS where I7 is null) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';DPTYPE='||rec.dptype;
		exit when length(errMsg)>1900;
	end loop;
	if (errMsg is not null) then
         raise_application_error(-20011,'Could not resolve DPTypes for devices:'||errMsg);
	end if;
		
	-- match devices that are already saved
	UPDATE CDB_API_PARAMS CDB SET CDB.I1=(SELECT I.ID FROM ITEMS I WHERE CDB.S1=I.DPNAME);
	
	-- ... and mark the new (non-existing) devices
	update cdb_api_params set i8=1 where i1 is null;

	
	 -- verify that the existing ones did not change...
	 errMsg:= null;
        for rec in (
		select i.dpname DPNAME, cdb.s1 DPNAME_NEW, i.type TYPE,cdb.s3 TYPE_NEW, i.detail MODEL, cdb.s4 MODEL_NEW, i.name NAME, cdb.s5 NAME_NEW 
		 from items i,cdb_api_params cdb 
                 where i.id=cdb.i1 and ( i.dpname != cdb.s1 OR  i.TYPE   != cdb.s3 OR i.detail != cdb.s4 OR i.name  != cdb.s5 )
	) loop
		errMsg:=errMsg||chr(13)||'DPNAME:'||rec.DPNAME||';TYPE:'||rec.type||'|'||rec.type_new||';MODEL:'||rec.model||'|'||rec.model_new||';NAME:'||rec.name||'|'||rec.name_new;
		exit when length(errMsg)>1900;
        end loop;	
	if (errMsg is not null) then
         raise_application_error(-20012,'Inconsistend information about devices:'||errMsg);
	end if;

	-- make sure that "root" nodes (corresponding to system names) exist, for all the DPs
	if (hierarchyType='HARDWARE') then

	INSERT INTO ITEMS(HVER,ID,NAME,TYPE,DETAIL,DPNAME)  
		select myHVER,ITEMS_ID_SEQ.NextVal,S.sysname,'SYSTEM','SYSTEM',S.sysname from 
		    (select unique(substr(S1,0,INSTR(S1,':'))) sysname from CDB_API_PARAMS )S
		where S.sysname not in (select i.dpname from items i where i.hver=myhver and parent is null);
   elsif (hierarchyType='LOGICAL') then
	INSERT INTO ITEMS(HVER,ID,NAME,TYPE,DETAIL,DPNAME)  
			SELECT myhver, ITEMS_ID_SEQ.NextVal,'/','SYSTEM','SYSTEM','' from dual
		where not exists (select ID from items i where i.hver=myhver and parent is null);
   end if;
        --generate new ITEM_IDs for the new ones...
        UPDATE CDB_API_PARAMS CDB SET CDB.I1=ITEMS_ID_SEQ.NextVal WHERE I8=1;
	
        -- resolve parent pointers for the new ones, based on their names; local lookup
        UPDATE CDB_API_PARAMS CDB SET CDB.I3=(SELECT CDB2.I1 FROM CDB_API_PARAMS CDB2 WHERE CDB2.S1=CDB.S6);
        
		if (hierarchyType='HARDWARE') then
        -- resolve parent pointers for the non-FW devices (hook them to parent)
        UPDATE CDB_API_PARAMS CDB 
			SET CDB.I3=(SELECT I.ID FROM ITEMS I WHERE I.DPNAME=CDB.S6 and i.hver=myhver) 
			WHERE CDB.I3 IS NULL;
		elsif (hierarchyType='LOGICAL') then
		-- resolve the logical ones - hook them to the common root
			UPDATE CDB_API_PARAMS CDB 
			SET CDB.I3=(SELECT I.ID FROM ITEMS I WHERE I.PARENT IS NULL and i.hver=myhver) 
	WHERE CDB.I3 IS NULL;
		end if;

	-- verify that we resolved all parent ids
	errMsg:=null;
	for rec in ( select s1 DPNAME, s6 PARENT FROM CDB_API_PARAMS where I3 is null) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';PARENT='||rec.parent;
		exit when length(errMsg)>1900;
	end loop;
	if (errMsg is not null) then
         raise_application_error(-20013,'Could not resolve parents for devices:'||errMsg);
	end if;
	
       -- now we insert the new ones into the ITEMS table; we assume that type info is coherent
        INSERT INTO ITEMS(HVER,ID,PARENT,NAME,TYPE,DETAIL,DESCRIPTION,DPID,DPNAME,DPT_ID) 
             (SELECT  myhVer,I1,I3,S5,S3,S4,S7,I4,S1,I7 FROM CDB_API_PARAMS WHERE I8=1);

END;
PROCEDURE saveStaticConfiguration(configurationName IN VARCHAR2,
	hierarchyType In VARCHAR2)
IS
	errMsg VARCHAR2(2000);
	confId NUMBER;
	now date;
	myhver NUMBER;
	cnt NUMBER;
BEGIN
	select sysdate into now from dual;

	-- resolve hierarchyType into hver
	BEGIN
	SELECT HVER INTO myhver  FROM HIERARCHIES WHERE HTYPE=hierarchyType AND VALID_TO IS NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(-20009,'Unknown hierarchy type:'||hierarchyType);
	END;
	-- check/create new configuration
	BEGIN
		SELECT CONF_ID INTO ConfId FROM CONFIG_DESC WHERE CONF_TAG=configurationName;
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		SELECT CONF_ID_SEQ.NextVal INTO ConfId FROM DUAL;
		INSERT INTO CONFIG_DESC(CONF_ID,CONF_TAG) VALUES (ConfId,configurationName);
	END;
	if hierarchyType='LOGICAL' then
		setReferences(configurationName);
	
	elsif hierarchyType='HARDWARE' then
	-- treat "FwNode"
	DELETE FROM CDB_API_PARAMS WHERE S3='FwNode';
		
	-- Generate new CITEM_ID, set it in CDB_API_PARAMS
	UPDATE CDB_API_PARAMS CDB SET CDB.I2=CITEM_ID_SEQ.NextVal;
	-- close the interval of validity for the existing items that match the stored ones...
	UPDATE CONFIG_ITEMS_NEW SET VALID_TO=now 
		where valid_to is null and tag_id=confId 
		and item_id in (SELECT I1 FROM CDB_API_PARAMS);
	 
	 -- store new CITEMs in CONFIG_ITEMS_NEW
	INSERT INTO CONFIG_ITEMS_NEW(ITEM_ID,CITEM_ID,VALID_FROM,TAG_ID,DPT_ID) 
		(SELECT I1,I2,now,confId,I7 FROM CDB_API_PARAMS);


	-- generate the PROPERTIES (DPEs), and their IDs, and insert them into BOTH
	-- the TMP_ITEM_PROPS and into CONFIG_ITEMPROPS (!)
	INSERT ALL 
		INTO CONFIG_ITEMPROPS(IPROP_ID, CITEM_ID, DEVELEM_ID) 
			VALUES(IPROP_ID_SEQ.NextVal,CITEM_ID,DEVELEM_ID)
		INTO TMP_ITEM_PROPS(IPROP_ID, DPENAME) 
			VALUES(IPROP_ID_SEQ.CurrVal,DPENAME)
	SELECT CDB.I2 CITEM_ID, EL.DEVELEM_ID DEVELEM_ID, CDB.S1||EL.ELEMENTNAME DPENAME 
		FROM CDB_API_PARAMS CDB, DEVICE_ELEMENTS EL 
		WHERE EL.DPT_ID=CDB.I7;
	else
		raise_application_error(-20000,'Unsupported hierarchy type:'||hierarchyType);
	end if;
END;

function getSummaryAlerts return sumAlertTableType pipelined
as
PRAGMA AUTONOMOUS_TRANSACTION; -- this to be able to do inserts/updates
rc number;
idlist varchar2(4000);
dpelist varchar2(4000);
idx pls_integer;
begin
delete from cdb_api_params;
commit;
for rec in (select csa.iprop_id IPROP_ID, csa.sumdpelist SUMDPEIDS from config_sumalerts csa, tmp_item_props tip where csa.iprop_id=tip.iprop_id) loop
   idlist:=rec.SUMDPEIDS;
   if substr(idlist,1,8)='PATTERN:' then
   	-- note: we mark that it is a pattern in the I3 column
	insert into cdb_api_params(i1,i3,s4) values (rec.IPROP_ID,1,substr(idlist,9));
   elsif idlist is not null then
   loop
      idx :=instr(idlist,'|');
      if idx=0 then
      idx :=instr(idlist,',');
      end if;
      if idx > 0 then
        insert into cdb_api_params(i1,i5) values (rec.IPROP_ID,substr(idlist,1,idx-1));
	idlist:=substr(idlist,idx+1);
      else
        insert into cdb_api_params(i1,i5) values (rec.IPROP_ID,idlist);
	exit;
      end if;
  end loop;
  end if;
  end loop;
update cdb_api_params cda set cda.s2=(SELECT DPENAME FROM TMP_ITEM_PROPS TIP WHERE cda.i5=TIP.IPROP_ID) ;
commit;
 ----- firstly pipe rows with 'PATTERN:' dpelist
for rec in (select c1.i1 IPROPID, c1.s4 SUMDPELIST from cdb_api_params c1 where c1.i3=1) loop
    pipe row (sumAlertObject(rec.IPROPID,1,rec.SUMDPELIST));
end loop;
----- then pipe rows with translated list; note that we will not include unresolved ones 
 for rec2 in (select c1.i1 IPROPID, LSTAGG(S2) SUMDPELIST from cdb_api_params c1 where s2 is not null group by c1.i1) loop
 dpelist:=replace(rec2.SUMDPELIST,',','|');
  pipe row (sumAlertObject(rec2.IPROPID,0,dpelist));
 end loop;
commit;
 return;
end;

-- Everything goes via CDB_API_PARAMS
-- S1 -> DPType Name
-- S2 -> Element Name
-- I3 -> Element type
FUNCTION checkSaveDpTypes return number
IS
BEGIN

    --resolve known types
    update cdb_api_params cdb set i1=  (select dpt_id from DEVICE_TYPES where dptype=cdb.s1 and valid_to is null);

    --identify the types that have an element deleted; mark with i8=2
    update cdb_api_params set i8=2 where s1 in (
	select unique(dptype) from V_DEVICE_CONFIGS DC 
	WHERE DC.dptype in (
		select unique(s1) from cdb_api_params cdb1) 
	and not exists(select * from CDB_API_PARAMS CDB2 where cdb2.s1(+)=dc.dptype and cdb2.s2=dc.elementname));

    -- identify the elements(!) that are new or changed the type; identify the new ones as well; mark with i7=1
    update cdb_api_params cdb set i7=1 where not exists 
	(select * from v_device_configs dc where dc.dptype=cdb.s1 and dc.elementname=cdb.s2 and dc.elementtype=cdb.i3);
    -- propagate this info to all elements in the type (even those that match...)
    update cdb_api_params cdb set i7=1 where s1 in(select unique(s1) from CDB_API_PARAMS WHERE i7=1);

    -- clean up the ones that match
    delete from cdb_api_params where i1 is not null and i7 is null and i8 is null;

    -- invalidate the existing ones that have to be updated
    update device_types set valid_to=sysdate where dpt_id in (select unique(i1) from CDB_API_PARAMS);

    -- insert new types
    insert into device_types(DPTYPE,DPT_ID) 
	select S1 DPTYPE,DPT_ID_SEQ.NextVal DPT_ID from (select s1 from cdb_api_params group by s1);

    -- now complete the CDB_API_PARAMS with this info
    update cdb_api_params cdb set i1=(select dpt_id from device_types where dptype=cdb.s1 and valid_to is null);

    --generate element ids
    update cdb_api_params cdb set i2=DEVELEM_ID_SEQ.NextVal;

    -- transfer the data into DEVICE_ELEMENTS
    insert into device_elements(DEVELEM_ID,DPT_ID,ELEMENTNAME,ELEMENTTYPE) SELECT i2,i1,s2,i3 from cdb_api_params;
    
    return 0;
END;


END fwConfigurationDB;
/


----------------------------------------------------------------------------
-- as the last element we create our "internal" view, which
-- is used to determine if the schema exists.
----------------------------------------------------------------------------


DECLARE
    NOW VARCHAR2(32);
    VERS VARCHAR(32);
BEGIN
NOW:=TO_CHAR(SYSTIMESTAMP,'YYYY-MM-DD HH24:MI:SS');
VERS:=TO_CHAR(3.03,'9.99');
EXECUTE IMMEDIATE ' CREATE OR REPLACE VIEW v_confdb (SCHEMA_VERSION,SCHEMA_CREATED)'||
    ' AS SELECT '''||VERS||''', '''||NOW||''' FROM DUAL';
END;
/

GRANT SELECT  ON V_CONFDB TO PUBLIC;

commit;


