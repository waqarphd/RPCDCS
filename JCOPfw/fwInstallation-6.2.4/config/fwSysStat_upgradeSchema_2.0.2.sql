--System Configuration DB Update patch v2.0.1
-- Changes w.r.t. v 2.0.0
-- 1.- Add new column to installed project components table to keep track of the description file for installed components.
-- 2.- Add new column to installed project components table to keep track of the component installation directory.
-- 3.- Drop constraint: INST_COMP_PROJECT_UQ

--Update schema version
CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '2.0.2'
	FROM dual;

ALTER TABLE FW_SYS_STAT_PROJ_INSTALL_COMPS
	ADD (description_file VARCHAR2(512));

ALTER TABLE FW_SYS_STAT_PROJ_INSTALL_COMPS
	ADD (installation_path VARCHAR2(512));

ALTER TABLE FW_SYS_STAT_PROJ_INSTALL_COMPS
	DROP CONSTRAINT INST_COMP_PROJECT_UQ;
