--System Configuration DB Update patch v2.0.3
-- Changes w.r.t. v 2.0.2
-- 1.- Add new columns to fw_sys_stat_computer for:
--		a) bmc_user
--		b) bmc_pwd
--		c) group: computer group, e.g. tracker, ecal, etc.
--
-- 2.- Alter all foreign keys in order to add "DELETE ON CASCADE" such
--     that the different items will be deleted hierarchically
--
--
--Update schema version
CREATE OR REPLACE VIEW fw_sys_stat_schema (version) AS
	SELECT '2.0.3'
	FROM dual;

ALTER TABLE FW_SYS_STAT_COMPUTER
	ADD (bmc_user VARCHAR2(512),
		 bmc_pwd VARCHAR2(512),
		 fmc_group VARCHAR2(512));

ALTER TABLE fw_sys_stat_pvss_patch
	DROP CONSTRAINT patch_pvss_version_id_fk;

ALTER TABLE fw_sys_stat_pvss_base_version
	DROP CONSTRAINT base_pvss_version_id_fk;

ALTER TABLE fw_sys_stat_pvss_base_version
	DROP CONSTRAINT base_computer_id_fk;

ALTER TABLE fw_sys_stat_pvss_setup
	DROP CONSTRAINT setup_base_version_id_fk;

ALTER TABLE fw_sys_stat_pvss_setup
	DROP CONSTRAINT setup_pvss_patch_id_fk;

ALTER TABLE fw_sys_stat_project_manager
	DROP CONSTRAINT project_manager_type_id_fk;

ALTER TABLE fw_sys_stat_project_manager
	DROP CONSTRAINT project_manager_project_id_fk;

ALTER TABLE fw_sys_stat_pvss_project
	DROP CONSTRAINT project_computer_id_fk;

ALTER TABLE fw_sys_stat_pvss_project
	DROP CONSTRAINT project_system_id_fk;

ALTER TABLE fw_sys_stat_pvss_project
	DROP CONSTRAINT project_path_id_fk;

ALTER TABLE fw_sys_stat_inst_path
	DROP CONSTRAINT path_project_id_fk;


ALTER TABLE fw_sys_stat_pvss_system
	DROP CONSTRAINT system_system_id_fk;

ALTER TABLE fw_sys_stat_pvss_system
	DROP CONSTRAINT redu_system_system_id_fk;

ALTER TABLE fw_sys_stat_system_connect
	DROP CONSTRAINT system_peer_1_id_fk;

ALTER TABLE fw_sys_stat_system_connect
	DROP CONSTRAINT system_peer_2_id_fk;

ALTER TABLE fw_sys_stat_comp_patch_depend
	DROP CONSTRAINT fw_component_depend_id_fk;

ALTER TABLE fw_sys_stat_comp_patch_depend
	DROP CONSTRAINT patch_depend_id_fk;

ALTER TABLE fw_sys_stat_component_depend
	DROP CONSTRAINT fw_component_component_id_fk;

ALTER TABLE fw_sys_stat_component_depend
	DROP CONSTRAINT fw_comp_req_comp_id_fk;

ALTER TABLE fw_sys_stat_comp_in_groups
	DROP CONSTRAINT comp_comp_group_id_fk;

ALTER TABLE fw_sys_stat_comp_in_groups
	DROP CONSTRAINT group_comp_group_id_fk;

ALTER TABLE fw_sys_stat_project_groups
	DROP CONSTRAINT group_project_group_id_fk;

ALTER TABLE fw_sys_stat_project_groups
	DROP CONSTRAINT project_project_group_id_fk;

ALTER TABLE fw_sys_stat_ext_process
	DROP CONSTRAINT proc_pvss_project_id_fk;

ALTER TABLE fw_sys_stat_pvss_project
	DROP CONSTRAINT project_pvss_base_id_fk;

ALTER TABLE fw_sys_stat_proj_install_comps
	DROP CONSTRAINT inst_comp_project_comp_id_fk;

ALTER TABLE fw_sys_stat_proj_install_comps
	DROP CONSTRAINT inst_proj_proj_comp_id_fk;

ALTER TABLE fw_sys_stat_pvss_patch
	ADD CONSTRAINT patch_pvss_version_id_fk
	FOREIGN KEY (pvss_version_id)
	REFERENCES fw_sys_stat_pvss_version(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_pvss_base_version
	ADD CONSTRAINT base_pvss_version_id_fk
	FOREIGN KEY (pvss_version_id)
	REFERENCES fw_sys_stat_pvss_version(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_pvss_base_version
	ADD CONSTRAINT base_computer_id_fk
	FOREIGN KEY (computer_id)
	REFERENCES fw_sys_stat_computer(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_pvss_setup
	ADD CONSTRAINT setup_base_version_id_fk
	FOREIGN KEY (base_version_id)
	REFERENCES fw_sys_stat_pvss_base_version(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_pvss_setup
	ADD CONSTRAINT setup_pvss_patch_id_fk
	FOREIGN KEY (patch_id)
	REFERENCES fw_sys_stat_pvss_patch(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_project_manager
	ADD CONSTRAINT project_manager_type_id_fk
	FOREIGN KEY (manager_type)
	REFERENCES fw_sys_stat_manager_type(manager_type) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_project_manager
	ADD CONSTRAINT project_manager_project_id_fk
	FOREIGN KEY (project_id)
	REFERENCES fw_sys_stat_pvss_project(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_pvss_project
	ADD CONSTRAINT project_computer_id_fk
	FOREIGN KEY (computer_id)
	REFERENCES fw_sys_stat_computer(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_pvss_project
	ADD CONSTRAINT project_system_id_fk
	FOREIGN KEY (system_id)
	REFERENCES fw_sys_stat_pvss_system(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_pvss_project
	ADD CONSTRAINT project_path_id_fk
	FOREIGN KEY (default_inst_path_id)
	REFERENCES fw_sys_stat_inst_path(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_inst_path
	ADD CONSTRAINT path_project_id_fk
	FOREIGN KEY (project_id)
	REFERENCES fw_sys_stat_pvss_project(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_pvss_system
	ADD CONSTRAINT system_system_id_fk
	FOREIGN KEY (parent_system_id)
	REFERENCES fw_sys_stat_pvss_system(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_pvss_system
	ADD CONSTRAINT redu_system_system_id_fk
	FOREIGN KEY (redu_system_id)
	REFERENCES fw_sys_stat_pvss_system(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_system_connect
	ADD CONSTRAINT system_peer_1_id_fk
	FOREIGN KEY (peer_1_id)
	REFERENCES fw_sys_stat_pvss_system(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_system_connect
	ADD CONSTRAINT system_peer_2_id_fk
	FOREIGN KEY (peer_2_id)
	REFERENCES fw_sys_stat_pvss_system(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_comp_patch_depend
	ADD CONSTRAINT fw_component_depend_id_fk
	FOREIGN KEY (fw_component_id)
	REFERENCES fw_sys_stat_component(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_comp_patch_depend
	ADD CONSTRAINT patch_depend_id_fk
	FOREIGN KEY (min_patch_id)
	REFERENCES fw_sys_stat_pvss_patch(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_component_depend
	ADD CONSTRAINT fw_component_component_id_fk
	FOREIGN KEY (fw_component_id)
	REFERENCES fw_sys_stat_component(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_component_depend
	ADD CONSTRAINT fw_comp_req_comp_id_fk
	FOREIGN KEY (required_fw_component_id)
	REFERENCES fw_sys_stat_component(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_comp_in_groups
	ADD CONSTRAINT comp_comp_group_id_fk
	FOREIGN KEY (fw_component_id)
	REFERENCES fw_sys_stat_component(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_comp_in_groups
	ADD CONSTRAINT group_comp_group_id_fk
	FOREIGN KEY (group_id)
	REFERENCES fw_sys_stat_group_of_comp(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_project_groups
	ADD CONSTRAINT group_project_group_id_fk
	FOREIGN KEY (group_id)
	REFERENCES fw_sys_stat_group_of_comp(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_project_groups
	ADD CONSTRAINT project_project_group_id_fk
	FOREIGN KEY (project_id)
	REFERENCES fw_sys_stat_pvss_project(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_ext_process
	ADD CONSTRAINT proc_pvss_project_id_fk
	FOREIGN KEY (project_id)
	REFERENCES fw_sys_stat_pvss_project(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_pvss_project
	ADD CONSTRAINT project_pvss_base_id_fk
	FOREIGN KEY (pvss_base_id)
	REFERENCES fw_sys_stat_pvss_base_version(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_proj_install_comps
	ADD CONSTRAINT inst_comp_project_comp_id_fk
	FOREIGN KEY (component_id)
	REFERENCES fw_sys_stat_component(id) ON DELETE CASCADE;

ALTER TABLE fw_sys_stat_proj_install_comps
	ADD CONSTRAINT inst_proj_proj_comp_id_fk
	FOREIGN KEY (project_id)
	REFERENCES fw_sys_stat_pvss_project(id) ON DELETE CASCADE;