
// The following libraries are not any more used!
// #uses "fwExternalApps/gcsDIP.ctl"
// #uses "fwExternalApps/gcsGenericXMLOperations.ctl"

const string fwExternalApps_BASE_NODE = "ExternalApps";
const string fwExternalApps_EXPERIMENT_VARIABLE = "{varExperiment}";
const string fwExternalApps_EXPERIMENT_VARIABLE_UPPERCASE = "{varExperimentUppercase}";


fwExternalApps_readXmlFile(string xmlPath, string &xmlFileContents, dyn_string &exceptionInfo)
{
  if(isfile(xmlPath))
    fileToString(xmlPath, xmlFileContents);
  else
    fwException_raise(exceptionInfo, "ERROR", "The XML configuration file could not be found (" + xmlPath + ")", "");      
}


// Daniel Davids - IT/CO - July 2008
// 
// This is the second part of the code which has been added to deal with the different way of handling
// the External-Application's XML file - They are now displayed and are editable before loading them

//      -1-      -2-   -3-   -4-   -5-   -6-   -7-   -8-   -9-   -10-  (....... Element-Data .......)
//
//                A            <---+       +--->      n <= m!
//                |                |       |
// +-----------+--|--+-----+-----+-|---+---|-+-----+-----+-----+-----+-----+--  ....  --+-----+-----+
// | "Element" | par | fst | lst | prv | nxt | act | who | nbr | dat |     |            |     |     |
// +-----------+-----+-/---+---\-+-----+-----+--|--+--|--+--|--+--|--+-----+--  ....  --+-----+-----+
//                    /         \               |     |     |     |
//                   V           V             0-1   <n>   <m>   0-1


                                                 //  Indexes in the Table starting at One
                                                 //  ------------------------------------
const int fwExternalApps_TREE_ELEMT_INDEX =  1;  //  The Tree Node Element String Itself
const int fwExternalApps_PARENTNODE_INDEX =  2;  //  Parent Node - Index in Table
const int fwExternalApps_FRST_CHILD_INDEX =  3;  //  First Child - Index in Table
const int fwExternalApps_LAST_CHILD_INDEX =  4;  //  Last Child - Index in Table
const int fwExternalApps_PREV_SIBLG_INDEX =  5;  //  Prev Sibling - Index in Table
const int fwExternalApps_NEXT_SIBLG_INDEX =  6;  //  Next Sibling - Index in Table
const int fwExternalApps_ELEM_ACTIV_INDEX =  7;  //  Tree Node Element Itself is Active?
const int fwExternalApps_CHILDN_ACT_INDEX =  8;  //  Nb of Children Currently Active
const int fwExternalApps_NBCHILDREN_INDEX =  9;  //  Number of Children which do Exist
const int fwExternalApps_NODESUBPUB_INDEX = 10;  //  Does the Tree Node Got Data (Subs/Publ)?

const int fwExternalApps_NUMB_OF_CONTROLS = 10;  // Total Number of 'dyn_int' Control Nodes

// These are Currently the Four Types for the 'fwExternalApps_NODESUBPUB_INDEX' Index
const int fwExternalApps_DATA_TYPE_NODATA =  0;  // No Data Associated
const int fwExternalApps_DATA_TYPE_SUBSCR =  1;  // Only carries Subscriptions
const int fwExternalApps_DATA_TYPE_PUBLIC =  2;  // Only carries Publications
const int fwExternalApps_DATA_TYPE_SUBPUB =  3;  // Subscriptions and Publications

// This extra Entry Beyond the Control is Used to Store the Associated stored Data
// This Presence of the Data is Defined by the 'fwExternalApps_NODESUBPUB_INDEX' Field
const int fwExternalApps_NODES_DATA_INDEX = 11;

// The Following Flag Defines the Number of Displayed Columns in the Tree Widget
const int fwExternalApps_DISPLAY_EXPANDED =  0;

// These are the Columns in the Tree Widget
const int fwExternalApps_COLUMN_MAIN = 0;
const int fwExternalApps_COLUMN__ACT = 1;
const int fwExternalApps_COLUMN_SUBS = 2;
const int fwExternalApps_COLUMN__ALL = 3;
const int fwExternalApps_COLUMN_SOME = 4;
const int fwExternalApps_COLUMN_NONE = 5;

// These are the Icons Used in the Tree Widget that Denote the (Des)Active State
const string fwExternalApps_COLUMN_ASSERT_ICON = "checked.png";
const string fwExternalApps_COLUMN_DELETE_ICON = "delete.png";

// The Following is a Debug-Flag which Checks Performances
const int fwExternalApps_CHECK_PERFORMANCE  =  0;


// The Indexes into the Application Data's Dynamic Array

const int fwExternalApps_DATA_SUBS_PUBL     =  1;
const int fwExternalApps_DATA_SUBPUB_NAME   =  2;
const int fwExternalApps_DATA_SUBPUB_TYPE   =  3;
const int fwExternalApps_DATA_BUFF_MODE     =  4;
const int fwExternalApps_DATA_OVER_WRITE    =  5;
const int fwExternalApps_DATA_PNT_NAME      =  6;
const int fwExternalApps_DATA_PNT_ALIAS     =  7;
const int fwExternalApps_DATA_PNT_DESCRIP   =  8;
const int fwExternalApps_DATA_PNT_ELEMENT   =  9;
const int fwExternalApps_DATA_PNT_TAGNAME   = 10;
const int fwExternalApps_DATA_PNT_TYPNAME   = 11;
const int fwExternalApps_DATA_PNT_UNITS     = 12;
const int fwExternalApps_DATA_PNT_MINERROR  = 13;
const int fwExternalApps_DATA_PNT_MINWARN   = 14;
const int fwExternalApps_DATA_PNT_MAXWARN   = 15;
const int fwExternalApps_DATA_PNT_MAXERROR  = 16;
    

const string fwExternalApps_DIPCONFIG_TYPE = "_FwDipConfig";


/*
    The following functions are purely used for Debugging purposes
    
    _fwExternalApps_printTable prints out all the Control information of the Table
    
*/


int _fwExternalApps_printTable(dyn_dyn_anytype & tbl)
{
int siz = dynlen(tbl);
string lines;
int child;

  DebugN("Table Dump");
  for ( child = 1 ; child <= siz ; ++child )
  {
    sprintf(lines,"Entry %2d - %-16s | par %2d - fst %2d - lst %2d - prv %2d - nxt %2d",
            child,tbl[child][fwExternalApps_TREE_ELEMT_INDEX],tbl[child][fwExternalApps_PARENTNODE_INDEX],
                  tbl[child][fwExternalApps_FRST_CHILD_INDEX],tbl[child][fwExternalApps_LAST_CHILD_INDEX],
                  tbl[child][fwExternalApps_PREV_SIBLG_INDEX],tbl[child][fwExternalApps_NEXT_SIBLG_INDEX]);
    sprintf(lines,"%s | active %s - nbr %2d - who %2d - datas %s",
            lines,(tbl[child][fwExternalApps_ELEM_ACTIV_INDEX]==0?" No":"Yes"),
                   tbl[child][fwExternalApps_CHILDN_ACT_INDEX],
                   tbl[child][fwExternalApps_NBCHILDREN_INDEX],
                  (tbl[child][fwExternalApps_NODESUBPUB_INDEX]==fwExternalApps_DATA_TYPE_NODATA?"   -":
                  (tbl[child][fwExternalApps_NODESUBPUB_INDEX]==fwExternalApps_DATA_TYPE_SUBSCR?"Subs":
                  (tbl[child][fwExternalApps_NODESUBPUB_INDEX]==fwExternalApps_DATA_TYPE_PUBLIC?"Publ":
                  (tbl[child][fwExternalApps_NODESUBPUB_INDEX]==fwExternalApps_DATA_TYPE_SUBPUB?" S/P":"Bug!")))));
    DebugN(lines);
  }
}
  

/*
  
    The following routines initialise a Table that controls a Tree Widget's structure
    
    fwExternalApps_initialiseTable initialises a table
    
    _fwExternalApps_createNewTableEntry Creates a new entry in the Table
    
    fwExternalApps_readsDevicesFromString reads all the Subscriptions/Publications from a string (was a file)
    
    fwExternalApps_createDevicesFromTree creates all devices from information hold in the Tree widget's structure
  
    fwExternalApps_insertElementInTable & _fwExternalApps_insertDataElement inserts a canonical element in the Table
    
    _fwExternalApps_mergeDataInTable merges the application data in the Table
    
    fwExternalApps_showNodeDescription displays the Node's description
        
*/


// New Function that implements the reading of the Devices into the Database and Tree widget to be viewed

int fwExternalApps_initialiseTable(dyn_dyn_anytype & tbl, dyn_string & exceptionInfo)
{
int root;
  
  tbl = makeDynAnytype();
  root = _fwExternalApps_createNewTableEntry(tbl, "");
  
  tbl[root][fwExternalApps_ELEM_ACTIV_INDEX] = 1;
  
  // This Flag is Set so that One Can Insert New Entries in the Table
  // This Flag will be Cleared Once the Tree Widget Gets Populated
  tbl[1][fwExternalApps_NODES_DATA_INDEX] = 1;

  return ( root );
}


int _fwExternalApps_createNewTableEntry(dyn_dyn_anytype & tbl, string element)
{
int siz;
dyn_anytype tblentry;

  tblentry = makeDynAnytype(element);
  for ( int i = 2 ; i <= fwExternalApps_NUMB_OF_CONTROLS ; ++i ) dynAppend ( tblentry , 0 );
  
  siz = dynlen(tbl);
  ++siz;
  tbl[siz] = tblentry;
    
  return ( siz );
}
    

void fwExternalApps_readsDevicesFromXmlStr ( string xmlFileContents , 
                    string & configName , dyn_dyn_anytype & xmltable , dyn_string & exceptionInfo )
{
string errMsg;
int errLin, errCol;
int document, topchild, rtn_code;
dyn_mapping attrList, spAttrList, dpeAttrList;
dyn_string nameList, spNameList, dpeNameList;
dyn_string valsList, spValsList, dpeValsList;
string sSubscrPublicCommand, sSubscrPublicName, sSubscrPublicType;
string sBufferMode, sOverwriteMode;
dyn_string applicationData;
int sSubscrPublic;

  if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Starts fwExternalApps_readsDevicesFromXmlStr Parsing");

  document = xmlDocumentFromString ( xmlFileContents , errMsg , errLin , errCol );
  // DebugN ( "document = " + document );

  if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Ending fwExternalApps_readsDevicesFromXmlStr Parsing");

  if ( document < 0 )
  {
    fwException_raise(exceptionInfo, "ERROR", "Xml Parse Error '"+errMsg+"' Line="+errLin+" Column="+errCol, "");
    return;
  }
  
  if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Starts fwExternalApps_readsDevicesFromXmlStr ConfNam");

  topchild = xmlFirstChild ( document );
  // DebugN ( "topchild = " + topchild );
  
  while (  ( topchild != -1 )
        && ( xmlNodeType ( document , topchild ) != XML_ELEMENT_NODE ) )
  {
    topchild = xmlNextSibling ( document , topchild );
    // DebugN ( "topchild = " + topchild );
  }

  if ( topchild != -1 )
  {
    if ( xmlNodeName ( document , topchild ) == "contract" )
    {
      topchild = xmlFirstChild ( document , topchild );
    
      while (  ( topchild != -1 )
            && (  ( xmlNodeType ( document , topchild ) != XML_ELEMENT_NODE ) 
               || ( xmlNodeName ( document , topchild ) != "configuration" ) ) )
      {
        topchild = xmlNextSibling ( document , topchild );
        // DebugN ( "topchild = " + topchild );
      }
    }
  }
    
  if (  ( topchild == -1 )
     || ( xmlNodeName ( document , topchild ) != "configuration" ) )
  {
    fwException_raise(exceptionInfo, "ERROR", "Xml File's Top-Node must be 'contract' or 'configuration'", "");
    topchild = -1;
  }
  else
  {
    if ( xmlGetElementAttribute ( document , topchild , "name" , configName ) == -1 )
    {
      fwException_raise(exceptionInfo, "ERROR", "Xml File's 'configuration' carries no 'name' attribute", "");
      topchild = -1;
    } 
  }
  
  if ( topchild == -1 )
  {
    rtn_code = xmlCloseDocument ( document );
    // DebugN ( "rtn_code = " + rtn_code );
  }

  if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Ending fwExternalApps_readsDevicesFromXmlStr ConfNam");

  if ( topchild == -1 ) { return; }
  
  if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Starts fwExternalApps_readsDevicesFromXmlStr Analyse");
   
  rtn_code = fwXml_childNodesContent ( document , topchild ,
                   nameList , attrList , valsList , exceptionInfo );
  
  // DebugN ( "rtn_code = " + rtn_code );

  
  if ( rtn_code == 258 )
  {
    for ( int i = dynlen(nameList) ; i > 0 ; --i )
    {
      if ( nameList[i] == "#comment" ) { dynRemove(nameList,i); dynRemove(attrList,i); dynRemove(valsList,i); }
    }
    
    rtn_code = 2;
  }
  
  if ( rtn_code != 2 )
  {
    fwException_raise(exceptionInfo, "ERROR", "Xml File's 'configuration' may Only contain Elements", "");
  }
  else
  {
    int listSize = dynlen ( nameList );
    for ( int index = 1 ; index <= listSize ; ++index )
    {
      if ( ! mappingHasKey(attrList[index],fwXml_CHILDSUBTREEID) )
      {
        fwException_raise(exceptionInfo, "ERROR", "Xml File's 'configuration' may Only contain Elements", "");
        break;
      }
      
      topchild = attrList[index][fwXml_CHILDSUBTREEID];
          
      sSubscrPublicCommand = nameList[index];
      
      if      ( sSubscrPublicCommand == "subscription" ) sSubscrPublic = fwExternalApps_DATA_TYPE_SUBSCR;
      else if ( sSubscrPublicCommand == "publication" ) sSubscrPublic = fwExternalApps_DATA_TYPE_PUBLIC;
      else
      {
        fwException_raise(exceptionInfo, "ERROR", "Xml File's 'configuration' may Only contain 'subscription' and 'publication'", "");
        break;
      }

      if ( mappingHasKey(attrList[index],"name") )
         { sSubscrPublicName = attrList[index]["name"]; }
      else { sSubscrPublicName = "default"; }
      
      if ( mappingHasKey(attrList[index],"type") )
         { sSubscrPublicType = attrList[index]["type"]; }
      else { sSubscrPublicType = "multiple"; }

      rtn_code = fwXml_childNodesContent ( document , topchild ,
                       spNameList , spAttrList , spValsList , exceptionInfo );

      sBufferMode = "0";
      sOverwriteMode = "FALSE";

      int spSize = dynlen ( spNameList );
      for ( int sp = 1 ; sp <= spSize ; ++sp )
      {
        if ( spNameList[sp] == "buffer" )
        {
          sBufferMode = spValsList[sp];
          
          dynRemove(spNameList,sp);
          dynRemove(spAttrList,sp);
          dynRemove(spValsList,sp);
          --sp; --spSize;
        }
        else if ( spNameList[sp] == "overwrite" )
        {
          sOverwriteMode = spValsList[sp];
          
          dynRemove(spNameList,sp);
          dynRemove(spAttrList,sp);
          dynRemove(spValsList,sp);
          --sp; --spSize;
        }
        else if ( spNameList[sp] == "#comment" )
        {
          dynRemove(spNameList,sp);
          dynRemove(spAttrList,sp);
          dynRemove(spValsList,sp);
          --sp; --spSize;
        }
      }
      
      /* * /
      DebugN((sSubscrPublic==fwExternalApps_DATA_TYPE_SUBSCR?"Subscription":"Publication"));
      DebugN("Name   "+sSubscrPublicName);
      DebugN("Type   "+sSubscrPublicType);
      DebugN("Buffer "+sBufferMode);
      DebugN("O/W    "+(sOverwriteMode?"True":"False"));
      / * */
      
      for ( int sp = 1 ; sp <= spSize ; ++sp )
      {
        if ( spNameList[sp] != "dpe" )
        {
          fwException_raise(exceptionInfo, "WARNING", "Xml File's 'subscr/public' contains unknown '"+spNameList[sp]+"' object", "");
          next;
        }
        
        if ( ! mappingHasKey(spAttrList[sp],fwXml_CHILDSUBTREEID) )
        {
          fwException_raise(exceptionInfo, "WARNING", "Xml File's 'sunscr/public' may Only contain Elements", "");
          next;
        }

        topchild = spAttrList[sp][fwXml_CHILDSUBTREEID];

        rtn_code = fwXml_childNodesContent ( document , topchild ,
                   dpeNameList , dpeAttrList , dpeValsList , exceptionInfo );

        if ( rtn_code != 0 )
        {
          fwException_raise(exceptionInfo, "WARNING", "Xml File's 'subscr/public' contains badly-formed 'dpe' declaration", "");
          next;
        }

        mapping tempMapp;
        
        mappingClear ( tempMapp );
        
        tempMapp["name"]        = "";
        tempMapp["alias"]       = "";
        tempMapp["description"] = "";
        tempMapp["element"]     = ".";
        tempMapp["tag"]         = "default";
        tempMapp["type"]        = "";
        tempMapp["unit"]        = "";
        tempMapp["minError"]    = "";
        tempMapp["minWarn"]     = "";
        tempMapp["maxWarn"]     = "";
        tempMapp["maxError"]    = "";
        
        int dpeSize = dynlen ( dpeNameList );
        for ( int dpe = 1 ; dpe <= dpeSize ; ++dpe )
        {
          tempMapp[dpeNameList[dpe]] = dpeValsList[dpe];
        }
        
        /* * /
        string sp_idx;
        sprintf(sp_idx,"%-7d",sp);
        
        DebugN(sp_idx+"Name:     "+tempMapp["name"]);
        DebugN("       Alias:    "+tempMapp["alias"]);
        DebugN("       Descr:    "+tempMapp["description"]);
        DebugN("       Element:  "+tempMapp["element"]);
        DebugN("       Tag:      "+tempMapp["tag"]);
        DebugN("       Type:     "+tempMapp["type"]);
        DebugN("       Unit:     "+tempMapp["unit"]);
        
        DebugN("       MinError: "+tempMapp["minError"]);
        DebugN("       MinWarn:  "+tempMapp["minWarn"]);
        DebugN("       MaxWarn:  "+tempMapp["maxWarn"]);
        DebugN("       MaxError: "+tempMapp["maxError"]);
        / * */

        /*
           Note that the following logically needs to be done for each Datapoint-Element as
           first of all the Datapoint-Name needs Not to be unique for the Same Subsc/Public,
           and secondly, the Datapoint-Alias might change the outcome of the checks below!
           
           if DP-Name not empty
              if DP-Alias empty
                 do nothing
              elsif DP-Alias does Not map to an existing DP-Name
                 do nothing
              elsif DP-Alias maps to the same DP-Name
                 do nothing
              else {DP-Alias maps to a different DP-Name}
                 ignore this entry and raise an exception
           else {DP-Name empty}
              if DP-Alias empty
                 ignore this entry and raise an exception
              elsif DP-Alias does Not map to an existing DP-Name
                 ignore this entry and raise an exception
              else {DP-Alias maps to a DP-Name}
                 Use the translated DP-Name
        */
               
        dyn_string result;
          
        if ( tempMapp["name"] != "" )
        {
          if ( tempMapp["alias"] != "" )
          {
            result = dpNames("@"+tempMapp["alias"]);
            if ( ( dynlen(result) == 1 ) && ( tempMapp["name"] != result[1] ) )
            {
              fwException_raise(exceptionInfo, "WARNING", "DP-Name '"+tempMapp["name"]+"' and DP-Alias '"+tempMapp["alias"]+"' mismatched to '"+result[1]+"'", "");
              next;
            }
          }
        }
        else
        {
          if ( tempMapp["alias"] == "" )
          {
            fwException_raise(exceptionInfo, "WARNING", "Empty DP-Name and DP-Alias for Subscr/Public '"+sSubscrPublicName+"'", "");
            next;
          }    
          else
          {
            result = dpNames("@"+tempMapp["alias"]);
            if ( dynlen(result) != 1 )
            {
              fwException_raise(exceptionInfo, "WARNING", "Empty DP-Name and DP-Alias '"+tempMapp["alias"]+"' does Not Map to a DP-Name", "");
              next;
            }
            else
            {
              tempMapp["name"] = result[1];
            }
          }
        }  

        applicationData = makeDynString ( sSubscrPublic , sSubscrPublicName , sSubscrPublicType , sBufferMode , sOverwriteMode ,
                                         tempMapp["name"] , tempMapp["alias"] , tempMapp["description"] , tempMapp["element"] , 
                                         tempMapp["tag"] , tempMapp["type"] , tempMapp["unit"] ,
                                         tempMapp["minError"] , tempMapp["minWarn"] , tempMapp["maxWarn"] , tempMapp["maxError"] );
        
        dyn_string treeElems = strsplit ( tempMapp["name"] , "/" );
        fwExternalApps_insertElementInTable ( xmltable , treeElems , sSubscrPublic , applicationData , exceptionInfo );
      }
    }
  }
  
  rtn_code = xmlCloseDocument ( document );
  // DebugN ( "rtn_code = " + rtn_code );

  if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Ending fwExternalApps_readsDevicesFromXmlStr Analyse");
}


void fwExternalApps_createDevicesFromTree ( string configName , string systemType , 
                    dyn_string nodeTypes , dyn_string & exceptionInfo )
{
string dipConfigName;
int tracing = 1;
int entry = -1;
int index;
int depth;
bool enabled;
int sub_pub;
int data_size;
dyn_string elems;
string strException;
dyn_dyn_string thedata;
int maxTypeDepth = dynlen(nodeTypes);
int dp_datapoints_all = 0;
int dp_alarm_conf_all = 0;
dyn_string dpe_name_all_0 = makeDynString();
dyn_string dpe_tags_all_0 = makeDynString();
dyn_string dpe_item_all_0 = makeDynString();
dyn_string dpe_name_all_1 = makeDynString();
dyn_string dpe_tags_all_1 = makeDynString();
dyn_string dpe_item_all_1 = makeDynString();
int dpe_publ_all_0 = 0;
int dpe_publ_all_1 = 0;

  //
  // The dynamic-array 'nodeTypes' works in the following way...
  // Calculate first the depth of the Datapoint-Name
  // For depth 1 and 2, the DPs must already exist and have to be of type FwNode!
  // The array 'nodeTypes' correspond to depths 3, 4, 5, 6 ..., {last-DPT}
  // If the DPT falls outside the array or is the empty string, then the last entry in the array is taken!
  // It is as if the last DPT in the array is replicated forever...
  // An empty array is the same as an array of one DPT which corresponds in this case to FwExternalAppsNode
  //

  fwDevice_initialize();

  if ( tracing > 0 )
  {
    if ( maxTypeDepth > 0 )
    {
      DebugN("The following Levels correspond to the following Datapoint-Types");
      DebugN("Datapoint Types: '"+(string)nodeTypes+"'");
    }
  
    DebugN("DIP Configuration Name is '"+configName+"'");
    DebugN("DIP Configuration Type is '"+fwExternalApps_DIPCONFIG_TYPE+"'");
  }
  
  if ( configName == "" )
  {
    fwException_raise(exceptionInfo, "WARNING", "DIP Configuration Name Not Known!", "");
    return;
  }

  if ( dpExists(configName) == FALSE )
  {
    DebugN("Creating '"+configName+"' of type '"+fwExternalApps_DIPCONFIG_TYPE+"'");

    dpCreate ( configName , fwExternalApps_DIPCONFIG_TYPE );
    dyn_errClass errors = getLastError();
    if ( dynlen(errors) > 0 )
    {
      fwException_raise(exceptionInfo, "WARNING", "DIP Datapoint '"+configName+"' Could NOT be Created", "");
      return;
    }
  }
  
  fwDevice_setAlert ( fwExternalApps_BASE_NODE + fwDevice_HIERARCHY_SEPARATOR + systemType ,
                      fwDevice_ALERT_SET , exceptionInfo );
  
  if ( dynlen(exceptionInfo) > 0 ) { return; }

  // ++dp_alarm_conf_all;  *** don't count this one in as the DP should already exist ***
  
  while ( entry = fwExternalApps_getNextActiveFromTree ( XmlTable , entry , depth , elems , sub_pub , thedata , exceptionInfo ) )
  {
    if ( dynlen(exceptionInfo) > 0 ) { break; }
    
    data_size = dynlen(thedata);

    // This line is only here for testing the function out - It returns '1'!
    // int active = fwExternalApps_isNodeFromTreeActive ( XmlTable , elems , exceptionInfo );
    
    if ( tracing > 1 )
    {
    string datas = "No Associated DataPoint-Elements";
    
      if ( sub_pub != 0 ) { datas = "with "+(string)data_size+" Datapoint-Elements"; }
      DebugN("Tree-Node Depth "+depth+" ( "+(string)elems+" )");
      DebugN("          Entry "+entry+" - "+datas+" - "+
             (sub_pub==fwExternalApps_DATA_TYPE_NODATA?"No Subscr/Public":
             (sub_pub==fwExternalApps_DATA_TYPE_SUBSCR?"Subscriptions Only":
             (sub_pub==fwExternalApps_DATA_TYPE_PUBLIC?"Publications Only":"Subscriptions & Publications"))));
    }
    
    // 'entry' is the entry in the XmlTable but it should not be used directly
    // 'depth' and 'elems' are the depth and intermediat/final nodes of the Datapoint
    // 'sub_pub' denotes what the 'thedata' consists of - there are four possiblilities:
    //      fwExternalApps_DATA_TYPE_NODATA =  0;  // No Data Associated
    //      fwExternalApps_DATA_TYPE_SUBSCR =  1;  // Only carries Subscriptions
    //      fwExternalApps_DATA_TYPE_PUBLIC =  2;  // Only carries Publications
    //      fwExternalApps_DATA_TYPE_SUBPUB =  3;  // Subscriptions and Publications

    /*
       The DP-Name is constructed by joining the Element-Nodes in the Tree and
       it should match the DP-Names of each of the entries in the associated Data
       
       if DP-Type empty
          if DP-Type-List Defines DP-Type
             Use the DP-Type defined by the DP-Type-List
          else {DP-Type-List does Not define a DP-Type}
             Use the Default DP-Type
    */
    
    string dp_name;
    fwGeneral_dynStringToString ( elems , dp_name , fwDevice_HIERARCHY_SEPARATOR );
    
    string dp_type = "";
    
    if ( sub_pub != fwExternalApps_DATA_TYPE_NODATA )
    {
      dp_type = thedata[1][fwExternalApps_DATA_PNT_TYPNAME];
      
      if ( dp_type != "" )
      {
        // Chech that the DP-Type is identical for all entries in the associated Data
        for ( index = 2 ; index <= data_size ; ++index )
        {
          if (  ( thedata[index][fwExternalApps_DATA_PNT_TYPNAME] != "" )
             && ( dp_type != thedata[index][fwExternalApps_DATA_PNT_TYPNAME] ) ) { index = -1; break; }
        }

        if ( index == -1 )
        {
          fwException_raise(exceptionInfo, "WARNING", "DP-Name '"+dp_name+"' is associated to Two different DP-Types, Ignored", "");
          next;
        }
      }
    }
    
    if ( depth < 3 ) { dp_type = "FwNode"; }
    
    if ( ( dp_type == "" ) && ( maxTypeDepth != 0 ) )
    {
      // Check the DP-Type in the Table "nodeTypes"
      if ( depth - 2 > maxTypeDepth )
        { dp_type = nodeTypes[maxTypeDepth]; }
      else
      {
        dp_type = nodeTypes[depth-2];
        
        if ( dp_type == "" ) { dp_type = nodeTypes[maxTypeDepth]; }
      }
    }
    
    // Use the Default DP-Type if it is still not defined...
    if ( dp_type == "" ) { dp_type = "FwExternalAppsNode"; }
    
    // Check existance and possibly create the DP-Name of type DP-Type
     
    if ( tracing > 1 )
    {  
      DebugN("          Datapoint Name: '"+dp_name+"'");
      DebugN("          Datapoint Type: '"+dp_type+"'");
    }

    // Create the Datapoint if Necessary!
    
    if ( dpExists(dp_name) == FALSE )
    {
      dyn_string device, parels, parent;
      string p_name;
      
      DebugN("Creating '"+dp_name+"' of type '"+dp_type+"'");
      
      device[fwDevice_DP_NAME] = elems[dynlen(elems)];
      device[fwDevice_DP_TYPE] = dp_type;
      parels = elems;
      dynRemove(parels,dynlen(parels));
      fwGeneral_dynStringToString ( parels , p_name , fwDevice_HIERARCHY_SEPARATOR );
      parent[fwDevice_DP_NAME] = p_name;
      parent[fwDevice_DP_TYPE] = "";
      
      fwDevice_create ( device , parent , exceptionInfo );
      
      if ( dynlen(exceptionInfo) > 0 )
      {
        if ( dpExists(dp_name) == TRUE ) { dpDelete(dp_name); }
        next;
      }
      
      ++dp_datapoints_all;
      
      fwDevice_setAlert ( dp_name , fwDevice_ALERT_SET , exceptionInfo );
      
      if ( dynlen(exceptionInfo) > 0 )
      { 
        if ( dpExists(dp_name) == TRUE ) { dpDelete(dp_name); }
        next; 
      }
      
      ++dp_alarm_conf_all;
    }
    
    for ( index = 1 ; index <= data_size ; ++index )
    {
      // The following type can only be fwExternalApps_DATA_TYPE_SUBSCR or fwExternalApps_DATA_TYPE_PUBLIC
      int dpe_sort = thedata[index][fwExternalApps_DATA_SUBS_PUBL];
      int dpe_over = (thedata[index][fwExternalApps_DATA_OVER_WRITE]?1:0);
      string dpe_name = thedata[index][fwExternalApps_DATA_PNT_NAME]
                      + thedata[index][fwExternalApps_DATA_PNT_ELEMENT];
      string dpe_type = thedata[index][fwExternalApps_DATA_PNT_TYPNAME];
      
      // Use the following offsets in the data to created the appropriate Datapoint Element
      // fwExternalApps_DATA_SUBS_PUBL
      // fwExternalApps_DATA_SUBPUB_NAME
      // fwExternalApps_DATA_SUBPUB_TYPE
      // fwExternalApps_DATA_BUFF_MODE
      // fwExternalApps_DATA_OVER_WRITE
      // fwExternalApps_DATA_PNT_NAME
      // fwExternalApps_DATA_PNT_ALIAS
      // fwExternalApps_DATA_PNT_DESCRIP
      // fwExternalApps_DATA_PNT_ELEMENT
      // fwExternalApps_DATA_PNT_TAGNAME
      // fwExternalApps_DATA_PNT_TYPNAME
      // fwExternalApps_DATA_PNT_UNITS
      // fwExternalApps_DATA_PNT_MINERROR
      // fwExternalApps_DATA_PNT_MINWARN
      // fwExternalApps_DATA_PNT_MAXWARN
      // fwExternalApps_DATA_PNT_MAXERROR
      
      if ( tracing > 1 )
      {
      string stridx;
        sprintf(stridx,"DPE %-6d",index);
        
        DebugN(stridx+(thedata[index][fwExternalApps_DATA_SUBS_PUBL]==fwExternalApps_DATA_TYPE_SUBSCR?"Subscription":"Publication"));
        DebugN("          Name      "+thedata[index][fwExternalApps_DATA_SUBPUB_NAME]);
        DebugN("          Type      "+thedata[index][fwExternalApps_DATA_SUBPUB_TYPE]);
        DebugN("          Buffer    "+thedata[index][fwExternalApps_DATA_BUFF_MODE]);
        DebugN("          O/W       "+(thedata[index][fwExternalApps_DATA_OVER_WRITE]?"True":"False"));

        DebugN("dpe       Name:     "+thedata[index][fwExternalApps_DATA_PNT_NAME]);
        DebugN("          Alias:    "+thedata[index][fwExternalApps_DATA_PNT_ALIAS]);
        DebugN("          Descr:    "+thedata[index][fwExternalApps_DATA_PNT_DESCRIP]);
        DebugN("          Element:  "+thedata[index][fwExternalApps_DATA_PNT_ELEMENT]);
        DebugN("          Tag:      "+thedata[index][fwExternalApps_DATA_PNT_TAGNAME]);
        DebugN("          Type:     "+thedata[index][fwExternalApps_DATA_PNT_TYPNAME]);
        DebugN("          Unit:     "+thedata[index][fwExternalApps_DATA_PNT_UNITS]);
        
        DebugN("          MinError: "+thedata[index][fwExternalApps_DATA_PNT_MINERROR]);
        DebugN("          MinWarn:  "+thedata[index][fwExternalApps_DATA_PNT_MINWARN]);
        DebugN("          MaxWarn:  "+thedata[index][fwExternalApps_DATA_PNT_MAXWARN]);
        DebugN("          MaxError: "+thedata[index][fwExternalApps_DATA_PNT_MAXERROR]);
      }
      
      if ( dpe_sort == fwExternalApps_DATA_TYPE_SUBSCR )
      {
        if ( thedata[index][fwExternalApps_DATA_SUBPUB_TYPE] == "single" )
        {
          if ( dpe_over == 0 )
             dynAppend ( dpe_tags_all_0 , "" );
          else
             dynAppend ( dpe_tags_all_1 , "" );
        }
        else if ( thedata[index][fwExternalApps_DATA_SUBPUB_TYPE] == "multiple" )
        {
          if ( dpe_over == 0 )
             dynAppend ( dpe_tags_all_0 , thedata[index][fwExternalApps_DATA_PNT_TAGNAME] );
          else
             dynAppend ( dpe_tags_all_1 , thedata[index][fwExternalApps_DATA_PNT_TAGNAME] );
        }
        else
        {
          fwException_raise(exceptionInfo, "WARNING", "Subscription '"+dpe_name+"' has invalid Type '"
                            +thedata[index][fwExternalApps_DATA_SUBPUB_TYPE]+"'", "");
          next;
        } 
        
        if ( dpe_over == 0 )
           dynAppend ( dpe_name_all_0 , dpe_name );
        else
           dynAppend ( dpe_name_all_1 , dpe_name );
          
        if ( dpe_over == 0 )
           dynAppend ( dpe_item_all_0 , thedata[index][fwExternalApps_DATA_SUBPUB_NAME] );
        else
           dynAppend ( dpe_item_all_1 , thedata[index][fwExternalApps_DATA_SUBPUB_NAME] );
        
        if (  ( thedata[index][fwExternalApps_DATA_PNT_MINERROR] != "" )
           || ( thedata[index][fwExternalApps_DATA_PNT_MINWARN]  != "" )
           || ( thedata[index][fwExternalApps_DATA_PNT_MAXWARN]  != "" )
           || ( thedata[index][fwExternalApps_DATA_PNT_MAXERROR] != "" ) )
        {
        dyn_float alertLimits = makeDynFloat();
        dyn_string alertTexts = makeDynString();
        dyn_string alertClasses = makeDynString();

          if ( thedata[index][fwExternalApps_DATA_PNT_MINERROR] != "" )
          {
            dynAppend ( alertLimits , thedata[index][fwExternalApps_DATA_PNT_MINERROR] );
            dynAppend ( alertTexts , "Exceeded minimum error threshold" );
            dynAppend ( alertClasses , "_fwErrorAck." );
          }

          if ( thedata[index][fwExternalApps_DATA_PNT_MINWARN] != "" )
          {
            dynAppend ( alertLimits , thedata[index][fwExternalApps_DATA_PNT_MINWARN] );
            dynAppend ( alertTexts , "Exceeded minimum warning threshold" );
            dynAppend ( alertClasses , "_fwWarningAck." );
          }
        
          dynAppend(alertTexts, "OK");
          dynAppend(alertClasses, "");
          
          if ( thedata[index][fwExternalApps_DATA_PNT_MAXWARN] != "" )
          {
            dynAppend ( alertLimits , thedata[index][fwExternalApps_DATA_PNT_MAXWARN] );
            dynAppend ( alertTexts , "Exceeded maximum warning threshold" );
            dynAppend ( alertClasses , "_fwWarningAck." );
          }
        
          if ( thedata[index][fwExternalApps_DATA_PNT_MAXERROR] != "" )
          {
            dynAppend ( alertLimits , thedata[index][fwExternalApps_DATA_PNT_MAXERROR] );
            dynAppend ( alertTexts , "Exceeded maximum error threshold" );
            dynAppend ( alertClasses , "_fwErrorAck." );
          }
        
          fwAlertConfig_set ( dpe_name , DPCONFIG_ALERT_NONBINARYSIGNAL ,
                              alertTexts , alertLimits , alertClasses ,
                              makeDynString() , "" , makeDynString() , "" ,
                              strException , TRUE , TRUE , "." );
        }
      }
      else if ( dpe_sort == fwExternalApps_DATA_TYPE_PUBLIC )
      {
        if ( dpe_over == 0 ) { ++dpe_publ_all_0; } else { ++dpe_publ_all_1; }
        
        if ( thedata[index][fwExternalApps_DATA_SUBPUB_TYPE] == "single" )
        {
          fwDIP_publishPrimitive (
              thedata[index][fwExternalApps_DATA_SUBPUB_NAME] ,
              makeDynString(dpe_name) ,
              thedata[index][fwExternalApps_DATA_BUFF_MODE] ,
              configName , strException , 
              (thedata[index][fwExternalApps_DATA_OVER_WRITE]?TRUE:FALSE) );
        }
        else if ( thedata[index][fwExternalApps_DATA_SUBPUB_TYPE] == "multiple" )
        {
          fwDIP_publishStructure (
              thedata[index][fwExternalApps_DATA_SUBPUB_NAME] ,
              makeDynString(dpe_name) ,
              thedata[index][fwExternalApps_DATA_PNT_TAGNAME] ,
              thedata[index][fwExternalApps_DATA_BUFF_MODE] ,
              configName , strException , 
              (thedata[index][fwExternalApps_DATA_OVER_WRITE]?TRUE:FALSE) );
        }
        else
        {
          fwException_raise(exceptionInfo, "WARNING", "Publication '"+dpe_name+"' has invalid Type '"
                            +thedata[index][fwExternalApps_DATA_SUBPUB_TYPE]+"'", "");
          next;
        } 
      }
        
      if ( thedata[index][fwExternalApps_DATA_PNT_DESCRIP] != "" )
         { dpSetDescription ( dpe_name , thedata[index][fwExternalApps_DATA_PNT_DESCRIP] ); }
      
      if ( thedata[index][fwExternalApps_DATA_PNT_UNITS] != "" )
         { dpSetUnit ( dpe_name , thedata[index][fwExternalApps_DATA_PNT_UNITS] ); }
    }
  }
  
  if ( dynlen(exceptionInfo) > 0 ) { return; }

  if ( tracing > 0 ) DebugN("Number of Overall PVSS Datapoints Created are '"+dp_datapoints_all+"'");
  if ( tracing > 0 ) DebugN("Number of DP Alarm Configurations Created are '"+dp_alarm_conf_all+"'");

  if ( tracing > 0 ) DebugN("Number of Subscriptions [Overwrite=False] is '"+dynlen(dpe_name_all_0)+"'");
  
  fwDIP_subscribeMany ( dpe_name_all_0 , configName , dpe_item_all_0 , dpe_tags_all_0 ,
                        exceptionInfo , FALSE );

  if ( tracing > 0 ) DebugN("Number of Subscriptions [Overwrite=True] is  '"+dynlen(dpe_name_all_1)+"'");

  fwDIP_subscribeMany ( dpe_name_all_1 , configName , dpe_item_all_1 , dpe_tags_all_1 ,
                        exceptionInfo , TRUE );
  
  if ( tracing > 0 ) DebugN("Number of Publications [Overwrite=False] is '"+dpe_publ_all_0+"'");
  if ( tracing > 0 ) DebugN("Number of Publications [Overwrite=True] is  '"+dpe_publ_all_1+"'");
}
    

int _fwExternalApps_insertDataElement ( dyn_dyn_anytype & tbl , int entry , dyn_string elems , 
                                        int sub_pub , dyn_anytype thedata , 
                                        dyn_string & exceptionInfo )
{
int eleml = dynlen(elems);
int child,lastc;
int error = 0;
string elemt;

  if ( eleml < 1 ) { return(-1); }

  // The top-root entry in the tree is '1'
  if ( entry < 1 ) { entry = 1; }
  
  if ( eleml == 1 )
  {
    // Deal with the leaf element
    
    elemt = elems[1];
    child = tbl[entry][fwExternalApps_FRST_CHILD_INDEX];

    if ( child == 0 )
    {
      // Adding leaf element as the only child
      child = _fwExternalApps_createNewTableEntry(tbl, elemt);
      tbl[entry][fwExternalApps_FRST_CHILD_INDEX] = child;
      tbl[entry][fwExternalApps_LAST_CHILD_INDEX] = child;
    
      tbl[child][fwExternalApps_PARENTNODE_INDEX] = entry;
      tbl[child][fwExternalApps_ELEM_ACTIV_INDEX] = 1;
      _fwExternalApps_mergeDataInTable(tbl, child, sub_pub, thedata);
      
      for ( int part = entry ; part != 0 ; part = tbl[part][fwExternalApps_PARENTNODE_INDEX] )
      {
        ++tbl[part][fwExternalApps_CHILDN_ACT_INDEX];
        ++tbl[part][fwExternalApps_NBCHILDREN_INDEX];
      }
    }
    else
    {
      // Search for the existance of the child
      while ( child != 0 )
      {
        if ( tbl[child][fwExternalApps_TREE_ELEMT_INDEX] == elemt ) { break; }
        lastc = child;
        child = tbl[child][fwExternalApps_NEXT_SIBLG_INDEX];
      }
      
      if ( child == 0 )
      {
        // Adding leaf element as a new sibling
        child = _fwExternalApps_createNewTableEntry(tbl, elemt);
        tbl[entry][fwExternalApps_LAST_CHILD_INDEX] = child;

        tbl[lastc][fwExternalApps_NEXT_SIBLG_INDEX] = child;
      
        tbl[child][fwExternalApps_PREV_SIBLG_INDEX] = lastc;
        tbl[child][fwExternalApps_PARENTNODE_INDEX] = entry;
        tbl[child][fwExternalApps_ELEM_ACTIV_INDEX] = 1;
        _fwExternalApps_mergeDataInTable(tbl, child, sub_pub, thedata);
        
        for ( int part = entry ; part != 0 ; part = tbl[part][fwExternalApps_PARENTNODE_INDEX] )
        {
          ++tbl[part][fwExternalApps_CHILDN_ACT_INDEX];
          ++tbl[part][fwExternalApps_NBCHILDREN_INDEX];
        }
      }
      else
      {
        _fwExternalApps_mergeDataInTable(tbl, child, sub_pub, thedata);
      }
    }    
  }
  else
  {
    // More than one elements in the path
    
    elemt = elems[1];
    child = tbl[entry][fwExternalApps_FRST_CHILD_INDEX];
    
    if ( child == 0 )
    {
      // Adding node element as the only child
      child = _fwExternalApps_createNewTableEntry(tbl, elemt);
      tbl[entry][fwExternalApps_FRST_CHILD_INDEX] = child;
      tbl[entry][fwExternalApps_LAST_CHILD_INDEX] = child;
    
      tbl[child][fwExternalApps_PARENTNODE_INDEX] = entry;
      tbl[child][fwExternalApps_ELEM_ACTIV_INDEX] = 1;
      
      for ( int part = entry ; part != 0 ; part = tbl[part][fwExternalApps_PARENTNODE_INDEX] )
      {
        ++tbl[part][fwExternalApps_CHILDN_ACT_INDEX];
        ++tbl[part][fwExternalApps_NBCHILDREN_INDEX];
      }
      
      dynRemove(elems,1);
      error = _fwExternalApps_insertDataElement(tbl, child, elems, sub_pub, thedata, exceptionInfo);
    }
    else
    {
      // Search for the existance of the child
      while ( child != 0 )
      {
        if ( tbl[child][fwExternalApps_TREE_ELEMT_INDEX] == elemt ) { break; }
        lastc = child;
        child = tbl[child][fwExternalApps_NEXT_SIBLG_INDEX];
      }
      
      if ( child == 0 )
      {
        // Adding node element as a new sibling
  
        child = _fwExternalApps_createNewTableEntry(tbl, elemt);
        tbl[entry][fwExternalApps_LAST_CHILD_INDEX] = child;

        tbl[lastc][fwExternalApps_NEXT_SIBLG_INDEX] = child;
      
        tbl[child][fwExternalApps_PREV_SIBLG_INDEX] = lastc;
        tbl[child][fwExternalApps_PARENTNODE_INDEX] = entry;
        tbl[child][fwExternalApps_ELEM_ACTIV_INDEX] = 1;
        
        for ( int part = entry ; part != 0 ; part = tbl[part][fwExternalApps_PARENTNODE_INDEX] )
        {
          ++tbl[part][fwExternalApps_CHILDN_ACT_INDEX];
          ++tbl[part][fwExternalApps_NBCHILDREN_INDEX];
        }
      }    

      dynRemove(elems,1);
      error = _fwExternalApps_insertDataElement(tbl, child, elems, sub_pub, thedata, exceptionInfo);
    }  
  }
  
  return ( error );
}


int fwExternalApps_insertElementInTable ( dyn_dyn_anytype & tbl, dyn_string elems , 
                                          int sub_pub , dyn_anytype thedata , 
                                          dyn_string & exceptionInfo )
{
int error;

  if ( dynlen ( tbl ) == 0 )
  {
    fwException_raise(exceptionInfo, "WARNING", "Table into which Data is Inserted is Not Initialised!", "");
    error = -1;
  }
  else if ( tbl[1][fwExternalApps_NODES_DATA_INDEX] == 0 )
  {
    fwException_raise(exceptionInfo, "WARNING", "Table Already Displayed in Tree - No Further Data Insertion Possible!", "");
    error = -1;
  }
  else
  {
    error = _fwExternalApps_insertDataElement(tbl, -1, elems, sub_pub, thedata, exceptionInfo);
  }
  
  return ( error );
}
  

void _fwExternalApps_mergeDataInTable(dyn_dyn_anytype & tbl, int entry, 
                                      int sub_pub, dyn_anytype thedata)
{
int index = 0;
dyn_dyn_anytype all_data;

  if ( sub_pub == fwExternalApps_DATA_TYPE_NODATA ) return;
  
  if ( tbl[entry][fwExternalApps_NODESUBPUB_INDEX] == fwExternalApps_DATA_TYPE_NODATA )
  {
    tbl[entry][fwExternalApps_NODESUBPUB_INDEX] = sub_pub;
    all_data = makeDynAnytype();
  }
  else
  {
    if ( sub_pub != tbl[entry][fwExternalApps_NODESUBPUB_INDEX] )
    {
      tbl[entry][fwExternalApps_NODESUBPUB_INDEX] = fwExternalApps_DATA_TYPE_SUBPUB;
    }
    
    all_data = tbl[entry][fwExternalApps_NODES_DATA_INDEX];
    index = dynlen ( all_data );
  }
  
  all_data[index+1] = thedata;
  
  tbl[entry][fwExternalApps_NODES_DATA_INDEX] = all_data;
}


void fwExternalApps_showNodeDescription ( string treename , dyn_dyn_anytype & inf , 
                                          dyn_dyn_anytype & tbl , string id , int column )
{
shape tree = getShape(treename);
dyn_string exceptionInfo;
int entry = (int)id;
dyn_dyn_string data;
dyn_string elems;
int length;

  if ( column != 0 )
    tree.clear();
  else if ( tbl[entry][fwExternalApps_NODESUBPUB_INDEX] == fwExternalApps_DATA_TYPE_NODATA )
    tree.clear();
  else
  {
    data = tbl[entry][fwExternalApps_NODES_DATA_INDEX];

    length = dynlen(data);
    
    fwExternalApps_initialiseTable ( inf , exceptionInfo );
    
    for ( int idx = 1 ; idx <= length ; ++idx )
    {
      string subpub = ( data[idx][fwExternalApps_DATA_SUBS_PUBL] == fwExternalApps_DATA_TYPE_SUBSCR ? "Subscription: " : 
                      ( data[idx][fwExternalApps_DATA_SUBS_PUBL] == fwExternalApps_DATA_TYPE_PUBLIC ? "Publication: " : "Unknown - Bug! " ) );
      
      elems = makeDynString(subpub + data[idx][fwExternalApps_DATA_SUBPUB_NAME],
                            data[idx][fwExternalApps_DATA_PNT_TAGNAME],
                            "DP-Element: " + data[idx][fwExternalApps_DATA_PNT_ELEMENT]);
      
      fwExternalApps_insertElementInTable ( inf , elems, fwExternalApps_DATA_TYPE_NODATA , "" , exceptionInfo );

      
      elems = makeDynString(subpub + data[idx][fwExternalApps_DATA_SUBPUB_NAME],
                            data[idx][fwExternalApps_DATA_PNT_TAGNAME],
                            data[idx][fwExternalApps_DATA_PNT_DESCRIP]);
            
      fwExternalApps_insertElementInTable ( inf , elems, fwExternalApps_DATA_TYPE_NODATA , "" , exceptionInfo );
    }
    
    fwExternalApps_populateTree ( treename , inf , exceptionInfo , 0 );
  }
} 


/*
  
  The following routines initialise and populate the Tree
  
  fwExternalApps_initialiseTree is only called once at initialisation
  
  fwExternalApps_populateTree is called every time the Tree needs to be populated from scratch
  _fwExternalApps_populateSubTree is recursively called from the fwExternalApps_populateTree global routine
  
*/


void fwExternalApps_initialiseTree ( string treename , int mainTree = 1 )
{
int full_tree_width;
shape tree = getShape ( treename );

  tree.clear();
  
  tree.hScrollBarMode("Auto");
  tree.vScrollBarMode("Auto");
   
  tree.resizeMode("AllColumns");
  
  tree.selectionMode("Single");
    
  full_tree_width = tree.width();
    
  if ( mainTree )
  {
    if ( fwExternalApps_DISPLAY_EXPANDED )
    {
      tree.addColumn ( "Tree Nodes & Leafs" );
      tree.addColumn ( "   Active" );
      tree.addColumn ( "    S/P" );
      tree.addColumn ( "     All" );
      tree.addColumn ( "   Some" );
      tree.addColumn ( "   None" );
    
      tree.setColumnWidth ( fwExternalApps_COLUMN_MAIN , full_tree_width - 280 - 5 );
      tree.setColumnWidth ( fwExternalApps_COLUMN__ACT , 60 );
      tree.setColumnWidth ( fwExternalApps_COLUMN_SUBS , 55 );
      tree.setColumnWidth ( fwExternalApps_COLUMN__ALL , 55 );
      tree.setColumnWidth ( fwExternalApps_COLUMN_SOME , 55 );
      tree.setColumnWidth ( fwExternalApps_COLUMN_NONE , 55 );
    }
    else
    {
      tree.addColumn ( "Tree Nodes & Leafs" );
      tree.addColumn ( "   Active" );
      tree.addColumn ( "    S/P" );
    
      tree.setColumnWidth ( fwExternalApps_COLUMN_MAIN , full_tree_width - 115 - 5 );
      tree.setColumnWidth ( fwExternalApps_COLUMN__ACT , 60 );
      tree.setColumnWidth ( fwExternalApps_COLUMN_SUBS , 55 );
    }
  }
  else
  {
    tree.showHeader(FALSE);
    
    tree.addColumn ( "Node's Description [Subs/Publ-Name Tag-Name Element-and-Description]" );
    
    tree.setColumnWidth ( fwExternalApps_COLUMN_MAIN , full_tree_width - 5 );
  }
}    
    
    
int _fwExternalApps_populateSubTree ( int mainTree , shape tree , dyn_dyn_anytype & tbl , int entry , dyn_string & exceptionInfo )
{
string parentstr;

  while ( entry != 0 )
  {
    parentstr = (string)tbl[entry][fwExternalApps_PARENTNODE_INDEX];
    if ( parentstr == "1" ) { parentstr = ""; }
    
    // DebugN("Append '"+entry+"' to Parent '"+parentstr+"'");
    
    tree.appendItem ( parentstr , (string)entry , tbl[entry][fwExternalApps_TREE_ELEMT_INDEX] );
    tree.setOpen( (string)entry , TRUE );
    
    if ( mainTree )
    {
      tree.setIcon( (string)entry , fwExternalApps_COLUMN__ACT , fwExternalApps_COLUMN_ASSERT_ICON );
      _fwExternalApps_assertTreeColumn ( tree , tbl , entry );
      
      int dattyp = tbl[entry][fwExternalApps_NODESUBPUB_INDEX];
      string datstr = ( dattyp == fwExternalApps_DATA_TYPE_NODATA ? "       -" :
                      ( dattyp == fwExternalApps_DATA_TYPE_SUBSCR ? "  Subscr" :
                      ( dattyp == fwExternalApps_DATA_TYPE_PUBLIC ? " Publicat" : 
                      ( dattyp == fwExternalApps_DATA_TYPE_SUBPUB ? " Sub/Pub" : "    Bug!" ) ) ) );
      tree.setText( (string)entry , fwExternalApps_COLUMN_SUBS , datstr );
    }
    
    _fwExternalApps_populateSubTree ( mainTree , tree , tbl , tbl[entry][fwExternalApps_FRST_CHILD_INDEX] , exceptionInfo );
    
    entry = tbl[entry][fwExternalApps_NEXT_SIBLG_INDEX];
  }
  
  return ( 0 );
}
                     
                                 
int fwExternalApps_populateTree ( string treename , dyn_dyn_anytype & tbl , dyn_string & exceptionInfo , int mainTree = 1 )
{
int error = 0;
int first_child;
shape tree = getShape ( treename );
  
  if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Starts fwExternalApps_populateTree");

  tree.clear();
  
  if ( dynlen ( tbl ) == 0 )
  {
    fwException_raise(exceptionInfo, "WARNING", "Table to be Displayed in Tree Widget is Not Initialised!", "");
    error = -1;
  }
  else if ( ( first_child = tbl[1][fwExternalApps_FRST_CHILD_INDEX] ) == 0 )
  {
    // DebugN("### Table to be Displayed in Tree Widget is Empty! ###");

    fwException_raise(exceptionInfo, "WARNING", "Table to be Displayed in Tree Widget is Empty!", "");
    error = -1;
  }
  else
  {
    // This Flag is Cleared because the Tree Widget Gets Now Populated
    // This Flag is Set when the Table Gets Initialised for Data Insertion
    tbl[1][fwExternalApps_NODES_DATA_INDEX] = 0;
    
    error = _fwExternalApps_populateSubTree ( mainTree , tree , tbl , first_child , exceptionInfo );
  }
  
  if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Ending fwExternalApps_populateTree");
    
  return ( error );
}


/*
  
  The following routines are specific for interogating the individual Tree widget's Nodes conditions
  
  fwExternalApps_isNodeFromTreeActive to check if a particular Node in the Tree is active

  fwExternalApps_getNextActiveFromTree to get the next active Node in the Tree
  
  fwExternalApps_getNextNodeFromTree to get the next Node in the Tree
  
*/


int fwExternalApps_isNodeFromTreeActive ( dyn_dyn_anytype & tbl , dyn_string elems , dyn_string & exceptionInfo )
{
int length;
string elemt;
int child;
int entry = 1;
bool active = -1;

  for ( length = dynlen(elems) ; length != 0 ; --length )
  {
    elemt = elems[1];
    child = tbl[entry][fwExternalApps_FRST_CHILD_INDEX];
    while ( child != 0 )
    {
      if ( tbl[child][fwExternalApps_TREE_ELEMT_INDEX] == elemt ) { break; }
      child = tbl[child][fwExternalApps_NEXT_SIBLG_INDEX];
    }
    if ( child == 0 ) break;
    dynRemove(elems,1);
    entry = child;
  }
  
  if ( child != 0 ) active = tbl[entry][fwExternalApps_ELEM_ACTIV_INDEX];
  else
  {
    fwException_raise(exceptionInfo, "WARNING", "Node '"+(string)elems+"' could Not be Found in the Tree!", "");
  }
  return ( active );
}
    

int fwExternalApps_getNextActiveFromTree ( dyn_dyn_anytype & tbl , int entry , int & depth , dyn_string & elems ,
                                           int & sub_pub , dyn_dyn_anytype & thedata , dyn_string & exceptionInfo )
{
int next,part;
  
  // The top-root entry in the tree is '1'
  if ( entry < 1 ) { entry = 1; if ( dynlen ( tbl ) == 0 ) return ( 0 ); }
  
  do
  {
    if (  ( ( next = tbl[entry][fwExternalApps_FRST_CHILD_INDEX] ) == 0 )
       && ( ( next = tbl[entry][fwExternalApps_NEXT_SIBLG_INDEX] ) == 0 ) )
    {
      if ( entry == 1 ) return ( 0 );
    
      while ( next == 0 )
      {
        entry = tbl[entry][fwExternalApps_PARENTNODE_INDEX];
     
        if ( entry == 1 ) return ( 0 );
     
        next = tbl[entry][fwExternalApps_NEXT_SIBLG_INDEX];
      }
    }
  
    entry = next;
  }
  while ( tbl[entry][fwExternalApps_ELEM_ACTIV_INDEX] == 0 );
  
  part = entry;
  elems = makeDynString();
  for ( depth = 0 ; part != 1 ; ++depth )
  {
    dynInsertAt(elems,tbl[part][fwExternalApps_TREE_ELEMT_INDEX],1);
    part = tbl[part][fwExternalApps_PARENTNODE_INDEX];
  }
  
  // enabled = ( tbl[entry][fwExternalApps_ELEM_ACTIV_INDEX] == 0 ? FALSE : TRUE );
      
  sub_pub = tbl[entry][fwExternalApps_NODESUBPUB_INDEX];
  
  if ( sub_pub != fwExternalApps_DATA_TYPE_NODATA )
  {
    thedata = tbl[entry][fwExternalApps_NODES_DATA_INDEX];
  }
  
  return ( entry );
}


int fwExternalApps_getNextNodeFromTree ( dyn_dyn_anytype & tbl , int entry , int & depth , dyn_string & elems ,
                                          bool & enabled , int & sub_pub , dyn_dyn_anytype & thedata , dyn_string & exceptionInfo )
{
int next,part;
  
  // The top-root entry in the tree is '1'
  if ( entry < 1 ) { entry = 1; if ( dynlen ( tbl ) == 0 ) return ( 0 ); }
  
  if (  ( ( next = tbl[entry][fwExternalApps_FRST_CHILD_INDEX] ) == 0 )
     && ( ( next = tbl[entry][fwExternalApps_NEXT_SIBLG_INDEX] ) == 0 ) )
  {
    if ( entry == 1 ) return ( 0 );
    
    while ( next == 0 )
    {
      entry = tbl[entry][fwExternalApps_PARENTNODE_INDEX];
     
      if ( entry == 1 ) return ( 0 );
     
      next = tbl[entry][fwExternalApps_NEXT_SIBLG_INDEX];
    }
  }
  
  entry = next;
  
  part = entry;
  elems = makeDynString();
  for ( depth = 0 ; part != 1 ; ++depth )
  {
    dynInsertAt(elems,tbl[part][fwExternalApps_TREE_ELEMT_INDEX],1);
    part = tbl[part][fwExternalApps_PARENTNODE_INDEX];
  }
  
  enabled = ( tbl[entry][fwExternalApps_ELEM_ACTIV_INDEX] == 0 ? FALSE : TRUE );
      
  sub_pub = tbl[entry][fwExternalApps_NODESUBPUB_INDEX];
  
  if ( sub_pub != fwExternalApps_DATA_TYPE_NODATA )
  {
    thedata = tbl[entry][fwExternalApps_NODES_DATA_INDEX];
  }
  
  return ( entry );
}


/*
  
  The following routines are specific for the handling of operations onto a Tree widget structure
  
  fwExternalApps_openTree & _fwExternalApps_openSubTree to Collaps and Expand the Tree widget's structure
  
  fwExternalApps_treeRowColumnClicked when one clicks a row-column combination in the Tree widget's structure
  
  _fwExternalApps_activateCurrentNode & _fwExternalApps_activateAllBelow when one activates a Node in the Tree
  
  _fwExternalApps_desactivateCurrentNode & _fwExternalApps_desactivateAllBelow when one desactivates a Node in the Tree

  _fwExternalApps_assertTreeColumn asserts a Tree Column in the Tree widget's structure
  
*/
  
  
void _fwExternalApps_openSubTree ( shape tree , dyn_dyn_anytype & tbl , bool openTree , int entry )
{
  for ( int child = tbl[entry][fwExternalApps_FRST_CHILD_INDEX] ; child != 0 ; child = tbl[child][fwExternalApps_NEXT_SIBLG_INDEX] )
  {
    tree.setOpen( (string)child , openTree );
  
    _fwExternalApps_openSubTree ( tree , tbl , openTree , child );
  }
}


void fwExternalApps_openTree ( string treename , dyn_dyn_anytype & tbl , bool openTree , int entry = 1 )
{
shape tree = getShape ( treename );

  // _fwExternalApps_printTable ( tbl );

  if ( dynlen ( tbl ) != 0 )
  {
    tree.setOpen( ( entry == 1 ? "" : (string)entry ) , openTree );
  
    _fwExternalApps_openSubTree ( tree , tbl , openTree , entry );
  }
}      


void fwExternalApps_treeRowColumnClicked ( string treename , dyn_dyn_anytype & tbl , string id , int column )
{
shape tree = getShape ( treename );
int entry = (int)id;

  switch ( column )
  {
    case fwExternalApps_COLUMN_MAIN:
    {
      // Clicked on the Tree-Node lable - Display information related to this Item
      int x0 = 0;
    }
    break;
    case fwExternalApps_COLUMN_SUBS:
    {
      // Clicked on the Subscription/Publication column - do nothing yet
      int x1 = 0;
    }
    break;
    case fwExternalApps_COLUMN__ACT:
    {
      // Clicked on the Node-Active column
      if ( tbl[entry][fwExternalApps_ELEM_ACTIV_INDEX] == 0 )
      {
        _fwExternalApps_activateCurrentNode ( tree , tbl , entry );
      }
      else
      {
        _fwExternalApps_desactivateCurrentNode ( tree , tbl , entry );
      }
    }
    break;
    case fwExternalApps_COLUMN__ALL:
    {
      // Clicked on the Include-All column
      // if (  ( tbl[entry][fwExternalApps_NBCHILDREN_INDEX] != 0 )
      //    && ( tbl[entry][fwExternalApps_CHILDN_ACT_INDEX] != tbl[entry][fwExternalApps_NBCHILDREN_INDEX] ) )
      // {
      //   _fwExternalApps_activateAllChildrenOfNode ( tree , tbl , entry );
      // }

      // Clicked on the Include-Some column - do nothing yet
      int x3 = 0;
    }
    break;
    case fwExternalApps_COLUMN_SOME:
    {
      // Clicked on the Include-Some column - do nothing yet
      int x4 = 0;
    }
    break;
    case fwExternalApps_COLUMN_NONE:
    {
      // Clicked on the Include-None column
      // if (  ( tbl[entry][fwExternalApps_NBCHILDREN_INDEX] != 0 )
      //    && ( tbl[entry][fwExternalApps_CHILDN_ACT_INDEX] != 0 ) )
      // {
      //   _fwExternalApps_desactivateAllChildrenOfNode ( tree , tbl , entry );
      // }
        
      // Clicked on the Include-Some column - do nothing yet
      int x5 = 0;
    }
    break;
    default:
    {
      DebugN("### Bug in XmlTable widget - Column '"+column+"' can Never be Clicked!");
    }
    break;
  }
}


void _fwExternalApps_activateAllBelow ( shape tree , dyn_dyn_anytype & tbl , int entry )
{
  tbl[entry][fwExternalApps_ELEM_ACTIV_INDEX] = 1;
  
  tbl[entry][fwExternalApps_CHILDN_ACT_INDEX] = tbl[entry][fwExternalApps_NBCHILDREN_INDEX];
  
  tree.setIcon( (string)entry , fwExternalApps_COLUMN__ACT , fwExternalApps_COLUMN_ASSERT_ICON );
  _fwExternalApps_assertTreeColumn ( tree , tbl , entry );
  
  for ( int child = tbl[entry][fwExternalApps_FRST_CHILD_INDEX] ; child != 0 ; child = tbl[child][fwExternalApps_NEXT_SIBLG_INDEX] )
  {
    _fwExternalApps_activateAllBelow ( tree , tbl , child );
  }
}

  
// This routine is Only called if the Current Node is Not Already Activated

void _fwExternalApps_activateCurrentNode ( shape tree , dyn_dyn_anytype & tbl , int entry )
{
int children_active;

  children_active = 1 + tbl[entry][fwExternalApps_NBCHILDREN_INDEX] - tbl[entry][fwExternalApps_CHILDN_ACT_INDEX];
  
  _fwExternalApps_activateAllBelow ( tree , tbl , entry );
  
  entry = tbl[entry][fwExternalApps_PARENTNODE_INDEX];
    
  while ( entry != 0 )
  {
    tbl[entry][fwExternalApps_CHILDN_ACT_INDEX] += children_active;
    
    if ( tbl[entry][fwExternalApps_ELEM_ACTIV_INDEX] == 0 )
    {
      tbl[entry][fwExternalApps_ELEM_ACTIV_INDEX] = 1; ++children_active;
      if ( entry != 1 ) tree.setIcon( (string)entry , fwExternalApps_COLUMN__ACT , fwExternalApps_COLUMN_ASSERT_ICON );
    }
    
    _fwExternalApps_assertTreeColumn ( tree , tbl , entry );
    
    entry = tbl[entry][fwExternalApps_PARENTNODE_INDEX];
  }
  
  // _fwExternalApps_printTable ( tbl );
}    
      
      
void _fwExternalApps_desactivateAllBelow ( shape tree , dyn_dyn_anytype & tbl , int entry )
{
  tbl[entry][fwExternalApps_ELEM_ACTIV_INDEX] = 0;
  
  tbl[entry][fwExternalApps_CHILDN_ACT_INDEX] = 0;
  
  tree.setIcon( (string)entry , fwExternalApps_COLUMN__ACT , fwExternalApps_COLUMN_DELETE_ICON );
  _fwExternalApps_assertTreeColumn ( tree , tbl , entry );

  for ( int child = tbl[entry][fwExternalApps_FRST_CHILD_INDEX] ; child != 0 ; child = tbl[child][fwExternalApps_NEXT_SIBLG_INDEX] )
  {
    _fwExternalApps_desactivateAllBelow ( tree , tbl , child );
  }
}

  
// This routine is Only called if the Current Node is Already Activated

void _fwExternalApps_desactivateCurrentNode ( shape tree , dyn_dyn_anytype & tbl , int entry )
{
int children_desact;

  children_desact = 1 + tbl[entry][fwExternalApps_CHILDN_ACT_INDEX];

  _fwExternalApps_desactivateAllBelow ( tree , tbl , entry );
  
  entry = tbl[entry][fwExternalApps_PARENTNODE_INDEX];

  while ( entry != 0 )
  {
    tbl[entry][fwExternalApps_CHILDN_ACT_INDEX] -= children_desact;
    
    if (  ( tbl[entry][fwExternalApps_ELEM_ACTIV_INDEX] != 0 )
       && ( tbl[entry][fwExternalApps_CHILDN_ACT_INDEX] == 0 )
       && ( tbl[entry][fwExternalApps_NODESUBPUB_INDEX] == fwExternalApps_DATA_TYPE_NODATA ) )
    {
      tbl[entry][fwExternalApps_ELEM_ACTIV_INDEX] = 0; ++children_desact;
      if ( entry != 1 ) tree.setIcon( (string)entry , fwExternalApps_COLUMN__ACT , fwExternalApps_COLUMN_DELETE_ICON );
    }
    
    _fwExternalApps_assertTreeColumn ( tree , tbl , entry );
    
    entry = tbl[entry][fwExternalApps_PARENTNODE_INDEX];
  }
  
  // _fwExternalApps_printTable ( tbl );
}    
      

void _fwExternalApps_assertTreeColumn ( shape tree , dyn_dyn_anytype & tbl, int entry )
{
int column = -1;
int nbchildren = tbl[entry][fwExternalApps_NBCHILDREN_INDEX];
int childn_act = tbl[entry][fwExternalApps_CHILDN_ACT_INDEX];
    
  if ( entry == 1 ) { return; }
  
  if ( nbchildren == 0 )
  {
    if ( childn_act != 0 )
    {
      DebugN("### Software Error: Tree Table Entry '"+entry+"' Should have Zero Number of Active Children!");
      tree.setText ( (string)entry , fwExternalApps_COLUMN__ACT , "  Bug!" );
      _fwExternalApps_printTable ( tbl );
    }
    else
    {
      tree.setText ( (string)entry , fwExternalApps_COLUMN__ACT , "      -" );
    }
    column = 0;
  }
  else if ( childn_act < 0 )
  {
    DebugN("### Software Error: Tree Table Entry '"+entry+"' Contains Negative Number of Active Children!");
    tree.setText ( (string)entry , fwExternalApps_COLUMN__ACT , "  Bug!" );
    _fwExternalApps_printTable ( tbl );
    column = 0;
  }
  else if ( childn_act == 0 )
  {
    tree.setText ( (string)entry , fwExternalApps_COLUMN__ACT , "  None" );
    column = fwExternalApps_COLUMN_NONE;
  }
  else if ( childn_act == nbchildren )
  {
    tree.setText ( (string)entry , fwExternalApps_COLUMN__ACT , "    All" );
    column = fwExternalApps_COLUMN__ALL;
  }
  else if ( childn_act > nbchildren )
  {
    DebugN("### Software Error: Tree Table Entry '"+entry+"' Contains a Too High Number of Active Children!");
    tree.setText ( (string)entry , fwExternalApps_COLUMN__ACT , "  Bug!" );
    _fwExternalApps_printTable ( tbl );
    column = 0;
  }
  else
  {
    tree.setText ( (string)entry , fwExternalApps_COLUMN__ACT , "  Some" );
    column = fwExternalApps_COLUMN_SOME;
  }
  
  if ( fwExternalApps_DISPLAY_EXPANDED )
  {
    tree.setText ( (string)entry , fwExternalApps_COLUMN__ALL , ( column == 0 ? "          " : 
                   ( column == fwExternalApps_COLUMN__ALL ? "       X" : "        -" ) ) );
    tree.setText ( (string)entry , fwExternalApps_COLUMN_SOME , ( column == 0 ? "          " : 
                   ( column == fwExternalApps_COLUMN_SOME ? "       X" : "        -" ) ) );
    tree.setText ( (string)entry , fwExternalApps_COLUMN_NONE , ( column == 0 ? "          " : 
                   ( column == fwExternalApps_COLUMN_NONE ? "       X" : "        -" ) ) );
  }
}


/*   The following functions are the old calls which are using the GCS sub-routines
     
fwExternalApps_createDevicesFromFile(string configurationFilePath, string systemType, dyn_string intermediateNodeTypes,
                                     dyn_string intermediateNodeLevels, dyn_string &exceptionInfo,
                                     dyn_string variables = "", dyn_string substitutions = "")
{
  string xmlFileContents;
  string dipConfigName;

  fwExternalApps_readXmlFile(configurationFilePath, xmlFileContents, exceptionInfo);
  
  for(int i=1; i<=dynlen(variables); i++)
    strreplace(xmlFileContents, variables[i], substitutions[i]);
  
  fwExternalApps_createDpStructure(xmlFileContents, intermediateNodeTypes, intermediateNodeLevels, exceptionInfo);

  fwDevice_setAlertRecursively(fwExternalApps_BASE_NODE + fwDevice_HIERARCHY_SEPARATOR + systemType, fwDevice_ALERT_SET, exceptionInfo);
  
  fwExternalApplications_createDipConfig(xmlFileContents, dipConfigName, exceptionInfo);
  if(dynlen(exceptionInfo)==0)
  {
    fwExternalApplications_createPublications(xmlFileContents, dipConfigName, exceptionInfo);
    fwExternalApplications_createSubscriptions(xmlFileContents, dipConfigName, exceptionInfo);
  }  
}

fwExternalApplications_createDipConfig(string xmlFileContents, string &dipConfigName, dyn_string &exceptionInfo)
{
  string rc = gcsDIP_CreateConfig(xmlFileContents, dipConfigName);
  if (rc)
    fwException_raise(exceptionInfo, "ERROR", rc, "");
}

fwExternalApplications_createPublications(string xmlFileContents, string dipConfigName, dyn_string &exceptionInfo)
{
  string rc = gcsDIP_CreatePublications(xmlFileContents, dipConfigName);
  if(rc)
    if(strpos(rc, "Probably they are not declared") < 0)
      fwException_raise(exceptionInfo, "WARNING", rc, "");
}

fwExternalApplications_createSubscriptions(string xmlFileContents, string dipConfigName, dyn_string &exceptionInfo)
{
  string rc = gcsDIP_CreateSubscriptions(xmlFileContents, dipConfigName);
  if (rc)
    if(strpos(rc, "Probably they are not declared") < 0)
      fwException_raise(exceptionInfo, "WARNING", rc, "");
}

fwExternalApps_createDpStructure(string xmlFileContents, dyn_string types, dyn_string levels, dyn_string &exceptionInfo)
{
  int length;
  string dpName;
  mapping dpTypeMap;
  dyn_string dpesList, dpeTypesList;
  
  dpesList = gcsDIP_GetDpeList(xmlFileContents);
  dpeTypesList = gcsDIP_GetDpeTypeList(xmlFileContents);

  length = dynlen(dpesList);
  for(int i=1; i<=length; i++) 
  {
    dpesList[i] = substr(dpesList[i], 0, strpos(dpesList[i], "."));
    if(!mappingHasKey(dpTypeMap, dpesList[i]))
      dpTypeMap[dpesList[i]] = dpeTypesList[i];    
  }

  dynUnique(dpesList);
//DebugN(dpesList, dpTypeMap);  
  
  length = dynlen(dpesList);
  for(int i=1; i<=length; i++) 
  {
    int pathParts;
    string path, previousPath="";
    dyn_string parts, device, parentDevice;
    
    parts = strsplit(dpesList[i], fwDevice_HIERARCHY_SEPARATOR);
    pathParts = dynlen(parts);
    for(int j=1; j<=pathParts; j++)
    {
      path = previousPath + parts[j];
//DebugN("Checking if exists: " + path, dpExists(path));
      if(!dpExists(path))
      {
        int pos;
        
        device[fwDevice_DP_NAME] = parts[j];
        parentDevice[fwDevice_DP_NAME] = strrtrim(previousPath, fwDevice_HIERARCHY_SEPARATOR);

        if(mappingHasKey(dpTypeMap, path))
          device[fwDevice_DP_TYPE] = dpTypeMap[path];
        else
        {
//DebugN(levels, j, pathParts);
          if(j==pathParts)
            pos = dynContains(levels, "$");
          if(pos <= 0)
            pos = dynContains(levels, (string)j);
          if(pos <= 0)
            pos = dynContains(levels, "*");

          if(pos <= 0)
            device[fwDevice_DP_TYPE] = "FwExternalAppsNode";
          else
            device[fwDevice_DP_TYPE] = types[pos];
        }
//DebugN("Creating", device);
        fwDevice_create(device, parentDevice, exceptionInfo);
      }
      previousPath = path + fwDevice_HIERARCHY_SEPARATOR;
    } 
  }
}

void fwExternalApps_readsDevicesFromString ( string xmlFileContents , dyn_dyn_anytype & xmltable , dyn_string & exceptionInfo )
{
  string sSubscrPublicName, sSubscrPublicType, sOverwriteMode;
  string sDpeName, sDpeAlias, sDpeDescr, sDpeElement;
  string sDpeTagName, sDpeTypeName, sDpeUnitSpec;
  string sdpeMinError, sdpeMinWarn;
  string sdpeMaxWarn, sdpeMaxError;
  dyn_string applicationData;
  dyn_string dataPoints;
  int sSubscrPublic;
  int listSize;
      
  if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Starts fwExternalApps_readsDevicesFromString");
  
  sSubscrPublic = fwExternalApps_DATA_TYPE_NODATA;
  
  for ( ; ; )
  {
    if ( sSubscrPublic == fwExternalApps_DATA_TYPE_NODATA ) sSubscrPublic = fwExternalApps_DATA_TYPE_SUBSCR;
    else if ( sSubscrPublic == fwExternalApps_DATA_TYPE_SUBSCR ) sSubscrPublic = fwExternalApps_DATA_TYPE_PUBLIC;
    else if ( sSubscrPublic == fwExternalApps_DATA_TYPE_PUBLIC ) break;
    else
    {
      fwException_raise(exceptionInfo, "ERROR", "Software Bug fwExternalApps_readsDevicesFromString bad 'sSubscrPublic'", "");
      
      break;
    }
    
    if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Starts gcsDIP_GetTagsList");
    dataPoints = gcsDIP_GetTagsList ( xmlFileContents , 
                 ( sSubscrPublic == fwExternalApps_DATA_TYPE_SUBSCR ? _SUBSCRIPTION : _PUBLICATION ) );
    if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Ending gcsDIP_GetTagsList");

    // DebugN("dataPoints");
    // DebugN(dataPoints);

    // Sleep One Second Such that the UI Can Communicate with "pmon"
    // Didn't make any difference...
    // delay(1);

    listSize = dynlen ( dataPoints );
    for ( int index = 1 ; index <= listSize ; ++index )
    {
      if ( sSubscrPublic == fwExternalApps_DATA_TYPE_SUBSCR )
      {
        sSubscrPublicName = gcsDIP_GetSubscriptionName ( dataPoints[index] );
        sSubscrPublicType = gcsDIP_GetSubscriptionType ( dataPoints[index] );
      }
      else if ( sSubscrPublic == fwExternalApps_DATA_TYPE_PUBLIC )
      {
        sSubscrPublicName = gcsDIP_GetPublicationName ( dataPoints[index] );
        sSubscrPublicType = gcsDIP_GetPublicationType ( dataPoints[index] );
      }
      sOverwriteMode = gcsDIP_GetOverwriteOrNot ( dataPoints[index] );
        
      / *
      DebugN((sSubscrPublic==fwExternalApps_DATA_TYPE_SUBSCR?"Subscription":"Publication"));
      DebugN("Name   "+sSubscrPublicName);
      DebugN("Type   "+sSubscrPublicType);
      DebugN("O/W    "+(sOverwriteMode?"True":"False"));
      * /
      
      dyn_string dpElements = gcsDIP_GetTagsList ( dataPoints[index] , _DPE );
    
      int dpeSize = dynlen ( dpElements );
      for ( int dpe = 1 ; dpe <= dpeSize ; ++dpe )
      {
        // DebugN(dpElements[dpe]);

        // Note that for the GCS there are NO Default values specified for the 'Name', 'Alias' and 'Type' elements...
        
        // Further Information when Checked with the GCS the following are the default values...
        //
        // sDpeName      ""
        // sDpeAlias     ""
        // sDpeDescr     ""
        // sDpeElement   "."
        // sDpeTagName   "default"
        // sDpeTypeName  ""
        // sDpeUnitSpec  ""
        // sdpeMinError  ""
        // sdpeMinWarn   ""
        // sdpeMaxWarn   ""
        // sdpeMaxError  ""
        
        sDpeName     = gcsGenericXMLOperations_XMLParseTagInfo ( dpElements[dpe] , _DP_NAME ,             "" );
        sDpeAlias    = gcsGenericXMLOperations_XMLParseTagInfo ( dpElements[dpe] , _DP_ALIAS ,            "" );
        sDpeDescr    = gcsGenericXMLOperations_XMLParseTagInfo ( dpElements[dpe] , _DPE_DESCRIPTION ,    _DPE_DESCRIPTION_DEFAULT );
        sDpeElement  = gcsGenericXMLOperations_XMLParseTagInfo ( dpElements[dpe] , _DP_ELEMENT ,         _DP_ELEMENT_DEFAULT );
        sDpeTagName  = gcsGenericXMLOperations_XMLParseTagInfo ( dpElements[dpe] , _DPE_TAG ,            _DPE_TAG_DEFAULT );
        sDpeTypeName = gcsGenericXMLOperations_XMLParseTagInfo ( dpElements[dpe] , _DP_ELEMENT_TYPE ,     "" );
        sDpeUnitSpec = gcsGenericXMLOperations_XMLParseTagInfo ( dpElements[dpe] , _DPE_UNIT ,           _DPE_UNIT_DEFAULT );

        sdpeMinError = gcsGenericXMLOperations_XMLParseTagInfo ( dpElements[dpe] , _DPE_ALERT_MIN_ERROR, _DPE_ALERT_DEFAULT );
        sdpeMinWarn  = gcsGenericXMLOperations_XMLParseTagInfo ( dpElements[dpe] , _DPE_ALERT_MIN_WARN,  _DPE_ALERT_DEFAULT );
        sdpeMaxWarn  = gcsGenericXMLOperations_XMLParseTagInfo ( dpElements[dpe] , _DPE_ALERT_MAX_WARN,  _DPE_ALERT_DEFAULT );
        sdpeMaxError = gcsGenericXMLOperations_XMLParseTagInfo ( dpElements[dpe] , _DPE_ALERT_MAX_ERROR, _DPE_ALERT_DEFAULT );

        / *
        string dpeidx;
        sprintf(dpeidx,"%-7d",dpe);
        
        DebugN(dpeidx+"Name:     "+sDpeName);
        DebugN("       Alias:    "+sDpeAlias);
        DebugN("       Descr:    "+sDpeDescr);
        DebugN("       Element:  "+sDpeElement);
        DebugN("       Tag:      "+sDpeTagName);
        DebugN("       Type:     "+sDpeTypeName);
        DebugN("       Unit:     "+sDpeUnitSpec);
        
        DebugN("       MinError: "+sdpeMinError);
        DebugN("       MinWarn:  "+sdpeMinWarn);
        DebugN("       MaxWarn:  "+sdpeMaxWarn);
        DebugN("       MaxError: "+sdpeMaxError);
        * /

        / *
           Note that the following logically needs to be done for each Datapoint-Element as
           first of all the Datapoint-Name needs Not to be unique for the Same Subsc/Public,
           and secondly, the Datapoint-Alias might change the outcome of the checks below!
           
           if DP-Name not empty
              if DP-Alias empty
                 do nothing
              elsif DP-Alias does Not map to an existing DP-Name
                 do nothing
              elsif DP-Alias maps to the same DP-Name
                 do nothing
              else {DP-Alias maps to a different DP-Name}
                 ignore this entry and raise an exception
           else {DP-Name empty}
              if DP-Alias empty
                 ignore this entry and raise an exception
              elsif DP-Alias does Not map to an existing DP-Name
                 ignore this entry and raise an exception
              else {DP-Alias maps to a DP-Name}
                 Use the translated DP-Name
        * /
               
        dyn_string result;
          
        if ( sDpeName != "" )
        {
          if ( sDpeAlias != "" )
          {
            result = dpNames("@"+sDpeAlias);
            if ( ( dynlen(result) == 1 ) && ( sDpeName != result[1] ) )
            {
              fwException_raise(exceptionInfo, "WARNING", "DP-Name '"+sDpeName+"' and DP-Alias '"+sDpeAlias+"' mismatched to '"+result[1]+"'", "");
              next;
            }
          }
        }
        else
        {
          if ( sDpeAlias == "" )
          {
            fwException_raise(exceptionInfo, "WARNING", "Empty DP-Name and DP-Alias for Subscr/Public '"+sSubscrPublicName+"'", "");
            next;
          }    
          else
          {
            result = dpNames("@"+sDpeAlias);
            if ( dynlen(result) != 1 )
            {
              fwException_raise(exceptionInfo, "WARNING", "Empty DP-Name and DP-Alias '"+sDpeAlias+"' does Not Map to a DP-Name", "");
              next;
            }
            else
            {
              sDpeName = result[1];
            }
          }
        }  

        applicationData = makeDynString ( sSubscrPublic , sSubscrPublicName , sSubscrPublicType , sOverwriteMode ,
                                         sDpeName , sDpeAlias , sDpeDescr , sDpeElement , 
                                         sDpeTagName , sDpeTypeName , sDpeUnitSpec ,
                                         sdpeMinError , sdpeMinWarn , sdpeMaxWarn , sdpeMaxError );
        
        dyn_string treeElems = strsplit ( sDpeName , "/" );
        fwExternalApps_insertElementInTable ( xmltable , treeElems , sSubscrPublic , applicationData , exceptionInfo );
      }
    }
  }
  
  if ( fwExternalApps_CHECK_PERFORMANCE ) DebugTN("Ending fwExternalApps_readsDevicesFromString");
}

*/


