// Browser.cpp: implementation of the Browser class.
//
//////////////////////////////////////////////////////////////////////
#include "PVSSDIPAPIOptions.h"
#include "DipApiManager.hxx"
#include "Browser.h"
#include <map>

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////


struct PSStringLess  {

bool operator()(const SString *s1, const SString *s2) const
  {
    return strcmp(s1->getString(), s2->getString()) < 0;
  }
};

struct SStringLess  {

bool operator()(const SString s1, const SString s2) const
  {
    return strcmp(s1.getString(), s2.getString()) < 0;
  }
};



/*************************  sof dip browser simulator  **********************************/
#ifdef SIMULATE_DIPNAMESPACE

struct CopyCharStringLess  {
	bool operator()(const CharString _X, const CharString _Y) const
		{return ((_X < _Y) == 1); 
	}
};


class DipPub{
	struct Tuple{
		SString name;
		int val;
	
		Tuple(char *n, int v):name(n), val(v){};
	};

	typedef std::vector<Tuple> FieldMap;
	FieldMap fieldMap;
public:


	DipPub(char ** names, int *types, int count)
	{
		for (int i = 0; i < count; i++){
			fieldMap.push_back(Tuple(names[i], types[i]));
		}
	}


	std::vector<char *> getFieldNames(){
		std::vector<char *> names;
		for (int i = 0; i < fieldMap.size(); i++){
			names.push_back(fieldMap[i].name.getString());
		}

		return names;
	}


	int getFieldType(SString &name){
		for (int i = 0; i < fieldMap.size(); i++){
			if (fieldMap[i].name == name){
				return fieldMap[i].val;
			}
		}
		
		throw DipException("field does not exist");
	}
};





class DipBrowser{
private:
	/**
	* Keyed on publiction name
	*/
	typedef std::map<SString, DipPub *, SStringLess> PubMap;
	PubMap pubMap;


	/**
	* who designed DIP browsing?
	*/
	DipPub * currentPub;

	/**
	* Internal buffer for holding names - its a ragged array
	*/
	char ** nameArray;

public:
	DipBrowser();

	int getType(const char *tagName);

	const char **getTags(const char * publication, unsigned &noPubs);

	// this sim ignores start
	const char **getPublications(char * start, unsigned &noPubs);
};



DipBrowser::DipBrowser():currentPub(NULL), nameArray(NULL){
	/// this is just quick and dirty - should ref count pub!
	{
		char *names[10] = {"f1", "f2", "f3"};
		int types[] = {1,1,3};
		DipPub *pub = new DipPub(names, types, 3);
		pubMap["/test/t1"] = pub;
		pubMap["/test/t2"] = pub;
		pubMap["/t1"] = pub;
	}
	{
		char *names[10] = {"x", "y", "z", "t"};
		int types[] = {1,1,1,2};
		DipPub *pub = new DipPub(names, types, 4);
		pubMap["/test"] = pub;
		pubMap["/test/dect1/Lkr/pos1"] = pub;
		pubMap["/test/dect1/Lkr/pos2"] = pub;
	}
	{
		char *names[10];
		int *types;
		DipPub *pub = new DipPub(names, types, 0);
		pubMap["/test/dect1"] = pub;
	}
}

int DipBrowser::getType(const char *tagName){
	if (currentPub == NULL){
		throw DipException("pub not defined");
	}

	return currentPub->getFieldType(SString(tagName));
}

const char **DipBrowser::getTags(const char * publication, unsigned &noFields){
	currentPub = pubMap[publication];
	if (currentPub == NULL){
		throw DipException("pub does not");
	}

	std::vector<char *> names = currentPub->getFieldNames();
	noFields = names.size();
	if (nameArray != NULL){
		delete [] nameArray;
	}

	nameArray = new char * [noFields];
	for (int i = 0; i < noFields; i++){
		nameArray[i] = names[i];
	}
	return (const char **)nameArray;
}




const char **DipBrowser::getPublications(char * start, unsigned &noPubs){
	// ignoring start
	noPubs = pubMap.size();
	if (nameArray != NULL){
		delete [] nameArray;
	}

	nameArray = new char * [noPubs];
	PubMap::iterator it = pubMap.begin();
	int count = 0;
	while (it != pubMap.end()){
		const SString &pubName = it->first;
		nameArray[count] = pubName.getString();
		it++;
		count++;
	}
	return (const char **)nameArray;
}

#endif
/*************************  eof dip browser simulator  **********************************/





/**
* We do'nt need this class to be globally visable - hence its definition here
*/
class TreeNode{
public:
	/**
	* UNDEF is should never be passed to PVSS - for internal use only
	*/
	enum TreeNodeType{ERROR=0, BRANCH=1, LEAF=2, LEAFBRANCH = 3};

private:
	TreeNodeType nodeType;

	/**
	* Name of the publications (concat of node names from root to here)
	* Only used by leaf nodes.
	*/
	SString pubName;

	/**
	* relative name of node (not named from root)
	*/
	SString nodeName;


	/**
	* Stores children of this node.
	* Owned - keyed on node name.
	*/
	typedef std::map<SString, TreeNode *, SStringLess> ChildMap;
	ChildMap children;


	
	/**
	*Add a child to this node
	*Ownership passes to this object
	*/
	void AddChild(TreeNode *child);

public:

	TreeNode(const SString &name):nodeType(ERROR), nodeName(name){};


	~TreeNode(){
		ChildMap::iterator it = children.begin();
		while(it != children.end()){
			delete it->second;
			it++;
		}
	}


	
	const SString &TreeNode::getName() const{
		return nodeName;
	}

	
	
	const SString &TreeNode::getPublicationName() const{
		return pubName;
	}


	/**
	* Tells us if the node we are looking at is branch or leaf (or both)
	*/
	const TreeNode::TreeNodeType TreeNode::getType() const{
		return nodeType;
	}



	

	/**
	* Obtain a node given its name components (relative from root)
	*/
	TreeNode & getNode(SArray<SString> &nameComponents, int indexOfComponentToBeExamined){
		if ((unsigned)indexOfComponentToBeExamined ==  nameComponents.size()){
			return *this;
		}	

		
		const SString nodeName = nameComponents[indexOfComponentToBeExamined];
		ChildMap::iterator it = children.find(nodeName);
		if (it == children.end()){
			throw BrowseException();
		}

		TreeNode * node = it->second;

		// recurse down tree branchs
		return node->getNode(nameComponents, indexOfComponentToBeExamined+1);
	}




	/**
	* get list of all the child nodes 
	*/
	void TreeNode::getChildren(std::vector<TreeNode *> & childrenOfNode){
		childrenOfNode.clear();
		ChildMap::iterator it = children.begin();
		while(it != children.end()){
			childrenOfNode.push_back(it->second);
			it++;
		}
	}


	/**
	* put a leaf in the tree
	*/
	void insertLeaf(SString & fullPubName, SArray<SString> &pathToLeaf, int indexOfChildName){
		if ((unsigned)indexOfChildName == pathToLeaf.size()){
			// we are in the leaf node
			if ((getType() & LEAF) == LEAF){
				// node already leaf - should NEVER happen - we are trying to 
				//insert a leaf where there is already one
				throw BrowseException();
			}
			
			// make the node a leaf (or leaf branch)
			nodeType = (TreeNodeType)(nodeType | LEAF);
			pubName = fullPubName;
			return;
		}


		// make the node a branch (or leaf branch)
		nodeType = (TreeNodeType)(nodeType | BRANCH);

		SString childNameToLookFor = pathToLeaf[indexOfChildName];
		TreeNode * child = children[childNameToLookFor];
		if (child == NULL){
			child = new TreeNode(childNameToLookFor);
			AddChild(child);
		}
		// Insert leaf lower down the tree
		child->insertLeaf(fullPubName, pathToLeaf, indexOfChildName+1);
	}
};




	TreeNode * l1 = NULL;


	void TreeNode::AddChild(TreeNode *child){
		if (l1 == NULL){
			l1=child;
		}
		SString childName = child->getName();
		children[childName] = child;
	}







DipBrowser * BrowserManager::dipBrowser = NULL;
const char   BrowserManager::nameSpaceSeperator = '/';





BrowserManager::BrowserManager(DipApiManager & apiMan):root(NULL), browseRequestHandler(NULL), updateBrowseSpaceRequestHandler(NULL)
{
	browseRequestHandler = new BrowseRequestHandler(*this, apiMan);
	updateBrowseSpaceRequestHandler = new UpdateBrowseSpaceRequestHandler(*this, apiMan);

	if (dipBrowser == NULL){
#ifdef SIMULATE_DIPNAMESPACE
		dipBrowser = new DipBrowser();
		PVSSWARNING("IN SIMULATE_DIPNAMESPACE MODE");
#else
		PVSSINFO("Using real dip namespace");
		dipBrowser = DipApiManager::getDip().createDipBrowser();
#endif
	}
}


BrowserManager::~BrowserManager()
{
/* MD ACtually the browser comes from the DIP Factory and cannot be deleted now.
	if (dipBrowser != NULL){
		delete dipBrowser;
	}
*/

	if (browseRequestHandler != NULL){
		delete browseRequestHandler;
	}
	
	if (updateBrowseSpaceRequestHandler != NULL){
		delete updateBrowseSpaceRequestHandler;
	}

	clearNameSpace();
}



void BrowserManager::clearNameSpace(){
	if (root){
		delete root;
		root = NULL;
		PVSSINFO("Destroyed cached copy of namespace");
	}
}



void BrowserManager::updateNameSpace(){
	PVSSTRACE(TRACEIN,"BrowserManager::updateNameSpace");
	clearNameSpace();
	root = new TreeNode(SString("/"));
	unsigned int noPubs;
	const char ** pubNames = dipBrowser->getPublications(NULL, noPubs);

	PVSSINFO("Found " << (int)noPubs << " publications:-");
	for (unsigned int i = 0; i < noPubs; i++){
		SString fullPubName = pubNames[i];
		SArray<SString> * nameParts = fullPubName.splitAt(nameSpaceSeperator);
		root->insertLeaf(fullPubName, *nameParts, 0);
		delete nameParts;
		//PVSSINFO(i << " " << fullPubName);
	}
	PVSSTRACE(TRACEOUT,"BrowserManager::updateNameSpace");
}



/**
* Node does not exist - all vectors empty
*/
int BrowserManager::getNodeInfo(SString &nodeName, 
						   std::vector<SString> & fieldNames, 
						   std::vector<int> & fieldTypes, 
						   std::vector<SString> & childNames,
						   std::vector<int> & childTypes){
	fieldNames.clear();
	fieldTypes.clear();
	childNames.clear();
	childTypes.clear();

	TreeNode * node = NULL;
	SArray<SString> * nameParts = NULL;
	try{
		if (!root){
			updateNameSpace();
		}

		nameParts = nodeName.splitAt(nameSpaceSeperator);
		node = &(root->getNode(*nameParts, 0));
	}catch(...){
		if (nameParts){
			delete nameParts;
		}
		return TreeNode::ERROR;
	}
	delete nameParts;
	

	if ((node->getType() & TreeNode::BRANCH) == TreeNode::BRANCH){
		// collect child details
		std::vector<TreeNode *> children;
		node->getChildren(children);
		for (unsigned i = 0; i < children.size(); i++){
			childNames.push_back(children[i]->getName());
			childTypes.push_back(children[i]->getType());
		}
	}

	if ((node->getType() & TreeNode::LEAF) == TreeNode::LEAF){
		try{
			// collect field details
			unsigned noFields;
			const char ** fields = BrowserManager::dipBrowser->getTags(node->getPublicationName(), noFields);

			for (int unsigned i = 0; i < noFields; i++){
				const char * currentField = fields[i];
				fieldNames.push_back(currentField);
				fieldTypes.push_back(BrowserManager::dipBrowser->getType(currentField));
			}
		} catch(DipException &){
			PVSSWARNING(node->getPublicationName() << " no longer exists");
			return TreeNode::ERROR;
		}
	}

	return node->getType();
}







void UpdateBrowseSpaceRequestHandler::dataChanged(const VariablePtr changedData){
	PVSSTRACE(TRACEIN,"UpdateBrowseSpaceRequestHandler::dataChanged");

	IntegerVar status(1);
	DpIdValueList * listOfValuesToSend = new DpIdValueList();

	browser.updateNameSpace();
	
	TimeVar currentTime;
	BC_CTime timeSeconds;
	short timeMSec;
	currentTime.getValue(timeSeconds, timeMSec); 
	DipLong timeInMs = ((DipLong)timeSeconds.ElapsedSeconds() * 1000) + timeMSec;
	listOfValuesToSend->appendItem(refreshActionStatusID, status); 
	
	apiManager.queueDPEDataReadyForUpdate(listOfValuesToSend, timeInMs); // can't return values from inside handler - so we queue it to be processed later


	PVSSTRACE(TRACEOUT,"UpdateBrowseSpaceRequestHandler::dataChanged");
}






void BrowseRequestHandler::dataChanged(const VariablePtr changedData){
	PVSSTRACE(TRACEIN,"BrowseRequestHandler::dataChanged");
	std::vector<SString>	fieldNames; 
	std::vector<int> dipFieldTypes; 
	std::vector<SString> childNames;
	std::vector<int> childTypes;


	TextVar * name = (TextVar *)changedData;
	if (!name){
		return;
	}

	// the overloaded const const char *() operator for TextVAR does not seem to
	// work - so I get a char string by going though the intermediate CharString
	// var
	CharString & charStr = name->getString(); 
	SString nodeName = (const char *)charStr;
	PVSSINFO("Browse request for " << nodeName.getString());
	int nodeType = browser.getNodeInfo(nodeName,fieldNames,dipFieldTypes,childNames,childTypes);

	DpIdValueList *listOfValuesToSend = new DpIdValueList();
	{
		DynVar * fieldNameArray = new DynVar(TEXT_VAR);
		DynVar * pvssFieldTypeArray = new DynVar(INTEGER_VAR);  // holds equiv. PVSS types 
		PVSSINFO("Fields");
		for (unsigned i=0; i < fieldNames.size(); i++){
			TextVar nameElement(fieldNames[i]);
			fieldNameArray->append(nameElement);
			const TConv * converter = TMap::findDipToDpeConverterFor(dipFieldTypes[i], 0);
			IntegerVar typeElement(converter->getDPEtypeID());
			pvssFieldTypeArray->append(typeElement);
			PVSSINFO((const char *)nameElement << " data type " << (longlong)typeElement.getValue());
		}
		listOfValuesToSend->appendItem(fieldNameDpeID, fieldNameArray);
		listOfValuesToSend->appendItem(fieldTypeDpeID, pvssFieldTypeArray);
	}
		
	{
		DynVar * childNameArray = new DynVar(TEXT_VAR);
		DynVar * childTypeArray = new DynVar(INTEGER_VAR);  // indicates branch/node
		PVSSINFO("Children");
		for (unsigned i=0; i < childNames.size(); i++){
			TextVar nameElement(childNames[i]);
			childNameArray->append(nameElement);
			IntegerVar typeElement(childTypes[i]);
			childTypeArray->append(typeElement);
			PVSSINFO((const char *)nameElement << " node type " << (longlong)typeElement.getValue());
		}
		listOfValuesToSend->appendItem(childNameDpeID, childNameArray);
		listOfValuesToSend->appendItem(childTypeDpeID, childTypeArray);
	}
	
	{
		IntegerVar status(nodeType);
		listOfValuesToSend->appendItem(browseStatusDpeID, status);
	}

	BC_CTime tmpTime;  // gives me current time in seconds
	TimeVar pvssFormatTime(tmpTime,0);
	
	TimeVar currentTime;
	BC_CTime timeSeconds;
	short timeMSec;
	currentTime.getValue(timeSeconds, timeMSec); 
	DipLong timeInMs = ((DipLong)timeSeconds.ElapsedSeconds() * 1000) + timeMSec;

	apiManager.queueDPEDataReadyForUpdate(listOfValuesToSend, timeInMs); // can't return values from inside handler - so we queue it to be processed later

	PVSSTRACE(TRACEOUT,"BrowseRequestHandler::dataChanged");
}

