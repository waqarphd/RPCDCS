/**@name LIBRARY: gcsGenericXMLOperations.ctl

@author: Kulman Nikolay(IT-CO)

Creation Date: 24.03.2005

Modification History: None

version 1.0

Internal Functions :
	. gcsGenericXMLOperations_XMLParseTag
	. gcsGenericXMLOperations_XMLParseTagInfo
	. gcsGenericXMLOperations_XMLParseTagAttribute
	. gcsGenericXMLOperations_FindXMLtag
	. gcsGenericXMLOperations_dynReplace
	. gcsGenericXMLOperations_dynReplaceMany
	
Purpose: This library contains functions which will help to deal with (parse) XML-files.

Usage: Public

*/

//@{


//---------------------------------------------------------------------------------------------------------------------------------------
// gcsGenericXMLOperations_XMLParseTag
/**
Purpose: find and returns first tag with given name.

Parameters:
	returns tag and it's contents. ex. 123<a>abc</a>456 function will return <a>abc</a> if tag does not exist, returns "".
	- sourse, string, input, xml text
	- tag, string, input, tag name. we will search this tag.
	
Usage: External

PVSS manager usage: NG, NV

Constraints:
	. PVSS version: 3.0 and 2.12 , but tested only under 3.0
	. operating system: NT, W2000, WinXP, but tested only under WinXP.
*/
string gcsGenericXMLOperations_XMLParseTag(string sourse, string tag)
{
	string  c, t, res = "";
	int pos1, pos = 0, n = -1;
	t = "<" + tag;
	n = strpos(sourse, t + ">");
	pos1 = strpos(sourse, t +" ");
	if(n == -1 && pos1 == -1) return "";

	if(n != -1) pos = n;
	else if (pos1 != -1) pos = pos1;

	n = pos + strlen(t);
	c = substr(sourse, n, 1);	//	check if this is a <tag> or <tag with="" attributes="">
	res = substr(sourse, pos);
	t = "</"+ tag +">";
	pos = strpos(res, t);
	n = pos + strlen(t);
	if(pos == -1)
	{
		if(c != " ") return "";
		pos = strpos(res, "/>");
		if(pos == -1) return "";
		n = pos + strlen("/>");
	}
	res = substr(res, 0, n);
	res=strltrim(res, " ");
	res=strrtrim(res, " ");
	return res;
}


//---------------------------------------------------------------------------------------------------------------------------------------
// gcsGenericXMLOperations_XMLParseTagInfo
/**
Purpose: find and returns first tag with fiven name. It will return only inner part of the tag

Parameters:
	returns tag's contents. ex. 123<a>abc</a>456 function will return "abc". if tag does not exist, returns default string.
	- sourse, string, input, xml text
	- tag, string, input, tag name. we will search this tag.
	- def, string, input, this string we will return in case od any problem.
	
Usage: External

PVSS manager usage: NG, NV

Constraints:
	. PVSS version: 3.0 and 2.12 , but tested only under 3.0
	. operating system: NT, W2000, WinXP, but tested only under WinXP.
*/
string gcsGenericXMLOperations_XMLParseTagInfo(string source, string tag, string def)
{
	string str, t, res = def;
	int pos = 0;
	
	str = gcsGenericXMLOperations_XMLParseTag(source, tag);
	pos = strpos(str, ">"); //t
	if(pos == -1) return def;

	res = substr(str, pos + 1);
	t = "</" + tag + ">";
	pos = strpos(res, t);
	if(pos == -1) return def;
	res = substr(res, 0, pos);
	res=strltrim(res, " ");
	res=strrtrim(res, " ");
	return res;
}


//---------------------------------------------------------------------------------------------------------------------------------------
// gcsGenericXMLOperations_XMLParseTagAttribute
/**
Purpose: find and returns in first tag with fiven name attribute.

Parameters:
	returns tag's contents. ex. 123<a b="abc" />456 function will return "abc". if tag does not exist, returns default string.
	- sourse, string, input, xml text
	- tag, string, input, tag name. we will search this tag.
	- attr, string, input, attribute name. we will search this attribute inside the tag.
	- def, string, input, this string we will return in case od any problem.
	
Usage: External

PVSS manager usage: NG, NV

Constraints:
	. PVSS version: 3.0 and 2.12 , but tested only under 3.0
	. operating system: NT, W2000, WinXP, but tested only under WinXP.
*/
string gcsGenericXMLOperations_XMLParseTagAttribute(string sourse, string tag, string attr, string def)
{
	string t, res = def;
	int pos = 0;
	pos = strpos(sourse, tag);
	if(pos == -1) return def;
	t = substr(sourse, pos + strlen(tag));
	pos = strpos(t, ">");
	if(pos == -1) return def;
	t = substr(t, 0, pos);	//	in 'T' we got whole tag. Let's parse attribute
	pos = strpos(t, attr);
	if(pos == -1) return def;
	res = substr(t, pos);
	pos = strpos(res, "\"");
	if(pos == -1) return def;
	res = substr(res, pos + strlen("\""));
	pos = strpos(res, "\"");
	if(pos == -1) return def;
	res = substr(res, 0, pos);
	res=strltrim(res, " ");
	res=strrtrim(res, " ");
	return res;
}



string gcsGenericXMLOperations_FindXMLtag(string XMLsource, string tagName, string AttrName, string AttrVal)
{
string curTag, curAttr;
string source = XMLsource;

	while(1)
	{
		curTag = gcsGenericXMLOperations_XMLParseTag(source, tagName);
		if(curTag == "") return "";
		curAttr = gcsGenericXMLOperations_XMLParseTagAttribute(curTag, tagName, AttrName, "");
		if(curAttr == AttrVal) return curTag;
		strreplace(source, curTag, "");
	}
	return "";
}


gcsGenericXMLOperations_dynReplace(dyn_anytype& values, anytype pattern, anytype newval)
{
	while(true)
	{
		int i = dynContains(values, pattern);
		if( i <= 0) break;
		dynRemove(values, i);
		dynInsertAt(values, newval, i);
	}
}

gcsGenericXMLOperations_dynReplaceMany(dyn_anytype& values, dyn_anytype pattern, dyn_anytype newval)
{
	if(dynlen(pattern) != dynlen(newval)) return;
	for(int i = 1; i <= dynlen(pattern); i++)
		gcsGenericXMLOperations_dynReplace(values, pattern[i], newval[i]);
}

/*
CString XMLStringPrepareToRead(const CString sourse)
{
	CString t = sourse;
	t.Replace("&#60;", "<");
	t.Replace("&#62;", ">");
	t.Replace("&#34;", "\"");
	return t;
}

CString XMLStringPrepareToWrite(const CString sourse)
{
	CString t = sourse;
	t.Replace("\'", "&#34;");
	t.Replace("<", "&#60;");
	t.Replace(">", "&#62;");
	return t;
}
*/


////////////////////////
