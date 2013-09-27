/**@file

This package contains internal functions of the Configuration Database tool

@author Piotr Golonka (EN/ICE-SCD)
@date   October 2012
*/

global string _fwConfigurationDB_fileVersion_fwConfigurationDB_Utils_ctl="3.5.7";

// for progress dialog...
global bool       fwConfigurationDB_closeProgressDialog=FALSE;
global dyn_int    fwConfigurationDB_operationIds;
global dyn_string fwConfigurationDB_operationNames;
global dyn_float  fwConfigurationDB_operationsProgress;
global string     fwConfigurationDB_currentOperation;
global bool       fwConfigurationDB_abortOperation=FALSE;
global bool       fwConfigurationDB_pauseOperation=FALSE;


// constants to deal with large float numbers, etc (compensate for lack of BINARY_DOUBLE)
// some of them need to be initialized by scripting, as there are no literals for them...
global float fwConfigurationDB_NaNPlus;
global float fwConfigurationDB_NaNMinus;
global float fwConfigurationDB_InfPlus;
global float fwConfigurationDB_InfMinus;
global const float fwConfigurationDB_OraNumberLimit= 9.999999999999999e124;
global const float fwConfigurationDB_InfPlus_ORA   = 8.0e125;
global const float fwConfigurationDB_InfMinus_ORA  =-8.0e125;
global const float fwConfigurationDB_NaNPlus_ORA   = 4.0e125;
global const float fwConfigurationDB_NaNMinus_ORA  =-4.0e125;
global const float fwConfigurationDB_MaxValue_ORA  = 1.0e125;
global const float fwConfigurationDB_MinValue_ORA  =-1.0e125;
global bool _fwConfigurationDB_numericConstantsInitialized=FALSE;


void _fwConfigurationDB_initNumericConstants()
{
    // we need to generate the +inf by numerical overfloat
    float m=maxFLOAT();
    fwConfigurationDB_InfPlus  = m+m;;
    fwConfigurationDB_InfMinus =-m-m;
    fwConfigurationDB_NaNMinus = fwConfigurationDB_InfMinus - fwConfigurationDB_InfMinus;
    fwConfigurationDB_NaNPlus  = - fwConfigurationDB_NaNMinus;

    _fwConfigurationDB_numericConstantsInitialized=TRUE;
}


bool _fwConfigurationDB_collapseFloats(dyn_float &df, dyn_string &exceptionInfo, string what="")
{
    bool modified=false;
    const float fMax=maxFLOAT();
    const float fMin=-maxFLOAT();
    for (int i=1;i<=dynlen(df);i++) {
	switch(df[i]) {
	    case fMax:                       df[i] = fwConfigurationDB_MaxValue_ORA; modified=true; break;
	    case fMin:                       df[i] = fwConfigurationDB_MinValue_ORA; modified=true; break;
	    case fwConfigurationDB_InfPlus:  df[i] = fwConfigurationDB_InfPlus_ORA;  modified=true; break;
	    case fwConfigurationDB_InfMinus: df[i] = fwConfigurationDB_InfMinus_ORA; modified=true; break;
	    case fwConfigurationDB_NaNPlus:  df[i] = fwConfigurationDB_NaNPlus_ORA;  modified=true; break;
	    case fwConfigurationDB_NaNMinus: df[i] = fwConfigurationDB_NaNMinus_ORA; modified=true; break;
	    default: 
		if (df[i]>fwConfigurationDB_OraNumberLimit || df[i]<-fwConfigurationDB_OraNumberLimit) {
		    fwException_raise(exceptionInfo,"ERROR",what+":Cannot store such number in DB,"+df[i],"");
		    DebugTN("ERROR Number out of range, idx="+i,df[i]);
		    return;
		}
	    break;
	}
    }
    return modified;
}

bool _fwConfigurationDB_expandFloats(dyn_float &df, dyn_string &exceptionInfo)
{
    bool modified=false;
    const float fMax=maxFLOAT();
    const float fMin=-maxFLOAT();
    for (int i=1;i<=dynlen(df);i++) {
	switch(df[i]) {
	    case fwConfigurationDB_MaxValue_ORA : df[i] = fMax; modified=true; break;
	    case fwConfigurationDB_MinValue_ORA : df[i] =-fMax; modified=true; break;
	    case fwConfigurationDB_InfPlus_ORA  : df[i] = fwConfigurationDB_InfPlus; modified=true; break;
	    case fwConfigurationDB_InfMinus_ORA : df[i] = fwConfigurationDB_InfMinus; modified=true; break;
	    case fwConfigurationDB_NaNPlus_ORA  : df[i] = fwConfigurationDB_NaNPlus; modified=true; break;
	    case fwConfigurationDB_NaNMinus_ORA : df[i] = fwConfigurationDB_NaNMinus; modified=true; break;
	    default: break;
	}
    }
    return modified;
}



void _fwConfigurationDB_startFunction(string fncName,time &t0)
{
    t0=getCurrentTime();
    if (g_fwConfigurationDB_Debug & 1)
    DebugTN("-- fwConfigurationDB_"+fncName+" --");

}

void _fwConfigurationDB_endFunction(string fncName,time t0)
{
    if (g_fwConfigurationDB_Debug & 2) {
        time t1=getCurrentTime();
        time dt=t1-t0;
        DebugTN("## fwConfigurationDB_"+fncName+" ## finished in "+minute(dt)+":"+second(dt)+"."+milliSecond(dt));
    }
}




/** Handles standard errors, taking care of closing the progress bars, etc
 * Used in panels
 * typical use would be:
 * @code
 * someFunction(parameter, exceptionInfo);
 * if (fwConfigurationDB_handleErrors(exceptionInfo)) return;
 * @endcode
 *
 * @sa see also @ref fwConfigurationDB_checkErrors
 */
bool fwConfigurationDB_handleErrors(dyn_string &exceptionInfo)
{
    if (fwConfigurationDB_checkErrors(exceptionInfo)) {
	if (isFunctionDefined("fwExceptionHandling_display")) {
    	    fwExceptionHandling_display(exceptionInfo);
    	} else {
    	    DebugTN("fwConfigurationDB Exception",exceptionInfo[1],exceptionInfo[2],exceptionInfo[3]);
    	}
        return TRUE;
    }
    return FALSE;
}

/** check errors, taking care of closing the progress bars, etc
 * Used in scripts
 * typical use would be:
 * @code
 * someFunction(parameter, exceptionInfo);
 * if (fwConfigurationDB_checkErrors(exceptionInfo,true)) return;
 * @endcode
 *
 * @sa see also @ref fwConfigurationDB_handleErrors
 */
bool fwConfigurationDB_checkErrors(dyn_string &exceptionInfo, bool dbRollbackOnError=true)
{
    if (dynlen(exceptionInfo)) {
        fwConfigurationDB_closeProgressDialog();
	fwConfigurationDB_abortOperation=FALSE;
	fwConfigurationDB_pauseOperation=FALSE;
	if (dbRollbackOnError && fwConfigurationDB_hasDBConnectivity) fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);
        return TRUE;
    }
    return FALSE;
}



/** reports progress of operation, with handling of "Abort" requests and errors
 * it returns TRUE and the "ABORT" exception in the
 * exceptionInfo when the operation needs to be aborted.
 * Used in the library functions
 * typical use would be:
 * @code
 * if (fwConfigurationDB_progress(OPER_LoadFile,"Loading file", 35.0, exceptionInfo)) return;
 * @endcode
 */
bool fwConfigurationDB_progress(int operationId, string currentOperation,
                                float progress, dyn_string &exceptionInfo,
                                bool dbRollbackOnError=true)
{
    if (fwConfigurationDB_checkErrors(exceptionInfo, dbRollbackOnError)) return true;

    if (fwConfigurationDB_pauseOperation) {
        DebugN("Operation paused");
        while (fwConfigurationDB_pauseOperation) {
            delay(0,500);
        }
        DebugN("Operation resumed");
    }

    if (fwConfigurationDB_abortOperation) {
        fwConfigurationDB_abortOperation=FALSE;
        fwConfigurationDB_pauseOperation=FALSE;
        fwConfigurationDB_closeProgressDialog();
        if (dbRollbackOnError) fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);
        fwException_raise(exceptionInfo,"INFO","Operation aborted","");
        return TRUE;
    }


    int idx=dynContains(fwConfigurationDB_operationIds,operationId);
    if (progress>100.0) progress=100.0;
    progress=((int)(100*progress))/100;
    if (idx>0) {
        fwConfigurationDB_operationsProgress[idx]=progress;
        fwConfigurationDB_currentOperation=currentOperation;
    }
    return FALSE; // we did not abort
}


void _fwConfigurationDB_progressDialogThread()
{
    dyn_float df;
    dyn_string ds;
    fwConfigurationDB_closeProgressDialog=FALSE;
    fwConfigurationDB_pauseOperation=FALSE;
    fwConfigurationDB_abortOperation=FALSE;
    // # bug in PVSS 3.8/Windoze (CT575251): problems with modal progress dialogs
//    ChildPanelOnCentralModalReturn("fwConfigurationDB/fwConfigurationDB_ProgressDialog.pnl","CDB Progress",makeDynString(),df,ds);
    ChildPanelOnCentralReturn("fwConfigurationDB/fwConfigurationDB_ProgressDialog.pnl","CDB Progress",makeDynString(),df,ds);
    fwConfigurationDB_closeProgressDialog=FALSE;
    fwConfigurationDB_pauseOperation=FALSE;
    fwConfigurationDB_abortOperation=FALSE;
}

/** opens a custom progress bar
 * Used in panels
 *
 */
void fwConfigurationDB_openProgressDialog(dyn_int operationIds,dyn_string operationNames)
{

    fwConfigurationDB_pauseOperation=FALSE;
    fwConfigurationDB_abortOperation=FALSE;
    fwConfigurationDB_operationIds=operationIds;
    fwConfigurationDB_operationNames=operationNames;
    fwConfigurationDB_currentOperation="";
    dynClear(fwConfigurationDB_operationsProgress);
    for (int i=1;i<=dynlen(operationIds);i++) fwConfigurationDB_operationsProgress[i]=0.0;

    startThread("_fwConfigurationDB_progressDialogThread");
    delay(0,5);
}


void fwConfigurationDB_closeProgressDialog()
{
    fwConfigurationDB_closeProgressDialog=TRUE;

}


void fwConfigurationDB_updateDBStatusIndicator()
{
    shape dbstatus=getShape("DB_STATUS");
    shape dbstatustext=getShape("DB_STATUS_TEXT");
    shape dbstatusprivs=getShape("DB_STATUS_PRIVS");

    string fill="[pattern,[tile,gif,dbicon_na.gif]]";
    string toolTipText="Configuration Database not available";
    string statusText="N/A";
    string privs="";


    if (fwConfigurationDB_DBConfigured) {

    if (fwConfigurationDB_hasDBConnectivity) {
        fill="[pattern,[tile,gif,dbicon_ok.gif]]";
        toolTipText="Configuration Database OK";
        statusText="OK";
        if (     fwConfigurationDB_SchemaPrivs =="OWNER" ) privs="";
        else if (fwConfigurationDB_SchemaPrivs =="READER") privs="R";
        else if (fwConfigurationDB_SchemaPrivs =="WRITER") privs="W";
        else {
    	    privs="?";
    	    DebugTN("Unknown fwConfigurationDB_SchemaPrivs",fwConfigurationDB_SchemaPrivs);
    	}
    } else {
        if (g_fwConfigurationDB_DBConnectionOpen) {
            fill="[pattern,[tile,gif,dbicon.gif]]";
    	    toolTipText="Configuration Database: WARNING";
            statusText="WARNING";
        } else {
            fill="[pattern,[tile,gif,dbicon_bad.gif]]";
            toolTipText="Configuration Database ERROR";
            statusText="ERROR";
        }

    }

    }
    dbstatus.fill=fill;
    dbstatus.toolTipText=toolTipText;
    dbstatustext.text=statusText;
    dbstatusprivs.text=privs;
}



/// @if PrivateFunctions
//__________________________________________________________________________
/**
 * @name Private Functions in general module
 * @{
 */



/** Retrieves dp elements for a dp type

This function retrieves the list of data point elements
for a given data poin type. If the dpt is a framework
data point type, the appropriate device definition is
queried to determine the names related to data point elements.

On return, for the Framework Device  data point types,
the first list (properties variable) will contain the list of
property names present in the device definition.
The  second list (dpes variable) will contain the data point
element names associated with the property names from the
first list, plus all the data point elements that have no
device definition.
This way, the function may be used to get the list of all dpes
(the second list), the list of dpes from the device definitions
(take only the first N items from the second list, where N is
the number of elements of the first list), etc.
The function will also return the device name from the device definition
(in the devName argument).

For non-Frame Device data point types, the first list will always
be empty, and the second list will contain the list of all
dpes.

Note, that this function will work even if there is no instance
of a device type available yet! (In such a case, extracting
all data point element could have been done simply by
a combination of dpNames() and dpSubStr() for an arbitrary,
existing data point...

See also @ref _fwConfigurationDB_getDPTElements .


@param dptName          the name of data point type
@param properties       on return will contain the list of property names
@param dpes             on return will contain the list of all data point elements
@param devTypeName          on return will contain the device type name from the device definition, or dptName
@param exceptionInfo 	standard exception handling variable
@param deviceModel 	    (optional) device model


@ingroup PrivateFunctions
*/
void _fwConfigurationDB_getPropertiesAndDPEs(string dptName, dyn_string &properties, dyn_string &dpes,
                                             string &devTypeName, dyn_string &exceptionInfo, string deviceModel = "")
{
    devTypeName=dptName;
    // at first, get all dpes:
    dyn_string all_dpes =_fwConfigurationDB_getDPTElements(dptName, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    // locate the device definition point
    string definitionDp;
    fwDevice_getDefinitionDp(makeDynString("", dptName, "", deviceModel), definitionDp, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    if (dpExists(definitionDp)) {
        // get the device definition contents ...
        dpGet(  definitionDp + fwDevice_ELEMENTS, dpes,
                definitionDp + fwDevice_PROPERTY_NAMES, properties,
                definitionDp + ".type", devTypeName);
    };

    // we will append the dpes that were not in the device definitions
    for (int i=1;i<=dynlen(all_dpes);i++) {
        if (!dynContains(dpes,all_dpes[i])) dynAppend(dpes, all_dpes[i]);
    }

}





/** Retrieves the names of DP elements for given data point type

This function retrieves all data point elements for specified data point type.
resolving (recursively) all references to other data points and structures.

@param dptName 		the name of the data point type
@param exceptionInfo 	standard exception handling variable
@param all (optional) if TRUE, all properties, including the "." entries of structures will
			be resolved; If FALSE, only the leaves of the structures will be
			    returned
@returns 		the list of all data point elements for dptName
@ingroup PrivateFunctions

@sa	@ref _fwConfigurationDB_getDPTElements2
*/
dyn_string _fwConfigurationDB_getDPTElements(string dptName, dyn_string &exceptionInfo, bool all=FALSE)
{
    dyn_string elementNames;
    dyn_int elementTypes;
    _fwConfigurationDB_getDPTElements2(dptName, elementNames, elementTypes, exceptionInfo, all);
    return elementNames;
}


/** Retrieves the names and types of DP elements for given data point type

This function retrieves all data point elements for specified data point type.
resolving (recursively) all references to other data points and structures.

@param dptName 		the name of the data point type
@param elementNames	on return will contain the names of dp elements
@param elementTypes	on return will contain the types of dp elements
@param exceptionInfo 	standard exception handling variable
@param all (optional) if TRUE, all properties, including the "." entries of structures will
			be resolved; If FALSE, only the leaves of the structures will be
			    returned
@ingroup PrivateFunctions

@sa	@ref fwConfigurationDB_getDPTElements

**/
void _fwConfigurationDB_getDPTElements2(string dptName, dyn_string &elementNames, dyn_int &elementTypes,
		dyn_string &exceptionInfo, bool all=FALSE)
{

    dyn_int excludedTypes;
    if (!all) dynAppend(excludedTypes, DPEL_STRUCT);

    // once the next version of fwCore is released we will uncomment the next line, and remove
    // our "private" copt of the __fwGeneral_getDpElements function (which is at the end of this file)
    //fwGeneral_getDpElements("", dptName, elementNames, elementTypes, exceptionInfo, excludedTypes, TRUE);

    fwGeneral_getDpElements("", dptName, elementNames, elementTypes, exceptionInfo, excludedTypes, TRUE);

}


int _fwConfigurationDB_typeIdToDpeTypeId(int varType)
{
    switch(varType) {
    case ANYTYPE_VAR:
    case MIXED_VAR:
    case ERRCLASS_VAR:
    case MAPPING_VAR:
    case FILE_VAR:
    case ATIME_VAR:
    //case FTIME_VAR:
    case DYN_BLOB_VAR:
    case DYN_MAPPING_VAR:
    case DYN_MIXED_VAR:
    case DYN_ERRCLASS_VAR:
    case DYN_ANYTYPE_VAR:
	DebugN("ERROR: Unsupported conversion of data from type "+varType);
	return 0;
	break;
    case STRING_VAR:		return DPEL_STRING;
    case LANGSTRING_VAR:	return DPEL_LANGSTRING;
    case FLOAT_VAR:		return DPEL_FLOAT;
    case INT_VAR:		return DPEL_INT;
    case BIT32_VAR:		return DPEL_BIT32;
    case BLOB_VAR:		return DPEL_BLOB;
    case UINT_VAR:		return DPEL_UINT;
    case CHAR_VAR:		return DPEL_CHAR;
    case DYN_STRING_VAR:	return DPEL_DYN_STRING;
    case DYN_BIT32_VAR: 	return DPEL_DYN_BIT32;
    case DYN_LANGSTRING_VAR: 	return DPEL_DYN_LANGSTRING;
    case DYN_DPIDENTIFIER_VAR: 	return DPEL_DYN_DPID;
    case DYN_FLOAT_VAR: 	return DPEL_DYN_FLOAT;
    case DYN_INT_VAR: 		return DPEL_DYN_INT;
    case DYN_UINT_VAR: 		return DPEL_DYN_UINT;
    case DYN_CHAR_VAR: 		return DPEL_DYN_CHAR;
    case DYN_BOOL_VAR: 		return DPEL_DYN_BOOL;
    case DYN_TIME_VAR: 		return DPEL_DYN_TIME;
    case BOOL_VAR: 		return DPEL_BOOL;
    case TIME_VAR: 		return DPEL_TIME;
    case DPIDENTIFIER_VAR: 	return DPEL_DPID;
    default:
	DebugN("WARNING: _fwConfigurationDB_typeIdToDpeTypeId: DON'T KNOW HOW TO CONVERT FROM VARTYPE "+varType);
	return 0;
    }
    return 0;
}

void _fwConfigurationDB_dataToString(anytype data, int dataType, string listSeparator,
                                     string &encodedData, dyn_string &exceptionInfo)
{
    time t=0;
    encodedData="";
    switch(dataType) {

    case DPEL_STRING:
    case DPEL_LANGSTRING:
    case DPEL_FLOAT:
    case DPEL_INT:
    case DPEL_BIT32:
    case DPEL_BLOB:
    case DPEL_UINT:
        encodedData=data;
        break;
    case DPEL_CHAR:
        {
	    char c = data;
	    if((c < ' ') || (c == listSeparator) || (c == '\\') || (c > '~')) {
        	// special character: encode it in hex into something like "\xAB"
        	sprintf(encodedData,"\\x%02X",c);
    	    } else {
    		encodedData=c;
    	    }
        }
        break;
    case DPEL_DYN_STRING:
    case DPEL_DYN_LANGSTRING:
    case DPEL_DYN_DPID:
        for (int i=1;i<=dynlen(data);i++) {
	    // sanity check: the texts in the list must not have separator character!
	    string dat=data[i];
	    strreplace(dat,listSeparator,"\\x7c");
            encodedData=encodedData+dat;
            if (i!=dynlen(data)) encodedData=encodedData+listSeparator;
        }
        break;
	break;
    case DPEL_DYN_FLOAT:
    case DPEL_DYN_INT:
    case DPEL_DYN_UINT:
        for (int i=1;i<=dynlen(data);i++) {
            encodedData=encodedData+data[i];
            if (i!=dynlen(data)) encodedData=encodedData+listSeparator;
        }
        break;
    case DPEL_DYN_CHAR:
        {
          string tmp;
          int len = dynlen(data);
          for (int i=1;i<=len;i++) {
            if((data[i] < ' ') || (data[i] == listSeparator) || (data[i] == '\\') || (data[i] > '~')) {
              // special character: encode it in hex into something like "\xAB"
              if(i != len)
                sprintf(tmp,"\\x%02X%s",data[i],listSeparator);
              else
                sprintf(tmp,"\\x%02X",data[i]);
              encodedData += tmp;
            }
            else {
              encodedData += data[i];
              if(i != len)
                encodedData += listSeparator;
            }
          }
          break;
        }
    case DPEL_DYN_BOOL:
        for (int i=1;i<=dynlen(data);i++) {
	    if (data[i]) {
		encodedData=encodedData+"TRUE";
	    }else{
		encodedData=encodedData+"FALSE";
	    }
            if (i!=dynlen(data)) encodedData=encodedData+listSeparator;
        }
        break;
    case DPEL_DYN_TIME:
        for (int i=1;i<=dynlen(data);i++) {
    	    time t0=0;
	    if (data[i]>t0) {
		string stime=data[i];
		encodedData=encodedData+formatTime("%Y-%m-%d %H:%M:%S",data[i]);
	    }
            if (i!=dynlen(data)) encodedData=encodedData+listSeparator;
        }
        break;

    case DPEL_BOOL:
        if (data) encodedData="TRUE"; else encodedData="FALSE";
        break;
    case DPEL_TIME:
	if (data==t)
	    encodedData="";
	else
	    encodedData=formatTime("%Y-%m-%d %H:%M:%S",data);
	break;
    case DPEL_DPID:
	    if (data=="") {
		encodedData="";
		return;
	    }
	    // strip the system name...
	    encodedData=_fwConfigurationDB_NodeNameWithoutSystem(data);
	break;
    default:
    DebugN("WARNING: _fwConfigurationDB_dataToString: FALL BACK TO PVSS TYPE CASTING FOR TYPE "+dataType);
        encodedData=data;
        break;
    }

}

void _fwConfigurationDB_stringToData(string encodedData, int dataType, string listSeparator,
                                     anytype &data, dyn_string &exceptionInfo)
{
    dyn_string sdata;
    dyn_bool bdata;
    dyn_int idata;
    dyn_uint udata;
    dyn_float fdata;
    dyn_time tdata;
    dyn_char cdata;
    time t=0;
    int ic;
    char c;
    unsigned yr,mo,d,h,m,s;
    dyn_string tmp1,tmp2,tmp3;

    switch(dataType) {
    case DPEL_STRING:
    case DPEL_LANGSTRING:
        data=(string)encodedData;
        break;
    case DPEL_FLOAT:
        data=(float)encodedData;
        break;
    case DPEL_INT:
        data=(int)encodedData;
        break;
    case DPEL_BIT32:
        data=(bit32)encodedData;
        break;
    case DPEL_BLOB:
        data=(blob)encodedData;
        break;
    case DPEL_CHAR:
	c=encodedData;
        if(c =='\\') {
	    // we have it in form "\x34"
	    char bslash,xchar;
	    sscanf(encodedData,"%c%c%X",bslash,xchar,ic);
	    c = (char)ic;
	}
	data=c;
        break;


    case DPEL_UINT:
	// PVSS casting to uint is buggy!
	// we need to have special treatment for
	// values with the highest bit set!
	if (strlen(encodedData)<10) {
	    data=(unsigned)encodedData;
	    break;
	} else {
	    string s0=substr(encodedData,0,1);
	    string s1=substr(encodedData,1);
    	    data=(unsigned)s0*1000000000U+(unsigned)s1;
        }
        break;
    case DPEL_DYN_STRING:
    case DPEL_DYN_LANGSTRING:
    case DPEL_DYN_DPID:
        sdata=strsplit(encodedData,listSeparator);
	// append an empty element at the end if the last character was "|"
        if (substr(encodedData,strlen(encodedData)-1)=="|") dynAppend(sdata,"");
        // restore "|" characters...
        for (int i=1;i<=dynlen(sdata);i++) {
    	    strreplace(sdata[i],"\\x7c",listSeparator);
    	}
        data=sdata;
        break;
    case DPEL_DYN_BIT32:
        sdata=strsplit(encodedData,listSeparator);
	// append an empty element at the end if the last character was "|"
        if (substr(encodedData,strlen(encodedData)-1)=="|") dynAppend(sdata,"");
        // restore "|" characters...
        for (int i=1;i<=dynlen(sdata);i++) {
    	    strreplace(sdata[i],"\\x7c",listSeparator);
    	}
        data=(dyn_bit32)sdata;
        break;
    case DPEL_DYN_FLOAT:
        fdata=strsplit(encodedData,listSeparator);
        data=fdata;
        break;
    case DPEL_DYN_TIME:
        sdata=strsplit(encodedData,listSeparator);
        if (substr(encodedData,strlen(encodedData)-1)=="|") dynAppend(sdata,"");
	for (int i=1;i<=dynlen(sdata);i++) {
	    time t;
	    _fwConfigurationDB_stringToData(sdata[i], DPEL_TIME, listSeparator,t,exceptionInfo);
	    if (dynlen(exceptionInfo)) return;
	    dynAppend(tdata,t);
	}
        data=tdata;
        break;
    case DPEL_DYN_INT:
        idata=strsplit(encodedData,listSeparator);
        data=idata;
        break;
    case DPEL_DYN_UINT:
        sdata=strsplit(encodedData,listSeparator);
        for (int i=1;i<=dynlen(sdata);i++) {
    	    unsigned u;
	    _fwConfigurationDB_stringToData(sdata[i], DPEL_UINT, listSeparator,u,exceptionInfo);
	    if (dynlen(exceptionInfo)) return;
	    dynAppend(udata,u);
    	}
        data=udata;
        break;
    case DPEL_DYN_BOOL:
	strreplace(encodedData," | ", listSeparator);
        bdata=strsplit(encodedData,listSeparator);
        data=bdata;
        break;
    case DPEL_DYN_CHAR:
	sdata=strsplit(encodedData,listSeparator);
	for (int i=1;i<=dynlen(sdata);i++) {
	    c=sdata[i];
            if(c =='\\') {
		// we have it in form "\x34"
		char bslash,xchar;
		sscanf(sdata[i],"%c%c%X",bslash,xchar,ic);
		c = (char)ic;
	    }
            cdata[i] = c;
	}
	data=cdata;
        break;
    case DPEL_BOOL:
        if (encodedData=="TRUE") data=(bool)TRUE; else data=(bool)FALSE;
        break;
    case DPEL_TIME:
	data=t; // by default, return "zero" date...
	if (encodedData=="") return;
	tmp1=strsplit(encodedData," ");
	if (dynlen(tmp1)!=2) {fwException_raise(exceptionInfo,"ERROR","Wrong format of date\n"+encodedData+"\n"+"Expected YYYY-MM-DD hh-mm-ss",""); return;}
	tmp2=strsplit(tmp1[1],"-");
	if (dynlen(tmp2)!=3) {fwException_raise(exceptionInfo,"ERROR","Wrong format of date\n"+encodedData+"\n"+"Expected YYYY-MM-DD hh-mm-ss",""); return;}
	yr=tmp2[1];
	mo=tmp2[2];
	d=tmp2[3];
	tmp3=strsplit(tmp1[2],":");
	if (dynlen(tmp3)!=3) {fwException_raise(exceptionInfo,"ERROR","Wrong format of date\n"+encodedData+"\n"+"Expected YYYY-MM-DD hh-mm-ss",""); return;}
	h=tmp3[1];
	m=tmp3[2];
	s=tmp3[3];
	t=setTime(t,yr,mo,d,h,m,s);
	if ( ((int)t)==-1) {fwException_raise(exceptionInfo,"ERROR","Cannot decode date:\n"+encodedData,""); return;}
	data=t;
	break;
    case DPEL_DPID:
	if (encodedData=="") {
	    data=encodedData;
	    return;
	}
	data=_fwConfigurationDB_NodeNameWithSystem(encodedData, getSystemName(), exceptionInfo);
	if (dynlen(exceptionInfo)) return;

	break;
    default:
    DebugN("WARNING: _fwConfigurationDB_stringToData: FALL BACK TO PVSS TYPE CASTING FOR TYPE "+dataType);
        data=encodedData;
        break;
    }

}


void fwConfigurationDB_deviceTypesToDpTypes(dyn_string devTypes, dyn_string &dpTypes, dyn_string &exceptionInfo,
	bool errorOnNonExistingType=true)
{
    dynClear(dpTypes);

    // we will need these for type conversions:
    dyn_dyn_string fwAllDevTypes;
    dyn_string allDpTypes=dpTypes();
    fwDevice_getAllTypes(fwAllDevTypes, exceptionInfo);
    if (dynlen(exceptionInfo)) return;


    for (int i=1;i<=dynlen(devTypes);i++) {
        if (devTypes[i]=="SYSTEM") {
            dpTypes[i]="";
            continue;
        };
        int idx=dynContains(fwAllDevTypes[1],devTypes[i]);
        if (idx>=1) {
            dpTypes[i]=fwAllDevTypes[2][idx];
        } else {
            int idx0=dynContains(allDpTypes,devTypes[i]);
            if (idx0>=1) {
                dpTypes[i]=allDpTypes[idx0];
            } else {
        	if (errorOnNonExistingType) {
            	    fwException_raise(exceptionInfo,"ERROR","Unknown device/dpType "+devTypes[i],"");
            	} else {
            	    dpTypes[i]="";
            	}
            }
        }
    };
}


string _fwConfigurationDB_getFwDeviceName(string dptName, dyn_string &exceptionInfo)
{
    dyn_dyn_string fwDevices;
    string devName;
    fwDevice_getAllTypes(fwDevices,exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    // fwDevices[1][i] - device type
    // fwDevices[2][i] - datapoint type

    // find out the Fw device name
    devName=dptName;
    for (int i=1;i<=dynlen(fwDevices[2]);i++) {
        if (fwDevices[2][i]==dptName) {
            devName=fwDevices[1][i];
            break;
        }
    };
    return devName;
}



//@} // end of Recipe functions
//______________________________________________________________________________


/** Gets the alert settings

This function gets current alert settings for a dp from the system and
stores it in the data structure which is a single row of @ref recipeObject.
The data point name and data point element are passed in thr recipeRow variable as well.

@param recipeRow        the input/output variable, a single row of the recipeObject
                        refering to a single DPE.
@li on entry, recipeRow[@ref fwConfigurationDB_RO_DP_NAME] should contain the datapoint name, and
              recipeRow[@ref fwConfigurationDB_RO_ELEMENT_NAME] the data point element
@li on exit, the entries that refer to alerts will be filled with data
    (indices @ref fwConfigurationDB_RO_HAS_ALERT, and
@ref fwConfigurationDB_RO_ALERT_MINIDX to @ref fwConfigurationDB_RO_ALERT_MINIDX),
    the other will not be touched
@param exceptionInfo 	standard exception handling variable

*/
void _fwConfigurationDB_getAlertData(dyn_dyn_mixed &recipeObject, int row, dyn_string &exceptionInfo)
{

    for (int i=fwConfigurationDB_RO_ALERT_MINIDX;i<=fwConfigurationDB_RO_ALERT_MAXIDX;i++) {
	recipeObject[i][row]="";
    }

    string dpe=recipeObject[fwConfigurationDB_RO_DPE_NAME][row];

    dyn_string summaryDpeList;
    string alertPanel;
    dyn_string alertPanelParameters;
    string alertHelp;


    bool configExists,isActive;
    int alertConfigType;
    dyn_string alertTexts,alertClasses;
    dyn_float alertLimits;


    if (recipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][row]==DPEL_DPID) {
	recipeObject[fwConfigurationDB_RO_HAS_ALERT][row]=FALSE;
	return;
    }

    fwAlertConfig_get(  dpe,
			configExists,
			alertConfigType,
			alertTexts,
			alertLimits,
			alertClasses,
                      summaryDpeList,
                      alertPanel,
                      alertPanelParameters,
                      alertHelp,
		        isActive,
                      exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    for (int i=1;i<=dynlen(alertClasses);i++) {
	if (alertClasses[i]!="") {
	    alertClasses[i]=_fwConfigurationDB_NodeNameWithoutSystem(alertClasses[i]);
	}
    }

    recipeObject[fwConfigurationDB_RO_HAS_ALERT][row]=configExists;
    recipeObject[fwConfigurationDB_RO_ALERT_TYPE][row]=alertConfigType;
    recipeObject[fwConfigurationDB_RO_ALERT_TEXTS][row]=alertTexts;
    recipeObject[fwConfigurationDB_RO_ALERT_LIMITS][row]=alertLimits;
    recipeObject[fwConfigurationDB_RO_ALERT_CLASSES][row]=alertClasses;
    recipeObject[fwConfigurationDB_RO_ALERT_ACTIVE][row]=isActive;

}



/** Returns system name of the node. If not specified in nodeName, returns local system

*/
string _fwConfigurationDB_NodeSystemName(string nodeName)
{
    string result = getSystemName();
    dyn_string tmp = strsplit(nodeName,":");
    // protection: if system name is passed as nodeName, e.g. "dist_1:"
    // the splitted string will contain only one item, instead of two ("dist_1" and "")
    if (dynlen(tmp)==1) {
	if (substr(nodeName,strlen(nodeName)-1) == ":") tmp[2]="";
    }

    if (dynlen(tmp)>1) result=tmp[1]+":";
    return result;
}

/** Returns the device (node) name, ensuring it does not contain system name
*/
string _fwConfigurationDB_NodeNameWithoutSystem(string nodeName)
{
    string result = nodeName;
    dyn_string tmp = strsplit(nodeName,":");
    // protection: if system name is passed as nodeName, e.g. "dist_1:"
    // the splitted string will contain only one item, instead of two ("dist_1" and "")
    if (dynlen(tmp)==1) {
	if (substr(nodeName,strlen(nodeName)-1) == ":") tmp[2]="";
    }

    if (dynlen(tmp)>1) {
	result=tmp[2];
	for (int i=3;i<=dynlen(tmp);i++) result+=":"+tmp[i];
    }
    return result;
}

/** Returns the device (node) name, ensuring it has system name in it.

passing "" as systemName means: use local system.
*/
string _fwConfigurationDB_NodeNameWithSystem(string nodeName, string systemName, dyn_string &exceptionInfo)
{

    if (systemName=="") systemName=getSystemName();

    // make sure system name contains ":"
    if (substr(systemName,strlen(systemName)-1) != ":") {
	fwException_raise(exceptionInfo, "ERROR in _fwConfigurationDB_NodeNameWithSystem",
	 "Specified system name does not contain colon at the end\n"+systemName,"");
	 return "";
    }

    string result = nodeName;
    dyn_string tmp = strsplit(nodeName,":");
    // protection: if system name is passed as nodeName, e.g. "dist_1:"
    // the splitted string will contain only one item, instead of two ("dist_1" and "")
    if (dynlen(tmp)==1) {
	if (substr(nodeName,strlen(nodeName)-1) == ":") tmp[2]="";
    }

    if (dynlen(tmp)>1) { // OK, we already have sysname there. check if it is the same
        string tmpSysName=tmp[1]+":";
        if (tmpSysName!=systemName) {
            fwException_raise(exceptionInfo,"ERROR in _fwConfigurationDB_NodeNameWithSystem",
        	"Device "+nodeName+" has system name other than "+systemName,"");
            return "";
        }
    } else { // it has no system name: we prepend it
        result=systemName+nodeName;
    }

    return result;
}


string _fwConfigurationDB_itemIdListForSQLQuery(dyn_int itemIdList)
{
    return _fwConfigurationDB_listToSQLString("ITEM_ID", itemIdList);
}

string _fwConfigurationDB_listToSQLString(string columnName, dyn_string itemIdList)
{
    if (dynlen(itemIdList)==0) return "";

    string sItemIdList=" ( "+columnName+" IN (";
    for (int i=1;i<=dynlen(itemIdList);i++){
        sItemIdList=sItemIdList+"\'"+itemIdList[i]+"\'";
        if (i!=dynlen(itemIdList)) {
            if (i%999==0) {
                sItemIdList=sItemIdList+") OR "+columnName+" IN (";
            } else {
                sItemIdList=sItemIdList+",";
            }
        }
    };
    sItemIdList=sItemIdList+") )";

    return sItemIdList;

}

/* Perform dpSet for many datapoints

Datapoints for many systems may be specified in the dpes parameter, 
but if systemName is specified, then only the dpes matching this 
system name will be set.

Parameters: dpes and values are passed by reference to avoid re-allocation; they are not modified

*/
void fwConfigurationDB_dpSetMany(dyn_string &dpes, dyn_mixed &values, dyn_string &exceptionInfo, string systemName="")
{
    systemName=strrtrim(systemName,":");

    int rc;
    dyn_string dpeGroup;
    dyn_mixed  valGroup;
    int j=0;
    int total=0;
    for (int i=1;i<=dynlen(dpes);i++) {
	if (systemName!="") {
	    // skip the entries that are not from the specified system
	    if (strpos(dpes[i],systemName+":")==-1) continue;
	}
        j++;
        dpeGroup[j]=dpes[i];
        valGroup[j]=values[i];
        if (j >= fwConfigs_OPTIMUM_DP_SET_SIZE)
        {
            rc=dpSet(dpeGroup,valGroup);
            if (rc!=0) {
                dyn_errClass err=getLastError();
                fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_dpSetMany: cannot set values","");
                DebugN("ERROR in fwConfigurationDB_dpSetMany",err);
            }
            dynClear(dpeGroup);
            dynClear(valGroup);
            total+=j;
            j=0;
        }
    }

     //apply remaining part...
    if (j>0) {

        rc=dpSetWait(dpeGroup,valGroup);
        if (rc!=0) {
            dyn_errClass err=getLastError();
            fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_dpSetMany: cannot set values","");
            DebugN("ERROR in fwConfigurationDB_dpSetMany",err);
        }
        total+=j;
    }
    
    if (g_fwConfigurationDB_Debug & 1) DebugTN("Values set OK for system "+systemName+"; dpes:"+total+"/"+dynlen(dpes));
}

/** performs a dpSet for a list of datapoint elements
 *
 * the list may contain dpes for many systems - they are sorted/grouped appropriately

The parameters: dpes and values are passed by reference to avoid re-allocation; they are not modified

 */
void fwConfigurationDB_dpSetManyDist(dyn_string &dpes, dyn_mixed &values, dyn_string &exceptionInfo, bool checkDpeExist=false)
{
    if (dynlen(dpes)!=dynlen(values)) {
        fwException_raise(exceptionInfo,
    	    "ERROR",
    	    "fwConfigurationDB_dpSetManyDist: number of dpes ("+
    		dynlen(dpes)+") and values ("+dynlen(values)+") do not match",
    	    "");
        return;
    }

    // Note about performance and implementation:
    // it is very ineffective to re-process the dpes and values list, eg
    // to form secondary lists per-system. One needs to re-allocate the lists'
    // contents and this scale very badly!
    // It is hence much better to keep the original list, and only hint the
    // function that does actual dpSet, which system to treat, and call it
    // per system.
    // All we need to do is to extract the list of systems...

    // extract system names
    dyn_string systems;
    for (int i=1;i<=dynlen(dpes);i++){
        if (checkDpeExist) {
            if (dpElementType(dpes[i])<0) {
                fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_dpSetManyDist: no such DPE "+dpes[i],"");
            }
        }
        string sys=dpSubStr(dpes[i],DPSUB_SYS);
        if (sys=="") sys=getSystemName();
        if (!dynContains(systems,sys)) dynAppend(systems,sys);
    }
    for (int i=1;i<=dynlen(systems);i++) {
        //DebugN("Setting values for system "+systems[i]);
	fwConfigurationDB_dpSetMany(dpes, values, exceptionInfo,systems[i]);
	if (dynlen(exceptionInfo)) return;
    }
}

//@} // end of Private Functions
/// @endif

//______________________________________________________________________________


void fwConfigurationDB_printDynDynMixed(dyn_dyn_mixed data, 
    dyn_string header="", int maxrows=0, string description="Table")
{
    int maxStringLen=100;
    int ncol=0;
    if (dynlen(data)) ncol=dynlen(data[1]);

    if (dynlen(header)==1 && header[1]=="") dynClear(header);
    
    bool trunc=FALSE; // flag signifying that more data was there...
    
    dyn_int colLengths;
    if (dynlen(header)) {
	for (int i=1;i<=dynlen(header);i++) colLengths[i]=strlen(header[i]);
    }
    
    dyn_dyn_string values;
    for (int i=1;i<=dynlen(data);i++) {
	dyn_mixed row=data[i];
	for (int j=1;j<=dynlen(row);j++) {
	    string val=(string) row[j];
	    int len=strlen(val);
	    if (len>maxStringLen) {
		val=substr(val,0,maxStringLen-1)+"#";
		len=maxStringLen;
	    }
	    values[i][j]=val;
	    int curlen=0;
	    if (dynlen(colLengths)>=j) 
		curlen=colLengths[j];
	    else
		colLengths[j]=len;
	    if (len>curlen) colLengths[j]=len;
	}
	// have something if we have empty rows!
	if (dynlen(row)<1) {
	    dyn_string dummy;
	    values[i]=dummy;
	}
	
	if (maxrows>0 && i>=maxrows ) {trunc=TRUE;break;};
    }

    int numCols=dynlen(colLengths);
    // now pad the missing columns...
    for (int i=1;i<=dynlen(values);i++) {
	dyn_string row=values[i];
	for (int j=dynlen(row)+1;j<=numCols;j++) values[i][j]="";
    }

    // generate missing headers...
    for (int i=dynlen(header)+1;i<=numCols;i++) {
	header[i]=" ["+i+"] ";
    }

    // adjust column lengths with header lengths
    for (int i=1;i<=numCols;i++) {
	int clen=colLengths[i];
	if (strlen(header[i]) > clen) 
	    colLengths[i]=strlen(header[i]);
    }
    string s="\n"+description+"\n";
    for (int i=0;i<=dynlen(values);i++) { //i==0 is for header
	string srow;
	sprintf(srow,"[%4d] |",i);
	if (i==0) sprintf(srow,"   #   |",i);
	dyn_string row;
	if (i==0) row=header;
	 else row=values[i];
	for (int j=1;j<=dynlen(row);j++) {
	    string sval;
	    string format="%-"+colLengths[j]+"s";
	    sprintf(sval,format,row[j]);
	    //DebugTN(i,j,row[j],format,sval);
	    srow+=sval+"|";
	}
	if (i==0) {
	    string separator="";
	    for (int j=1;j<=strlen(srow);j++) separator+="_";
	    s+=separator+"\n"+srow+"\n"+separator+"\n";
	} else if (i==dynlen(values)) {
	    string separator="";
	    for (int j=1;j<=strlen(srow);j++) separator+="_";
	    int diff = dynlen(data)-dynlen(values);
	    if (trunc && (diff>0) ) 
		s+=srow+"\n       ... "+(string)diff+" row(s) more ...\n"+separator+"\n";
	    else
		s+=srow+"\n"+separator+"\n";
	} else {
	    s+=srow+"\n";
	}

    }
    DebugTN(s);
}

void _fwConfigurationDB_queryPrint(string sql, string description="", int maxRows=10)
{
    dyn_dyn_mixed data;
    dyn_string exceptionInfo;
    if (description=="") description=sql;
    _fwConfigurationDB_executeDBQuery(sql, g_fwConfigurationDB_DBConnection,data,exceptionInfo,999,false);
    if (dynlen(exceptionInfo)) {DebugTN("Cannot query data to display",sql,description,exceptionInfo);return;}
    fwConfigurationDB_printDynDynMixed(data,makeDynString(),maxRows,description);
}

void _fwConfigurationDB_showItemsInCDB_API_PARAMS(string description="CDB_API_PARAMS")
{
    dyn_dyn_mixed data;
    dyn_string exceptionInfo;
    string sql="SELECT I1,I2,I3,I4,I5,I7,I8,S1,S2,S3,S4,S5,S6,S7 from CDB_API_PARAMS";
    _fwConfigurationDB_executeDBQuery(sql, g_fwConfigurationDB_DBConnection,data,exceptionInfo,14,false);
    if (dynlen(exceptionInfo)) {DebugTN("Cannot query data to display",description,exceptionInfo);return;}
    int maxRows=200;
    fwConfigurationDB_printDynDynMixed(data, 
	makeDynString("ITEM_ID","CITEM_ID","PARENT_ID","DPID","REF_ID","DPType ID","IsNew",
		    "DPName","Ref","DPType","Model","Name","Parent","Comment"),
	maxRows,
	description);
}