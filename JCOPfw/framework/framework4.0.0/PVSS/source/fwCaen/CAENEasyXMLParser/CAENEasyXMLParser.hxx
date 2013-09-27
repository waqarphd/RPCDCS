#ifndef _CAENEASYXMLPARSER_H_
#define _CAENEASYXMLPARSER_H_

#include <BaseExternHdl.hxx>

// ---------------------------------------------------------------------------
// Xerces Includes
// ---------------------------------------------------------------------------
#include <xercesc/util/PlatformUtils.hpp>
#include <xercesc/parsers/AbstractDOMParser.hpp>
//#include <xercesc/util/XMLString.hpp>
#include <xercesc/dom/DOMImplementation.hpp>
#include <xercesc/dom/DOMImplementationLS.hpp>
#include <xercesc/dom/DOMImplementationRegistry.hpp>
#include <xercesc/dom/DOMBuilder.hpp>
#include <xercesc/dom/DOMException.hpp>
#include <xercesc/dom/DOMDocument.hpp>
#include <xercesc/dom/DOMNodeList.hpp>
#include <xercesc/dom/DOMError.hpp>
#include <xercesc/dom/DOMLocator.hpp>
#include <xercesc/dom/DOMNamedNodeMap.hpp>
#include <xercesc/dom/DOMAttr.hpp>
#include <xercesc/dom/DOMNode.hpp>

#include <xercesc/util/OutOfMemoryException.hpp>

# ifdef _WIN32
#   define  PVSS_EXPORT  __declspec(dllexport)
# else
#   define  PVSS_EXPORT
# endif


class CAENEasyXMLParser : public BaseExternHdl
{
  public:
    // List of user defined functions
    // Internal use only
    enum 
    {
//	  F_tcpConnect = 0,
//	  F_tcpSend,
//     F_tcpRecv,
//      F_tcpClose,
      F_DOMBuilderCreate = 0
    };

    // Descritption of user defined functions. 
    // Used by libCtrl to identify function calls
    static FunctionListRec  fnList[];

    CAENEasyXMLParser(BaseExternHdl *nextHdl, PVSSulong funcCount, FunctionListRec fnList[])
      : BaseExternHdl(nextHdl, funcCount, fnList) {}
    
    // Execute user defined function
    virtual const Variable *execute(ExecuteParamRec &param);

  private:   
    int DOMBuilderCreate(const char *host);
	
//	int getAttributesOrChildNodeValue(DOMNode *node, const char *name, char *value);
};


// Create new ExternHdl. This must be global function named newExternHdl
PVSS_EXPORT   
BaseExternHdl *newExternHdl(BaseExternHdl *nextHdl);

#endif 
