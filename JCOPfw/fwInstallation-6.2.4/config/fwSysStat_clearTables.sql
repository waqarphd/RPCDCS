begin
for rec in (select table_name from user_tables where table_name like 'FW_SYS_STAT_%') loop
	delete rec.table_name;
end loop;
end;
