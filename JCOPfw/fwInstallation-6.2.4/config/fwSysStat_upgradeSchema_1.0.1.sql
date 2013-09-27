--Update schema version
CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '1.0.1'
	FROM dual;

--Update table fw_sys_stat_pvss_project to allow for the different statuses:
ALTER TABLE fw_sys_stat_pvss_project
		ADD (is_pvss_ok NUMBER,
		     is_patch_ok NUMBER,
		     is_host_ok NUMBER,
		     is_path_ok NUMBER,
		     is_manager_ok NUMBER,
		     is_group_ok NUMBER,
		     is_component_ok NUMBER,
		     is_ext_process_ok NUMBER);

--Create external process table
CREATE TABLE fw_sys_stat_ext_process
   		     (id 			NUMBER,
   		      process_name 	VARCHAR2(128) NOT NULL,
   		      path 			VARCHAR2(256) NOT NULL,
   		      description	VARCHAR2(256),
   		      options		VARCHAR2(256),
   		      project_id NUMBER,
   		      valid_from 		DATE default SYSDATE,
		      valid_until 		DATE,
			  CONSTRAINT ext_proc_id_pk PRIMARY KEY (id));

ALTER TABLE fw_sys_stat_ext_process
	ADD CONSTRAINT proc_pvss_project_id_fk
	FOREIGN KEY (project_id)
	REFERENCES fw_sys_stat_pvss_project(id);

CREATE SEQUENCE fw_sys_stat_ext_process_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

--Add column to signal FW component or PVSS patch to FW Components:
ALTER TABLE fw_sys_stat_component
		ADD (is_patch NUMBER);

--Add source dir to FW components in groups:
ALTER TABLE fw_sys_stat_comp_in_groups
		ADD (description_file VARCHAR2(512));


--Add dependency between project and pvss version
ALTER TABLE fw_sys_stat_pvss_project
		ADD (pvss_base_id number);

ALTER TABLE fw_sys_stat_pvss_project
	ADD CONSTRAINT project_pvss_base_id_fk
	FOREIGN KEY (pvss_base_id)
	REFERENCES fw_sys_stat_pvss_base_version(id);


--Add versioning to computers table
ALTER TABLE fw_sys_stat_computer
		ADD (valid_from 		DATE default SYSDATE,
             valid_until 		DATE);

--Add versioning to PVSS system table
ALTER TABLE fw_sys_stat_pvss_system
		ADD (valid_from 		DATE default SYSDATE,
             valid_until 		DATE);

--Add versioning to FW Components table
ALTER TABLE fw_sys_stat_component
	ADD (valid_from 		DATE default SYSDATE,
         valid_until 		DATE);

--Add versioning to connectivity table
ALTER TABLE fw_sys_stat_system_connect
		ADD (valid_from 		DATE default SYSDATE,
             valid_until 		DATE);

--Add centrally managed flag to the project
ALTER TABLE fw_sys_stat_pvss_project
		ADD (centrally_managed 		NUMBER);


----Modify project manager table:
--Step 1.- remove previous constraints:
ALTER TABLE fw_sys_stat_project_manager
DROP CONSTRAINT manger_type_NUMBER_project_uq;
--Step 2.- Create new contraint:
ALTER TABLE fw_sys_stat_project_manager
ADD CONSTRAINT  manger_type_number_project_uq UNIQUE(manager_type, command_line, project_id);

ALTER TABLE fw_sys_stat_project_manager
DROP COLUMN manager_number;

ALTER TABLE fw_sys_stat_project_manager
DROP COLUMN ok_state;
--Step 3.- add table to indicate whether the alerts are triggered by the system overview tool if manager is not running
ALTER TABLE fw_sys_stat_project_manager
ADD (triggers_alerts NUMBER);

--Fix bug in table fw_sys_stat_pvss_setup:
----Modify pvss setup table:
--Step 1.- remove previous constraints:
ALTER TABLE fw_sys_stat_pvss_setup
DROP CONSTRAINT pvss_setup_id_pk;
--Step 2.- Create new contraint:
ALTER TABLE fw_sys_stat_pvss_setup
ADD CONSTRAINT  pvss_setup_id_pk PRIMARY KEY(id);



--Create sequence for project managers:
CREATE SEQUENCE fw_sys_stat_proj_manager_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;
