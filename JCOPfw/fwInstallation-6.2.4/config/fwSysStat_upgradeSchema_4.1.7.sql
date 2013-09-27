drop table fw_sys_stat_conf_contents;
drop table fw_sys_stat_proj_confs;
drop table fw_sys_stat_comp_configs;
drop sequence fw_sys_stat_configuration_sq;
-----------------------------
CREATE TABLE fw_sys_stat_comp_configs
   		     (id 			NUMBER,
   		      configuration 	VARCHAR2(32) NOT NULL,
   		      version 	VARCHAR2(32) NOT NULL,
   		      valid_from date not null,
   		      valid_until date,
			  CONSTRAINT comp_conf_id_pk PRIMARY KEY (id),
			  CONSTRAINT configuration UNIQUE (configuration, version));

CREATE TABLE fw_sys_stat_conf_contents
   		     (configuration_id 			NUMBER,
   		      type	 	VARCHAR2(32) NOT NULL,
   		      section 	VARCHAR2(32),
   		      item	 	VARCHAR2(1024) NOT NULL,
   		      value	 	VARCHAR2(4000),
   		      valid_from date not null,
   		      valid_until date);

ALTER TABLE fw_sys_stat_conf_contents
	ADD CONSTRAINT configuration_id_fk
	FOREIGN KEY (CONFIGURATION_ID)
	REFERENCES FW_SYS_STAT_COMP_CONFIGS(id)  ON DELETE CASCADE;;

CREATE TABLE fw_sys_stat_proj_confs
   		     (project_id 			NUMBER,
   		      configuration_id 			NUMBER,
   		      valid_from date not null,
   		      valid_until date,
   		      reapply number);

ALTER TABLE fw_sys_stat_proj_confs
	ADD CONSTRAINT proj_conf_id_fk
	FOREIGN KEY (CONFIGURATION_ID)
	REFERENCES FW_SYS_STAT_COMP_CONFIGS(id)  ON DELETE CASCADE;;

ALTER TABLE fw_sys_stat_proj_confs
	ADD CONSTRAINT proj_confs_id_fk
	FOREIGN KEY (project_ID)
	REFERENCES FW_SYS_STAT_PVSS_PROJECT(id) ON DELETE CASCADE;;


CREATE SEQUENCE fw_sys_stat_configuration_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '4.1.7'
	FROM dual;
