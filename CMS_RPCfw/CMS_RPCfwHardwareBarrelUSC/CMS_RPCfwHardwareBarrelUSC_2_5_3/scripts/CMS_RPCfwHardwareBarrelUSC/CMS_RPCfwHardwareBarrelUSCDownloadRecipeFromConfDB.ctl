/****
  
Fixed problem with recipe  
  
*///////////////
main()
{
loadFromConfigDB();

}

void loadFromConfigDB()
{
dbConnection dbCon; 
dyn_string deviceList,exceptionInfo,recipeSettings; 
string defaultConnectString, recipeName,on,stb; 
string setupName = "";
dyn_dyn_mixed recipeSTANDBY,recipeON,recipe; 
//DebugN("IOPP",device,command,recipeName);


fwConfigurationDB_checkInit(exceptionInfo);

DebugN("Initialization completed"); 
dyn_string recipeList;
int exists;
  fwConfigurationDB_getRecipesInCache(recipeList,exceptionInfo);
  if(dynlen(exceptionInfo)>0) DebugN("Searching for cache failed", exceptionInfo);
  dynClear(exceptionInfo);
// Ricorda che se le device non ci sono su questo pc non funziona!!
dyn_string deviceList=dpAliases("*/HV/*","*");

dyn_string type = makeDynString("run_stateON","run_stateSTB","run_i0high","run_i0low","RPCB_i1settings_v1.0");
dyn_string cacheName = makeDynString("cacheON","cacheSTB","I0Ramp","I0Stable","fsmValues");
for(int i = 1;i<=dynlen(type);i++)
{
   exists = dynContains(recipeList,cacheName[i]);
   if(exists>0)
    {
     fwConfigurationDB_dropRecipeInCache(cacheName[i],fwDevice_LOGICAL,exceptionInfo);
     if(dynlen(exceptionInfo)>0) DebugN("Deleting cache failed",exceptionInfo);
      }
  fwConfigurationDB_getRecipeFromDB("",deviceList,fwDevice_LOGICAL,type[i],recipe,exceptionInfo); 
  fwConfigurationDB_storeRecipeInCache(recipe,cacheName[i], fwDevice_LOGICAL, exceptionInfo);
    DebugN("loaded recipe "+ cacheName[i] + " from DB"); 
dynClear(recipe);
  }
  
  
 // Apply FSM chache 
  
  
   	fwConfigurationDB_getRecipeFromCache("fsmValues",deviceList,fwDevice_LOGICAL, recipe,exceptionInfo);
        fwConfigurationDB_ApplyRecipe( recipe,fwDevice_LOGICAL,exceptionInfo); 
        if (fwConfigurationDB_handleErrors(exceptionInfo)) {
          ok = false;
          return;  
          }else {DebugN("Recipe Applied");}
 

}


