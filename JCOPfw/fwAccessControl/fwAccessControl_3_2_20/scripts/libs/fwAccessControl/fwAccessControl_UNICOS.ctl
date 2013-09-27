// $License: NOLICENSE

/**
@file fwAccessControl_UNICOS.ctl
UNICOS compatibilty layer of the JCOP Framework Access Control library

Note that you need to add this file manualy to the list of libraries you use.

@author Piotr Golonka, CERN IT/CO-BE
@version 2.4.4
@date September 2005

*/


//////////// UNICOS-SPECIFIC FUNCTIONS

//__________________________________________________________________________
/**
 * @name UNICOS-compatibility functions

This is a set of functions provided for compatibilty with the UNICOS
framework, which used the API of framework 1.0.

 * @{
*/


/** Returns the names of privileges in UNICOS Access Control scheme.

@param priviledgeList: dyn_string, output, the priviledge names
@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

@deprecated This is a legacy function that assures compatibility with UNICOS API\n
One should use @ref fwAccessControl_getPrivilegeNames instead

@ingroup UNICOSFunctions
@see fwAccessControl_getPrivilegeNames
*/
fwAccessControl_getPriviledgeList( dyn_string &priviledgeList, dyn_string &exceptionInfo)
{
    dynClear(priviledgeList);
    dyn_int privilegeIds;

    fwAccessControl_getPrivilegeNames ("", priviledgeList, privilegeIds, exceptionInfo);
}

/** checks if a user has a privilege in a domain, according to UNICOS Access Control scheme.

@param priviledgeLevelRequired: string, input, the required priviledge
@param domain: string, input, the domain
@param granted: bool, output, allowed or not
@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

@deprecated This is a legacy function that assures compatibility with UNICOS API\n
One should use @ref fwAccessControl_checkUserPrivilege instead

@ingroup UNICOSFunctions
@see fwAccessControl_checkUserPrivilege
*/

fwAccessControl_getUserPermission( string priviledgeLevelRequired, string domain, bool &granted, dyn_string &exceptionInfo)
{
    granted=FALSE;
    string userName=""; // we will be asking about current user...
    fwAccessControl_checkUserPrivilege   ( userName, domain,  priviledgeLevelRequired, granted, exceptionInfo);
}


/** Returns the names of domains in UNICOS Access Control scheme.

@param domainList: dyn_string, output, the domain names
@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

@deprecated This is a legacy function that assures compatibility with UNICOS API\n
One should use @ref fwAccessControl_getAllDomains instead

@ingroup UNICOSFunctions
@see fwAccessControl_getAllDomains
*/
fwAccessControl_getDomainList(dyn_string &domainList, dyn_string &exceptionInfo)
{
    dynClear(domainList);
    dyn_string fullDomainNames;
    fwAccessControl_getAllDomains ( domainList, fullDomainNames, exceptionInfo);
}

/** Returns user information in UNICOS Access Control API.

@param userName: string, output, the user name
@param userId: int, output, the user id
@param dsGroupName: dyn_string, output, the user group name
@param diGroupId: dyn_int, output, the user group id
@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

@deprecated This is a legacy function that assures compatibility with UNICOS API\n
One should use @ref fwAccessControl_getUser instead

@ingroup UNICOSFunctions
@see fwAccessControl_getUser
*/
fwAccessControl_getUserCharacteristics(string &userName, int &userId, dyn_string &dsGroupName, dyn_int &diGroupId, dyn_string exceptionInfo)
{
    dynClear(dsGroupName);
    dynClear(diGroupId);

    string userFullName, description;
    bool enabled;
    dyn_string groupNames;
    dyn_int groupIds;

    userName=""; // we will be asking about current user...

    fwAccessControl_getUser (userName, userFullName, description, userId, enabled, groupNames, exceptionInfo);

    _fwAccessControl_convert (GROUP_NAME_TO_IDX, groupNames, groupIds, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    dsGroupName = groupNames;
    diGroupId   = groupIds;
}

/** Will return if the current user is granted privileges according to the <b>deprecated</b> framework scheme.

Modification History: None\n
Constraints: None\n
\n
Usage: JCOP framework internal, public\n
PVSS manager usage: VISION\n

@param privilegeLevelRequired           string that contains the name of the seeked privilege
@param domain                                           string that contains the domain, the privilege is seeked in
@param granted                                          boolean that will contain the result of the query
@param exceptionInfo                            dyn_string for JCOP Fw exception handling


@deprecated This is a legacy function that assures compatibility with obsolete Framework 1.0\n
One should use @ref fwAccessControl_checkUserPrivilege instead

@ingroup UNICOSFunctions
@see fwAccessControl_isGranted , PermissionFunctions
*/
void fwGetUserPermission(string privilegeLevelRequired, string domain, bool & granted, dyn_string & exceptionInfo)
{
  granted=FALSE;
  fwAccessControl_checkUserPrivilege(domain, privilegeLevelRequired, granted, exceptionInfo);
}


//@} // end of UNICOS-compatibility functions





