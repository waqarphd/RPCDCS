CREATE TABLE fw_sys_stat_configuration
	(project_autoreg NUMBER);
INSERT INTO fw_sys_stat_configuration values(1);

ALTER TABLE fw_sys_stat_group_of_comp
ADD acdomain VARCHAR(128);


ALTER TABLE fw_sys_stat_pvss_system
ADD (REDU_PORT NUMBER, SPLIT_PORT NUMBER);

CREATE TABLE fw_sys_stat_system_responsible
	(id NUMBER,
	 system_id NUMBER,
	 responsible VARCHAR(128),
	 CONSTRAINT system_resp_id_pk PRIMARY KEY(id));

ALTER TABLE fw_sys_stat_system_responsible
	ADD CONSTRAINT fw_sys_stat_system_resp_id_fk
	FOREIGN KEY (system_id)
	REFERENCES fw_sys_stat_pvss_system(id);

CREATE TABLE fw_sys_stat_pc_responsible
	(id NUMBER,
	 computer_id NUMBER,
	 responsible VARCHAR(128),
	 CONSTRAINT pc_resp_id_pk PRIMARY KEY(id));

ALTER TABLE fw_sys_stat_pc_responsible
	ADD CONSTRAINT fw_sys_stat_comp_resp_id_fk
	FOREIGN KEY (computer_id)
	REFERENCES fw_sys_stat_computer(id);

CREATE OR REPLACE TRIGGER FW_SYS_STAT_COMPUTER_AC
	AFTER UPDATE OF VALID_UNTIL OR DELETE ON FW_SYS_STAT_COMPUTER
	FOR EACH ROW
DECLARE cID number;
BEGIN
	cID := :old.id;
	IF DELETING OR (UPDATING('VALID_UNTIL') AND :new.valid_until is not null) THEN
	    UPDATE  fw_sys_stat_pvss_project SET redu_computer_id = null
	    WHERE id in (SELECT id FROM fw_sys_stat_pvss_project where redu_computer_id=cID);
	END IF;
END;
/
--Upgrade Schema version
CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '4.1.5'
	FROM dual;

