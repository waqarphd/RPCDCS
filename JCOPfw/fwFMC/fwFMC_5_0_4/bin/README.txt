Program name: PVSS00procmon.exe

Author: Fernando Varela (CERN EN-ICE)

Date:   April 9th 2010

Description: WMI client that allows to monitor Microsoft Windows PCs remotely. 
  	     The program publishes the information via DIM. The program is linked against 
             the PVSS pmon table so that it can be monitored/controlled by pmon. It can 
             also be used standalone, with no PVSS.

Supported Plaforms: 

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
                            	or event managers). This argument is optional.

  -dim_dns_node <host>      	DIM DNS node. This argument is optional if the 
                            	DIM_DNS_NODE environment variable is defined.

  -dim_dns_port <portNumber> 	DIM DNS port. This argument is optional.

Feedback: itcontrols.support@cern.ch
  