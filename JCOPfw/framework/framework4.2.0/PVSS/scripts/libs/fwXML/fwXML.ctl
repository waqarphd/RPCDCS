/**@file

This library contains the XML SAX function call and some additional XML DOM function calls.

@par Creation Date
	01/12/2008

@par Modification History
        01/12/2008: Initial version
        22/06/2009: Added fwXml_appendChildContent
        06/04/2010: Removed .dll extension from #uses
	
@par Constraints
	For PVSS 3.6 SP2 and later versions

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@author 
	Daniel Davids (IT-CO)
*/

#uses "CtrlXml"


//@{


/** fwXml_StartElement
Constant used in the mapping that associates the user-defined callback 
to the start of an Xml element-node
*/
const int fwXml_SAXSTARTELEMENT       = 2;
/** fwXml_EndElement
Constant used in the mapping that associates the user-defined callback 
to the end of an Xml element-node
*/
const int fwXml_SAXENDELEMENT         = 3;
/** fwXml_Characters
Constant used in the mapping that associates the user-defined callback 
to an Xml text-node
*/
const int fwXml_SAXCHARACTERS         = 6;


/** 'fwXml_trim' to trim a string, especially to be used for trimming an Xml-Node's value.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@param value          inout, the value to be trimmed
@return               output, the trimmed value
*/

public string fwXml_trim ( string value )
{
  return ( strltrim ( strrtrim ( value ) ) );
}


/** '_fwXml_parseSaxRecursive' called by 'fwXml_parseSaxFromFile' and itself in a recursive way.

@par Constraints
	None

@par Usage
	Private

@par PVSS managers
	UI, CTRL

@param document          input, the document-ident of the loaded Xml file
@param callBacks         input, the callback functions to be called while parsing
@param level             input, the current nesting-level of the recursive calls
@param nodes_id          input, the node-ident from which the sub-tree is parsed
@param exceptionInfo     inout, returns details of any exceptions
@return                  void
*/

private void _fwXml_parseSaxRecursive ( int document , 
                    mapping callBacks , int level , int nodes_id ,
                    dyn_string &exceptionInfo )
{
dyn_errClass error;
mapping      attributs;
int          rtn_code, node_typ;
string       node_nam, node_val;
int          this_node, neighbour;
string       commandCallback;

  node_typ = xmlNodeType ( document , nodes_id );
  node_nam = xmlNodeName ( document , nodes_id );
  node_val = xmlNodeValue ( document , nodes_id );

  if ( node_typ == XML_ELEMENT_NODE )
  {
    attributs = xmlElementAttributes ( document , nodes_id );
  }

  if ( mappingHasKey ( callBacks , 2*node_typ ) )
  {
    commandCallback = "int main(int level, int typ, string nam, string val, mapping map ) ";
    
    switch ( 2*node_typ )
    {
      case fwXml_SAXSTARTELEMENT:
              commandCallback += "{ "+callBacks[fwXml_SAXSTARTELEMENT]+"( nam , map ); return 0; }";
              break;
      case fwXml_SAXCHARACTERS:
              commandCallback += "{ "+callBacks[fwXml_SAXCHARACTERS]+"( val ); return 0; }";
              break;
      default:
              commandCallback = "";
              break;
    }
  
    // DebugN ( "callbk "+commandCallback );
  
    rtn_code = execScript(commandCallback, makeDynString(), 
                          level , node_typ, node_nam, node_val, attributs );
    // DebugN("execScript Returns '"+rtn_code+"'");
  }
  
  ++level;

  this_node = nodes_id;
  
  neighbour = xmlFirstChild ( document , this_node );
  
  while ( neighbour >= 0 )
  {
    _fwXml_parseSaxRecursive ( document , callBacks , level , neighbour , exceptionInfo );

    this_node = neighbour;

    neighbour = xmlNextSibling ( document , this_node );
  }
  
  --level;
  
  if ( mappingHasKey ( callBacks , 2*node_typ+1 ) )
  {
    commandCallback = "int main(int level, int typ, string nam, string val, mapping map ) ";
    
    switch ( 2*node_typ+1 )
    {
      case fwXml_SAXENDELEMENT:
              commandCallback += "{ "+callBacks[fwXml_SAXENDELEMENT]+"( nam ); return 0; }";
              break;
      default:
              commandCallback = "";
              break;
    }
  
    // DebugN ( "callbk "+commandCallback );
  
    rtn_code = execScript(commandCallback, makeDynString(), 
                          level , node_typ, node_nam, node_val, attributs );
    // DebugN("execScript Returns '"+rtn_code+"'");
  }  
}


/** 'fwXml_parseSaxFromFile' parses an Xml-file according to the SAX mechanism with user-defined callbacks.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@param xml_file          input, the file-name of the Xml file to be parsed
@param callBacks         input, the callback functions to be called while parsing
@param errMsg            output, the error message if the Xml file cannot be parsed
@param errLin            output, the line in the Xml file at which the error occurred
@param errCol            output, the column in the Xml file at which the error occurred
@param exceptionInfo     inout, returns details of any exceptions
@return                  output, 0 on success and -1 if an error during parsing occurred

@par SAX Callback Mechanism
        The callback function-names are passed to the 'fwXml_parseSaxFromFile' 
        function as a PVSS mapping.  Three different callbacks are currently 
        implemented which can be activated by associating them to corresponding 
        function-names in the PVSS mapping.  The parameter passing of the callback 
        functions follow very closely the Qt-implementation of the 'QXmlContentHandler'.
        These three types are the following:
@par
        Type 'fwXml_StartElement' called when an Xml element-node is encountered.<br>
        Activate: 'callBacks[fwXml_StartElement] = "<start-element-callback>";'<br>
        Declaration: 'void <start-element-callback> ( string elementName , mapping elementAttributes )'
@par
        Type 'fwXml_EndElement' called when an Xml element-node is left (exited).<br>
        Activate: 'callBacks[fwXml_EndElement] = "<end-element-callback>";'<br>
        Declaration: 'void <end-element-callback> ( string elementName )'
@par
        Type 'fwXml_Characters' called when an Xml text-node is encountered.<br>
        Activate: 'callBacks[fwXml_Characters] = "<characters-callback>";'<br>
        Declaration: 'void <characters-callback> ( string characters )'
            
@par
        A typical example is included in the example-panel "xmlParseSaxFromFileExample.pnl". 
        The Xml-file "xmlExampleSaxParsing.xml" is parsed by the program in this panel.
        The push-button parses the Xml-file in a pre-order traversal of the element tree
        and calls the user-defined callbacks on encountering the various node-boundaries.
*/

public int fwXml_parseSaxFromFile ( string xml_file , mapping callBacks , 
                                    string & errMsg , string & errLin , string & errCol ,
                                    dyn_string &exceptionInfo )
{
int this_node, neighbour;
int rtn_code, document;
int level = 0;

  document = xmlDocumentFromFile ( xml_file , errMsg , errLin , errCol );
  
  if ( document >= 0 )
  {
    neighbour = xmlFirstChild ( document );
    
    while ( neighbour >= 0 )
    {
      _fwXml_parseSaxRecursive ( document , callBacks , level , neighbour , exceptionInfo );
      
      this_node = neighbour;
      
      neighbour = xmlNextSibling ( document , this_node );
    }

    rtn_code = xmlCloseDocument ( document );
  }
  
  return ( document < 0 ? -1 : 0 );
}


/** '_fwXml_elementsRecursive' called by '' and itself in a recursive way.

@par Constraints
	None

@par Usage
	Private

@par PVSS managers
	UI, CTRL

@param doc               input, the document identifier
@param node              input, the node identifier of the parent or -1 (root-node)
@param tag               input, the tag-name of the children which need to be returned
@param elements          inout, the elements satisfying the tag-name condition
@param exceptionInfo     inout, returns details of any exceptions
@return                  void
*/

void _fwXml_elementsRecursive ( unsigned doc , int node , string tag , dyn_int &elements ,
                                dyn_string &exceptionInfo )
{
dyn_int children;
int node_typ;
string node_nam;

  node_typ = xmlNodeType ( doc , node );
   
  if ( node_typ == XML_ELEMENT_NODE )
  {
    node_nam = xmlNodeName ( doc , node );
    
    if ( node_nam == tag ) { dynAppend ( elements , node ); }
    
    if ( xmlChildNodes ( doc , node , children ) != 0 ) { return; }
  
    for ( int idx = 1 ; idx <= dynlen(children) ; ++idx )
    {
      _fwXml_elementsRecursive ( doc , children[idx] , tag , elements , exceptionInfo );
    }     
  }  
}


/** 'fwXml_elementsByTagName' returns all children which have a specific element's tag-name

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@param doc               input, the document identifier
@param node              input, the node identifier of the parent or -1 (root-node)
@param tag               input, the tag-name of the children which need to be returned
@param exceptionInfo     inout, returns details of any exceptions
@return                  output, all children which have a specific element's tag-name
        
@par
Returns a dynamic-integer array containing all descendent elements of this 
element that are called tag-name. The order they are in the dynamic-integer
array is the order they are encountered in a pre-order traversal of the element 
tree.  If '-1' is given to the node-identifier's value, then the whole document 
is searched.
  
@par
A typical example is included in the example-panel "xmlElementsByTagNameExample.pnl". 
The Xml-file "xmlExampleProcessTags.xml" is parsed by the two programs in this panel.
The first push-button gets the element-nodes with tagnames 'home', 'room' and 'floor'.
The second push-button gets only the element-nodes of the 'room's which are within 
'bedrooms's.
*/

dyn_int fwXml_elementsByTagName ( unsigned doc , int node , string tag ,
                                  dyn_string &exceptionInfo )
{
dyn_int elements = makeDynInt();
int ident;

  if ( node == -1 )
  {
    if ( ( ident = xmlFirstChild ( doc ) ) >= 0 )
    {
      do {
           _fwXml_elementsRecursive ( doc , ident , tag , elements , exceptionInfo );
         }
      while ( ( ident = xmlNextSibling ( doc , ident ) ) >= 0 );
    }
  }
  else
  {
    _fwXml_elementsRecursive ( doc , node , tag , elements , exceptionInfo );
  }
    
  return ( elements );
}


/** fwXml_CHILDNODESTYPE
Constant used in the mapping that identifies the node-type of the node in question
*/
const string fwXml_CHILDNODESTYPE = "fwXml_ChildNodesType";
/** fwXml_CHILDSUBTREEID
Constant used in the mapping that identifies the node-identifier of the node in question
*/
const string fwXml_CHILDSUBTREEID = "fwXml_ChildSubTreeId";


/** 'fwXml_childNodesContent' returns tags, attributes and contained data of all children

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@param doc               input, the document identifier
@param node              input, the node identifier of the parent element-node container
@param node_names        output, the node-names or tag-names for element-nodes
@param attributes        output, the attributes of element-nodes and added infomation
@param nodevalues        output, the node-values or values of the unique child's text-node
@param exceptionInfo     inout, returns details of any exceptions
@return                  output, the combined types of the type of children which data is returned
        
@par When used for simple Xml-file structures
If the function returns '0' (zero), then the child-nodes are all element-nodes
which contain at most one text-node as their child.  The following is returned via
the three output-parameters: 'node_names' returns the tag-names of the element-nodes, 
'attributes' returns all the attributes of the element-nodes, 'nodevalues' returns 
the value (character-data) of the contained text-node if present, otherwise it returns 
the empty string.

@par
A typical example is included in the example-panel "xmlChildNodesContentExample.pnl"
(first push-button).  The Xml-file "xmlExampleFlatListing.xml" can be completely 
read by issuing one single call to this function - specify for the 'node' variable 
the node-identifier of the element-node called "<room>".

@par
Note that this function was created especially for users who want to parse Xml-files
of a structure which corresponds to the above description.  Only read further if you
want to use this function to parse more complex Xml-file structures.

@par When used for complex Xml-file structures
If any of the child-nodes is different from an element-node which contains at most one
text-node as its child, then the return-code will be different from '0' and will be
more specific the bitwise OR-ed values which are obtained by shifting the value '1' 
to the left by a number of places which corresponds to the internal enumerated value 
of the node-type.

@par
An example will illustrate this much easier.  Refer again to the example-panel
"xmlChildNodesContentExample.pnl" (second push-button).  The Xml-file corresponds
this time to "xmlExampleGreatText.xml".  In this example there is in addition to 
the above at least one text-node as a direct child (not as a child of an element-node).
In that case, the return-code is '8' - this is obtained by shifting '1' to the left 
by XML_TEXT_NODE places (1<<XML_TEXT_NODE) [1<<3].  

@par
For nodes which are not element-nodes, the returned values are: 'node_names' returns 
the node-name of the node as queried by 'xmlNodeName', 'attributes' returns a single 
mapping "[fwXml_CHILDNODESTYPE;(int)<node-type>]" which indicates the node-type of the 
node, 'nodevalues' returns the node-value of the node as queried by 'xmlNodeValue'.

@par
If there is additionally at least one child-node with more than one child or with 
a child which is not a text-node then the return-code will have the bit-value '2'
also set.  The same example-panel "xmlChildNodesContentExample.pnl" illustrates
this.  Third button parses the "xmlExampleHierarchical.xml" Xml-file - return-code 
corresponds to '2' (1<<XML_ELEMENT_NODE) [1<<1]. Fourth button parses the Xml-file
"xmlExampleMoreComplex.xml"  - return-code corresponds to '10' - obtained by bitwise 
OR-ing of (1<<XML_ELEMENT_NODE) and (1<<XML_TEXT_NODE) which is [(1<<1)|(1<<3)].

@par
For element-nodes with more than one child or with a child which is not a text-node, 
the returned values are: 'node_names' returns the tag-name of the node, 'attributes' 
returns all the attributes of the element-nodes with additionally the two following 
added mappings "[fwXml_CHILDNODESTYPE;(int)XML_ELEMENT_NODE]" which is the node-type 
and "[fwXml_CHILDSUBTREEID;(int)<element-node-identifier>]", 'nodevalues' returns 
the empty string.
*/

int fwXml_childNodesContent ( unsigned doc , int node ,
              dyn_string &node_names , dyn_anytype &attributes , dyn_string &nodevalues ,
              dyn_string &exceptionInfo )
{
int rtn_code;
int node_typ;
mapping node_att;
string node_nam, node_val;
dyn_int children, subnodes;
int child_types = 0;

  node_names = makeDynString();
  attributes = makeDynAnytype();
  nodevalues = makeDynString();
  
  rtn_code = xmlChildNodes ( doc , node , children );
  if ( rtn_code != 0 ) return ( rtn_code );
  
  for ( int idx = 1 ; idx <= dynlen(children) ; ++idx )
  {
    node_typ = xmlNodeType ( doc , children[idx] );
    node_nam = xmlNodeName ( doc , children[idx] );
    
    mappingClear ( node_att );
    
    if ( node_typ == XML_ELEMENT_NODE )
    {
      node_att = xmlElementAttributes ( doc , children[idx] );
      
      rtn_code = xmlChildNodes ( doc , children[idx] , subnodes );
      if ( dynlen(subnodes) == 0 )
         { node_val = ""; }
      else if (  ( dynlen(subnodes) == 1 )
              && ( xmlNodeType ( doc , subnodes[1] ) == XML_TEXT_NODE ) )
         { node_val = xmlNodeValue ( doc , subnodes[1] ); }
      else
      {
        node_val = "";
        node_att[fwXml_CHILDNODESTYPE] = node_typ;
        node_att[fwXml_CHILDSUBTREEID] = children[idx];
        child_types |= ( 1 << node_typ );
      }
    }
    else
    {
      node_val = xmlNodeValue ( doc , children[idx] );
      node_att[fwXml_CHILDNODESTYPE] = node_typ;
      child_types |= ( 1 << node_typ );
    }
    
    dynAppend ( node_names , node_nam );
    dynAppend ( attributes , node_att );
    dynAppend ( nodevalues , node_val );
  }
  
  return ( child_types );
}


/** 'fwXml_appendChildContent' appends element-nodes, attributes and contained data to the Xml Tree

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@param doc               input, the document identifier
@param node              input, the node identifier of the parent element-node container
@param node_names        input, tag-names for element-nodes
@param attributes        input, the attributes of element-nodes
@param nodevalues        input, the values of the unique child's text-node
@param exceptionInfo     inout, returns details of any exceptions
@return                  output, 0 on success and -1 if an error during construction occurred
        
@par Only used for simple Xml-file structures
This function constructs underneath the given node an ordered list of children element-nodes.
Each of these children element-nodes gets their corresponding attributes and if defined and
not the empty-string their corresponding child text-node.

@par
A typical example is included in the example-panel "xmlCreateChildContentExample.pnl".
The first push-button creates a list of element-nodes.  The second push-button creates 
a list of element-nodes with most of them having a unique child's text-node.  The third 
push-button creates a list of element-nodes with some of them having one or more qualifying 
attributes.  The fourth push-button combines all the above examples together and creates 
a list of element-nodes with some of them attributes and most of them a unique child's 
text-node.
*/

int fwXml_appendChildContent ( unsigned doc , int node ,
    dyn_string node_names , dyn_anytype attributes , dyn_string nodevalues ,
    dyn_string &exceptionInfo )
{
int children, childr_a, childr_v;
int subchild, func_rtn, rtn_code;
anytype child_attrs;
dyn_int subnodes;
string attr_key;

  func_rtn = 0;
  
  children = dynlen(node_names);
  childr_a = dynlen(attributes);
  childr_v = dynlen(nodevalues);
  
  if ( ( childr_a != 0 ) && ( childr_a != children ) )
  {
    fwException_raise(exceptionInfo, "ERROR", "Node-Name and Attribute Lists have Different Size!", "" );
    return ( -1 );
  }
  
  if ( ( childr_v != 0 ) && ( childr_v != children ) )
  {
    fwException_raise(exceptionInfo, "ERROR", "Node-Name and Node-Value Lists have Different Size!", "" );
    return ( -1 );
  }

  for ( int idx = 1 ; idx <= children ; ++idx )
  {
    if ( ( subchild = xmlAppendChild ( doc , node , XML_ELEMENT_NODE , node_names[idx] ) ) < 0 )
    {
      fwException_raise(exceptionInfo, "ERROR", "Child '"+idx+"' Could Not be Added!", "" );
      func_rtn = -1;
      break;
    }
    
    if ( childr_a )
    {
      child_attrs = attributes[idx];
      
      for ( int i = 1 ; i <= mappinglen(child_attrs) ; i++ )
      {
        attr_key = mappingGetKey ( child_attrs , i );
        
        if ( ( xmlSetElementAttribute ( doc , subchild , attr_key , child_attrs[attr_key] ) ) != 0 )
        { 
          fwException_raise(exceptionInfo, "ERROR", "Attribute of Child '"+idx+"' Could Not be Added!", "" );
          func_rtn = -1;
          break;
        }
      }
      
      if ( func_rtn != 0 ) { break; }
    }
    
    if ( childr_v )
    {
      if ( nodevalues[idx] != "" )
      {
        if ( ( rtn_code = xmlAppendChild ( doc , subchild , XML_TEXT_NODE , nodevalues[idx] ) ) < 0 )
        {
          fwException_raise(exceptionInfo, "ERROR", "Sub-Child '"+idx+"' Could Not be Added!", "" );
          func_rtn = -1;
          break;
        }
      }
    }
  }
  
  if ( func_rtn != 0 )
  {
    if ( xmlChildNodes ( doc , node , subnodes ) == 0 )
    {
      for ( int idx = 1 ; idx <= dynlen(subnodes) ; ++idx )
      {
        xmlRemoveNode ( doc , subnodes[idx] );
      }
    }
  }
  
  return ( func_rtn );
}


//@}

