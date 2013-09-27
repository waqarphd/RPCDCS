#include "fwUiLib.hxx"

#include <stdio.h>
#include <ctype.h>
#include <iostream.h>
#include <CharString.hxx>
#include <BlobVar.hxx>
#include <CtrlExpr.hxx>
#include <ExprList.hxx>
#include <CtrlThread.hxx>
#include <IdExpr.hxx>
#include <Variable.hxx>
#include <AnyTypeVar.hxx>
#include <BitVar.hxx>
#include <CharVar.hxx>
#include <IntegerVar.hxx>
#include <UIntegerVar.hxx>
#include <FloatVar.hxx>
#include <TextVar.hxx>
#include <TimeVar.hxx>
#include <DynVar.hxx>
#include <ErrorVar.hxx>
#include <ExternData.hxx>
#include <ErrClass.hxx>
#include <BCTime.h>

#include <dic.hxx>

#ifdef WIN32
#include <process.h>
#else
extern int errno;
#endif

// Function description
FunctionListRec FwUiExternHdl::fnList[] = 
{
  //  Return-Value    function name        parameter list               true == thread-save
  //  -------------------------------------------------------------------------------------
    { INTEGER_VAR, "fwUiGetPid",			"(string domain)"			, true},
    { INTEGER_VAR, "fwUiGetOwnPid",			"()"				        , true},
  };


BaseExternHdl *newExternHdl(BaseExternHdl *nextHdl)
{
  // Calculate number of functions defined
  PVSSulong funcCount = sizeof(FwUiExternHdl::fnList)/sizeof(FwUiExternHdl::fnList[0]);  
  
  // now allocate the new instance
  FwUiExternHdl *hdl = new FwUiExternHdl(nextHdl, funcCount, FwUiExternHdl::fnList);

  return hdl;
}

const Variable *FwUiExternHdl::execute(ExecuteParamRec &param)
{
  // We return a pointer to a static variable. 
  static IntegerVar integerVar;

  // A pointer to one "argument". Any input argument may be an exprssion
  // like "a ? x : y" instead of a simple value.
  CtrlExpr   *expr;
  // A generic pointer to the input / output value
  const Variable   *varPtr;

  // switch / case on function numbers
  switch (param.funcNum)
  {
   case F_fwUiGetPid:
    {
      // Forget all errors so far. We generate our own errors
      param.thread->clearLastError();

    	// Check for first parameter "domain" (string)
      if (!param.args || !(expr = param.args->getFirst()) ||
          !(varPtr = expr->evaluate(param.thread)) || (varPtr->isA() != TEXT_VAR)
         )
      {
        ErrClass  errClass(
          ErrClass::PRIO_WARNING, ErrClass::ERR_PARAM, ErrClass::ARG_MISSING,
          "FwUiExternHdl", "execute", "missing or wrong argument fwUiGetPid");

        // Remember error message. 
        // In the Ctrl script use getLastError to retreive the error message
        param.thread->appendLastError(&errClass);

        // Return error
        integerVar.setValue (-1); 
        return &integerVar;    // error ->return
      }

      // Get first parameter
      TextVar domain;
      domain = *varPtr;        // Assignment calls the appropriate operator

      int pid = fwUiGetPid(domain.getValue());

      if (pid == -1)
      {
# ifdef _WIN32
         // Win NT: Get the error code with WSAGetLastError.
         // Unfortunately this is just the error code, no error text,
         // therefore we give just a generic message
         ErrClass  errClass(
           ErrClass::PRIO_WARNING, ErrClass::ERR_SYSTEM, ErrClass::UNEXPECTEDSTATE,
           "FwUiExternHdl", "fwUiGetPid", "Could not get Pid");
# else
         // Unix compatible: The error code is in (the macro) errno
         // Get the error description with strerror(errno)
         ErrClass  errClass(
           ErrClass::PRIO_WARNING, ErrClass::ERR_SYSTEM, ErrClass::UNEXPECTEDSTATE,
           "FwUiExternHdl", "fwUiGetPid", strerror(errno));
# endif
        // Append the error message. 
        // In the Ctrl script use the getLastError-function to retreive the error
        param.thread->appendLastError(&errClass);

        // Return (-1) to indicate an error
        integerVar.setValue (-1); 
        return &integerVar;    // error ->return
      }

      // Return the PID
      integerVar.setValue (pid); 
  	  return &integerVar;    
    }

    case F_fwUiGetOwnPid:
    {
      // Forget all errors so far. We generate our own errors
      param.thread->clearLastError();

      int pid = fwUiGetOwnPid();

      if (pid == -1)
      {
# ifdef _WIN32
         // Win NT: Get the error code with WSAGetLastError.
         // Unfortunately this is just the error code, no error text,
         // therefore we give just a generic message
         ErrClass  errClass(
           ErrClass::PRIO_WARNING, ErrClass::ERR_SYSTEM, ErrClass::UNEXPECTEDSTATE,
           "FwUiExternHdl", "fwUiGetPid", "Could not get Pid");
# else
         // Unix compatible: The error code is in (the macro) errno
         // Get the error description with strerror(errno)
         ErrClass  errClass(
           ErrClass::PRIO_WARNING, ErrClass::ERR_SYSTEM, ErrClass::UNEXPECTEDSTATE,
           "FwUiExternHdl", "fwUiGetPid", strerror(errno));
# endif
        // Append the error message. 
        // In the Ctrl script use the getLastError-function to retreive the error
        param.thread->appendLastError(&errClass);

        // Return (-1) to indicate an error
        integerVar.setValue (-1); 
        return &integerVar;    // error ->return
      }

      // Return the Pid
      integerVar.setValue (pid); 
  	  return &integerVar;    
    }
	default :
        // Return (-1) to indicate an error
        integerVar.setValue (-1); 
        return &integerVar;    // error ->return
   }
}



int FwUiExternHdl::fwUiGetPid( const char *domain)
{
	int j;
	char str[128];
	int ret;

	strcpy(str,"SMI/");
	for(j = 0; j < ((int)strlen(domain))+1; j++)
		str[j+4] = toupper(domain[j]);
	strcat(str,"/SMI_PID");
	DimCurrentInfo pid(str,-1); 
	ret = pid.getInt();
	return (ret);
}

int FwUiExternHdl::fwUiGetOwnPid()
{
  int pid;

#ifdef WIN32
	pid = _getpid();
#else
	pid = getpid();
#endif
	return (pid);
}


// DLLInit Funktion fuer Win NT
// Initialize / DeInit winsock
/*
#ifdef _WIN32
BOOL WINAPI DllInit(HINSTANCE, DWORD dwReason, LPVOID)
{
  return TRUE;
}
#endif
*/
