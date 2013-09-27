ALTER TABLE  fw_sys_stat_pvss_project DROP COLUMN need_synchronize;

DROP TRIGGER FW_SYS_STAT_TOOL_UPGRADE_ch;
DROP TRIGGER fw_sys_stat_inst_path_ch;
DROP TRIGGER fw_sys_stat_pvss_project_ch;
DROP TRIGGER fw_sys_stat_pvss_system_ch;
DROP TRIGGER fw_sys_stat_FORCE_REINSTALL_ch;
DROP TRIGGER FW_SYS_STAT_COMP_IN_GROUPS_ch;
DROP TRIGGER fw_sys_stat_project_groups_ch;

CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '4.1.5'
	FROM dual;

