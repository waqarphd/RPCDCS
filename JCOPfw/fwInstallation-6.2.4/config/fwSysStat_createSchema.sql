CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '1.0.0'
	FROM dual;

CREATE TABLE fw_sys_stat_pvss_version
   		     (id 			NUMBER,
   		      version_name 	VARCHAR2(32) NOT NULL,
   		      os 			VARCHAR2(32) NOT NULL,
			  CONSTRAINT pvss_id_pk PRIMARY KEY (id),
			  CONSTRAINT version_os_uq UNIQUE (version_name, os));

CREATE TABLE fw_sys_stat_pvss_patch
			 (id 							NUMBER,
			  patch_name 					VARCHAR2(32) NOT NULL,
			  pvss_version_id				NUMBER,
			  CONSTRAINT patch_id_pk PRIMARY KEY (id),
			  CONSTRAINT patch_pvss_version_uq UNIQUE (patch_name, pvss_version_id));

CREATE TABLE fw_sys_stat_computer
			 (id			NUMBER,
			  hostname 		VARCHAR2(64) UNIQUE NOT NULL,
			  ip 			VARCHAR2(64) UNIQUE,
			  mac		    VARCHAR2(128) UNIQUE,
			  ip2			VARCHAR2(64),
			  mac2			VARCHAR2(128),
			  bmc_ip		VARCHAR2(64),
			  bmc_ip2		VARCHAR2(64),
			  CONSTRAINT computer_id_pk PRIMARY KEY (id));

CREATE TABLE fw_sys_stat_pvss_base_version
			 (id 				NUMBER,
			  computer_id		NUMBER,
			  pvss_version_id 	NUMBER,
			  CONSTRAINT base_version_id_pk PRIMARY KEY (id),
			  CONSTRAINT computer_pvss_uq UNIQUE(computer_id, pvss_version_id));

CREATE TABLE fw_sys_stat_pvss_setup
             (id 				NUMBER,
              base_version_id 	NUMBER,
              patch_id 	NUMBER,
              valid_from 		DATE default SYSDATE,
              valid_until 		DATE,
              CONSTRAINT pvss_setup_id_pk PRIMARY KEY(id, valid_until));


CREATE TABLE fw_sys_stat_pvss_project
             (id 						NUMBER,
              project_name 				VARCHAR2(128) NOT NULL,
              computer_id				NUMBER,
              project_dir 				VARCHAR2(1024),
              pmon_port 				NUMBER default 4999,
              pmon_username 			VARCHAR2(64),
              pmon_password 			VARCHAR2(64),
              fw_inst_tool_version 		VARCHAR2(32),
              valid_from 				DATE default SYSDATE,
              valid_until 				DATE,
              system_id 				NUMBER,
              default_inst_path_id		NUMBER,
              is_project_ok				NUMBER,
              last_time_checked			DATE,
              CONSTRAINT project_id_pk PRIMARY KEY (id),
              CONSTRAINT project_uq UNIQUE (project_name, computer_id, valid_until));


CREATE TABLE fw_sys_stat_inst_path
             (id 					NUMBER,
              project_id				NUMBER,
              path					VARCHAR2(1024),
              valid_from 			DATE default SYSDATE,
              valid_until 			DATE,
              CONSTRAINT installtion_path_id_pk PRIMARY KEY (id),
              CONSTRAINT project_path_uq UNIQUE(project_id, path, valid_until));


CREATE TABLE fw_sys_stat_pvss_system
			 (id 						NUMBER,
			  system_name 				VARCHAR2(128) NOT NULL,
			  system_NUMBER 			NUMBER NOT NULL,
			  redundancy_NUMBER 		NUMBER default 1,
			  data_port 				NUMBER default 4897,
			  event_port 				NUMBER default 4998,
			  dist_port 				NUMBER default 4777,
			  parent_system_id 	 		NUMBER,
			  redu_system_id 	NUMBER,
			  CONSTRAINT system_id_pk PRIMARY KEY (id),
			  CONSTRAINT name_NUMBER_redundancy_uq UNIQUE (system_name, system_NUMBER, redundancy_NUMBER));




CREATE TABLE fw_sys_stat_system_connect
			 (peer_1_id 			NUMBER,
			  peer_2_id 			NUMBER,
			  CONSTRAINT peer_1_2_uq UNIQUE (peer_1_id, peer_2_id));



CREATE TABLE fw_sys_stat_manager_type
             (manager_type 			VARCHAR2(128) NOT NULL,
              description 			VARCHAR2(256),
              manager_group			VARCHAR2(64),
              CONSTRAINT manager_type_pk PRIMARY KEY (manager_type));

CREATE TABLE fw_sys_stat_project_manager
			 (id 					NUMBER,
			  manager_type 			VARCHAR2(128) NOT NULL,
			  manager_NUMBER 		NUMBER(3) NOT NULL,
			  start_mode 			VARCHAR2(32) default 'once',
			  restart_count 		NUMBER default 2,
			  reset_min 			NUMBER default 2,
			  sec_kill 				NUMBER default 30,
			  command_line 			VARCHAR2(256),
			  project_id 			NUMBER,
			  ok_state				NUMBER NOT NULL,
			  CONSTRAINT project_manager_id_pk PRIMARY KEY (id),
			  CONSTRAINT manger_type_NUMBER_project_uq UNIQUE(manager_type, manager_NUMBER, project_id));


CREATE TABLE fw_sys_stat_component
             (id 					NUMBER,
              component_name 		VARCHAR2(128) NOT NULL,
              component_version 	VARCHAR2(32) NOT NULL,
              is_subcomponent 		NUMBER default 0,
              default_path 			VARCHAR2(1024),
              is_official 			NUMBER default 1,
              CONSTRAINT component_id_pk PRIMARY KEY (id),
              CONSTRAINT name_version_uq UNIQUE (component_name, component_version));

CREATE TABLE fw_sys_stat_component_depend
			 (fw_component_id 			NUMBER,
			  required_fw_component_id NUMBER,
			  CONSTRAINT component_required_uq UNIQUE(fw_component_id, required_fw_component_id));

CREATE TABLE fw_sys_stat_group_of_comp
             (id					NUMBER,
              name 			varchar(256) NOT NULL,
              CONSTRAINT group_id_pk PRIMARY KEY (id),
              CONSTRAINT group_name_uq UNIQUE(name));

CREATE TABLE fw_sys_stat_project_groups
			 (id					NUMBER,
			  group_id 				NUMBER,
			  project_id 			NUMBER,
              requested_by 			VARCHAR2(64),
              request_DATE 			DATE default SYSDATE,
              overwrite_files 	 	NUMBER default 0,
              force_required 	 	NUMBER default 1,
              is_silent 		 	NUMBER default 0,
              scheduled_inst_DATE 	DATE default SYSDATE,
              valid_until			DATE,
			  CONSTRAINT project_groups_id_pk PRIMARY KEY (id),
			  CONSTRAINT group_project_uq UNIQUE (group_id, project_id, valid_until));

CREATE TABLE fw_sys_stat_comp_in_groups
			 (group_id 						NUMBER,
			  fw_component_id 				NUMBER,
			  valid_from					DATE default SYSDATE,
			  valid_until					DATE,
			  CONSTRAINT group_component_uq UNIQUE (group_id, fw_component_id, valid_until));


CREATE TABLE fw_sys_stat_comp_patch_depend
			 (fw_component_id 			NUMBER,
			  min_patch_id 				NUMBER,
			  CONSTRAINT component_patch_uq UNIQUE (fw_component_id, min_patch_id));

ALTER TABLE fw_sys_stat_pvss_patch
	ADD CONSTRAINT patch_pvss_version_id_fk
	FOREIGN KEY (pvss_version_id)
	REFERENCES fw_sys_stat_pvss_version(id);


ALTER TABLE fw_sys_stat_pvss_base_version
	ADD CONSTRAINT base_pvss_version_id_fk
	FOREIGN KEY (pvss_version_id)
	REFERENCES fw_sys_stat_pvss_version(id);


ALTER TABLE fw_sys_stat_pvss_base_version
	ADD CONSTRAINT base_computer_id_fk
	FOREIGN KEY (computer_id)
	REFERENCES fw_sys_stat_computer(id);


ALTER TABLE fw_sys_stat_pvss_setup
	ADD CONSTRAINT setup_base_version_id_fk
	FOREIGN KEY (base_version_id)
	REFERENCES fw_sys_stat_pvss_base_version(id);


ALTER TABLE fw_sys_stat_pvss_setup
	ADD CONSTRAINT setup_pvss_patch_id_fk
	FOREIGN KEY (patch_id)
	REFERENCES fw_sys_stat_pvss_patch(id);


ALTER TABLE fw_sys_stat_project_manager
	ADD CONSTRAINT project_manager_type_id_fk
	FOREIGN KEY (manager_type)
	REFERENCES fw_sys_stat_manager_type(manager_type);


ALTER TABLE fw_sys_stat_project_manager
	ADD CONSTRAINT project_manager_project_id_fk
	FOREIGN KEY (project_id)
	REFERENCES fw_sys_stat_pvss_project(id);


ALTER TABLE fw_sys_stat_pvss_project
	ADD CONSTRAINT project_computer_id_fk
	FOREIGN KEY (computer_id)
	REFERENCES fw_sys_stat_computer(id);


ALTER TABLE fw_sys_stat_pvss_project
	ADD CONSTRAINT project_system_id_fk
	FOREIGN KEY (system_id)
	REFERENCES fw_sys_stat_pvss_system(id);


ALTER TABLE fw_sys_stat_pvss_project
	ADD CONSTRAINT project_path_id_fk
	FOREIGN KEY (default_inst_path_id)
	REFERENCES fw_sys_stat_inst_path(id);


ALTER TABLE fw_sys_stat_inst_path
	ADD CONSTRAINT path_project_id_fk
	FOREIGN KEY (project_id)
	REFERENCES fw_sys_stat_pvss_project(id);



ALTER TABLE fw_sys_stat_pvss_system
	ADD CONSTRAINT system_system_id_fk
	FOREIGN KEY (parent_system_id)
	REFERENCES fw_sys_stat_pvss_system(id);


ALTER TABLE fw_sys_stat_pvss_system
	ADD CONSTRAINT redu_system_system_id_fk
	FOREIGN KEY (redu_system_id)
	REFERENCES fw_sys_stat_pvss_system(id);


ALTER TABLE fw_sys_stat_system_connect
	ADD CONSTRAINT system_peer_1_id_fk
	FOREIGN KEY (peer_1_id)
	REFERENCES fw_sys_stat_pvss_system(id);


ALTER TABLE fw_sys_stat_system_connect
	ADD CONSTRAINT system_peer_2_id_fk
	FOREIGN KEY (peer_2_id)
	REFERENCES fw_sys_stat_pvss_system(id);


ALTER TABLE fw_sys_stat_comp_patch_depend
	ADD CONSTRAINT fw_component_depend_id_fk
	FOREIGN KEY (fw_component_id)
	REFERENCES fw_sys_stat_component(id);


ALTER TABLE fw_sys_stat_comp_patch_depend
	ADD CONSTRAINT patch_depend_id_fk
	FOREIGN KEY (min_patch_id)
	REFERENCES fw_sys_stat_pvss_patch(id);


ALTER TABLE fw_sys_stat_component_depend
	ADD CONSTRAINT fw_component_component_id_fk
	FOREIGN KEY (fw_component_id)
	REFERENCES fw_sys_stat_component(id);


ALTER TABLE fw_sys_stat_component_depend
	ADD CONSTRAINT fw_comp_req_comp_id_fk
	FOREIGN KEY (required_fw_component_id)
	REFERENCES fw_sys_stat_component(id);


ALTER TABLE fw_sys_stat_comp_in_groups
	ADD CONSTRAINT comp_comp_group_id_fk
	FOREIGN KEY (fw_component_id)
	REFERENCES fw_sys_stat_component(id);


ALTER TABLE fw_sys_stat_comp_in_groups
	ADD CONSTRAINT group_comp_group_id_fk
	FOREIGN KEY (group_id)
	REFERENCES fw_sys_stat_group_of_comp(id);


ALTER TABLE fw_sys_stat_project_groups
	ADD CONSTRAINT group_project_group_id_fk
	FOREIGN KEY (group_id)
	REFERENCES fw_sys_stat_group_of_comp(id);


ALTER TABLE fw_sys_stat_project_groups
	ADD CONSTRAINT project_project_group_id_fk
	FOREIGN KEY (project_id)
	REFERENCES fw_sys_stat_pvss_project(id);



CREATE SEQUENCE fw_sys_stat_pvss_version_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE fw_sys_stat_pvss_patch_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE fw_sys_stat_computer_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE fw_sys_stat_base_version_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE fw_sys_stat_pvss_setup_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE fw_sys_stat_pvss_project_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE fw_sys_stat_inst_path_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE fw_sys_stat_pvss_system_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE fw_sys_stat_project_manger_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE fw_sys_stat_group_of_comp_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE fw_sys_stat_project_groups_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE fw_sys_stat_component_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

