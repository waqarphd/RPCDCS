// Our Resources administration
#include "PVSSDIPAPIOptions.h"
#include  "DipApiResources.hxx"
#include  <ErrHdl.hxx>
#include "platformDependant.h"
#include "CmdLine.h"

// Our static Variable
CharString  DipApiResources::configRootName = "";

string DipApiResources::DNSName = "";

// Our static Variable
//CharString  DipApiResources:: configIsStandby = "";

bool DipApiResources::isActive = false;

bool DipApiResources::m_considerRangeInvalidAsBadQualityForDipPublishing = true;

bool DipApiResources::m_attemptToPublishCorrectionValuesForDipTimestampsInThePast = false;

bool DipApiResources::m_logDataMappingErrorsMultipleTimes = false;

bool DipApiResources::m_lockMappedDpes = true;

long DipApiResources::m_staleDipTimestampThresholdInSeconds = 172800 ; // = 48 hours (3600*48);

// Wrapper to read config file
void  DipApiResources::init(int &argc, char *argv[])
{
	//Standard mechanism for PVSS
	begin(argc, argv);
	while ( readSection() || generalSection() )
    ;
	end(argc, argv);

	//Now using our own parsing mechanism to read the command line arguments.
	CCmdLine theCommandLineParser;
	theCommandLineParser.SplitLine(argc, argv);
	try {
		bool DNSSpecified = theCommandLineParser.HasSwitch("-dns");
		if (true ==DNSSpecified) {
			DNSName = theCommandLineParser.GetArgument("-dns", 0);
			if ("" == DNSName) {
				//No DNS specified, using the default one. (DNSName set to empty)
				PVSSLOG(ErrClass::PRIO_WARNING, "The \"-dns\" has been provided on the command line without a value: ignored.");
				DNSName.erase(DNSName.begin(),DNSName.end());
			}
		} else {
			//No DNS specified, using the default one. (DNSName set to empty)
			DNSName.erase(DNSName.begin(),DNSName.end());
		}

		bool invalidRangeSpecified = theCommandLineParser.HasSwitch("-ignore_invalid_ranges");
		if(true ==invalidRangeSpecified) {
			m_considerRangeInvalidAsBadQualityForDipPublishing = false;
			PVSSWARNING("The \"-ignore_invalid_ranges\" flag was specified, we will not consider PVSS range invalidity to mark a DIP publication with BAD quality.");
		}

		// ENS-1411
		bool publishCorrectionValuesSpecified = theCommandLineParser.HasSwitch("-publish_correction_values");
		if(true ==publishCorrectionValuesSpecified) {
			m_attemptToPublishCorrectionValuesForDipTimestampsInThePast = true;
			PVSSWARNING("The \"-publish_correction_values\" flag was specified, we will publish DPE Correction Values when the DIP timestamp is anterior to the last DPE update (provided DPE archiving is active).");
		}
		
		// DIP-65
		bool doNotLockDPEs = theCommandLineParser.HasSwitch("-no_dpe_locking");
		if(true ==doNotLockDPEs) {
			m_lockMappedDpes = false;
			PVSSWARNING("The \"-no_dpe_locking\" flag was specified, do not lock DPEs mapped to DIP subscriptions (WARNING, not supported in production, will cause PVSS timestamp issues, c.f. DIP-44).");
		}

		bool verboseLogging = theCommandLineParser.HasSwitch("-verbose");
		if(true ==verboseLogging) {
			m_logDataMappingErrorsMultipleTimes = true;
			PVSSWARNING("The \"-verbose\" flag was specified, warnings and errors (including data mapping issues) will be reported as many times as they occur.");
		}
		
		string dipDpConfig = "";
		if (true == theCommandLineParser.HasSwitch("-dip_dp_config") ) {
			dipDpConfig = theCommandLineParser.GetArgument("-dip_dp_config", 0);
			if (dipDpConfig.empty()) {
				//No DIP config specified, using the default one already stored in the configuration file
				//means doing nothing
				PVSSLOG(ErrClass::PRIO_WARNING, "The \"-dip_dp_config\" flag has been provided on the command line without a value: ignored.");
				dipDpConfig.erase(dipDpConfig.begin(),dipDpConfig.end());
			}
			else
			{
				configRootName = "";
				configRootName.appendString(dipDpConfig.c_str(), dipDpConfig.length());	
				PVSSLOG(ErrClass::PRIO_INFO, "DIP Datapoint Config was provided on the API manager command line, now using : " << configRootName);
			}
		}

		std::string dipTimestampThresholdStr = "";
		if (true == theCommandLineParser.HasSwitch("-stale_dip_timestamp_threshold") ) {
			dipTimestampThresholdStr = theCommandLineParser.GetArgument("-stale_dip_timestamp_threshold", 0);
			std::istringstream conversionStream(dipTimestampThresholdStr);
			int dipTimestampThreshold;
			if( !(conversionStream >> dipTimestampThreshold) ){
				PVSSWARNING("The \"-stale_dip_timestamp_threshold\" value was not a valid long number, ignoring it.");
			}else{
				m_staleDipTimestampThresholdInSeconds = (long)dipTimestampThreshold;
				PVSSINFO("The \"-stale_dip_timestamp_threshold\" flag has been provided on the command line with value: "<<m_staleDipTimestampThresholdInSeconds<<" seconds." );
			}
		}
	} catch (...) {
		//Just consume silently...
	}
}

// Read the config file.
// Our section is [dip] or [dip_<num>], 
PVSSboolean  DipApiResources::readSection()
{
  // Is it our section ? 
  // This will test for [dip] and [dip_<num>]
  if (!isSection("dip"))
    return PVSS_FALSE;

  // Read next entry
  getNextEntry();

  // Loop thru section
  while ( (cfgState != CFG_SECT_START) &&  // Not next section
          (cfgState != CFG_EOF) )          // End of config file
  {
	  if (!keyWord.icmp("DipConfig")){            // It matches
		cfgStream >> configRootName;              // read the value
//	  } else if (!keyWord.icmp("IsStandbySystem")){    // It matches
//		cfgStream >> configIsStandby;
	  } else if (!readGeneralKeyWords())          // keywords handled in Resources
    {
      ErrHdl::error(ErrClass::PRIO_WARNING,     // not that bad
                    ErrClass::ERR_PARAM,        // wrong parametrization
                    ErrClass::ILLEGAL_KEYWORD,  // illegal Keyword in Res.
                    keyWord);

      // Signal error, so we stop later
	  cfgError = PVSS_TRUE;
    }

    getNextEntry();
  }

  // So the loop will stop at the end of the file
  return cfgState != CFG_EOF;
}

void DipApiResources::setActiveSystem(bool flag)
{
	isActive = flag;
}

bool DipApiResources::getActiveSystem()
{
	return (isActive);
}

string DipApiResources::getDNSName()
{
	return (DNSName);
}

