const int HASH_MAX = 10000;

fwDim_hashCreate()
{
int i;

	if(!globalExists("HashTableKeys"))
	{
		addGlobal("HashTableKeys", DYN_DYN_STRING_VAR);
		addGlobal("HashTablePars", DYN_DYN_ANYTYPE_VAR);
		for(i = 1; i <= HASH_MAX; i++)
		{
			HashTableKeys[i] = makeDynString();		
			HashTablePars[i] = makeDynAnytype();		
		}
	}			
}

fwDim_hashDelete()
{
int i;

	if(globalExists("HashTableKeys"))
	{
		removeGlobal("HashTableKeys");
		removeGlobal("HashTablePars");
	}			
}

int fwDim_hashAdd(string key, string name, anytype par)
{
int hashIndex, index;

	hashIndex = fwDim_hashFunction(key, HASH_MAX);
	if((index = dynContains(HashTableKeys[hashIndex], name)))
	{
		HashTablePars[hashIndex][index] = par;
	}
	else
	{
		dynAppend(HashTableKeys[hashIndex], name);
		dynAppend(HashTablePars[hashIndex], par);
	}
	return hashIndex;
}

fwDim_hashAddByIndex(int hashIndex, string name, anytype par)
{
int index;

	if((index = dynContains(HashTableKeys[hashIndex], name)))
	{
		HashTablePars[hashIndex][index] = par;
	}
	else
	{
		dynAppend(HashTableKeys[hashIndex], name);
		dynAppend(HashTablePars[hashIndex], par);
	}
}

fwDim_hashRemove(string key, string name)
{
int hashIndex, index;

	hashIndex = fwDim_hashFunction(key, HASH_MAX);
	if((index = dynContains(HashTableKeys[hashIndex], name)))
	{
		dynRemove(HashTableKeys[hashIndex], index);
		dynRemove(HashTablePars[hashIndex], index);
	}
}

fwDim_hashRemoveByIndex(int hashIndex, string name)
{
int index;

	if((index = dynContains(HashTableKeys[hashIndex], name)))
	{
		dynRemove(HashTableKeys[hashIndex], index);
		dynRemove(HashTablePars[hashIndex], index);
	}
}

int fwDim_hashFind(string key, string name, anytype &par)
{
int hashIndex, index;

	hashIndex = fwDim_hashFunction(key, HASH_MAX);
	if((index = dynContains(HashTableKeys[hashIndex], name)))
	{
		par = HashTablePars[hashIndex][index];
		return 1;
	}
	return 0;
}

int fwDim_hashFindByIndex(int hashIndex, string name, anytype &par)
{
int index;

//DebugN("Hash", HashTableKeys[hashIndex]);
//DebugN("Hash", name, dynlen(HashTableKeys[hashIndex]));
	if((index = dynContains(HashTableKeys[hashIndex], name)))
	{
		par = HashTablePars[hashIndex][index];
		return 1;
	}
	return 0;
}

int fwDim_hashFunction(string key, unsigned max)
{
   unsigned b    = 378551;
   unsigned a    = 63689;
   unsigned hash = 0;
   int i    = 0;
   int len;
   unsigned ret;
   time t1;

   len = strlen(key);

   for(i = 0; i < len; i++)
   {
      hash = hash*a+(key[i]);
      a = a*b;
   }
   ret = hash % max;
   return ret + 1;
}

int fwDim_cacheCreate(string config, string type, int hash = 0)
{
string cache_name;
int cache_index = 0;

	if(!globalExists("CacheCurrent"))
	{
		addGlobal("Caches", DYN_DYN_STRING_VAR);
		addGlobal("CacheIndexes", DYN_STRING_VAR);
		addGlobal("CacheHashes", DYN_INT_VAR);
		addGlobal("CacheChanges", DYN_INT_VAR);
		addGlobal("CacheBusy", DYN_INT_VAR);
		addGlobal("CacheCurrent", DYN_STRING_VAR);
		addGlobal("CacheItems", DYN_DYN_STRING_VAR);
	}
	fwDim_hashCreate();
	cache_name = config+"_"+type;
	if(!(cache_index = dynContains(CacheIndexes, cache_name)))
	{
		cache_index = dynAppend(CacheIndexes, cache_name);	
		CacheHashes[cache_index] = hash;
		CacheChanges[cache_index] = 0;
		CacheBusy[cache_index] = 0;
		if(fwDim_cacheRead(config, type, Caches[cache_index], hash))
			CacheChanges[cache_index] += 1;
	}
	else
	{
		if(CacheHashes[cache_index])
			hash = 1;
		CacheHashes[cache_index] = hash;
//DebugTN("cache changes", CacheChanges[cache_index], CacheBusy[cache_index], cache_index);
		if( (!CacheChanges[cache_index]) && (!CacheBusy[cache_index]))
		{
			if(fwDim_cacheRead(config, type, Caches[cache_index], hash))
				CacheChanges[cache_index] += 1;
		}
	}
	return cache_index;
}

dyn_string fwDim_cacheGet(int cache_index)
{
dyn_string lines;

	return(Caches[cache_index]);
}

dyn_string fwDim_getCacheLineItems(string line, int &hashIndex, int clean = 0)
{
dyn_string items;
string num_str;
int i, pos;

	hashIndex = 0;
	items = strsplit(line,",");

	if(clean)
	{
		for(i = 1; i <= dynlen(items); i++)
		{
			items[i] = strrtrim(items[i]);
			items[i] = strltrim(items[i]);
		}
	}
	if(dynlen(items))
	{
		if((pos = strpos(items[1],"#") == 0))
		{
			num_str = substr(items[1], 1);
			hashIndex = num_str;
			dynRemove(items, 1);
		}
	}
//DebugTN(line, items, hashIndex);
	return(items);
}

fwDim_cacheGetItems(int cache_index, dyn_dyn_string &cache_items)
{
int i, j, refill = 0;
dyn_dyn_string result;
int hashIndex;
dyn_string items;

	if(CacheCurrent != Caches[cache_index])
	{
		CacheCurrent = Caches[cache_index];
		refill = 1;
	}
	if( (!dynlen(CacheItems)) || refill)
	{
		for(i = 1; i <= 10; i++)
		{
			CacheItems[i] = makeDynString();
		}
	}
	if(refill)
	{
		for(i = 1; i <= dynlen(CacheCurrent); i++)
		{
			items = fwDim_getCacheLineItems(CacheCurrent[i], hashIndex, 1);
			for(j = 1; j <= dynlen(items); j++)
			{
				CacheItems[j][i] = items[j];
			}
		}
	}
	cache_items = CacheItems;
}

int fwDim_cacheRead(string config, string type, dyn_string &cache, int hash)
{
int i, hashIndex;
dyn_string items;
string key, cache_name, name, hashNum;
int changed = 0;

	cache_name = config+"_"+type;

	dpGet(config+"."+type,cache);

	if(!hash)
		return(0);

	for(i = 1; i <= dynlen(cache); i++)
	{
		items = fwDim_getCacheLineItems(cache[i], hashIndex);
		key = items[1];
		name = cache_name+"_"+key;
		if(!hashIndex)
		{
			hashIndex = fwDim_hashAdd(key, name, i);
			sprintf(hashNum,"#%04d",hashIndex);
			cache[i] = hashNum+","+cache[i];
			changed = 1;
		}
//		else
		fwDim_hashAddByIndex(hashIndex, name, i);
	}
	return(changed);
}

fwDim_cacheWrite(int cache_index, dyn_string &cache)
{
int pos, last_pos;
string cache_name, tmp, config, type;

	cache_name = CacheIndexes[cache_index];

	tmp = cache_name;
	last_pos = 0;
	while((pos = strpos(tmp,"_")) != -1)
	{
		tmp = substr(tmp, pos+1);
		last_pos += pos+1;
	}
	--last_pos;
	config = substr(cache_name, 0, last_pos);
	type = substr(cache_name, last_pos+1);
	dpSetWait(config+"."+type, cache);
}


int fwDim_cacheFind(int cache_index, string dp, string &new_line)
{
int hashIndex;
string cache_name, key, name, line, hashNum;
int typ, index = 0;
int par, pos;

	key = dp;
	cache_name = CacheIndexes[cache_index];
	name = cache_name+"_"+dp;
	hashIndex = fwDim_hashFunction(key, HASH_MAX);
//DebugTN("cacheFind", dp, name, hashIndex, new_line);
	if(new_line != "")
	{
		sprintf(hashNum,"#%04d",hashIndex);
		new_line = hashNum+","+new_line;
	}
	if(fwDim_hashFindByIndex(hashIndex, name, par))
	{
		index = par;
		line = Caches[cache_index][index];
		if(new_line != "")
		{
			if(line != new_line)
				fwDim_cacheReplace(cache_index, index, new_line);
		}
		else
			new_line = line; 
	}
//DebugTN("done", new_line);
	return index;
}

fwDim_cacheAdd(int cache_index, dyn_string lines)
{
dyn_string items;
string key, name;
int index;
int len, i, hashIndex;

	if(!dynlen(lines))
		return;
	CacheChanges[cache_index] += 1;
	len = dynlen(Caches[cache_index]);
	dynAppend(Caches[cache_index], lines);		
	for(i = 1; i <= dynlen(lines); i++)
	{
		items = fwDim_getCacheLineItems(lines[i], hashIndex);
		key = items[1];
		name = cache_name+"_"+key;
		index = i+len;
		fwDim_hashAddByIndex(hashIndex, name, index);
	}
}


fwDim_cacheRemove(int cache_index, int index)
{
string line, cache_name, key, name;
dyn_string items;
int hashIndex;

	line = Caches[cache_index][index];
//	dynRemove(Caches[cache_index], index);
	Caches[cache_index][index] = "";
	CacheChanges[cache_index] += 1;
	if(CacheHashes[cache_index])
	{
		items = fwDim_getCacheLineItems(line, hashIndex);
		cache_name = CacheIndexes[cache_index];
		key = items[1];
		name = cache_name+"_"+key;
		fwDim_hashRemoveByIndex(hashIndex, name);
	}
}

synchronized fwDim_cacheRemoveMany(int cache_index, dyn_int indexList)
{
string line, cache_name, key, name;
dyn_string items;
int hashIndex;
dyn_string lines;
int i, index;

	for(i = 1; i <= dynlen(indexList); i++)
	{
		CacheChanges[cache_index] += 1;
		index = indexList[i];
		lines[i] = Caches[cache_index][index];
//	dynRemove(Caches[cache_index], index);
		Caches[cache_index][index] = "";
	}
	if(CacheHashes[cache_index])
	{
		cache_name = CacheIndexes[cache_index];
		for(i = 1; i <= dynlen(lines); i++)
		{
			items = fwDim_getCacheLineItems(lines[i], hashIndex);
			key = items[1];
			name = cache_name+"_"+key;
			fwDim_hashRemoveByIndex(hashIndex, name);
		}
	}
}

fwDim_cacheReplace(int cache_index, int index, string line)
{
	Caches[cache_index][index] = line;
	CacheChanges[cache_index] += 1;
}

fwDim_cleanupCache(int cache_index)
{
int i;
		
	for(i = 1; i <= dynlen(Caches[cache_index]); i++)
	{
		if(Caches[cache_index][i] == "")
		{
			dynRemove(Caches[cache_index], i);
			i--;
		}
	}
}

fwDim_cacheSave(int cache_index, int now, int secs = 1)
{
int i;

//DebugTN("SavingCache", now, secs, CacheChanges[cache_index]);
//DebugTN("Cache Busy");
//	if(CacheChanges[cache_index])
//	{
		CacheBusy[cache_index] += 1;
		if(!now)
			startThread("fwDim_cacheCheckMore", secs, cache_index, CacheChanges[cache_index]);
		else
		{
			if(CacheChanges[cache_index])
			{
				CacheChanges[cache_index] = 0;
				fwDim_cleanupCache(cache_index);
//DebugN("Setting "+dynlen(Caches[cache_index])+" services");
//DebugN("writing now", Caches[cache_index], cache_index);
				fwDim_cacheWrite(cache_index, Caches[cache_index]);
			}
			CacheBusy[cache_index] -= 1;
//		}
	}
//DebugTN("SavingCache Done", CacheChanges[cache_index]);
}

fwDim_cacheCheckMore(int secs, int cache_index, int nChanges)
{

	delay(secs);
	while(FwDimSubscribeBusy)
		delay(0, 100);
	FwDimSubscribeBusy = 1;

	if(nChanges)
	{
		if(CacheChanges[cache_index] == nChanges)
		{
			CacheChanges[cache_index] = 0;
			fwDim_cleanupCache(cache_index);
//DebugN("Setting "+dynlen(Caches[cache_index])+" services");
//DebugN("writing", Caches[cache_index], cache_index);
			fwDim_cacheWrite(cache_index, Caches[cache_index]);
		}
	}
//DebugTN("Cache NOT Busy", CacheBusy[cache_index]);
	CacheBusy[cache_index] -= 1;
	FwDimSubscribeBusy = 0;
}
