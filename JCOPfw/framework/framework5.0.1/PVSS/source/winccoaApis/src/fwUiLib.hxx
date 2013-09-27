#ifndef _FWUIEXTERNHDL_H_
#define _FWUIEXTERNHDL_H_

#include <BaseExternHdl.hxx>

# ifdef WIN32
#   define  PVSS_EXPORT  __declspec(dllexport)
# else
#   define  PVSS_EXPORT
# endif


class FwUiExternHdl : public BaseExternHdl
{
  public:
    // List of user defined functions
    // Internal use only
    enum 
    {
      F_fwUiGetPid = 0,
      F_fwUiGetOwnPid,
    };

    // Descritption of user defined functions. 
    // Used by libCtrl to identify function calls
    static FunctionListRec  fnList[];

    FwUiExternHdl(BaseExternHdl *nextHdl, PVSSulong funcCount, FunctionListRec fnList[])
      : BaseExternHdl(nextHdl, funcCount, fnList) {}
    
    // Execute user defined function
    virtual const Variable *execute(ExecuteParamRec &param);

  private:
    int fwUiGetPid(const char *domain);
    int fwUiGetOwnPid();
};

// Create new ExternHdl. This must be global function named newExternHdl
PVSS_EXPORT   
BaseExternHdl *newExternHdl(BaseExternHdl *nextHdl);

#endif 
