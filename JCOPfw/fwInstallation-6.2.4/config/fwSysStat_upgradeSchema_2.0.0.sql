--Update schema version
CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '2.0.0'
	FROM dual;

--Wiew on the project components taking the highest version of a component registered for a project
--Note: When using different groups, different versions of the same component can be targeted on the same project.
--      This view solves this problem by picking up the highest version of each component in a project.
CREATE OR REPLACE VIEW fw_sys_stat_proj_comps AS
	SELECT HOSTNAME, PROJECT_NAME, COMPONENT_NAME, MAX(COMPONENT_VERSION) COMPONENT_VERSION, IS_SUBCOMPONENT, DEFAULT_PATH, IS_OFFICIAL, IS_PATCH, DESCRIPTION_FILE, OVERWRITE_FILES, FORCE_REQUIRED, IS_SILENT
	FROM (SELECT PC.HOSTNAME, P.PROJECT_NAME, C.COMPONENT_NAME, C.COMPONENT_VERSION, C.IS_SUBCOMPONENT, C.DEFAULT_PATH, C.IS_OFFICIAL, C.IS_PATCH, GC.DESCRIPTION_FILE, PG.OVERWRITE_FILES, PG.FORCE_REQUIRED, PG.IS_SILENT
			FROM FW_SYS_STAT_PVSS_PROJECT P, FW_SYS_STAT_GROUP_OF_COMP G, FW_SYS_STAT_PROJECT_GROUPS PG, FW_SYS_STAT_COMP_IN_GROUPS GC, FW_SYS_STAT_COMPONENT C, FW_SYS_STAT_COMPUTER PC
			WHERE P.ID = PG.PROJECT_ID AND PG.VALID_UNTIL IS NULL AND P.VALID_UNTIL IS NULL AND G.ID = PG.GROUP_ID AND GC.GROUP_ID = G.ID AND GC.VALID_UNTIL IS NULL AND C.ID = GC.FW_COMPONENT_ID AND C.VALID_UNTIL IS NULL AND PC.ID = P.COMPUTER_ID AND PC.VALID_UNTIL IS NULL)
	GROUP BY COMPONENT_NAME, HOSTNAME, PROJECT_NAME, COMPONENT_NAME, IS_SUBCOMPONENT, DEFAULT_PATH, IS_OFFICIAL, IS_PATCH, DESCRIPTION_FILE, OVERWRITE_FILES, FORCE_REQUIRED, IS_SILENT;

-- Add table fw_sys_stat_install_proj_comps: list of project requested components
CREATE TABLE fw_sys_stat_proj_install_comps
			 (id					NUMBER,
			 component_id			NUMBER,
			 project_id 			NUMBER,
             installed_by 			VARCHAR2(64),
             installation_date		DATE default SYSDATE,
             valid_until			DATE,
			 CONSTRAINT inst_project_comp_id_pk PRIMARY KEY (id),
			 CONSTRAINT inst_comp_project_uq UNIQUE (component_id, project_id, valid_until));

-- Add foreign key onto the component table
ALTER TABLE fw_sys_stat_proj_install_comps
	ADD CONSTRAINT inst_comp_project_comp_id_fk
	FOREIGN KEY (component_id)
	REFERENCES fw_sys_stat_component(id);

-- Add foreign key onto the project table
ALTER TABLE fw_sys_stat_proj_install_comps
	ADD CONSTRAINT inst_proj_proj_comp_id_fk
	FOREIGN KEY (project_id)
	REFERENCES fw_sys_stat_pvss_project(id);

CREATE SEQUENCE fw_sys_stat_proj_inst_comp_sq
    MINVALUE 1
    MAXVALUE 9999999
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

 ALTER TABLE fw_sys_stat_project_manager
	ADD (valid_from 		DATE default SYSDATE,
         valid_until 		DATE);