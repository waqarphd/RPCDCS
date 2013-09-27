const string rssFile = "feed.rss.xml";
const string FW_SYSTEMOVERVIEW_RSS_FOLDER = "/home/unicryo/HtmlFiles/rss/";
const int FW_SYSTEMOVERVIEW_RSS_MAX_NEWS = 20;
    
string fwSystemOverviewRss_getGuid(string dpe, string alarmTime)
{
  return dpe + "_" + alarmTime;
}


int fwSystemOverviewRss_createHeader()
{
  int docId = xmlNewDocument();
  xmlAppendChild(docId, -1, XML_PROCESSING_INSTRUCTION_NODE, "xml version=\"1.0\" encoding=\"ISO-8859-1\""); 
  int topNodeId = xmlAppendChild(docId, -1, XML_ELEMENT_NODE, "rss");
  xmlSetElementAttribute(docId, topNodeId, "version","2.0");
  int child = xmlAppendChild(docId, topNodeId, XML_ELEMENT_NODE, "channel");

  int subChild = xmlAppendChild(docId, child, XML_ELEMENT_NODE, "title");
  xmlAppendChild(docId, subChild, XML_TEXT_NODE, "MOON SBS's feed");
  subChild = xmlAppendChild(docId, child, XML_ELEMENT_NODE, "link");
  xmlAppendChild(docId, subChild, XML_TEXT_NODE, "http://www.cern.ch/moon");
  subChild = xmlAppendChild(docId, child, XML_ELEMENT_NODE, "description");
  xmlAppendChild(docId, subChild, XML_TEXT_NODE, "MOON SBS Home Page");
  subChild = xmlAppendChild(docId, child, XML_ELEMENT_NODE, "category");
  xmlAppendChild(docId, subChild, XML_TEXT_NODE, "SBS News");
  subChild = xmlAppendChild(docId, child, XML_ELEMENT_NODE, "ttl");
  xmlAppendChild(docId, subChild, XML_TEXT_NODE, "10"); 
 
  return docId; 
}

int fwSystemOverviewRss_openXml(string rssFile)
{
  string filename = FW_SYSTEMOVERVIEW_RSS_FOLDER + rssFile;

  string errMsg;
  int errLine, errCol;
  int docId = xmlDocumentFromFile(filename, errMsg, errLine, errCol);
  
  if(docId < 0)
    docId = fwSystemOverviewRss_createHeader();    

  return docId;
}

fwSystemOverviewRss_closeXml(int docId, string rssFile)
{
  xmlDocumentToFile(docId, FW_SYSTEMOVERVIEW_RSS_FOLDER + rssFile);
  xmlCloseDocument(docId);
}

int fwSystemOverviewRss_findChannelId(int docId)
{
  int id = xmlFirstChild(docId);
  while(xmlNodeType(docId, id) != XML_ELEMENT_NODE)  //get rid of all lines that are not elements, e.g. comments and processing lines
  {
    id = xmlNextSibling(docId, id);      
  }  
  
  //id points now to the top element node in the file
  return xmlFirstChild(docId, id);
  
}


bool fwSystemOverviewRss_newsExists(int docId, int channelId, string guid)
{
  dyn_int nodeIds;
  xmlChildNodes(docId, channelId, nodeIds);
  for(int i =1; i<= dynlen(nodeIds); i++)
  {
    dyn_int subNodeIds;
    xmlChildNodes(docId, nodeIds[i], subNodeIds);
    for(int j =1; j <= dynlen(subNodeIds); j++)
    {
      if(xmlNodeName(docId, subNodeIds[j]) == "guid")
      {
        if(xmlNodeValue(docId, xmlFirstChild(docId, subNodeIds[j])) == guid)
        {
          return true;
        }
      }
    }
  }
  return false;
}

fwSystemOverviewRss_appendNews(int docId, int channelId, string guid, string title, string description)
{
  int itemNodeId = xmlAppendChild(docId, channelId, XML_ELEMENT_NODE, "item");
  int id = xmlAppendChild(docId, itemNodeId, XML_ELEMENT_NODE, "title");
  xmlAppendChild(docId, id, XML_TEXT_NODE, title);
  id = xmlAppendChild(docId, itemNodeId, XML_ELEMENT_NODE, "guid");
  xmlAppendChild(docId, id, XML_TEXT_NODE, guid);
  string pubDate = fwSystemOverviewRss_getUTCTime();
  id = xmlAppendChild(docId, itemNodeId, XML_ELEMENT_NODE, "pubDate");
  xmlAppendChild(docId, id, XML_TEXT_NODE, pubDate);
  id = xmlAppendChild(docId, itemNodeId, XML_ELEMENT_NODE, "link");
  xmlAppendChild(docId, id, XML_TEXT_NODE, "http://www.cern.ch/moon/");
  id = xmlAppendChild(docId, itemNodeId, XML_ELEMENT_NODE, "description");
  xmlAppendChild(docId, id, XML_TEXT_NODE, description);
  
  dyn_int nodeIds;
  xmlChildNodes(docId, channelId, nodeIds);
  
  //Determine where the news start:
  int n = 0;
  for(int j =1; j <= dynlen(nodeIds); j++)
  {
    if(xmlNodeName(docId, nodeIds[j]) == "item")
    {
      n = j;
      break;
    }
  }

  if(dynlen(nodeIds) > (n + FW_SYSTEMOVERVIEW_RSS_MAX_NEWS -1))
  {
    xmlRemoveNode(docId, nodeIds[n]);
  }
}

string fwSystemOverviewRss_getUTCTime()
{
  time t = getCurrentTime() - timeFromGMT();
  string str = formatTime("%a, %d %b %Y %H:%M:%S GMT", t);
  return str;
}

void fwSystemOverviewRss_createRSSHtmlFile(string filePath="")
{
   string html = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"http://www.w3.org/TR/html4/loose.dtd\">" +
                "<html>"+
                "<head>"+
                "<title>MOON RSS Feeds</title>"+
                "<link href=\"../styles/styles.css\" rel=\"stylesheet\" type=\"text/css\" >"+
                "</head>"+
                "<body>" +
                "<table class='rssTable'>"+
            	  "<caption>MOON RSS Feeds</caption>"+
              	"<tr>";
  dyn_string soTrees;
  fwSystemOverviewFsm_getTrees(soTrees);  
  for(int i = 1; i<= dynlen(soTrees); i++)
  {
    string treeLabel;
    fwUi_getLabel(soTrees[i], soTrees[i], treeLabel);
    html += "<td>"+
             "<table class=\"moonTable\">"+
             "<tr><th>" + treeLabel + "</th></tr>";
    dyn_int types;
    dyn_string applications = fwCU_getChildren(types, soTrees[i]);
  
    for(int j = 1; j <= dynlen(applications); j++)
    {
      string label;
      string domain;

      if (fwSysOverviewFsm_isDomain(applications[j]))
        domain = applications[j];
      else
        domain = soTrees[i];
      fwUi_getLabel(domain, applications[j], label);
    
      html += "<tr><td name=\"application\"><img src=\"../styles/feed.gif\" alt=\"pic not found\"><a href=\"" + strtolower(treeLabel + "_" + label) + ".xml\"> " + label + "</a></td></tr>";
    }
    html += "</table>" +
            "</td>";
  }
  html += "</tr>" +
          "</table>" +
          "</body>"+
          "</html>";
  
   string folder = filePath==""?rss_FOLDER:filePath ;
   if(!isdir(folder + "/rss/"))
     mkdir(folder + "/rss/", "755");

   file f = fopen(folder +"/rss/moonRssFrontPage.html", "w+");
   int err = ferror(f);
   if (!err)
   {
     fputs(html, f);
     fclose(f);
   }

}
int fwSystemOverviewRss_createEmptyRss(string destination, string fileName)
{
  int docId = fwSystemOverviewRss_createHeader();    
  xmlDocumentToFile(docId, destination + "/" + fileName);
}
