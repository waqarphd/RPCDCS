int fwSysOverviewDB_getHostProjects(string host, dyn_dyn_mixed &projectsInfo)
{
  string sql;
  dyn_dyn_mixed record;
  dyn_mixed var;
  var[1] = strtoupper(host);
  
  sql = "SELECT p.project_name, p.pmon_port, p.pmon_username, p.pmon_password, upper(h.hostname), s.system_name, s.system_number, p.system_overview " +
      	 "FROM fw_sys_stat_pvss_project p, fw_sys_stat_computer h, fw_sys_stat_pvss_system s " +
      	 "WHERE h.hostname = :1 and p.valid_until is null AND h.valid_until is null AND p.computer_id = h.id AND s.valid_until is null AND p.system_id = s.id " +
      	 "order by system_name";
              
  if(fwInstallationDB_executeQuery(sql, var, record)) {fwInstallation_throw("fwSysOverviewDB_getHostProjects() -> Could not execute the following SQL: " + sql); return -1;};
  
  projectsInfo = record;
  
//  DebugN("******************projectInfo", projectInfo);
//  DebugTN("*****************dynlen projectInfo", dynlen(projectInfo));
  
  return 0;
}
