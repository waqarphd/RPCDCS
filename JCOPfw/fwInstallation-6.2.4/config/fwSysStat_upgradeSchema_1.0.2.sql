--Update schema version
CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '1.0.2'
	FROM dual;

ALTER TABLE fw_sys_stat_system_connect
DROP CONSTRAINT PEER_1_2_UQ;
