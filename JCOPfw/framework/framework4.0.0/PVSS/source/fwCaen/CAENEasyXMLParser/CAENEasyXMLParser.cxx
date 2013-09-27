// XML parser for CAEN Easy configuration files

/*
# ifdef _WIN32
#   include <winsock2.h>
# else
#   include  <netdb.h>
#   include  <sys/socket.h>
#   include  <netinet/in.h>
#   include  <arpa/inet.h>
#   include  <errno.h>
#   include  <sys/time.h>
#   include  <sys/types.h>
#   include  <unistd.h>
#endif

*/

#include "CAENEasyXMLParser.hxx"

#include <stdio.h>
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


/*
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

#include <xercesc/util/OutOfMemoryException.hpp>
*/

#include <string.h>
#include <stdlib.h>

#if defined(XERCES_NEW_IOSTREAMS)
#include <fstream>
#else
#include <fstream.h>
#endif

using namespace xercesc;


// Function description
FunctionListRec CAENEasyXMLParser::fnList[] = 
{
  //  Return-Value    function name        parameter list               true == thread-save
  //  -------------------------------------------------------------------------------------
 //   { INTEGER_VAR, "tcpConnect","(string ipAddr,  unsigned portNr)"     , true},
    { INTEGER_VAR, "DOMBuilderCreate",  "(string xmlFile, DynVar &devices)"              , true},
  };


BaseExternHdl *newExternHdl(BaseExternHdl *nextHdl)
{
  // Calculate number of functions defined
  PVSSulong funcCount = sizeof(CAENEasyXMLParser::fnList)/sizeof(CAENEasyXMLParser::fnList[0]);  
  
  // now allocate the new instance
  CAENEasyXMLParser *hdl = new CAENEasyXMLParser(nextHdl, funcCount, CAENEasyXMLParser::fnList);

  return hdl;
}

/* This function
*/
int  getAttributesOrChildNodeValue(DOMNode *node, const char *name, char **value)
{
	DOMNode *nodeWithName = NULL;
	DOMNodeList *childNodes = NULL, *childNodes2 = NULL;

	// Fisrt look in the attributes
 	DOMNamedNodeMap *myNodeMap = node->getAttributes();

	if(myNodeMap != NULL)
		nodeWithName = myNodeMap->getNamedItem(XMLString::transcode(name));
	
	if(nodeWithName != NULL)
	{
		*value = XMLString::transcode(nodeWithName->getNodeValue()); 
//		cerr	<< "Found attribute with name " << name << " and value " << *value << endl;
		return 0;
	}

	// If it wasn't found in the attributes, look in the child nodes
	childNodes = node->getChildNodes();
	if(childNodes == NULL)
		return -1;

	unsigned int i, j;
	for(i = 0; i < childNodes->getLength(); i++)
	{
		nodeWithName = childNodes->item(i);
		if(XMLString::equals(XMLString::transcode(nodeWithName->getNodeName()), name))
		{
			*value = XMLString::transcode(nodeWithName->getNodeValue());
			if(*value == NULL)
			{
				childNodes2 = nodeWithName->getChildNodes();
				for(j = 0; j < childNodes2->getLength(); j++)
				{
					nodeWithName = childNodes2->item(j);
					if(nodeWithName->getNodeType() == DOMNode::TEXT_NODE)
					{
						*value = XMLString::transcode(nodeWithName->getNodeValue());
		//				cerr	<< "Found child node with name " << name << " and value " << *value << endl;
						return 0;
					}
				}
			}
			else
			{
//				cerr	<< "Found child node with name " << name << " and value " << *value << endl;
				return 0;
			}
		}
	}

	// value for given name not found
	return -1;
}


const Variable *CAENEasyXMLParser::execute(ExecuteParamRec &param)
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
	case F_DOMBuilderCreate:
	{
		bool errorOccurred = false;
		// Forget all errors so far. We generate our own errors
		param.thread->clearLastError();
		
		// Check for first parameter "file name" (string)
		if (!param.args || !(expr = param.args->getFirst()) ||
			!(varPtr = expr->evaluate(param.thread)) || (varPtr->isA() != TEXT_VAR))
		{
			ErrClass  errClass(
				ErrClass::PRIO_WARNING, ErrClass::ERR_PARAM, ErrClass::ARG_MISSING,
				"CAENEasyXMLParser", "execute", "missing or wrong argument DOMBuilderCreate");
				
			// Remember error message. 
			// In the Ctrl script use getLastError to retreive the error message
			param.thread->appendLastError(&errClass);

			// Return error
			integerVar.setValue (-1); 
			return &integerVar;    // error ->return
      	}

		// Get first parameter
		TextVar xmlFile;
		xmlFile = *varPtr;        // Assignment calls the appropriate operator

		// Check for second argument dyn_dyn_string
		// This parameter is an output value (it receives our data),
		// so get a pointer via the getTarget call.
		if (!param.args || !(expr = param.args->getNext()) ||
			!(varPtr = expr->getTarget(param.thread)) || 
			(varPtr->isA() != DYNDYNTEXT_VAR)
			)
		{
			ErrClass  errClass(
				ErrClass::PRIO_WARNING, ErrClass::ERR_PARAM, ErrClass::ARG_MISSING,
				"CAENEasyXMLParser", "DOMBuilderCreate", "missing or wrong argument data");

			// Remember error message.
			// In the Ctrl script use getLastError to retreive the error message
			param.thread->appendLastError(&errClass);

			// Return (-1) to indicate error
			integerVar.setValue (-1); 
			return &integerVar;    // error ->return
		}

		
		// Xerces
		// Initialize the XML4C system
		try
		{
              XMLPlatformUtils::Initialize();
		}

		catch (const XMLException& toCatch)
		{
			//XERCES_STD_QUALIFIER
			cerr << "Error during initialization! :\n"
              << toCatch.getMessage() << XERCES_STD_QUALIFIER endl;

			cerr << "Error in XMLPlatformUtils::Initialize()";
			integerVar.setValue(-17);
			return &integerVar;
		}

		// Instantiate the DOM parser.
		static const XMLCh gLS[] = { chLatin_L, chLatin_S, chNull };

		DOMImplementation *impl = DOMImplementationRegistry::getDOMImplementation(gLS);
		DOMBuilder        *parser = ((DOMImplementationLS*)impl)->createDOMBuilder(DOMImplementationLS::MODE_SYNCHRONOUS, 0);
		
//		cerr << "Punto 2 \n";

		parser->setFeature(XMLUni::fgDOMNamespaces, false);
		parser->setFeature(XMLUni::fgXercesSchema, false);
		parser->setFeature(XMLUni::fgXercesSchemaFullChecking, false);
		parser->setFeature(XMLUni::fgDOMValidateIfSchema, true);
        parser->setFeature(XMLUni::fgDOMValidation, false);
        parser->setFeature(XMLUni::fgDOMValidation, true);
		// enable datatype normalization - default is off
		parser->setFeature(XMLUni::fgDOMDatatypeNormalization, true);
		
		// And create our error handler and install it
//		DOMCountErrorHandler errorHandler;
//		parser->setErrorHandler(&errorHandler);
		
//		cerr << "Punto 3 \n";

		unsigned long duration;
		//reset error count first
//		errorHandler.resetErrors();

        XERCES_CPP_NAMESPACE_QUALIFIER DOMDocument *doc = 0;

        try
        {
            // reset document pool
            parser->resetDocumentPool();

            const unsigned long startMillis = XMLPlatformUtils::getCurrentMillis();
            doc = parser->parseURI(xmlFile.getValue());
            const unsigned long endMillis = XMLPlatformUtils::getCurrentMillis();
            duration = endMillis - startMillis;

//			unsigned int elementCount = doc->getElementsByTagName(XMLString::transcode("*"))->getLength();		
//			XERCES_STD_QUALIFIER cout << "The tree just created contains: " << elementCount
//                   << " elements." << XERCES_STD_QUALIFIER endl;

			// Get all the racks in the xml file (in the current version of the CAEN Easy Rack Builder there 
			// can only be one rack per file)
 			DOMNodeList *nodeList = doc->getElementsByTagName(XMLString::transcode("EASY_Rack"));
			DOMNode *rackNode = nodeList->item(0);

//			cerr << "Rack node " << XMLString::transcode(rackNode->getNodeName()) << endl;
			DOMNodeList *crateList = rackNode->getChildNodes();

			DOMNodeList *boardList;
			XMLSize_t len = crateList->getLength();
//			cerr << "There are " << len << " crates" << endl;
			DOMNode *crateNode, *boardNode;
			char *value;

			PVSSboolean result;
			DynVar myDynVar, myDynDynVar;

			// Go through the crates and see which boards are there
			unsigned int i, j, count = 0;
			for(i = 0; i < len; i++)
			{
				crateNode = crateList->item(i);
				
				if(XMLString::equals(XMLString::transcode(crateNode->getNodeName()), "EASY_Crate"))
				{
//					cerr << "Crate node " << count << " " << XMLString::transcode(crateNode->getNodeName()) << " ";

					if(getAttributesOrChildNodeValue(crateNode, "Name", &value) == 0)
					{
//						cerr << " with name " <<  value << endl;
					}
					
					myDynVar.reset();
					myDynVar.append(new TextVar("EASY_Crate"));
					myDynVar.append(new TextVar(value));
					myDynVar.append(new TextVar(count));
					myDynDynVar.append(myDynVar);

					boardList = crateNode->getChildNodes();
//					cerr << "There are " << boardList->getLength() << " boards" << endl;
					for(j = 0; j < boardList->getLength(); j++)
					{
						boardNode = boardList->item(j);			
						if(XMLString::equals(boardNode->getNodeName(), XMLString::transcode("EASY_Board")))
						{
//							cerr << "Board node " << XMLString::transcode(boardNode->getNodeName());

							myDynVar.reset();
							myDynVar.append(new TextVar("EASY_Board"));

							if(getAttributesOrChildNodeValue(boardNode, "EASY_Board_Model", &value) == 0)
							{
//								cerr << " of model " << value;		
								myDynVar.append(new TextVar(value));
							}
							else
							{
								myDynVar.append(new TextVar(""));
							}

							
							if(getAttributesOrChildNodeValue(boardNode, "Slot", &value) == 0)
							{
//								cerr << " in slot " << value;
								myDynVar.append(new TextVar(value));
							}
							else
							{
								myDynVar.append(new TextVar(""));
							}
//							cerr << endl;

							myDynDynVar.append(myDynVar);
						}					
					}
					count++;
				}
			}

			((DynVar *) varPtr)->reset();
			((DynVar *) varPtr)->merge(myDynDynVar);

//			XMLString::release(&tagName);

        }
        catch (const XMLException& toCatch)
        {
            XERCES_STD_QUALIFIER cerr << "\nError during parsing: '" << xmlFile.getValue() << "'\n"
                 << "Exception message is:  \n"
                 << XMLString::transcode(toCatch.getMessage()) << "\n" << XERCES_STD_QUALIFIER endl;
            errorOccurred = true;
//          continue;
        }
        catch (const DOMException& toCatch)
        {
            const unsigned int maxChars = 2047;
            XMLCh errText[maxChars + 1];

            XERCES_STD_QUALIFIER cerr << "\nDOM Error during parsing: '" << xmlFile.getValue() << "'\n"
                 << "DOMException code is:  " << toCatch.code << XERCES_STD_QUALIFIER endl;

            if (DOMImplementation::loadDOMExceptionMsg(toCatch.code, errText, maxChars))
                 XERCES_STD_QUALIFIER cerr << "Message is: " << XMLString::transcode(errText) << XERCES_STD_QUALIFIER endl;

            errorOccurred = true;
            //continue;
        }
		catch (const OutOfMemoryException& toCatch)
		{
			XERCES_STD_QUALIFIER cerr << "OutOfMemoryException" << XERCES_STD_QUALIFIER endl;
			errorOccurred = true;
		}
        catch (...)
        {
            XERCES_STD_QUALIFIER cerr << "\nUnexpected exception during parsing: '" << xmlFile.getValue() << "'\n";
            errorOccurred = true;
           // continue;
        }

		if (errorOccurred)
		{
			ErrClass  errClass(
				ErrClass::PRIO_WARNING, ErrClass::ERR_SYSTEM, ErrClass::UNEXPECTEDSTATE,
				"CAENEasyXMLParser", "tcpConnect", "Could not parse file");

			// Append the error message. 
			// In the Ctrl script use the getLastError-function to retreive the error
			param.thread->appendLastError(&errClass);
			
			// Return (-1) to indicate an error
			integerVar.setValue (-23); 
			return &integerVar;    // error ->return
		}

//		cerr << "Parsing " << " lasted:" << duration << endl;

		integerVar.setValue(200);
		return &integerVar;
	}
    	
    // May never happen, but make compilers happy
    default: 
      integerVar.setValue(-15);
      return &integerVar;
  }

  return &integerVar;
}
