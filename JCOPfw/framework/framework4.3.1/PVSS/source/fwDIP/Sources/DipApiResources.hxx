// The Resource file for the Demo manager
#ifndef  DIPAPIRESOURCES_H
#define  DIPAPIRESOURCES_H
#include  <vector>
#include  <string>
#include "CharString.hxx"
#include  <Resources.hxx>
#include <sstream>
#include <stdexcept>
#include <iostream>

using namespace std;

class  DipApiResources : public Resources
{
  private:

	static CharString configRootName;

	static bool isActive;

	static string DNSName;

	static bool m_considerRangeInvalidAsBadQualityForDipPublishing;

	// ENS-1411
	static bool m_attemptToPublishCorrectionValuesForDipTimestampsInThePast;
	
	// DIP-65
	static bool m_lockMappedDpes;

	// DIP-96
	static bool m_logDataMappingErrorsMultipleTimes;

	// FWDIP-79
	static long m_staleDipTimestampThresholdInSeconds;

  public:

	/** 
	  * The base name for the DPE structure
	  */

    // These functions initializes the manager
    static  void  init(int &argc, char *argv[]);  


	/** 
	  * Determines from the FwDIP config file whether it is configured as 
	  * Standby system (returns true), Hot system (returns false) or not redundant
	  * (returns true).
	  */
	//static bool isStandbySystem();

	/** 
	  * Sets whether the System is active or not at a given time.
	  */
	static void setActiveSystem(bool flag);

	/** 
	  * Sets whether the System is active or not at a given time.
	  */
	static bool getActiveSystem();

	/** 
	  * Gets the DNSName, returns NULL if empty.
	  */
	static string getDNSName();

	/**
	* Read the config section.
	* Read the values for the tags 
	* clientDPList - optional, name of the DPE that identifies DPE client
	* pubDPList - optional, name of the DPE that holds DPE config info. for publication
	* publisherName - manditory, name of publilication
	*/ 
    static  PVSSboolean  readSection();

	/**
	 * Indicate whether DPE range invalidity should be consider to establish DIP publication BAD quality
	 */
	static const bool isConsiderRangeInvalidAsBadQualityForDipPublishing(){
		return m_considerRangeInvalidAsBadQualityForDipPublishing;
	}

	static const bool isAttemptToPublishCorrectionValuesForDipTimestampsInThePast(){
		return m_attemptToPublishCorrectionValuesForDipTimestampsInThePast;
	}
	
	static const bool isLockMappedDPEs(){
		return m_lockMappedDpes;
	}
	
	static const bool isLogDataMappingErrorsMultipleTimes(){
	        return m_logDataMappingErrorsMultipleTimes;
	}
	
	static const long getStaleDipTimestampThresholdInSeconds(){
            return m_staleDipTimestampThresholdInSeconds;
	}

	static const CharString getConfigRootName(){
		return configRootName;
	}

    /**
	* Get name of the DPE that contains a list of all the DPEs that are to be clients
	* of the DIP.
	*/
	  static const CharString getClientSourceName(){
			static CharString suffix = ".clientConfig:_online.._value";
		return configRootName + suffix;
	  }

	/**
	* Get name of the DPE that contains a list of all the DPEs that are to be published
	* to DIP.
	*/
	  static const CharString getPubSourceName(){
		static CharString suffix = ".serverConfig:_online.._value";
		return configRootName + suffix;
	  }


	  /**
	  *Get the name of the DPE that contains the publisher (DIM server) name
	  */
	  static const CharString getPublisherNameDPE(){
		static CharString suffix = ".publishName:_online.._value";
		return configRootName + suffix;
	  }


	  static const CharString getRefreshAllSubscriptionsOnlineValueName(){
		static CharString suffix = ".refreshAllSubscriptions:_online.._value";
		return configRootName + suffix;
	  }

	  static const CharString getRefreshAllSubscriptionsOriginalValueName(){
		static CharString suffix = ".refreshAllSubscriptions:_original.._value";
		return configRootName + suffix;
	  }
	 /**
	* Get name of the DPE name that is used to trigger a refesh of the cached
	* DIP namespace.
	*/
	  static const CharString getBrowseRefreshName(){
		static CharString suffix = ".command.refreshBrowser:_online.._value";
		return configRootName + suffix;
	  }

	   /**
		* Get name of the DPE name that provides the start point for a browse query
		*/
	  static const CharString getBrowseStartPointName(){
		static CharString suffix = ".command.startPoint:_online.._value";
		return configRootName + suffix;
	  }

	   /**
		* Get name of the DPE name that is used to pass Field names back
		* in response to a browse request.
		*/
	  static const CharString getBrowseFieldNameResponseName(){
		static CharString suffix = ".response.fieldName:_original.._value";
		return configRootName + suffix;
	  }
	  
	  /**
		* Get name of the DPE name that is used to pass Field types back
		* in response to a browse request.
		*/
	  static const CharString getBrowseFieldTypeResponseName(){
		static CharString suffix = ".response.fieldType:_original.._value";
		return configRootName + suffix;
	  }

	   /**
		* Get name of the DPE name that is used to pass Child names back
		* in response to a browse request.
		*/
	  static const CharString getBrowseChildNameResponseName(){
		static CharString suffix = ".response.childName:_original.._value";
		return configRootName + suffix;	
	  }

	   /**
		* Get name of the DPE name that is used to pass child types back
		* in response to a browse request.
		*/
	  static const CharString getBrowseChildTypeResponseName(){
		static CharString suffix = ".response.childType:_original.._value";
		return configRootName + suffix;
	  }


	   /**
		* Get name of the DPE name that is used to indicate that the 
		* requested browse operation is complete
		*/
	  static const CharString getBrowseCompleteResponseName(){
		static CharString suffix = ".response.browseStatusDpeID:_original.._value";
		return configRootName + suffix;
	  }

	  static const CharString getRefreshActionStatusResponseName(){
		static CharString suffix = ".response.refreshActionStatus:_original.._value";
		return configRootName + suffix;
	  }
	  
	  static const CharString getSplitModeSourceName() {
		CharString prefix = "_Driver13";
		int reduNum = + ::Resources::getMyReduHostNum();
		if (reduNum == 2)
		{
			prefix+= "_2";
		} else {
			//Do nothing.
		}
		CharString result = prefix + ".MS:_original.._value";
		
		return result;
	  }

	  static const CharString getSplitComSourceName() {
		CharString prefix = "_Driver13";
		int reduNum = + ::Resources::getMyReduHostNum();
		if (reduNum == 2)
		{
			prefix+= "_2";
		} else {
			//Do nothing.
		}
		CharString result = prefix + ".DC:_original.._value";
		
		return result;
	  }
};

#endif
