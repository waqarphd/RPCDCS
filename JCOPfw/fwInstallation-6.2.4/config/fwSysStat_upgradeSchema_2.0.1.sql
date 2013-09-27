--System Configuration DB Update patch v2.0.1
-- Changes w.r.t. v 2.0.0
-- 1.- Order project components view by timestamp in order to resolve dependencies 
--		correctly when compnents are installed
-- 2.- Add new column to project table to signal whether a project is to be monitored
--		by the FW System Overview Tool or not.

--Update schema version
CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '2.0.1'
	FROM dual;

--Wiew on the project components taking the highest version of a component registered for a project
--Note: When using different groups, different versions of the same component can be targeted on the same project.
--      This view solves this problem by picking up the highest version of each component in a project.
CREATE OR REPLACE VIEW fw_sys_stat_proj_comps AS
	SELECT HOSTNAME, PROJECT_NAME, COMPONENT_NAME, MAX(COMPONENT_VERSION) COMPONENT_VERSION, IS_SUBCOMPONENT, DEFAULT_PATH, IS_OFFICIAL, IS_PATCH, DESCRIPTION_FILE, OVERWRITE_FILES, FORCE_REQUIRED, IS_SILENT, VALID_FROM
	FROM (SELECT PC.HOSTNAME, P.PROJECT_NAME, C.COMPONENT_NAME, C.COMPONENT_VERSION, C.IS_SUBCOMPONENT, C.DEFAULT_PATH, C.IS_OFFICIAL, C.IS_PATCH, GC.DESCRIPTION_FILE, PG.OVERWRITE_FILES, PG.FORCE_REQUIRED, PG.IS_SILENT, GC.VALID_FROM
			FROM FW_SYS_STAT_PVSS_PROJECT P, FW_SYS_STAT_GROUP_OF_COMP G, FW_SYS_STAT_PROJECT_GROUPS PG, FW_SYS_STAT_COMP_IN_GROUPS GC, FW_SYS_STAT_COMPONENT C, FW_SYS_STAT_COMPUTER PC
			WHERE P.ID = PG.PROJECT_ID AND PG.VALID_UNTIL IS NULL AND P.VALID_UNTIL IS NULL AND G.ID = PG.GROUP_ID AND GC.GROUP_ID = G.ID AND GC.VALID_UNTIL IS NULL AND C.ID = GC.FW_COMPONENT_ID AND C.VALID_UNTIL IS NULL AND PC.ID = P.COMPUTER_ID AND PC.VALID_UNTIL IS NULL)
	GROUP BY COMPONENT_NAME, HOSTNAME, PROJECT_NAME, COMPONENT_NAME, IS_SUBCOMPONENT, DEFAULT_PATH, IS_OFFICIAL, IS_PATCH, DESCRIPTION_FILE, OVERWRITE_FILES, FORCE_REQUIRED, IS_SILENT, VALID_FROM ORDER BY VALID_FROM;

ALTER TABLE fw_sys_stat_pvss_project
	ADD (system_overview NUMBER);
