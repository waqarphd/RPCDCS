Program name: PVSS00procmon.exe

Author: Fernando Varela (CERN EN-ICE)

Date:   17/09/2012

Description: WMI client that allows to monitor Microsoft Windows PCs remotely. 
  	     The program publishes the information via DIM. The program is linked against 
             the PVSS pmon table so that it can be monitored/controlled by pmon. It can 
             also be used standalone, with no PVSS.

Supported Plaforms: 
  - For the machine on which PVSS00procmon.exe is running:
	- MS Windows XP - Service Pack 3
	- Windows 7
  - For the monitored machines:			
	- Windows 7
	- MS Windows XP - Service Pack 3
	- MS Windows 2003 Server - Service Pack 3
	- MS Windows 2003 Server - Service Pack 2 (requires MS hot fix: KB932370 available 
                                             here: http://support.microsoft.com/kb/932370/)
  

Command line options:
  -fmc_config <configFile>  	where <configFile> is a text file containing the list
                            	of host to be monitored. Each computer is specified 
                            	in a new line. This option is mandatory.

  -proj <projectName>       	name of the PVSS project to connect to (connection 
                            	only to the pmon shared memory. No connection to db 
                            	or event managers). 

  -dim_dns_node <host>      	DIM DNS node. This argument is optional if the 
                            	DIM_DNS_NODE environment variable is defined.

  -dim_dns_port <portNumber> 	DIM DNS port. This argument is optional.


  -l <logFile>			Full path to a log file. 


Additional comments: The monitoring of the process owner requires executing 
		     a wmi command on the remote host, which renders the monitoring a little bit
		     more intrusive. If this information is not necessary
		     PVSS00procmon_noUser.exe can be used instead. 		    		

Feedback: itcontrols.support@cern.ch
  