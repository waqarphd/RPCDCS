CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '4.1.0'
	FROM dual;

ALTER TABLE FW_SYS_STAT_PVSS_SYSTEM
	ADD CONSTRAINT COMPUTER_ID_FK
	FOREIGN KEY (COMPUTER_ID)
	REFERENCES FW_SYS_STAT_COMPUTER(ID) ON DELETE CASCADE;

ALTER TABLE FW_SYS_STAT_PVSS_PROJECT
DROP COLUMN DEFAULT_INST_PATH_ID;

ALTER TABLE FW_SYS_STAT_COMPUTER
ADD (FMC_ENABLE_PROCESS_MONITORING NUMBER,
	 LOCATION VARCHAR2(64),
	 DESCRIPTION VARCHAR(512),
	 FMC_WIN_PROCS_CONTROLLER VARCHAR(64),
	 FMC_OS VARCHAR2(32),
	 FMC_IPMI_MASTER VARCHAR2(128));

--SELECT * FROM FW_SYS_STAT_COMPUTER;

alter table fw_sys_stat_computer rename column enable_ipmi to fmc_enable_ipmi;
alter table fw_sys_stat_computer rename column ipmi_device_name to bmc_name;
alter table fw_sys_stat_computer rename column enable_monitoring to fmc_enable_monitoring;
alter table fw_sys_stat_computer rename column monitoring_level to fmc_monitoring_level;
alter table fw_sys_stat_computer rename column enable_tm to fmc_enable_tm;
alter table fw_sys_stat_computer rename column enable_logger to fmc_enable_logger;
alter table fw_sys_stat_computer drop column fmc_group;


CREATE TABLE FW_SYS_STAT_FMC_GROUP
   		     (COMPUTER_ID NUMBER NOT NULL,
   		      NAME VARCHAR(128));

ALTER TABLE FW_SYS_STAT_FMC_GROUP
	ADD CONSTRAINT FMC_GROUP_COMPUTER_ID_FK
	FOREIGN KEY (COMPUTER_ID)
	REFERENCES FW_SYS_STAT_COMPUTER(ID) ON DELETE CASCADE;



