#uses "fwFMC/fwFMCProcess.ctl"

main()
{
   dyn_string connectedNodesServices, connectedNodesProcesses;
   while(true)
   {
     fwFMCProcess_monitorProcesses(connectedNodesProcesses);
     fwFMCProcess_monitorServices(connectedNodesServices);
     delay(30);
   }
}
