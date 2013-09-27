/*
  Example of an API manager
  This will copy the values from one datapoint to another.
  To do this the manager will connect to the first datapoint and
  for everey hotlink it receives it will set the second one.
  The names of both datapoints can be given in the config file.
*/
#include "PVSSDIPAPIOptions.h"
#include  "DipApiManager.hxx"
#include  "DipApiResources.hxx"
#include  <signal.h>

using namespace std;

int main(int argc, char *argv[])
{
  // Let Manager handle SIGINT and SIGTERM (Ctrl+C, kill)
  // Manager::sigHdl will call virtual function Manager::signalHandler 
	signal(SIGINT,  Manager::sigHdl);
	signal(SIGTERM, Manager::sigHdl);



  // Initialize Resources, i.e. 
  //  - interpret commandline arguments
  //  - interpret config file
	DipApiResources::init(argc, argv);

  // Are we called with -helpDbg or -help ?
  if (DipApiResources::getHelpDbgFlag())
  {
    DipApiResources::printHelpDbg();
    return 0;
  }

  if (DipApiResources::getHelpFlag())
  {
    DipApiResources::printHelp();
    return 0;
  }

  // Now run our demo manager
	DipApiManager *apiManager = new DipApiManager;
	apiManager->run();

  // Exit gracefully :) 
  // Call Manager::exit instead of ::exit, so we can clean up
	Manager::exit(0);
	
  // Just make the compilers happy...
	return 0;
}
