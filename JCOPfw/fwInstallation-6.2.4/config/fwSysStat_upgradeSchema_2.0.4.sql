--System Configuration DB Update patch v2.0.4
-- Changes w.r.t. v 2.0.2
-- 1.- Drop constraint MANGER_TYPE_NUMBER_PROJECT_UQ in order to allow for 'moving' managers, i.e. managers whose number is allocated dynamically by PVSS

--Update schema version
CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '2.0.4'
	FROM dual;

ALTER TABLE FW_SYS_STAT_PROJECT_MANAGER
	DROP CONSTRAINT MANGER_TYPE_NUMBER_PROJECT_UQ;
