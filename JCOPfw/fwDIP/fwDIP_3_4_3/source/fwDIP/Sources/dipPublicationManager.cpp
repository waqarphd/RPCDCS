//////////////////////////////////////////////////////////////////////
//
// dipPublicationManager.cpp: implementation of the CdipPublicationManager class.
//
//////////////////////////////////////////////////////////////////////
#include "PVSSDIPAPIOptions.h"
#include "dipPublicationManager.h"
#include "DIPClientManager.h"

std::map<const CharString * ,CdipPubGroup *, CharStringLess> CdipPublicationManager::publications;

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CdipPublicationManager::CdipPublicationManager(DipApiManager &m):
CdipManager(m),
DIPPublicationLock("DIPPublicationLock")
{
}

CdipPublicationManager::~CdipPublicationManager()
{
	//TODO Have to destroy the created map<> entries.
}

bool CdipPublicationManager::makePublication(const CharString & thePubName, const int theBufferTime_ms,const CvectorOfdpeMappingTuples &mappingList){
	try{
			CdipPubGroup * pubGroup = new CdipPubGroup(thePubName, theBufferTime_ms, mappingList);
		publications[&pubGroup->getPubName()]=pubGroup;
		return true;
	}
	catch (CPubGroupException &){
		PVSSERROR("Failed to create Publication group " << (const char *)thePubName);
	}
	return false;
}

void CdipPublicationManager::dataChanged(const VariablePtr changedData){
	PVSSTRACE(TRACEIN,"CdipPublicationManager::dataChanged ()");
	const DynVar * pubConfigurations = (DynVar *)changedData;
	TextVar * publicationConfiguration = (TextVar *)pubConfigurations->getFirst();
	while (publicationConfiguration != NULL){
		CharString pubConf(publicationConfiguration->getString());
		std::vector<std::string> strings;
		extractStringsFromCompoundString(pubConf,strings);
		// empty string indicates badly formed config.
		bool isBadlyFormed = false;
		for (unsigned int i = 0; i < strings.size(); i++){
			if (strings[i].size() == 0){
				isBadlyFormed = true;
				break;
			}
		}

		// size should be either 3 (primitive) or even (structured)
		if (isBadlyFormed || (strings.size() < 3) ||
			((strings.size() > 3) && ((strings.size() %2) != 0))){
			PVSSERROR("Badly formated publication configuration " << (const char *) pubConf);
		}else{
			CharString pubName = strings[0].c_str();
			std::map<const CharString * ,CdipPubGroup *, CharStringLess>::iterator it = publications.find(&pubName);
			if (it == publications.end()){
				//Does not exists yet.
				int bufferTime_ms;
				sscanf(strings[1].c_str(),"%d", &bufferTime_ms);
				CvectorOfdpeMappingTuples mappingList;
				if (strings.size() == 3){
					mappingList.push_back(new CdpeMappingTuple(strings[2].c_str(), CdpeMappingTuple::noTag));
				}else{
					for (unsigned int i = 2; i < strings.size(); i+=2){
						mappingList.push_back(new CdpeMappingTuple(strings[i].c_str(), strings[i+1].c_str()));
					}
				}
				makePublication(pubName,bufferTime_ms,mappingList);
			}
			else {
				// ignore the config since the publication structure should not changes (user must restart API manager for changes to take effect)
				PVSSWARNING(pubName << " - any  mods ignored - DIP pubs must have stable structure - restart if any changes are to be effective");
			}
		}
		publicationConfiguration = (TextVar *)pubConfigurations->getNext();
	}
	PVSSTRACE(TRACEOUT,"CdipPublicationManager::dataChanged ()");
}

void CdipPublicationManager::extractStringsFromCompoundString(CharString &compoundString, std::vector<std::string> & strings){
	unsigned int startOfStringInd = 0;
	unsigned int endOfStringInd = 0;
	std::string localCopy = (const char *)compoundString;
	
	char delimiter;

	//Check which delimiter is used, well at least present in the strin provided, then run the string processing.
	if (-1 != compoundString.indexOf(CdipClientManager::pubNameDelimiter[0])) {
		//Use delimiter 0
		delimiter = CdipClientManager::pubNameDelimiter[0][0];
	} else if (-1 != compoundString.indexOf(CdipClientManager::pubNameDelimiter[1])){
		//Use delimiter 1
		delimiter = CdipClientManager::pubNameDelimiter[1][0];
	} else if (-1 != compoundString.indexOf(CdipClientManager::pubNameDelimiter[0])
		 && -1 != compoundString.indexOf(CdipClientManager::pubNameDelimiter[1])
		){
		//Both delimiters present, this is a problem to report.
		PVSSERROR("Configuration string delimiters "<<CdipClientManager::pubNameDelimiter[0]<<" and "<<CdipClientManager::pubNameDelimiter[1]<<" are both present for Publications, take first one.");
		delimiter = CdipClientManager::pubNameDelimiter[0][0];
	} else {
		//No delimiter found, this is a problem to report.
		PVSSERROR("None of the configuration string delimiters "<<CdipClientManager::pubNameDelimiter[0]<<" and "<<CdipClientManager::pubNameDelimiter[1]<<" were found for Publications.");
		return;
	}

	while(endOfStringInd < localCopy.size()){
		if ((localCopy[endOfStringInd] == delimiter) || (endOfStringInd == (localCopy.size()-1))){
			int lenOfString = (endOfStringInd - startOfStringInd) + 1;
			if (localCopy[endOfStringInd] == delimiter){
				lenOfString--;
			}
			std::string str = localCopy.substr(startOfStringInd, lenOfString);
			strings.push_back(str);
			startOfStringInd = endOfStringInd+1;
		}
		endOfStringInd++;
	}
}

bool CdipPublicationManager::destroyAllDIPPublication() throw (CPubGroupException) {

	PVSSINFO("destroyAllDIPPublication() - going to get lock");
	SmutexGuard lock(DIPPublicationLock);
	//PVSSINFO("Got lock");

	bool result = true;
	//Go to each entry and detroy any Active DIP publication.	
	std::map<const CharString * ,CdipPubGroup *, CharStringLess>::iterator it = publications.begin();
	for (;it != publications.end();it++) {
		if (it->second == NULL)
		{
			PVSSWARNING("A publication group is NULL !!!");
		}
		else 
		{
			if (it->second->destroyDIPPublication()) {
				result = true;
			} else {
				result = false;
				break;
			}
		}
	}
	PVSSINFO("DIP publication destruction : Succes.");
	return (result);
}

bool CdipPublicationManager::rebindAllDIPPublication() throw (CPubGroupException) {

	SmutexGuard lock(DIPPublicationLock);
	bool result = true;
	//Go to each entry and tell them to (re)bind their DIP publications.	
	std::map<const CharString * ,CdipPubGroup *, CharStringLess>::iterator it = publications.begin();
	for (;it != publications.end();it++) {
		if (it->second->rebindDIPPublication()) {
			result = true;
		} else {
			result = false;
			break;
		}
	}
	return (result);
}
