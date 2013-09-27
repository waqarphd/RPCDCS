CREATE OR REPLACE VIEW fw_sys_stat_api (version) AS
	SELECT '1.0.0'
	FROM dual;

CREATE OR REPLACE PROCEDURE FW_SYS_STAT_UDPATE_COMP
       (p_component_name IN VARCHAR2,
        p_old_component_version IN VARCHAR2,
        p_new_component_version IN VARCHAR2,
        p_descfile IN VARCHAR2,
        p_is_subcomponent IN NUMBER := 0)
AS

BEGIN
                BEGIN
                                INSERT INTO FW_SYS_STAT_COMPONENT(ID, COMPONENT_NAME, COMPONENT_VERSION, IS_SUBCOMPONENT, VALID_FROM)
                                                                                                                VALUES(FW_SYS_STAT_COMPONENT_SQ.NEXTVAL, p_component_name, p_new_component_version, 0, SYSDATE);

                                EXCEPTION
--                                             WHEN DUP_VAL_ON_INDEX THEN  DBMS_OUTPUT.PUT_LINE('WARNING: ' || p_component_name || ' v.' || p_new_component_version || 'already registered in DB');
                                                WHEN others THEN  DBMS_OUTPUT.PUT_LINE('WARNING: ' || p_component_name || ' v.' || p_new_component_version || 'already registered in DB');
                END;

                UPDATE FW_SYS_STAT_COMP_IN_GROUPS G SET G.FW_COMPONENT_ID = ((SELECT C.ID FROM FW_SYS_STAT_COMPONENT C WHERE C.COMPONENT_NAME = p_component_name AND C.COMPONENT_VERSION = p_new_component_version AND C.VALID_UNTIL IS NULL)), DESCRIPTION_FILE = p_descfile, VALID_FROM = SYSDATE WHERE G.FW_COMPONENT_ID IN(
                                SELECT C.ID
                                FROM FW_SYS_STAT_COMPONENT C, FW_SYS_STAT_GROUP_OF_COMP G, FW_SYS_STAT_COMP_IN_GROUPS GC
                                WHERE C.ID = GC.FW_COMPONENT_ID AND G.ID = GC.GROUP_ID
                                                AND GC.VALID_UNTIL IS NULL AND C.VALID_UNTIL IS NULL
                                                AND C.ID = (SELECT C.ID FROM FW_SYS_STAT_COMPONENT C WHERE C.COMPONENT_NAME = p_component_name AND C.COMPONENT_VERSION = p_old_component_version AND C.VALID_UNTIL IS NULL)
                                );
END;
