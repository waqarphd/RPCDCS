#uses "CtrlXml" 
#uses "fwXml/fwXml.ctl" 

string JCOP_FRAMEWORK_CAEN_DEBUG = "JCOP_FRAMEWORK_CAEN_DEBUG";

DOMBuilderCreate(string caenEasyFileName, dyn_dyn_string &devices, dyn_string &exceptionInfo)
{
	_fwCaen_parseXmlFile(caenEasyFileName, devices, exceptionInfo);
}

_fwCaen_parseXmlFile(string caenEasyFileName, dyn_dyn_string &listOfDevices, dyn_string &exceptionInfo)
{
	int i, j, k, rtn_code, docum, errorCode;
	string stringValue, errMsg, errLin, errCol;
	dyn_int racks, crates, crateList, boardList;
	dyn_string tempDevice, exInfo;

	DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "fwCaen_parseXmlFile: starting CAEN XML parsing...");
  
	docum = xmlDocumentFromFile(caenEasyFileName, errMsg, errLin, errCol );
	DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "fwCaen_parseXmlFile: document id = " + docum );
  
	if (docum < 0)
   {
		DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "fwCaen_parseXmlFile: parsing Error-Message = '" + errMsg + "' Line=" + errLin + " Column=" + errCol );
	}
	else
	{
		racks = fwXml_elementsByTagName ( docum , -1 , "EASY_Rack" , exInfo );
		_fwCaen_printElements ( docum , racks );
    
		if(dynlen(racks) < 1)
		{
      	DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "Parsing CAEN XML file: could not find any racks");
		}
    
    	// Iterate through the racks to fins the list of crates
		for(i = 1; i <= dynlen(racks); i++)
      {
      	errorCode = xmlChildNodes(docum, racks[i], crateList);
		}
    
		_fwCaen_printElements(docum , crateList);
  
		k = 1;
  		
		// Iterate over the crates to find the boards
		for(i = 1; i <= dynlen(crateList); i++)
		{
			tempDevice[1] = xmlNodeName(docum, crateList[i]);
      	errorCode = xmlGetElementAttribute(docum, crateList[i], "Name", stringValue);
         tempDevice[2] = stringValue;
         tempDevice[3] = i - 1;
      
        	// Add crate to the list of devices 
        	listOfDevices[k++] = tempDevice;
          
         // Get list of boards in the crate
	    	errorCode = xmlChildNodes(docum, crateList[i], boardList);

			// Iterate over the boards in the crate        
			for(j = 1; j <= dynlen(boardList); j++)
			{
				tempDevice[1] = xmlNodeName(docum, boardList[j]);
				errorCode = _fwCaen_getAttributesOrChildNodeValue(docum, boardList[j], "EASY_Board_Model", stringValue);
				tempDevice[2] = stringValue;
				errorCode = _fwCaen_getAttributesOrChildNodeValue(docum, boardList[j], "Slot", stringValue);
				tempDevice[3] = stringValue;

				// Add board to the list of devices        
     			listOfDevices[k++] = tempDevice;
			}
		}
    
		DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, listOfDevices);
    
		rtn_code = xmlCloseDocument(docum);
		DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "rtn_code = " + rtn_code );
	}	
}

int _fwCaen_getAttributesOrChildNodeValue(unsigned doc, unsigned node, string name, string &value)
{
  	unsigned i, j;
  	int errorCode, childNodeType;
   string childNodeName, childNodeValue;
   dyn_string elementChildNodes;
  	dyn_int childNodes;
  
	DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "_fwCaen_getAttributesOrChildNodeValue(): looking for value for " + name);  
  
	value = "";
  
	// Fisrt look in the attributes
 	errorCode = xmlGetElementAttribute(doc, node, name, value);
  
	if(value != "")
  	{
		DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "_fwCaen_getAttributesOrChildNodeValue(): found " + name + " as attribute with value " + value);
		return 0;
  	}
  
	// If it wasn't found in the attributes, look in the child nodes
	errorCode = xmlChildNodes(doc, node, childNodes);
	DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "_fwCaen_getAttributesOrChildNodeValue(): there are " + dynlen(childNodes) + " children.");

	for(i = 1; i <= dynlen(childNodes); i++)
	{
    	childNodeName = xmlNodeName(doc, childNodes[i]);
  		DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "_fwCaen_getAttributesOrChildNodeValue(): looking at " + childNodeName);
    
      // element node with the right name found, we have to look for a child text node
    	if(childNodeName == name)
      {
       	errorCode = xmlChildNodes(doc, childNodes[i], elementChildNodes);
        	for(j = 1; j <= dynlen(elementChildNodes); j++)
			{
            DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "_fwCaen_getAttributesOrChildNodeValue(): xmlNodeType " + xmlNodeType(doc, elementChildNodes[j]) + " xmlNodeValue: " + xmlNodeValue(doc, elementChildNodes[j]));
        		// if the node is of type text, get its value
		      if (xmlNodeType(doc, elementChildNodes[j]) == XML_TEXT_NODE)
	       	{
					value = xmlNodeValue(doc, elementChildNodes[j]);
         		return 0;
        		}
      	}
      }
   }
  
  // If no attribute or node with the right name was found then return error code
  if(value == "")
		return -1;
}


void _fwCaen_printElements ( int docum , dyn_int elements )
{
	string tagname;
	mapping attribs;

	for ( int idx = 1 ; idx <= dynlen(elements) ; ++idx )
	{
		tagname = xmlNodeName ( docum , elements[idx] );
		attribs = xmlElementAttributes ( docum , elements[idx] );
		DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "TagName of Node " + elements[idx] + " = '" + tagname 
					+ "'   Attribs = '" + (string)attribs + "'" );
	}
	DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "");
}
