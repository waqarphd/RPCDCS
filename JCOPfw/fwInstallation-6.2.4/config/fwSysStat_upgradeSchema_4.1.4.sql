DROP TABLE FW_SYS_STAT_PROJ_INST_LOG;

CREATE TABLE FW_SYS_STAT_PROJ_INST_LOG
   (ID NUMBER NOT NULL,
    PROJECT_ID NUMBER NOT NULL,
	TS TIMESTAMP (3),
	SEVERITY VARCHAR2(10),
	LOG VARCHAR2(4000),
	CONSTRAINT FW_SYS_STAT_PROJ_LOG_PK PRIMARY KEY (ID),
	 CONSTRAINT FW_SYS_STAT_PROJ_LOG_FK FOREIGN KEY (PROJECT_ID)
	  REFERENCES FW_SYS_STAT_PVSS_PROJECT (ID));


CREATE SEQUENCE FW_SYS_STAT_PROJ_INST_LOG_SQ
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

alter table fw_sys_stat_pvss_project drop column pvss_base_id;
alter table fw_sys_stat_pvss_project add pvss_version varchar(16);
alter table fw_sys_stat_pvss_project add os varchar(16);

alter table fw_sys_stat_pvss_project add need_synchronize char(1);

-- Synchronize of the project is necessary after changes to:
-- 1. Tool Upgrade
-- 2. Project Paths
-- 3. Project Information ( Redu Hosts, Centrally Managed, System_ID?)
-- 4. Dist Peers
-- 5. Components Reinstall
-- 6. Groups of components
-- 7. Helper Procedures


-- 7. ------------------
------ Helper Procedures
------ Necessary to overcome mutating tables for on delete cascade (Oracle 4091)
CREATE global temporary TABLE need_synchronize_4091 ( project_id number ) on commit delete rows;

CREATE OR REPLACE PROCEDURE set_need_synchronize(pID number) IS
BEGIN
	INSERT INTO need_synchronize_4091 (project_id) values (pID);
END;
/

CREATE OR REPLACE PROCEDURE put_need_synchronize AS
BEGIN
	UPDATE fw_SYS_STAT_PVSS_PROJECT SET NEED_SYNCHRONIZE = 'Y'
	WHERE fw_SYS_STAT_PVSS_PROJECT.id IN (SELECT project_id FROM need_synchronize_4091);

	DELETE FROM need_synchronize_4091;
END;
/
CREATE OR REPLACE PROCEDURE put_sys_need_synchronize AS
BEGIN
	UPDATE fw_SYS_STAT_PVSS_PROJECT SET NEED_SYNCHRONIZE = 'Y'
	WHERE fw_SYS_STAT_PVSS_PROJECT.system_id IN (
		SELECT project_id AS system_id FROM need_synchronize_4091
	);

	DELETE FROM need_synchronize_4091;
END;
/
CREATE OR REPLACE PROCEDURE put_group_need_synchronize AS
BEGIN
	UPDATE FW_SYS_STAT_PVSS_PROJECT SET NEED_SYNCHRONIZE = 'Y'
	WHERE ID IN (
		SELECT PROJECT_ID FROM FW_SYS_STAT_PROJECT_GROUPS WHERE GROUP_ID IN (
			SELECT project_id AS group_id FROM need_synchronize_4091 
		)
	);

	DELETE FROM need_synchronize_4091;
END;
/

--1. Tool Upgrade
CREATE OR REPLACE TRIGGER FW_SYS_STAT_TOOL_UPGRADE_bc
   BEFORE UPDATE OR INSERT OR DELETE ON FW_SYS_STAT_TOOL_UPGRADE
   FOR EACH ROW
DECLARE pID number;
BEGIN
	IF DELETING THEN
	    pID := :old.project_id;
	ELSE
	    pID := :new.project_id;
	END IF;
	set_need_synchronize(pID);
END;
/
CREATE OR REPLACE TRIGGER FW_SYS_STAT_TOOL_UPGRADE_ac
   AFTER UPDATE OR INSERT OR DELETE ON FW_SYS_STAT_TOOL_UPGRADE
BEGIN
	put_need_synchronize();
END;
/

-- 2. Project Paths
CREATE OR REPLACE TRIGGER fw_sys_stat_inst_path_bc
  BEFORE INSERT OR UPDATE OR DELETE ON fw_sys_stat_inst_path
  FOR EACH ROW
DECLARE pID number;
BEGIN
	IF DELETING THEN
	    pID := :old.project_id;
	ELSE
	    pID := :new.project_id;
	END IF;
	set_need_synchronize(pID);
END;
/
CREATE OR REPLACE TRIGGER fw_sys_stat_inst_path_ac
  AFTER INSERT OR UPDATE OR DELETE ON fw_sys_stat_inst_path
BEGIN
	put_need_synchronize();
END;
/

--3. Redu Host (redu_computer_id), centrally_managed, system_id.
CREATE OR REPLACE TRIGGER fw_sys_stat_pvss_project_bc
  BEFORE UPDATE OF REDU_COMPUTER_ID, CENTRALLY_MANAGED, SYSTEM_ID ON fw_SYS_STAT_PVSS_PROJECT
  FOR EACH ROW
BEGIN
	:new.NEED_SYNCHRONIZE := 'Y';
END;
/

--4. System changes 
CREATE OR REPLACE TRIGGER fw_sys_stat_pvss_system_bc
  BEFORE UPDATE OR INSERT OR DELETE ON fw_sys_stat_pvss_system
  FOR EACH ROW
DECLARE sID number;
BEGIN
	IF DELETING THEN
	    sID := :old.id;
	ELSE
	    sID := :new.id;
	END IF;
	set_need_synchronize(sID);
END;
/
CREATE OR REPLACE TRIGGER fw_sys_stat_pvss_system_ac
  AFTER UPDATE OR INSERT OR DELETE ON fw_sys_stat_pvss_system
BEGIN
	put_sys_need_synchronize();
END;
/
--4.b FW_SYS_STAT_SYSTEM_CONNECT
CREATE OR REPLACE TRIGGER fw_sys_stat_system_connect_bc
  BEFORE UPDATE OR INSERT OR DELETE ON fw_sys_stat_system_connect
  FOR EACH ROW
DECLARE sID_1 number;
        sID_2 number;
BEGIN
	IF DELETING THEN
	    sID_1 := :old.peer_1_id;
	    sID_2 := :old.peer_2_id;
	ELSE
	    sID_1 := :new.peer_1_id;
	    sID_2 := :new.peer_2_id;
	END IF;
	set_need_synchronize(sID_1);
	set_need_synchronize(sID_2);
END;
/
CREATE OR REPLACE TRIGGER fw_sys_stat_system_connect_ac
  AFTER UPDATE OR INSERT OR DELETE ON fw_sys_stat_system_connect
BEGIN
	put_sys_need_synchronize();
END;
/

--5. On components reinstall
CREATE OR REPLACE TRIGGER fw_sys_stat_FORCE_REINSTALL_bc
   BEFORE UPDATE OR INSERT OR DELETE ON fw_sys_stat_force_reinstall
   FOR EACH ROW
DECLARE pID number;
BEGIN
	IF DELETING THEN
	    pID := :old.project_id;
	ELSE
	    pID := :new.project_id;
	END IF;
	set_need_synchronize(pID);
END;
/

CREATE OR REPLACE TRIGGER fw_sys_stat_FORCE_REINSTALL_ac
   AFTER UPDATE OR INSERT OR DELETE ON fw_sys_stat_force_reinstall
BEGIN
	put_need_synchronize();
END;
/

--6. Compid/Groupsid mapping
CREATE OR REPLACE TRIGGER fw_sys_stat_comp_in_groups_bc
   BEFORE INSERT OR UPDATE OR DELETE ON FW_SYS_STAT_COMP_IN_GROUPS
   FOR EACH ROW
DECLARE gID number;
BEGIN
	IF DELETING THEN
            gID := :old.group_id;
	ELSE
	    gID := :new.group_id;
	END IF;
	set_need_synchronize(gID);
END;
/
CREATE OR REPLACE TRIGGER fw_sys_stat_comp_in_groups_ac
  AFTER INSERT OR UPDATE OR DELETE ON fw_sys_stat_comp_in_groups
BEGIN
	put_group_need_synchronize();
END;
/  

--6.b mapping groupids to projectids
CREATE OR REPLACE TRIGGER fw_sys_stat_project_groups_bc
   BEFORE UPDATE OR INSERT OR DELETE ON fw_sys_stat_project_groups
   FOR EACH ROW
DECLARE pID number;
BEGIN
	IF DELETING THEN
	    pID := :old.project_id;
	ELSE
	    pID := :new.project_id;
	END IF;
	set_need_synchronize(pID);
END;
/
CREATE OR REPLACE TRIGGER fw_sys_stat_project_groups_ac
   AFTER UPDATE OR INSERT OR DELETE ON fw_sys_stat_project_groups
BEGIN
	put_need_synchronize();
END;
/
		
--Upgrade Schema version
CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '4.1.4'
	FROM dual;
