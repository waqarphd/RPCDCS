/**@name LIBRARY: fwTrending.ctl
This library contains utility functions for the Trending Tool.

Creation Date:

Modification History:

Exported functions:
Internal Functions:
Constraints: None

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

@author Piotr Starzyk (IT-CO)
*/

const string fwTrending_ON_VAL = ":_online.._value";
const string fwTrending_ORIG_VAL = ":_original.._value";

const string fwTrending_PAGE = "_FwTrendingPage";
const string fwTrending_PAGE_TITLE = ".pageTitle";
const string fwTrending_PAGE_NCOLS = ".nColumns";
const string fwTrending_PAGE_NROWS = ".nRows";
const string fwTrending_PAGE_PLOTS = ".plots";
const string fwTrending_PAGE_CONTROLS = ".controls";

const string fwTrending_PLOT = "_FwTrendingPlot";
const string fwTrending_PLOT_TITLE = ".plotTitle";
const string fwTrending_PLOT_LEGEND_ON = ".legend";
const string fwTrending_PLOT_BACK_COLOR = ".plotBackColor";
const string fwTrending_PLOT_DPES = ".dpes";
const string fwTrending_PLOT_LEGENDS = ".legendTexts";
const string fwTrending_PLOT_COLORS = ".colors";
const string fwTrending_PLOT_AXII = ".axii";
const string fwTrending_PLOT_IS_TEMPLATE = ".isTemplate";
const string fwTrending_PLOT_CURVES_HIDDEN = ".curvesHidden";
const string fwTrending_PLOT_RANGES_MIN = ".yRangeMin";
const string fwTrending_PLOT_RANGES_MAX = ".yRangeMax";
const string fwTrending_PLOT_TYPE = ".plotType";
const string fwTrending_PLOT_TIME_RANGE = ".timeRange";
const string fwTrending_PLOT_TEMPLATE_NAME = ".templateName";
const string fwTrending_PLOT_IS_LOGARITHMIC = ".isLogarithmic";
const string fwTrending_CURVE_TYPES = ".curveTypes";

const int fwTrending_PLOT_TYPE_POINTS = 0;
const int fwTrending_PLOT_TYPE_STEPS = 1;
const int fwTrending_PLOT_TYPE_LINEAR = 2;
const int fwTrending_PLOT_TYPE_INDIVIDUAL = 99;

/**
Tries to find a non-existing DP name by sticking an underscore at the front
and a random number at the end of a provided 'root'.
@param _from: the 'root' of dp name
@param _uniqueName: the name generated is assigned to this.
@author Piotr Starzyk (IT-CO-BE)
*/
void fwTrending_uniqueName(string _from, string & _uniqueName) {
    string sys, dp;
    sys = dpSubStr(_from, DPSUB_SYS);
    dp = dpSubStr(_from, DPSUB_DP);
	do {
		_uniqueName = "_" + dp + "_" + rand();
	} while(dpExists(sys + _uniqueName));
	//_uniqueName = sys + _uniqueName;
}


dyn_dyn_string fwTrending_makeDynDynString() {
    dyn_dyn_string ret;
    int i, j;
    for(i = 1; i <= 6; i++)
        for(j = 1; j <= 6; j++)
            ret[i][j] = "";
}

int fwTrending_nonEmptyDynLen(dyn_string _of) {
    int len = dynlen(_of);
    while(len > 0 && _of[len] == "")
        len--;
    return len;
}

string fwTrending_getColRow(dyn_string _from, int _col, int _row) {
    if(6 * (_row - 1) + _col > dynlen(_from)) return "";
    return _from[6*(_row - 1) + _col];
}

void fwTrending_setColRow(dyn_string & _in, int _col, int _row, string _value) {
    _in[6 * (_row - 1) + _col] = _value;
}

/**
Copies all the data from one page Dp to another one.
@param _from: data source
@param _to: data destination
*/
void fwTrending_copyPageData(string _from, string _to) {
    string title;
    int nCols, nRows;
    dyn_string plots;
    bool controls;

    fwTrending_readPageData(_from, title, nCols, nRows, plots, controls);
    fwTrending_fillPageData(_to, title, nCols, nRows, plots, controls);
}

/**
Reads all the page data and returns it in the argument variables provided.
@param _from: the page dp to read from.
@param _title: page title
@param _nCols: number of page columns
@param _nRows: number of page rows
@param _plots: dp names of plots on the page
@param _controls: page "controls on" flag
*/
void fwTrending_readPageData(string _from, string & _title, int & _nCols,
    int & _nRows, dyn_string & _plots, bool & _controls) {
    dpGet(_from + fwTrending_PAGE_TITLE + fwTrending_ON_VAL, _title);
    dpGet(_from + fwTrending_PAGE_NCOLS + fwTrending_ON_VAL, _nCols);
    dpGet(_from + fwTrending_PAGE_NROWS + fwTrending_ON_VAL, _nRows);
    dpGet(_from + fwTrending_PAGE_PLOTS + fwTrending_ON_VAL, _plots);
    dpGet(_from + fwTrending_PAGE_CONTROLS + fwTrending_ON_VAL, _controls);
}

/**
Sets all the page data.
@param _from: the page dp to read from.
@param _title: page title
@param _nCols: number of page columns
@param _nRows: number of page rows
@param _plots: dp names of plots on the page
@param _controls: page "controls on" flag
*/
void fwTrending_fillPageData(string _to, string _title, int _nCols, int _nRows,
    dyn_string _plots, bool _controls) {
    dpSet(_to + fwTrending_PAGE_TITLE + fwTrending_ORIG_VAL, _title);
    dpSet(_to + fwTrending_PAGE_NCOLS + fwTrending_ORIG_VAL, _nCols);
    dpSet(_to + fwTrending_PAGE_NROWS + fwTrending_ORIG_VAL, _nRows);
    dpSet(_to + fwTrending_PAGE_PLOTS + fwTrending_ORIG_VAL, _plots);
    dpSet(_to + fwTrending_PAGE_CONTROLS + fwTrending_ORIG_VAL, _controls);
}

/**
Creates a new page with a random name.
@param _pageName : returns the name of newly created page
 */
void fwTrending_newPage(string & _pageName) {
    fwTrending_uniqueName("", _pageName);
    dpCreate(_pageName, fwTrending_PAGE);
    fwTrending_fillPageData(_pageName, "", 1, 1, makeDynString(), false);
}

/**
Stores a page into a normal-name one and adds it into the context specified.
@param _pageName : page to store
@param _newName : a new name for the page
@param _context : context to add page to
@param _exceptionInfo : returns possible exception information
 */
void fwTrending_storePage(string _pageName, string _newName, dyn_string _context,
    dyn_string &_exceptionInfo) {
    string label;
//    dpCreate(_newName, fwTrending_PAGE);
    dpGet(_pageName + fwTrending_PAGE_TITLE + fwTrending_ON_VAL, label);
    fwDevice_create(fwTrending_PAGE, _newName, label, _context, _exceptionInfo);
    fwTrending_copyPageData(_pageName, _newName);
    dpGet(_newName + fwTrending_PAGE_TITLE + fwTrending_ON_VAL, label);
//    fwDevice_addInHierarchy(getSystemName() + _newName, label, _context, _exceptionInfo);
    dpDelete(_pageName);
}

/**
Copies contents of a page to a new instance
@param _pageName : the page to be copied
@param _newName : returns generated name of the new one
 */
void fwTrending_copyPage(string _pageName, string & _newName) {
    fwTrending_uniqueName(_pageName, _newName);
    dpCreate(_newName, fwTrending_PAGE);
    fwTrending_copyPageData(_pageName, _newName);
}

/**
Deletes a page. This includes unlinking it from all contexts.
@param _pageName : the name of a page to delete
@param _exceptionInfo : returns possible exception information
 */
void fwTrending_deletePage(string _pageName, dyn_string & _exceptionInfo) {
    fwDeviceDelete(_pageName, _exceptionInfo);
}

/**
Copies all the data from one plot to another.
@param _from : source plot name
@param _to : destination plot name
*/
void fwTrending_copyPlotData(string _from, string _to) {
    string title, backColor, templateName; bool legendOn, isTemplate, isLogarithmic;
    dyn_string dpes, legends, colors; dyn_bool axii, curvesHidden;
    dyn_float rangesMin, rangesMax; int type, timeRange; dyn_int curveTypes;

    fwTrending_readPlotData(_from, title, legendOn, backColor, dpes, legends, colors, axii,
        curvesHidden, rangesMin, rangesMax, type, timeRange, templateName, isTemplate, isLogarithmic, curveTypes);
    fwTrending_fillPlotData(_to,   title, legendOn, backColor, dpes, legends, colors, axii,
        curvesHidden, rangesMin, rangesMax, type, timeRange, templateName, isTemplate, isLogarithmic, curveTypes);
}

/**
Reads all the data from a plot to variables provided.
@param _from : the name of a plot to read from.
@param _title
@param _legendOn
@param _backColor
@param _dpes
@param _legends
@param _colors
@param _axii
@param _curvesHidden
@param _rangesMin
@param _rangesMax
@param _type
@param _timeRange
@param _templateName
@param _isTemplate
@param _isLogarithmic
@param _curveTypes
*/
void fwTrending_readPlotData(string _from, string & _title, bool & _legendOn, string & _backColor,
    dyn_string & _dpes, dyn_string & _legends, dyn_string & _colors, dyn_bool & _axii,
    dyn_bool & _curvesHidden, dyn_float & _rangesMin, dyn_float & _rangesMax, int & _type,
    int & _timeRange, string & _templateName, bool & _isTemplate, bool & _isLogarithmic, dyn_int & _curveTypes) {
    dpGet(_from + fwTrending_PLOT_TITLE + fwTrending_ON_VAL, _title);
    dpGet(_from + fwTrending_PLOT_LEGEND_ON + fwTrending_ON_VAL, _legendOn);
    dpGet(_from + fwTrending_PLOT_BACK_COLOR + fwTrending_ON_VAL, _backColor);
    dpGet(_from + fwTrending_PLOT_DPES + fwTrending_ON_VAL, _dpes);
    dpGet(_from + fwTrending_PLOT_LEGENDS + fwTrending_ON_VAL, _legends);
    dpGet(_from + fwTrending_PLOT_COLORS + fwTrending_ON_VAL, _colors);
    dpGet(_from + fwTrending_PLOT_AXII + fwTrending_ON_VAL, _axii);
    dpGet(_from + fwTrending_PLOT_CURVES_HIDDEN + fwTrending_ON_VAL, _curvesHidden);
    dpGet(_from + fwTrending_PLOT_RANGES_MIN + fwTrending_ON_VAL, _rangesMin);
    dpGet(_from + fwTrending_PLOT_RANGES_MAX + fwTrending_ON_VAL, _rangesMax);
    dpGet(_from + fwTrending_PLOT_TYPE + fwTrending_ON_VAL, _type);
    dpGet(_from + fwTrending_PLOT_TIME_RANGE + fwTrending_ON_VAL, _timeRange);
    dpGet(_from + fwTrending_PLOT_TEMPLATE_NAME + fwTrending_ON_VAL, _templateName);
    dpGet(_from + fwTrending_PLOT_IS_TEMPLATE + fwTrending_ON_VAL, _isTemplate);
    dpGet(_from + fwTrending_PLOT_IS_LOGARITHMIC + fwTrending_ON_VAL, _isLogarithmic);
	dpGet(_from + fwTrending_CURVE_TYPES + fwTrending_ON_VAL, _curveTypes);	
}

/**
Fills a plot with the data provided.
@param _from : the name of a plot to write to.
@param _title
@param _legendOn
@param _backColor
@param _dpes
@param _legends
@param _colors
@param _axii
@param _curvesHidden
@param _rangesMin
@param _rangesMax
@param _type
@param _timeRange
@param _templateName
@param _isTemplate
@param _isLogarithmic
@param _curveTypes
*/
void fwTrending_fillPlotData(string _to, string  _title, bool  _legendOn, string  _backColor,
    dyn_string  _dpes, dyn_string  _legends, dyn_string  _colors, dyn_bool  _axii,
    dyn_bool  _curvesHidden, dyn_float  _rangesMin, dyn_float  _rangesMax, int  _type,
    int  _timeRange, string  _templateName, bool  _isTemplate, bool _isLogarithmic, dyn_int _curveTypes) {
    dpSet(_to + fwTrending_PLOT_TITLE + fwTrending_ORIG_VAL, _title);
    dpSet(_to + fwTrending_PLOT_LEGEND_ON + fwTrending_ORIG_VAL, _legendOn);
    dpSet(_to + fwTrending_PLOT_BACK_COLOR + fwTrending_ORIG_VAL, _backColor);
    dpSet(_to + fwTrending_PLOT_DPES + fwTrending_ORIG_VAL, _dpes);
    dpSet(_to + fwTrending_PLOT_LEGENDS + fwTrending_ORIG_VAL, _legends);
    dpSet(_to + fwTrending_PLOT_COLORS + fwTrending_ORIG_VAL, _colors);
    dpSet(_to + fwTrending_PLOT_AXII + fwTrending_ORIG_VAL, _axii);
    dpSet(_to + fwTrending_PLOT_CURVES_HIDDEN + fwTrending_ORIG_VAL, _curvesHidden);
    dpSet(_to + fwTrending_PLOT_RANGES_MIN + fwTrending_ORIG_VAL, _rangesMin);
    dpSet(_to + fwTrending_PLOT_RANGES_MAX + fwTrending_ORIG_VAL, _rangesMax);
    dpSet(_to + fwTrending_PLOT_TYPE + fwTrending_ORIG_VAL, _type);
    dpSet(_to + fwTrending_PLOT_TIME_RANGE + fwTrending_ORIG_VAL, _timeRange);
    dpSet(_to + fwTrending_PLOT_TEMPLATE_NAME + fwTrending_ORIG_VAL, _templateName);
    dpSet(_to + fwTrending_PLOT_IS_TEMPLATE + fwTrending_ORIG_VAL, _isTemplate);
    dpSet(_to + fwTrending_PLOT_IS_LOGARITHMIC + fwTrending_ORIG_VAL, _isLogarithmic);
    dpSet(_to + fwTrending_CURVE_TYPES + fwTrending_ORIG_VAL, _curveTypes);	
}

/**
Creates a new plot with a randomly generated name.
@param _plotName : returns the new plot name.
*/
void fwTrending_newPlot(string & _plotName) {
    fwTrending_uniqueName("", _plotName);
    dpCreate(_plotName, fwTrending_PLOT);
    fwTrending_fillPlotData(_plotName, "", false, "FwTrendingTrendBackgroundDefault", makeDynString(),makeDynString(), 
    	makeDynString("FwTrendingCurve1","FwTrendingCurve2","FwTrendingCurve3","FwTrendingCurve4",
    				  "FwTrendingCurve5","FwTrendingCurve6","FwTrendingCurve7","FwTrendingCurve8"), 
    	makeDynBool(), makeDynBool(),
        makeDynFloat(), makeDynFloat(), fwTrending_PLOT_TYPE_LINEAR, 3600, "", false, false,
        makeDynInt(fwTrending_PLOT_TYPE_POINTS, fwTrending_PLOT_TYPE_POINTS, fwTrending_PLOT_TYPE_POINTS, fwTrending_PLOT_TYPE_POINTS,
        		   fwTrending_PLOT_TYPE_POINTS, fwTrending_PLOT_TYPE_POINTS, fwTrending_PLOT_TYPE_POINTS, fwTrending_PLOT_TYPE_POINTS));
}

/**
Stores a plot into a new datapoint and adds it into a context specified.
@param _plotName : the name of a plot to store
@param _newName : the new name to store plot under
@param _context : a context to which the plot should be added
@param _exceptionInfo : returns possible exception information
*/
void fwTrending_storePlot(string _plotName, string _newName, dyn_string _context,
    dyn_string &_exceptionInfo) {
    string label;
    //dpCreate(_newName, fwTrending_PLOT);
    dpGet(_plotName + fwTrending_PLOT_TITLE + fwTrending_ON_VAL, label);
    fwDevice_create(fwTrending_PLOT, _newName, label, _context, _exceptionInfo);
    fwTrending_copyPlotData(_plotName, _newName);
    //fwDevice_addInHierarchy(getSystemName() + _newName, label, _context, _exceptionInfo);
    dpDelete(_plotName);
}

/**
Creates a new copy of an existing plot under a randomly generated name
@param _plotName : the name of a plot to be copied
@param _newName : returns the name plot has been copied to
*/
void fwTrending_copyPlot(string _plotName, string & _newName) {
    fwTrending_uniqueName(_plotName, _newName);
    dpCreate(_newName, fwTrending_PLOT);
    fwTrending_copyPlotData(_plotName, _newName);
}

/**
Deletes a plot
@param _plotName : the name of a plot to be deleted
@param _exceptionInfo : returns possible exception information
*/
void fwTrending_deletePlot(string _plotName, dyn_string & _exceptionInfo) {
    fwDeviceDelete(_plotName, _exceptionInfo);
}

/**
Searches for all plots which are based on a given one, i.e. have their templateName
set to this one.
@param _on : the parent plot to search for
@param _result : plots found
*/
void fwTrending_findPlotsBasedOn(string _on, dyn_string & _result) {
    dyn_dyn_anytype resultSet;
    int i;
    string query = "SELECT 'templateName:_online.._value'"
        + " FROM '*' WHERE (_DPT==\"_FwTrendingPlot\") AND 'templateName:_online.._value'==\"" + _on + "\"" ;

    dpQuery(query, resultSet);

    if(dynlen(resultSet) < 2)
        return;
    for(i = 2; i <= dynlen(resultSet); i++)
        _result[i - 1] = resultSet[i][1];
}

/**
Applies the settings of one plot (a template) to another one (an instance). 
This means overwriting all the values besides title, curves dpe specification 
and legend texts and the fiels indicating the template.
@param _in : the plot the changes are to be made in
@param _by : the plot values should be taken from
*/
void fwTrending_reapplyPlotSettings(string _in, string _by) {
    string title, backColor, templateName; bool legendOn, isTemplate, isLogarithmic;
    dyn_string dpes, legends, colors; dyn_bool axii, curvesHidden;
    dyn_float rangesMin, rangesMax; int type, timeRange; dyn_int curveTypes;

    fwTrending_readPlotData(_by, title, legendOn, backColor, dpes, legends, colors, axii,
        curvesHidden, rangesMin, rangesMax, type, timeRange, templateName, isTemplate, isLogarithmic, curveTypes);
    // reread these in order not to overwrite them.
    dpGet(_in + fwTrending_PLOT_TITLE + fwTrending_ON_VAL, title);
    dpGet(_in + fwTrending_PLOT_DPES + fwTrending_ON_VAL, dpes);
    dpGet(_in + fwTrending_PLOT_LEGENDS + fwTrending_ON_VAL, legends);
    dpGet(_in + fwTrending_PLOT_TEMPLATE_NAME + fwTrending_ON_VAL, templateName);
    fwTrending_fillPlotData(_in, title, legendOn, backColor, dpes, legends, colors, axii,
        curvesHidden, rangesMin, rangesMax, type, timeRange, templateName, isTemplate, isLogarithmic, curveTypes);
}

/**
Reapplies settings of a template plot to all plots based on it.
@param _by : the template plot whose settings are to be applied to the other plots.
*/
void fwTrending_reapplyPlotSettingsToAll(string _by) {
    dyn_string plots;
    int i;

    fwTrending_findPlotsBasedOn(_by, plots);
    for(i = 1; i <=dynlen(plots); i++) {
        fwTrending_reapplyPlotSettings(plots[i], _by);
    }
}


string _fwTrending_subst(string _in, dyn_string _by) {
	int i = 0;
	int j = 1;
	string out;

	while(i < strlen(_in)) {
		while(i < strlen(_in) && _in[i] != '[')
			out += _in[i++];
		while(i < strlen(_in) && _in[i] == '[')
			i++;
		while(i < strlen(_in) && _in[i] != ']')
			i++;
		while(i < strlen(_in) && _in[i] == ']')
			i++;
		if(i >= 1 && _in[i - 1] == ']') {
			if(j <= dynlen(_by))
				out += '[' + _by[j++] + ']';
			else
				out += "[]";
		}
	}
	return out;
}

dyn_string _fwTrending_split(string _in) {
	int i = 0;
	int j = 1;
	dyn_string out;

	while(i < strlen(_in)) {
		while(i < strlen(_in) && _in[i] != '[')
			out += _in[i++];
		while(i < strlen(_in) && _in[i] == '[')
			i++;
		while(i < strlen(_in) && _in[i] != ']')
			out[j] += _in[i++];
		j++;
		while(i < strlen(_in) && _in[i] == ']')
			i++;
	}
	return out;
}

string _fwTrending_strSubst(string _in, string _by) {
	return _fwTrending_subst(_in, _fwTrending_split(_by));
}

// plots & pages

