/**@file

This library contains utility functions for the Trending Tool.

@par Creation Date
	19/12/2002

@par Modification History

  28/08/2012: Johannes Lang
	Fix for FWTREND-872
	- _fwTrending_initCurve()'s algorithm to link/unlink curves changed: First cleaning all links, then linking again, if necessary

  13/04/2012: Johannes Lang
	Fix for FWTREND-865 and FWTREND-864
	- _fwTrending_initCurve() extended concerning alarm limits toggle, setting of scale limits completely removed
	- fwTrending_toggleAlarmLimits() changed: extended parameter list and scale adjustment changed
	- fwTrending_trendUpdateAlarmLimits() new: layer between init and alarm limit toggle for dpQueryConnect usage
	- fwTrending_trendUpdateScales() new: all explicit setting of scale min/max limits outsourced to this method
	
  23/03/2012: Johannes Lang
	Fix for FWTREND-866:
    - Whole code reformated
    - new internal methods for string adjustment of dpNames
    - Automatic adjustment of y-scale for alarm curves suppressed if min/max of scale is set manually
    - new fwTrending_trendZoomToAlarmLimits() for easy reseting of visible plot area by scale adjustment
    - new internal methods to calculate minimum and maximum in dyn_dyn_float (_fwTrending_getMin() and _fwTrending_getMax())
	
  16/06/2011: Marco Boccioli
    - Fix for @sav{83252}: Histogram: values not plotted if dpe passed as template param without sys name.
    in the function _fwTrending_updateHistogram(), if no system name was passed as template {} parameter, add the local sys name

  29/01/2011: Marco Boccioli
    - Fix for @sav{77214}, ENS-2447: assign dpe legend name to the legend of the alarm limits.
    - Fix for @sav{77700}: new functions fwTrending_getPageTreeTagNames(), fwTrending_getPlotTreeTagNames()
    they return an array of plot data as tag names, that can be used for export/import the trending configs.
    fwTrending_isPageTreeTagExportable(), fwTrending_isPlotTreeTagExportable(),
    they a index of the plot data and return if that data should be exported.

  02/12/2010: Marco Boccioli
    - Fix for @sav{75930}: After upgrading existing trending to fwTrending 3.3.1,
      the date on the X axis was shown twice on 2 lines. Now the default value is applied.

  12/11/2010: Marco Boccioli
    - Fix for @sav{75191}: Customizable default plot setting. Modified fwTrending_newPlot(): it checks now if
	  a default settings dpe (fwTrending_PLOT_DEFAULTS) exists. If yes, apply those settings to new plots.
	  If not, apply coded settings.
	
  11/11/2010: Marco Boccioli
    - Fix for @sav{71141}: Uncaught exception during install of trending tool.
      The SCALE_LEFT constant is probably imported from some library only by the UI manager.
      This is probably why the CTRL manager does not know it.

  27/10/2010: Marco Boccioli
    - @jira{IS-294} (back-compatibility with un functions). Modified functions fwTrending_setPlot(), fwTrending_setPage().
      It writes the new settings only after checking they are passed as parameters.

  27/10/2010: Marco Boccioli
    - Fix for @sav{74445} (Hide/show legend also on trend pages). Modified function fwTrending_controlBarOnOff()
      It now handles the references to the different trend plots in the trend pages.

  05/10/2010: Marco Boccioli
    - Fix for @sav{73928} (Y scale format error when applying settings). Modified function fwTrending_showStandardTrend()
    - Fix for @sav{73592} (Y axis: custom format not correctly set).

  20/08/2010: Marco Boccioli
    - fix for @jira{ENS-1707} (zoom in/out was not possible using the CTRL-# key shortcuts).
      The hidden buttons for zooming in/out were disabled by _fwTrending_initGenericTrendControls().
      Disabling is now removed. Furthermore, the buttons were using native trend widget methods.
      They now use the functions fwTrending_trendZoomX(), fwTrending_trendZoomY().

  20/08/2010: Marco Boccioli
    - fix for @jira{ENS-1520} (X axis scale information disappear): for some reason PVSS does not handle well
      the default value format (empty-string format): it is correctly shown only if inside a range that
      does not trigger the format overriding (PVSS overrides the scale format for some time ranges,
      i.e. very deep zoom in, or extensive zoom-out). I've added a default value ("%c") to be used if the
      received value is empty string.

  04/08/2010: Marco Boccioli
    - fix for @jira{ENS-1045} (log scale): when activating the Log scale, now the function fwTrending_showStandardTrend()
      accepts optional parameter plotData. With this it can access the scale formats and toggle automatically
      engineering format (if Log) or default/custom format (if linear).

  30/07/2010: Marco Boccioli
    - Fix for @sav{68678} (Plot alarm limits): the limits of the alarm of
      the plotted value can be plotted on the trend.
      This info is on fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW.
      On the panels, this parameter is appended to the param $dsCurveVisible. Positions:
      1-8: the curve visibility
      9-16: the curve alarms visibility

  30/06/2010: Marco Boccioli
    - Fix for @sav{68333}: exporting curves to CSV now has option to exclude hidden curves.
    - Fix for @sav{69566}: for each curve, the value format on the scale can be customized.
      This info is on fwTrending_PLOT_OBJECT_LEGEND_AXII_Y_FORMAT.
      On the panels, this parameter is appended to the param $dsCurveScaleVisible. Positions:
      1-8: the scale visibility
      9-16: the scale position
      17-24: the scale link
      25-32: the scale format
    - Fix for @sav{69424}: for each curve, value format on the legend can be customized.
      This info is on fwTrending_PLOT_OBJECT_LEGEND_VALUE_FORMAT.
      On the panels, this parameter is appended to the param $sLegends. Positions:
      1-8: the legends texts
      9-16: the legend values format
    - Fix for @sav{68074}: date format for the X axis can be customized.
      This info is on fwTrending_PLOT_OBJECT_AXII_X_FORMAT.
      On the panels, this parameter is appended to the param $sTimeRange. Positions:
      1   timeRange
      2   format for time on x axis - first line
      3   format for time on x axis - second line

  26/05/2010: Marco Boccioli
    - Fix for @sav{55166}: curves line can be modified in width and style.
      This info is on fwTrending_PLOT_OBJECT_CURVE_STYLE.
      On the panels, this parameter is appended to the param $iMarkerType.
    - Fix for @sav{67907}: fonts can be modified. This info is on fwTrending_PLOT_OBJECT_DEFAULT_FONT.
      On the panels, this parameter is appended to the param $sForeColor.
    - Fix for @sav{55167},	 @sav{66698}: curves can be linked to each other. Each curve has a new property:
      id number (1-8) of the curve to be linked to. This info is on fwTrending_PLOT_OBJECT_AXII_LINK.
      On the panels, this parameter is appended to the param $dsCurveScaleVisible after the scale position.

  29/04/2010: Marco Boccioli
    - Fix for @sav{66064},	 @sav{66488}: a new function fwTrending_controlBarOnOff() toggles the control menu bar and
      the captions bar.
      If the bar is hidden, the trending area is expanded.
      The captions can be hidden, the trending area is expanded.
    - Fix for @sav{35454}: scale position: the trending can now show the scale of a curve at the left or at the right.
      Such information is stored into the index fwTrending_PLOT_OBJECT_AXII_POS.
      It is passed to the trending panels through the already existing parameter $dsCurveScaleVisible
      (the 8 values are appended to the parameter).
    - removed Fix for @sav{65392}: the function _fwTrending_gotoNow() does just .gotoNow().

  06/04/2010: Marco Boccioli
    - Fix for @sav{65392}: a new function _fwTrending_gotoNow() shows the last value using a different
      procedure depending on the PVSS version. Replaced all the .gotoNow() with _fwTrending_gotoNow().

  25/03/2010: Marco Boccioli
    - Fix for @sav{40368}: added a check for empty values of datapoints to _fwTrending_updateHistogram().
      Now, if there is no value in the dpe to plot, the histogram is cleaned.
    - Fix for @sav{55165}: skip evaluation of parameters when calling _fwTrending_evaluateTemplate()
      passing the string "parameterValues" as given parameter.
    - Fix for @sav{64959}: _fwTrending_updateHistogram() could not load dpe from template "{}". Fixed.

  02/07/2008: Herve (ref. in the code start/end 02/07/2008: Herve)
    - bug in fwTrending_ShowCurve
      commented out the lines yAxisControl = getShape(ref + "YAxiiCascadeButton"); and
      yAxisControl.enableItem(curveNumber-1, visibility);
    - to keep consistency: in fwTrending_initControlTrendButtons the YAxiiCascadeButton cascade
      item is not disabled if the curve is not visible.

  20/05/2008: Herve (ref. in the code start/end 20/05/2008: Herve)
    - in fwTrending_initTrendWithObject, fwTrending_legendOnOff:
      comment out all manageLegend call
    - in _fwTrending_initCurve:
      add curveLegendShowDate, curveLegendShowDate curveLegendShowMilli curveLegendFormat, curveLegendUnit
      bug exp --> convert to %n.10f (n=nb of digit from the format of the DPE, ex: %2.3e converted to %2.10f
      markerType = 0 (POINT_NONE) by default
      reset exceptionInfo in case of UNICOS installation
      move curveScaleVisibility after connectDirectly
    - fwTrending_initTrendWithObject, fwTrending_showStandardTrend, fwTrending_changeTrendTimeRange,
    fwTrending_trendZoomX, fwTrending_trendZoomY, fwTrending_gridOnOff,
    fwTrending_legendOnOff, fwTrending_trendUnzoom, fwTrending_trendRefresh
    fwTrending_setRuntimePlotDataWithStrings, fwTrending_getRuntimePlotDataWithStrings:
      comment out any reference to logTrendShape

	10/06/2003: Herve added several functions
	12/06/2003: Herve
		in the fwTrending_getPlotData function
			. add a check of dynlen(dsAxii) >= i before adding dsAxii[i]+";" othervise add to returnValue[12] to "FALSE;" because
			the axii may be empty if the axii visibility was never modified.
			. add a check of dynlen(dsLeg) >= i before adding dsLeg[i]+";" othervise add to returnValue[5] to ";" because
			the legend may be empty if the it was never modified. If the legend is empty the set it to dpe.
		in the function fwTrending_getPlotTitle
			. if the title is "", set t=it to sPlotName
		add the function fwTrending_showPlot: to show one or many plots and also the constant for plots position
	17/06/2003: Herve added several functions
		modify the signature of fwTrending_showPlot: add dsReference as output param.
	10/07/2003: Sascha - new functions and some modifications to some
	14/07/2003: Sascha - some more modifications				
	17/07/2003: Sascha modify the functions fwTrending_getAllPlots and fwTrending_getAllPages to work in a distributed environment
	10/09/2003: Herve
		add two internal function _fwTrending_openProgressBar and _fwTrending_closeProgressBar
		add in fwTrending_exportTrend the _fwTrending_openProgressBar and _fwTrending_closeProgressBar function call
	20/01/2004: Sascha some modifications and deleted two functions
		deleted the function fwTrending_savePlotTitle: save the title of a plot
		deleted the function fwTrending_savePageTitle: save the title of a page
	
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author
	Oliver Holme, Sascha Schmeling, Herve Milcent, Piotr Starzyk (IT-CO)
*/

//@{
const string fwTrending_ON_VAL = ":_online.._value";
const string fwTrending_OFF_VAL = ":_offline.._value";
const string fwTrending_ORIG_VAL = ":_original.._value";

const string fwTrending_YT_PAGE_MODEL = "Value over time";
const string fwTrending_XY_PAGE_MODEL = "Value over value";
const string fwTrending_YT_PLOT_MODEL = "Value over time";
const string fwTrending_XY_PLOT_MODEL = "Value over value";
const string fwTrending_HISTOGRAM_PLOT_MODEL = "Histogram";

const string fwTrending_PAGE = "FwTrendingPage";
const string fwTrending_PAGE_MODEL = ".model";
const string fwTrending_PAGE_TITLE = ".pageTitle";
const string fwTrending_PAGE_NCOLS = ".nColumns";
const string fwTrending_PAGE_NROWS = ".nRows";
const string fwTrending_PAGE_PLOTS = ".plots";
const string fwTrending_PAGE_CONTROLS = ".controls";
const string fwTrending_PAGE_PLOT_TEMPLATE_PARAMETERS = ".plotTemplateParams";
const string fwTrending_PAGE_ACCESS_CONTROL_SAVE = ".accessControl.save";

const int fwTrending_PAGE_OBJECT_MODEL = 1;
const int fwTrending_PAGE_OBJECT_TITLE = 2;
const int fwTrending_PAGE_OBJECT_NCOLS = 3;
const int fwTrending_PAGE_OBJECT_NROWS = 4;
const int fwTrending_PAGE_OBJECT_PLOTS = 5;
const int fwTrending_PAGE_OBJECT_CONTROLS = 6;
const int fwTrending_PAGE_OBJECT_PLOT_TEMPLATE_PARAMETERS = 7;
const int fwTrending_PAGE_OBJECT_ACCESS_CONTROL_SAVE = 8;

const string fwTrending_PLOT = "FwTrendingPlot";
const string fwTrending_PLOT_MODEL = ".model";
const string fwTrending_PLOT_TITLE = ".plotTitle";
const string fwTrending_PLOT_LEGEND_ON = ".legend";
const string fwTrending_PLOT_BACK_COLOR = ".plotBackColor";
const string fwTrending_PLOT_FORE_COLOR = ".plotForeColor";
const string fwTrending_PLOT_DPES = ".dpes";
const string fwTrending_PLOT_DPES_X = ".xDpes";
const string fwTrending_PLOT_LEGENDS = ".legendTexts";
const string fwTrending_PLOT_LEGENDS_X = ".xLegendTexts";
const string fwTrending_PLOT_COLORS = ".colors";
const string fwTrending_PLOT_AXII = ".axii";
const string fwTrending_PLOT_AXII_X = ".xAxii";
const string fwTrending_PLOT_IS_TEMPLATE = ".isTemplate";
const string fwTrending_PLOT_CURVES_HIDDEN = ".curvesHidden";
const string fwTrending_PLOT_RANGES_MIN = ".yRangeMin";
const string fwTrending_PLOT_RANGES_MAX = ".yRangeMax";
const string fwTrending_PLOT_RANGES_MIN_X = ".xRangeMin";
const string fwTrending_PLOT_RANGES_MAX_X = ".xRangeMax";
const string fwTrending_PLOT_TYPE = ".plotType";
const string fwTrending_PLOT_TIME_RANGE = ".timeRange";
const string fwTrending_PLOT_TEMPLATE_NAME = ".templateName";
const string fwTrending_PLOT_IS_LOGARITHMIC = ".isLogarithmic";
const string fwTrending_PLOT_GRID = ".grid";
const string fwTrending_PLOT_CURVE_TYPES = ".curveTypes";
const string fwTrending_PLOT_MARKER_TYPE = ".markerType";
const string fwTrending_PLOT_ACCESS_CONTROL_SAVE = ".accessControl.save";
const string fwTrending_PLOT_CONTROL_BAR_ON = ".controlBar";
const string fwTrending_PLOT_AXII_POS = ".axiiPos";
const string fwTrending_PLOT_AXII_LINK = ".axiiLink";
const string fwTrending_PLOT_DEFAULT_FONT = ".defaultFont";
const string fwTrending_PLOT_CURVE_STYLE = ".curveStyle";
const string fwTrending_PLOT_AXII_X_FORMAT = ".xAxiiFormat";
const string fwTrending_PLOT_AXII_Y_FORMAT = ".yAxiiFormat";
const string fwTrending_PLOT_LEGEND_VALUES_FORMAT = ".legendValuesFormat";
const string fwTrending_PLOT_ALARM_LIMITS_SHOW = ".alarmLimitsVisible";
const string fwTrending_PLOT_LEGEND_DATE_ON = ".legendDateOn";
const string fwTrending_PLOT_LEGEND_DATE_FORMAT = ".legendDateFormat";

//kept for compatibility - should always be equal to fwTrending_PLOT_CURVE_TYPES
const string fwTrending_CURVE_TYPES = ".curveTypes";

const int fwTrending_PLOT_OBJECT_MODEL = 1;
const int fwTrending_PLOT_OBJECT_TITLE = 2;
const int fwTrending_PLOT_OBJECT_LEGEND_ON = 3;
const int fwTrending_PLOT_OBJECT_BACK_COLOR = 4;
const int fwTrending_PLOT_OBJECT_FORE_COLOR = 5;
const int fwTrending_PLOT_OBJECT_DPES_X= 6;
const int fwTrending_PLOT_OBJECT_DPES = 7;
const int fwTrending_PLOT_OBJECT_LEGENDS_X = 8;
const int fwTrending_PLOT_OBJECT_LEGENDS = 9;
const int fwTrending_PLOT_OBJECT_COLORS = 10;
const int fwTrending_PLOT_OBJECT_AXII_X = 11;
const int fwTrending_PLOT_OBJECT_AXII = 12;
const int fwTrending_PLOT_OBJECT_IS_TEMPLATE = 13;
const int fwTrending_PLOT_OBJECT_CURVES_HIDDEN = 14;
const int fwTrending_PLOT_OBJECT_RANGES_MIN_X = 15;
const int fwTrending_PLOT_OBJECT_RANGES_MAX_X = 16;
const int fwTrending_PLOT_OBJECT_RANGES_MIN = 17;
const int fwTrending_PLOT_OBJECT_RANGES_MAX = 18;
const int fwTrending_PLOT_OBJECT_TYPE = 19;
const int fwTrending_PLOT_OBJECT_TIME_RANGE = 20;
const int fwTrending_PLOT_OBJECT_TEMPLATE_NAME = 21;
const int fwTrending_PLOT_OBJECT_IS_LOGARITHMIC = 22;
const int fwTrending_PLOT_OBJECT_GRID = 23;
const int fwTrending_PLOT_OBJECT_CURVE_TYPES = 24;
const int fwTrending_PLOT_OBJECT_MARKER_TYPE = 25;
const int fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE = 26;
const int fwTrending_PLOT_OBJECT_CONTROL_BAR_ON = 27;
const int fwTrending_PLOT_OBJECT_AXII_POS = 28;
const int fwTrending_PLOT_OBJECT_AXII_LINK = 29;
const int fwTrending_PLOT_OBJECT_DEFAULT_FONT = 30;
const int fwTrending_PLOT_OBJECT_CURVE_STYLE = 31;
const int fwTrending_PLOT_OBJECT_AXII_X_FORMAT = 32;
const int fwTrending_PLOT_OBJECT_AXII_Y_FORMAT = 33;
const int fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT = 34;
const int fwTrending_PLOT_OBJECT_LEGEND_DATE_FORMAT = 35;
const int fwTrending_PLOT_OBJECT_LEGEND_DATE_ON = 36;
const int fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW = 37;

const int fwTrending_PLOT_OBJECT_EXT_MIN_FOR_LOG = 38;
const int fwTrending_PLOT_OBJECT_EXT_MAX_PERCENTAGE_FOR_LOG = 39;
const int fwTrending_PLOT_OBJECT_EXT_UNITS_X = 40;
const int fwTrending_PLOT_OBJECT_EXT_UNITS = 41;
const int fwTrending_PLOT_OBJECT_EXT_TOOLTIPS_X = 42;
const int fwTrending_PLOT_OBJECT_EXT_TOOLTIPS = 43;
const int fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE_X = 44;
const int fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE = 45;

const int fwTrending_CURVE_OBJECT_DPE = 1;
const int fwTrending_CURVE_OBJECT_TYPE = 2;
const int fwTrending_CURVE_OBJECT_COLOR = 3;
const int fwTrending_CURVE_OBJECT_LEGEND = 4;
const int fwTrending_CURVE_OBJECT_AXIS = 5;
const int fwTrending_CURVE_OBJECT_HIDDEN = 6;
const int fwTrending_CURVE_OBJECT_Y_MIN = 7;
const int fwTrending_CURVE_OBJECT_Y_MAX= 8;

const int fwTrending_LINEAR_TREND_NAME = 1;
const int fwTrending_LOG_TREND_NAME = 2;
const int fwTrending_ACTIVE_TREND_NAME = 3;

const int fwTrending_PLOT_TYPE_POINTS = 0;
const int fwTrending_PLOT_TYPE_STEPS = 1;
const int fwTrending_PLOT_TYPE_LINEAR = 2;
const int fwTrending_PLOT_TYPE_INDIVIDUAL = 99;

// Standards
const int fwTrending_PLOT_TYPE_STANDARD = 1;

// Access Control
const int fwTrending_DOMAIN = 1;
const int fwTrending_PRIVILEDGE_PLOT_CHANGE = 2;
const int fwTrending_PRIVILEDGE_PAGE_CHANGE = 2;
const int fwTrending_PRIVILEDGE_ARCHIVE_CHANGE = 3;

const int fwTrending_MAX_NUM_CURVES = 8;
const int fwTrending_Y_VALUE = 1;
const int fwTrending_X_VALUE = 2;

/* added by Herve */
const float fwTrending_MIN_FOR_LOG = 1e-1;
const float fwTrending_MAX_PERCENTAGE_FOR_LOG = 5; // in some case the Ymax range is not shown with the log trend. this guarantee to see it
const int fwTrending_TRENDING_MAX_CURVE = 8;
const int fwTrending_ZOOMED_WINDOW_MAX_LEGEND_SIZE=7;

const int fwTrending_SIZE_PLOT_OBJECT = 45;
const int fwTrending_SIZE_PAGE_OBJECT = 8;
const int fwTrending_SIZE_CURVE_OBJECT = 8;

//kept for compatibility - should always be equal to fwTrending_SIZE_PLOT_OBJECT
const int fwTrending_getPlotData_LEN_RETURN_DATA = 45;

const int fwTrending_TREND_CONTROL_Y_OFFSET = 20;

const int fwTrending_ONE_ROW = 0;
const int fwTrending_ONE_COLUMN = 0;

const int fwTrending_TWO_ROW_1 = 0;
const int fwTrending_TWO_ROW_2 = 417;
const int fwTrending_TWO_COLUMN_1 = 0;
const int fwTrending_TWO_COLUMN_2 = 635;

const int fwTrending_THREE_ROW_1 = 0;
const int fwTrending_THREE_ROW_2 = 280;
const int fwTrending_THREE_ROW_3 = 560;

const string fwTrending_AXIS_LIMITS_DIVIDER = ":";
const string fwTrending_CONTENT_DIVIDER = ";";
const string fwTrending_NOTHING_IN_TREND = ";;;;;;;;";
const int fwTrending_MAX_ROWS = 6;
const int fwTrending_MAX_COLS = 6;
const float fwTrending_TIME_BACK_RESOLUTION = 0.8;
const float fwTrending_TIME_FORWARD_RESOLUTION = 0.8;
const string fwTrending_DEFAULT_FONT ="MS Shell Dlg 2,8,-1,5,50,0,0,0,0,0";
const string fwTrending_DEFAULT_CURVE_STYLE = "[solid,oneColor,JoinMiter,CapButt,0]";
const string fwTrending_DEFAULT_AXII_X_FORMAT = "%c";
const string fwTrending_DEFAULT_AXII_Y_FORMAT = "";
const string fwTrending_DEFAULT_LEGEND_VALUE_FORMAT = "";

const string fwTrending_TEMPLATE_OPEN = "{";
const string fwTrending_TEMPLATE_CLOSE = "}";
const string fwTrending_TEMPLATE_DIVIDER = ",";

const int fwTrending_SECONDS_IN_ONE_MINUTE = 60;
const int fwTrending_SECONDS_IN_ONE_HOUR = 3600;
const int fwTrending_SECONDS_IN_ONE_DAY = 86400;

const string fwTrending_PANEL_PLOT_ZOOMED = "fwTrending/fwTrendingZoomedWindow.pnl";
const string fwTrending_PANEL_PLOT_STANDARD = "fwTrending/fwTrendingPlot.pnl";
const string fwTrending_PANEL_PLOT_FACEPLATE = "objects/fwTrending/fwTrendingFaceplate.pnl";
const string fwTrending_PANEL_PLOT_FACEPLATE_FULLCAPTION = "objects/fwTrending/fwTrendingFaceplateFullCaption.pnl";

const string fwTrending_EXPORT_DATA_PATH = PROJ_PATH + "data/export_CSV/";

const int fwTrending_MARKER_TYPE_FILLED_CIRCLE = 0;
const int fwTrending_MARKER_TYPE_UNFILLED_CIRCLE = 1;
const int fwTrending_MARKER_TYPE_NONE = 2;

const string fwTrending_QUICKPLOT_DEFAULTS = "_FwTrendingQuickPlotDefaults";
const string fwTrending_PLOT_DEFAULTS = "_FwTrendingPlotDefaults";
const string fwTrending_PAGE_DEFAULTS = "_FwTrendingPageDefaults";

const int fwTrending_HIDE_CONTROL_BAR = 1;
const int fwTrending_HIDE_CAPTIONS = 2;
const int fwTrending_HIDE_NONE = 0;

//@}

//@{
/** Read the relevant plot name from the dyn_string containing a list of the plots on a page by giving the column and row of the plot.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotsList		input, the list of plots on a page
@param column			input, the column of the plot to read
@param row				input, the row of the plot to read
@return					The name of the plot at this position on the page is returned
*/
string fwTrending_getColRow(dyn_string plotsList, int column, int row) {
    if(fwTrending_MAX_ROWS * (row - 1) + column > dynlen(plotsList)) {
    	return "";
	}
    return plotsList[fwTrending_MAX_ROWS*(row - 1) + column];
}


/** Writes the given plot name to the dyn_string containing a list of the plots on a page by giving the column and row of the plot.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotsList		the list of plots on a page is passed here and is updated by the function
@param column			input, the column of the plot to read
@param row				input, the row of the plot to read
@param plotName			input, the name of the plot to add in the list of plots on a page
*/
void fwTrending_setColRow(dyn_string &plotsList, int column, int row, string plotName) {
    plotsList[fwTrending_MAX_ROWS * (row - 1) + column] = plotName;
}


/** Get all the plot DP names on all systems

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDpNames		the list of plot dp names is returned here
@param exceptionInfo	details of any exceptions are returned here
*/
fwTrending_getAllPlots(dyn_string &plotDpNames, dyn_string &exceptionInfo) {
	fwTrending_getPlotDpNames(plotDpNames, exceptionInfo, "*:*");
}


/** Get all the plot DP names that match the given pattern

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDpNames		output, the list of plot dp names is returned here
@param exceptionInfo	output, details of any exceptions are returned here
@param pattern			inpupt, Optional parameter, default value "*:*" (all plots on all systems).  Specify a filter to search for plots.
*/
fwTrending_getPlotDpNames(dyn_string &plotDpNames, dyn_string &exceptionInfo, string pattern = "*:*") {
	plotDpNames = dpNames(pattern, fwTrending_PLOT);
}


/** Get all the page DP names on all systems

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param pageDpNames		the list of page dp names is returned here
@param exceptionInfo	details of any exceptions are returned here
*/
fwTrending_getAllPages(dyn_string &pageDpNames, dyn_string &exceptionInfo) {
	fwTrending_getPageDpNames(pageDpNames, exceptionInfo, "*:*");
}


/** Get all the page DP names that match the given pattern

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param pageDpNames		the list of page dp names is returned here
@param exceptionInfo	details of any exceptions are returned here
@param pattern			Optional parameter, default value "*:*" (all page on all systems).  Specify a filter to search for page.
*/
fwTrending_getPageDpNames(dyn_string &pageDpNames, dyn_string &exceptionInfo, string pattern = "*:*") {
	pageDpNames = dpNames(pattern, fwTrending_PAGE);
}


/** Deletes a given plot data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sPlotName			the data point name of the plot to delete
@param exceptionInfo		details of any exceptions are returned here
*/
fwTrending_deletePlot(string sPlotName, dyn_string &exceptionInfo) {
	dpDelete(sPlotName);
}


/** Deletes a given plot data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sPageName			the data point name of the plot to delete
@param exceptionInfo		details of any exceptions are returned here
*/
fwTrending_deletePage(string sPageName, dyn_string &exceptionInfo) {
	dpDelete(sPageName);
}


/** Creates a plot data point.  Checks are carried out if the name is valid or if it already exists.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sPlotName		the data point name of the plot to create
@param exInfo			details of any exceptions are returned here
@param model			OPTIONAL PARAMETER - default value fwTrending_YT_PLOT_MODEL (value over time plot)
						Defines the type of plot to be created, e.g.
						fwTrending_YT_PLOT_MODEL
						fwTrending_XY_PLOT_MODEL
						fwTrending_HISTOGRAM_PLOT_MODEL
*/
fwTrending_createPlot(string sPlotName, dyn_string &exInfo, string model = fwTrending_YT_PLOT_MODEL) {
	if(dpIsLegalName(sPlotName)) {
		if(!dpExists(sPlotName)) {
			fwTrending_newPlot(sPlotName, model);
			if(!dpExists(sPlotName))
				fwException_raise(exInfo, "ERROR", sPlotName+" not created", "");
		} else {
			fwException_raise(exInfo, "ERROR", sPlotName+" already existing", "");
		}
	} else {
		fwException_raise(exInfo, "ERROR", "The data point name is not valid. Valid characters are A..Z, a..z, 0..9 and _", "");
	}
}


/** Creates a page data point.  The page configuration is initialised to default values.
Checks are carried out if the name is valid or if it already exists.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sPageName		the data point name of the page to create
@param exInfo			details of any exceptions are returned here
@param model			OPTIONAL PARAMETER - default value fwTrending_YT_PAGE_MODEL (value over time plot)
						Defines the type of plot to be created, e.g.
						fwTrending_YT_PAGE_MODEL
						fwTrending_XY_PAGE_MODEL
*/
fwTrending_createPage(string sPageName, dyn_string &exInfo, string model = fwTrending_YT_PAGE_MODEL) {
	if(dpIsLegalName(sPageName)) {
		if(!dpExists(sPageName)) {
			fwTrending_newPage(sPageName, model);
			if(!dpExists(sPageName)) {
				fwException_raise(exInfo, "ERROR", sPageName+" not created", "");
			}
		} else {
			fwException_raise(exInfo, "ERROR", sPageName+" already existing", "");
		}
	} else {
		fwException_raise(exInfo, "ERROR", "The data point name is not valid. Valid characters are A..Z, a..z, 0..9 and _", "");
	}
}


/** Creates a page data point.  The page configuration is initialised to default values.
THIS IS AN INTERNAL FUNCTION - If you want to create a page use fwTrending_createPage

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param _pageName	the data point name of the page to create
@param model		OPTIONAL PARAMETER - default value fwTrending_YT_PAGE_MODEL (value over time plot)
					Defines the type of plot to be created, e.g.
					fwTrending_YT_PAGE_MODEL
					fwTrending_XY_PAGE_MODEL
*/
void fwTrending_newPage(string _pageName, string model = fwTrending_YT_PAGE_MODEL) {
	int i, j, maxCols, maxRows;
	dyn_string exceptionInfo;
	dyn_dyn_string data;

	dpCreate(_pageName, fwTrending_PAGE);

	data[fwTrending_PAGE_OBJECT_MODEL] = model;
	data[fwTrending_PAGE_OBJECT_TITLE] = _pageName;
	data[fwTrending_PAGE_OBJECT_NCOLS] = 1;
	data[fwTrending_PAGE_OBJECT_NROWS] = 1;
	data[fwTrending_PAGE_OBJECT_ACCESS_CONTROL_SAVE] = "";

	dpGet("TrendingConfiguration.PageSettings.maxColumns:_original.._value", maxCols);
	dpGet("TrendingConfiguration.PageSettings.maxRows:_original.._value", maxRows);

	for(i=1; i<=maxCols; i++) {
		for(j=1; j<=maxRows; j++) {
			dynAppend(data[fwTrending_PAGE_OBJECT_PLOT_TEMPLATE_PARAMETERS], "");
			dynAppend(data[fwTrending_PAGE_OBJECT_PLOTS], "");
		}
	}
	
	data[fwTrending_PAGE_OBJECT_CONTROLS] = FALSE;
	
	fwTrending_setPage(_pageName, data, exceptionInfo);
}


/** Creates a plot data point.  The plot configuration is initialised to default values.
THIS IS AN INTERNAL FUNCTION - If you want to create a plot use fwTrending_createPlot

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param _plotName		the data point name of the plot to create
@param model			OPTIONAL PARAMETER - default value fwTrending_YT_PLOT_MODEL (value over time plot)
						Defines the type of plot to be created, e.g.
						fwTrending_YT_PLOT_MODEL
						fwTrending_XY_PLOT_MODEL
						fwTrending_HISTOGRAM_PLOT_MODEL
*/
void fwTrending_newPlot(string _plotName, string model = fwTrending_YT_PLOT_MODEL) {
	dyn_string exceptionInfo;
	dyn_dyn_string data;

	dpCreate(_plotName, fwTrending_PLOT);

	//if the default settings exist, use them
	if(dpExists(fwTrending_PLOT_DEFAULTS) && fwTrending_PLOT_DEFAULTS !=_plotName) {
		fwTrending_getPlot(fwTrending_PLOT_DEFAULTS , data, exceptionInfo);
		//remove plot-specific information
		data[fwTrending_PLOT_OBJECT_DPES] = makeDynString("","","","","","","","");
		data[fwTrending_PLOT_OBJECT_DPES_X] = makeDynString("","","","","","","","");
		data[fwTrending_PLOT_OBJECT_TITLE] = makeDynString(_plotName);
		data[fwTrending_PLOT_OBJECT_LEGENDS] = makeDynString("","","","","","","","");
	} else {
		data[fwTrending_PLOT_OBJECT_MODEL] = model;
		data[fwTrending_PLOT_OBJECT_TITLE] = _plotName;
		data[fwTrending_PLOT_OBJECT_LEGEND_ON] = TRUE;
		data[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON] = fwTrending_HIDE_CAPTIONS;
		data[fwTrending_PLOT_OBJECT_BACK_COLOR] = "FwTrendingTrendBackground";
		data[fwTrending_PLOT_OBJECT_FORE_COLOR] = "FwTrendingTrendForeground";
		data[fwTrending_PLOT_OBJECT_DPES] = makeDynString();
		data[fwTrending_PLOT_OBJECT_LEGENDS] = makeDynString();
		data[fwTrending_PLOT_OBJECT_COLORS] = makeDynString("FwTrendingCurve1","FwTrendingCurve2","FwTrendingCurve3","FwTrendingCurve4",
			"FwTrendingCurve5","FwTrendingCurve6","FwTrendingCurve7","FwTrendingCurve8");
		data[fwTrending_PLOT_OBJECT_LEGENDS] = makeDynBool();
		data[fwTrending_PLOT_OBJECT_CURVES_HIDDEN] = makeDynBool(0,0,0,0,0,0,0,0);
		data[fwTrending_PLOT_OBJECT_RANGES_MIN] = makeDynFloat();
		data[fwTrending_PLOT_OBJECT_RANGES_MAX] = makeDynFloat();
		data[fwTrending_PLOT_OBJECT_TYPE] = fwTrending_PLOT_TYPE_LINEAR;
		data[fwTrending_PLOT_OBJECT_TIME_RANGE] = fwTrending_SECONDS_IN_ONE_HOUR;
		data[fwTrending_PLOT_OBJECT_TEMPLATE_NAME] = "";
		data[fwTrending_PLOT_OBJECT_IS_TEMPLATE] = FALSE;
		data[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC] = FALSE;
		data[fwTrending_PLOT_OBJECT_GRID] = TRUE;
		data[fwTrending_PLOT_OBJECT_MARKER_TYPE] = fwTrending_MARKER_TYPE_FILLED_CIRCLE;
		data[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE] = "";
		data[fwTrending_PLOT_OBJECT_CURVE_TYPES] = makeDynInt(fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS,
			fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS);
		data[fwTrending_PLOT_OBJECT_AXII] = makeDynInt(1,1,1,1,1,1,1,1);
		data[fwTrending_PLOT_OBJECT_AXII_POS] = makeDynInt(2,2,2,2,2,2,2,2);//2 = SCALE_LEFT, 3 = SCALE_RIGHT
		data[fwTrending_PLOT_OBJECT_AXII_LINK] = makeDynInt(1,1,1,1,1,1,1,1);
		data[fwTrending_PLOT_OBJECT_DEFAULT_FONT] = fwTrending_DEFAULT_FONT;
		data[fwTrending_PLOT_OBJECT_CURVE_STYLE] = 0;
		data[fwTrending_PLOT_OBJECT_AXII_X_FORMAT] = makeDynString("%X","%x","","","","","","");
		data[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT] = makeDynString("","","","","","","","");
		data[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT] = makeDynString("","","","","","","","");
		data[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW] = makeDynBool();
	}
	
	fwTrending_setPlot(_plotName, data, exceptionInfo);
}


/** Copies all the configuration data from a source page to a target page that already exists.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param _from		the data point name of the source page
@param _to			the data point name of the target page
*/
void fwTrending_copyPageData(string _from, string _to) {
	dyn_string exceptionInfo;
	dyn_dyn_string data;

	fwTrending_getPage(_from, data, exceptionInfo);
	fwTrending_setPage(_to, data, exceptionInfo);
}


/** Copies all the configuration data from a source plot to a target plot that already exists.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param _from		the data point name of the source plot
@param _to			the data point name of the target plot
*/
void fwTrending_copyPlotData(string _from, string _to) {
	dyn_string exceptionInfo;
	dyn_dyn_string data;

	fwTrending_getPlot(_from, data, exceptionInfo);
	fwTrending_setPlot(_to, data, exceptionInfo);
}


/** Creates a new page and copies all the configuration data from a source page to the new page.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param _from		the data point name of the source page
@param _to			the data point name of the page to create
*/
void fwTrending_copyPage(string _from, string _to) {
	dyn_string exInfo;

	fwTrending_createPage(_to, exInfo);
	fwTrending_copyPageData(_from, _to);
}


/** Creates a new plot and copies all the configuration data from a source plot to the new plot.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param _from		the data point name of the source plot
@param _to			the data point name of the plot to create
*/
void fwTrending_copyPlot(string _from, string _to) {
	dyn_string exInfo;

	fwTrending_createPlot(_to, exInfo);
	fwTrending_copyPlotData(_from, _to);
}


/** Purpose: set the button state and value of the fwTrending/fwTrendingTrendControl.pnl.
This function is called by the initScript of the fwTrending/fwTrendingTrend.pnl.
The sRef is mandatory in case of multiple plot sRef must be the reference given in the addSymbol function.
The fwTrending/fwTrendingTrend.pnl reference must be sRef+"trend".
If the sDpName is "" or not of type FwTrendingPlot, the option other->Plot configuration and Save settings is disabled
If the access control is not used or not defined the option other->Plot configuration and Save settings is enabled as described above.
If the access control is used and defined the option other->Plot configuration and Save settings is enabled as described above if the user loged in
has the second level of priviledge of the first domain.

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	The runtime data must have been transferred to the 'trendInfo' list object before calling this function.
	Not for reuse.

@par Usage
	Internal

@par PVSS managers
	VISION

@param currentTimeRange		input, the time range at startup
@param sRef					input, the reference given to with the addSymbol ("" if used directly as a plot or the symbol name in a page)
@param sDpName				input, the plot DP or "" if using the $params to pass configure the plot
@param sTrendLog			input, TRUE if this is a log trend.
*/
fwTrending_initControlTrendButtons(int currentTimeRange, string sRef, string sDpName,
									string sTrendLog, bool bCallBack = true) {
	bool isLog, grid, legend, configDpExists, allAuto, storedRanges;
	int i, iRes;
	string texts, tempAxii, temp, timeScaleMenuText, timeScaleMenuItem, tempDp, defaultText, isRunning, currentParameterValues, minimums, maximums;
	dyn_bool axii = makeDynBool(false, false, false, false, false, false, false, false);
	dyn_bool visibility = makeDynBool(false, false, false, false, false, false, false, false);
	dyn_string split, dsDPE, dsLegend, split2, plotShapes, plotData, exceptionInfo;
	shape YAxiiCascadeButton, cascadeButton;

	string ref = sRef;	
	ref = _fwTrending_appendDotTo(ref);

	// get the shape of the YAxii button
	YAxiiCascadeButton = getShape(ref+"YAxiiCascadeButton");

	// get the axii state value and curve visibility, both of them are string containing TRUE or FALSE 8 times seperated by ;
	// axiiText = axiiDpe1;axiiDpe2;axiiDpe3;axiiDpe4;axiiDpe5;axiiDp6;axiiDpe7;axiiDpe8;
	// curveVisibility = curveVisibilitype1;curveVisibilityDpe2;curveVisibilityDpe3;curveVisibilityDpe4;curveVisibilityDpe5;curveVisibilityDp6;curveVisibilityDpe7;curveVisibilityDpe8; true = curve visible, false = curve not visible
	getValue(sRef+"trend.parameterValues", "text", currentParameterValues);

	fwTrending_getRuntimePlotDataWithStrings(sRef, isRunning, plotShapes, plotData, exceptionInfo, FALSE);
	_fwTrending_evaluateTemplate(currentParameterValues, plotData[fwTrending_PLOT_OBJECT_DPES], exceptionInfo);
	_fwTrending_evaluateTemplate(currentParameterValues, plotData[fwTrending_PLOT_OBJECT_LEGENDS], exceptionInfo);
	_fwTrending_evaluateTemplate(currentParameterValues, plotData[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS], exceptionInfo);

	fwTrending_convertUnicosDpeStringToPvssDpeString(plotData[fwTrending_PLOT_OBJECT_DPES], plotData[fwTrending_PLOT_OBJECT_DPES], exceptionInfo);

	fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_AXII], split, exceptionInfo);
	fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], split2, exceptionInfo);
	for(i=1;i<=fwTrending_TRENDING_MAX_CURVE;i++) {
		if(split[i] == "TRUE") {
			axii[i] = true;
		}
		if(split2[i] == "TRUE") {
			visibility[i] = true;
		}
	}
	
	// get the curve DPEs and Legend and set the cascade button menu, if the axii of a DPE is allowed then mark it with *
	//curveDPE = dpe1;dpe2;dpe3;dpe4;dpe5;dp6;dpe7;dpe8;
	//curveLegend = legendDpe1;legendDpe2;legendDpe3;legendDpe4;legendDpe5;legendDp6;legendDpe7;legendDpe8;
	fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_DPES], dsDPE, exceptionInfo);
	fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_LEGENDS], dsLegend, exceptionInfo);
	
	for(i=1;i<=fwTrending_TRENDING_MAX_CURVE;i++) {
		temp = i-1;
		if(dsDPE[i] != "") {
			if(dsLegend[i] != "") {
				string legend = dsLegend[i];
				strreplace(legend, "\\_", " ");
				texts = legend;
			} else {
				string comment;
				comment = dpGetComment(dsDPE[i]);
				if(comment != "") {
					texts = comment;
				} else {
					texts = dsDPE[i];
				}
			}
			
			if(axii[i]) {
				texts += "  *";
			}

            YAxiiCascadeButton.enableItem(temp, true);			
		} else {
			texts = "---";
			YAxiiCascadeButton.enableItem(temp, false);
		}
		
		YAxiiCascadeButton.textItem(temp, texts);
	}

	_fwTrending_initGenericTrendControls(ref, sDpName,
		plotData[fwTrending_PLOT_OBJECT_GRID],
		plotData[fwTrending_PLOT_OBJECT_LEGEND_ON],
		exceptionInfo, bCallBack);
	_fwTrending_initTimeRange(currentTimeRange, ref, exceptionInfo);

	// set the check box to true or false
	if(sTrendLog == "TRUE") {
		isLog = TRUE;
	} else {
		isLog = FALSE;
	}

	setValue(ref+"logCheckBox", "state", 0, isLog);

	getValue(sRef+"trend.storedMinimums", "text", minimums);
	getValue(sRef+"trend.storedMaximums", "text", maximums);

	storedRanges = FALSE;
	if((minimums != "storedMinimums") && (maximums != "storedMaximums")) {
		fwTrending_convertStringToDyn(minimums, split, exceptionInfo);
		fwTrending_convertStringToDyn(maximums, split2, exceptionInfo);
		
		for(i=1;(i<=fwTrending_TRENDING_MAX_CURVE) && !storedRanges;i++) {
			if(split[i] == "0" && split2[i] == "0") {
				storedRanges = FALSE;
			} else {
				storedRanges = TRUE;
			}
		}
	}

	allAuto = TRUE;
	fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_RANGES_MIN], split, exceptionInfo);
	fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_RANGES_MAX], split2, exceptionInfo);
	
	for(i=1;(i<=fwTrending_TRENDING_MAX_CURVE) && allAuto;i++) {
		if(((int)split[i] == "0") && ((int)split2[i] == "0")) {
			allAuto = TRUE;
		} else {
			allAuto = FALSE;
		}
	}

	// enable all the other buttons
	setValue(ref+"resetTrendZoomButton", "enabled", TRUE);
	setValue(ref+"StopButton", "enabled", true);
	setValue(ref+"logCheckBox", "enabled", true);
	setValue(ref+"autoScaleCheckBox", "enabled", storedRanges || !allAuto);
	setValue(ref+"autoScaleCheckBox", "state", 0, allAuto);
	setValue(ref+"trendRefreshButton", "enabled", true);

	YAxiiCascadeButton.enabled = TRUE;
	YAxiiCascadeButton.enableItem("9",TRUE);

	cascadeButton = getShape(ref+"OtherCascadeButton");
	cascadeButton.enabled = TRUE;
	cascadeButton.textItem("8", "Plot configuration: " + plotData[fwTrending_PLOT_OBJECT_TITLE]);

	cascadeButton = getShape(ref+"TimeCascadeButton");
	cascadeButton.enabled = TRUE;
	cascadeButton.enableItem("7", TRUE);
	cascadeButton.enableItem("8", TRUE);
}


/** Purpose: get the amount of days, hours minutes from a specified time range (in s) to be shown on the trend.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param timeRange		input, the time range (in seconds) to be converted.
@param days				output, the amount of days in the time range
@param hours			output, the amount of hours in the time range
@param minutes			output, the amount of minutes in the time range
@param exceptionInfo	output, any exceptions are returned here
*/
fwTrending_getDaysHoursMinutesFromTimeRange(int timeRange, int &days, int &hours, int &minutes, dyn_string &exceptionInfo) {
	int tempInt;
	tempInt = timeRange;
	days = tempInt / fwTrending_SECONDS_IN_ONE_DAY;
	tempInt %= fwTrending_SECONDS_IN_ONE_DAY;
	hours = tempInt / fwTrending_SECONDS_IN_ONE_HOUR;
	tempInt %= fwTrending_SECONDS_IN_ONE_HOUR;
	minutes = tempInt / fwTrending_SECONDS_IN_ONE_MINUTE;		
}


/** Purpose: get the time range (in s) to be shown on the trend from a specified amount of days, hours minutes.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param timeRange								output, the time range in seconds.
@param days						input, the amount of days in the time range
@param hours						input, the amount of hours in the time range
@param minutes						input, the amount of minutes in the time range
@param exceptionInfo			output, any exceptions are returned here
*/
fwTrending_getTimeRangeFromDaysHoursMinutes(int &timeRange, int days, int hours, int minutes, dyn_string &exceptionInfo) {
	timeRange = days * 86400 + hours * 3600 + minutes * 60;
}


/**
Purpose: set the button state and value of the fwTrending/fwTrendingHistogramControl.pnl.
This function is called by the initScript of the fwTrending/fwTrendingHistogram.pnl.
The sRef is mandatory in case of multiple plot sRef must be the reference given in the addSymbol function.
The fwTrending/fwTrendingHistogram.pnl reference must be sRef+"trend".
If the sDpName is "" or not of type _FwTrendingPlot, the option other->Plot configuration and Save settings is disabled
If the access control is not used or not defined the option other->Plot configuration and Save settings is enabled as described above.
If the access control is used and defined the option other->Plot configuration and Save settings is enabled as described above if the user loged in
has the second level of priviledge of the first domain.

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	Not for reuse.

@par Usage
	Internal

@par PVSS managers
	VISION

@param ref								input, the reference given to with the addSymbol ("" if used directly as a plot or the symbol name in a page)
@param sDpName						input, the plot DP or "" if using the $params to pass configure the plot
@param plotData						input, the plot object that is being displayed in the display (contents of trendInfo object).
@param trendRunning				input, TRUE if the trend is running, else FALSE.
@param exceptionInfo			output, any exceptions are returned here
*/
fwTrending_initControlHistogramButtons(string ref, string sDpName, dyn_string plotData, bool trendRunning,
										dyn_string exceptionInfo, bool bCallBack = true) {
	bool grid, legend;
	string defaultText;
	dyn_string values;
	shape cascadeButton;

	ref = _fwTrending_appendDotTo(ref);

	setValue(ref+"StopButton", "enabled", TRUE);

	cascadeButton = getShape(ref+"OtherCascadeButton");
	cascadeButton.enabled = TRUE;

	if(trendRunning) {
		setValue(ref+"StopButton", "enabled", "Freeze");
	} else {
		setValue(ref+"StopButton", "enabled", "Run");
	}
	
	cascadeButton.enableItem("1", FALSE);

	fwGeneral_stringToDynString(plotData[fwTrending_PLOT_OBJECT_GRID], values);
	
	if((values[1] == "TRUE") || (values[1] == TRUE)) {
		grid = TRUE;
	} else {
		grid = FALSE;
	}
		
	defaultText = "Grid";
	if(grid) {
		cascadeButton.textItem("5", defaultText + "  *");
	} else {
		cascadeButton.textItem("5", defaultText);
	}
	
	fwGeneral_stringToDynString(plotData[fwTrending_PLOT_OBJECT_LEGEND_ON], values);
	if((values[1] == "TRUE") || (values[1] == TRUE)) {
		legend = TRUE;
	} else {
		legend = FALSE;
	}
	
	defaultText = "Legend";
	if(legend) {
		cascadeButton.textItem("4", defaultText + "  *");
	} else {
		cascadeButton.textItem("4", defaultText);
	}
	
	if(bCallBack) {
		setValue(ref+"saveSettings", "enabled", FALSE);
		cascadeButton.enableItem("7", FALSE);
		cascadeButton.enableItem("8", FALSE);
	}

	if((isFunctionDefined("unGenericDpFunctionsHMI_setCallBack_user")) &&
			(isFunctionDefined("unGenericButtonFunctionsHMI_TrendingHistogramselectCB"))) {
		unGenericDpFunctionsHMI_setCallBack_user("unGenericButtonFunctionsHMI_TrendingHistogramselectCB", iRes, exceptionInfo);
	} else {
		cascadeButton.enableItem("7", TRUE);

		if(sDpName != "") {
			if(dpExists(sDpName)) {	
				if(isFunctionDefined("fwAccessControl_setupPanel")) {
					if(bCallBack) {
						fwAccessControl_setupPanel("checkHasSaveRights", exceptionInfo);
					}
				} else {
					setValue(ref+"saveSettings", "enabled", TRUE);
					cascadeButton.enableItem("8", TRUE);
				}
			} else {
				cascadeButton.enableItem("8", TRUE);
			}
		} else {
			cascadeButton.enableItem("8", TRUE);
		}
	}
}


/**
Purpose: Do some setup of the trend display.
This function works for both Value over time and Value over value plots.

@par Constraints
	This function is only for use with the standard trend panels as it makes direct reference to many of the graphical objects.
	Not for reuse.

@par Usage
	Internal

@par PVSS managers
	VISION

@param ref				input, the reference given to with the addSymbol ("" if used directly as a plot or the symbol name in a page)
@param sDpName			input, the plot DP or "" if using the $params to pass configure the plot
@param showGrid			input, TRUE if grid is visible, else FALSE.
@param showLegend		input, TRUE if legend is visible, else FALSE.
@param exceptionInfo	output, any exceptions are returned here
*/
_fwTrending_initGenericTrendControls(string ref, string sDpName, string showGrid,
										string showLegend, dyn_string &exceptionInfo, bool bCallBack = true) {
	bool grid, legend;
	int iRes;
	string defaultText;
	shape xzoomin, xzoomout, yzoomin, yzoomout, cascadeButton;

// disable the zoomin/zoomout buttons because by default the trend is started
// 	xzoomin = getShape(ref+"xzoomin");
// 	xzoomin.enabled(false);
//
// 	xzoomout = getShape(ref+"xzoomout");
// 	xzoomout.enabled(false);
//
// 	yzoomin = getShape(ref+"yzoomin");
// 	yzoomin.enabled(false);
//
// 	yzoomout = getShape(ref+"yzoomout");
// 	yzoomout.enabled(false);

	cascadeButton = getShape(ref+"OtherCascadeButton");

	if((showGrid == "TRUE") || (showGrid == TRUE)) {
		grid = TRUE;
	} else {
		grid = FALSE;
	}
	
	defaultText = "Grid";
	if(grid) {
		cascadeButton.textItem("6", defaultText + "  *");
	} else {
		cascadeButton.textItem("6", defaultText);
	}
	
	if((showLegend == "TRUE") || (showLegend == TRUE)) {
		legend = TRUE;
	} else {
		legend = FALSE;
	}
	
	defaultText = "Legend";
	if(legend) {
		cascadeButton.textItem("4", defaultText + "  *");
	} else {
		cascadeButton.textItem("4", defaultText);
	}
	
    if(bCallBack) {
		setValue(ref+"saveSettings", "enabled", FALSE);
		cascadeButton.enableItem("8", FALSE);
		cascadeButton.enableItem("9", FALSE);
    }

	// if the sDpName is of type _FwTrendingPlot and the user access and UNICOS is defined then set up a callbac function for access control
	// the textItem of the cascade button is set to Plot configuration: plot title
	// the callback is in the initScript event of the fwTrending/fwTrendingTrend.pnl
	if((isFunctionDefined("unGenericDpFunctionsHMI_setCallBack_user")) && bCallBack &&
			(isFunctionDefined("unGenericButtonFunctionsHMI_TrendingTrendselectCB"))) {
		unGenericDpFunctionsHMI_setCallBack_user("unGenericButtonFunctionsHMI_TrendingTrendselectCB", iRes, exceptionInfo);
	} else {
		cascadeButton.enableItem("8", TRUE);

        if(sDpName != "") {
			if(dpExists(sDpName)) {	
				if(isFunctionDefined("fwAccessControl_setupPanel")) {
					if(bCallBack) {
						fwAccessControl_setupPanel("checkHasSaveRights", exceptionInfo);
					}
				} else {
					setValue(ref+"saveSettings", "enabled", TRUE);
					cascadeButton.enableItem("9", TRUE);
				}
			} else {
				cascadeButton.enableItem("9", TRUE);
			}
		} else {
			cascadeButton.enableItem("9", TRUE);
		}
	}
}


/** Purpose: set the button state and value of the fwTrending/fwTrendingTrendXYControl.pnl.
This function is called by the initScript of the fwTrending/fwTrendingTrendXY.pnl.
The sRef is mandatory in case of multiple plot sRef must be the reference given in the addSymbol function.
The fwTrending/fwTrendingTrendXY.pnl reference must be sRef+"trend".
If the sDpName is "" or not of type FwTrendingPlot, the option other->Plot configuration and Save settings is disabled
If the access control is not used or not defined the option other->Plot configuration and Save settings is enabled as described above.
If the access control is used and defined the option other->Plot configuration and Save settings is enabled as described above if the user loged in
has the second level of priviledge of the first domain.

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	The runtime data must have been transferred to the 'trendInfo' list object before calling this function.
	Not for reuse.

@par Usage
	Internal

@par PVSS managers
	VISION

@param currentTimeRange		input, the time range at startup
@param sRef					input, the reference given to with the addSymbol ("" if used directly as a plot or the symbol name in a page)
@param sDpName				input, the plot DP or "" if using the $params to pass configure the plot
@param sTrendLog			input, TRUE if this is a log trend.
*/
fwTrending_initControlTrendXYButtons(int currentTimeRange, string sRef, string sDpName, string sTrendLog) {
	string texts;
	string tempAxii, temp, timeScaleMenuText, timeScaleMenuItem;
	dyn_string split, dsDPE, dsLegend, split2;
	string tempDp, defaultText;
	shape YAxiiCascadeButton;
	bool isLog, grid, legend, configDpExists;
	shape xzoomin, xzoomout, yzoomin, yzoomout, cascadeButton;
	string isRunning, currentParameterValues;
	dyn_string plotShapes, plotData, exceptionInfo;		
	string ref = sRef;	

	ref = _fwTrending_appendDotTo(ref);
	
	getValue(sRef+"trend.parameterValues", "text", currentParameterValues);	

	fwTrending_getRuntimePlotDataWithStrings(sRef, isRunning, plotShapes, plotData, exceptionInfo, FALSE);
		
	_fwTrending_initGenericTrendControls(ref, sDpName, plotData[fwTrending_PLOT_OBJECT_GRID], plotData[fwTrending_PLOT_OBJECT_LEGEND_ON], exceptionInfo);
	_fwTrending_initTimeRange(currentTimeRange, ref, exceptionInfo);

	cascadeButton = getShape(ref+"ZoomCascadeButton");
	cascadeButton.enableItem("1.0", FALSE);
	cascadeButton.enableItem("1.1", FALSE);
	cascadeButton.enableItem("2.0", FALSE);
	cascadeButton.enableItem("2.1", FALSE);
	cascadeButton.enabled = TRUE;

	cascadeButton = getShape(ref+"OtherCascadeButton");
	cascadeButton.textItem("8", "Plot configuration: " + plotData[fwTrending_PLOT_OBJECT_TITLE]);
	cascadeButton.enabled = TRUE;

	setValue(ref+"TimeCascadeButton", "enabled", true);
	setValue(ref+"resetTrendZoomButton", "enabled", FALSE);
	setValue(ref+"StopButton", "enabled", true);
	setValue(ref+"trendRefreshButton", "enabled", true);
}


/** This functions sets the time range cascade button, the time range element (to the right of the trend controls)
as well a hidden value text field.
This function takes the given currentTimeRange in seconds and sets the graphical items in the display accordingly.

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	Not for reuse.

@par Usage
	Internal

@par PVSS managers
	VISION

@param currentTimeRange		input, the time range at startup
@param ref					input, the reference given to with the addSymbol ("" if used directly as a plot or the symbol name in a page)
@param exceptionInfo		output, any exceptions are returned here
*/
_fwTrending_initTimeRange(int currentTimeRange, string ref, dyn_string &exceptionInfo) {
	int i, d, h, m;
	string timeScaleMenuText, timeScaleMenuItem, temp;
	shape cascadeButton;

	// set the time range
	d = currentTimeRange / fwTrending_SECONDS_IN_ONE_DAY;
	h = currentTimeRange % fwTrending_SECONDS_IN_ONE_DAY / fwTrending_SECONDS_IN_ONE_HOUR;
	m = currentTimeRange % fwTrending_SECONDS_IN_ONE_HOUR / fwTrending_SECONDS_IN_ONE_MINUTE;

	cascadeButton = getShape(ref+"TimeCascadeButton");

	for(i=0; i<=5; i++) {
		timeScaleMenuText = cascadeButton.textItem(i);
		timeScaleMenuText = strrtrim(timeScaleMenuText, " *");
		cascadeButton.textItem(i, timeScaleMenuText);
	}

	switch(currentTimeRange) {
		case 600:
			timeScaleMenuItem = "0";
			timeScaleMenuText = cascadeButton.textItem(timeScaleMenuItem);
			break;			
		case 3600:
			timeScaleMenuItem = "1";
			timeScaleMenuText = cascadeButton.textItem(timeScaleMenuItem);
			break;			
		case 28800:
			timeScaleMenuItem = "2";
			timeScaleMenuText = cascadeButton.textItem(timeScaleMenuItem);
			break;			
		case 86400:
			timeScaleMenuItem = "3";
			timeScaleMenuText = cascadeButton.textItem(timeScaleMenuItem);
			break;			
		case 864000:
			timeScaleMenuItem = "4";
			timeScaleMenuText = cascadeButton.textItem(timeScaleMenuItem);
			break;			
		default:
			timeScaleMenuItem = "5";
			timeScaleMenuText = "User specified";
			timeScaleMenuText += (" (" + d + "d " + h + "h " + m + "m)");
			break;			
	}
	
	timeScaleMenuText = strrtrim(timeScaleMenuText, " *");
	timeScaleMenuText += "  *";
	cascadeButton.textItem(timeScaleMenuItem, timeScaleMenuText);

	setValue(ref+"curvesTimeRangeHidden", "text", currentTimeRange);
	sprintf(temp,"%3d d %2d h %2d m",d,h,m);
	setValue(ref+"curvesTimeRange","text",temp);

	setValue(ref+"rigthArrow", "text","->|");
	setValue(ref+"leftArrow", "text", "|<-");
}


/** Purpose: set all the data of the trend caption, the caption contains 8 times: one per curvex (x from 1 to 8)
	. curveTimex
	. Textx: legend of the curve DPE
	. valueCurvex: value of the DPE
	. unitx: unit of the DPE
	. visibilityx: check box, visibility state of the curve
The trend caption must have the name trendCaption. curveTimex and valueCurvex are set by the trend

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	Not for reuse.

@par Usage
	Internal

@par PVSS managers
	VISION

@param curveNumber				input, curve number
@param dsDpe					input, DPE connected to the curve
@param ddsCurveParams			input, curve parameters:
								[1]: legend of the DPE
								[2]: tool tip text of the DPE
								[3]: color of the curve
@param legendObj				input, name of the legend graphical object
@param valueObj					input, name of the valueCurve graphical object
@param visibilityObj			input, name of the visibility check box graphical object
@param dsUnit					input, unit of the DPE
@param unitObj					input, name of the unit graphical object
@param visibility				input, visibility state of curve
@param curveTimeObj				input, name of the curveTime graphical object
@param bEnabledVisibility		input, enable/disable the visibility check box
*/
_fwTrending_initTrendCaption(int curveNumber, dyn_string dsDpe, dyn_dyn_string ddsCurveParams, dyn_string legendObj,
								dyn_string valueObj, string visibilityObj, dyn_string dsUnit, dyn_string unitObj, bool visibility,
								dyn_string curveTimeObj, bool bEnabledVisibility) {
	int i, indexToCheck;
	string sLegend, sCurveToolTip, sColor, sFormat;
	dyn_string exceptionInfo;
	
	if(dynlen(dsDpe) > 1) {
		indexToCheck = fwTrending_X_VALUE;
	} else {
		indexToCheck = fwTrending_Y_VALUE;
	}
	
	if((dsDpe[indexToCheck] != "") && (dsDpe[fwTrending_Y_VALUE] != "")) {
		for(i=1; i<=dynlen(dsDpe); i++) {
			sLegend = ddsCurveParams[1][i];
			sCurveToolTip = ddsCurveParams[2][i];
			sColor = ddsCurveParams[3][1];
	
			// correct dpe
			// set the legend to description of legend is ""
			setValue(legendObj[i],"text", sLegend);
			
			// set the color if defined
			if(sColor != "") {
				setValue(legendObj[i],"foreCol", sColor);
				setValue(valueObj[i],"foreCol", sColor);
				setValue(unitObj[i], "foreCol", sColor);
			} else {
				setValue(legendObj[i],"foreCol", "FwTrendingCurve"+curveNumber);
				setValue(valueObj[i],"foreCol", "FwTrendingCurve"+curveNumber);
				setValue(unitObj[i], "foreCol", "FwTrendingCurve"+curveNumber);
			}
			
			//set the foarmat of the value object
			if(isFunctionDefined("unTrendTree_getDPEFormat")) {
				unTrendTree_getDPEFormat(dsDpe[i], sFormat, exceptionInfo);	
				strreplace(sFormat, "%", "");
				setValue(valueObj[i], "format", "[" + sFormat + "]");
			}
			
			// set the tooltiptext of the legend and curveValue
			setValue(valueObj[i], "toolTipText", sCurveToolTip);
			setValue(legendObj[i], "toolTipText", sCurveToolTip);
			
			// set the unit
			setValue(unitObj[i], "text", dsUnit[i]);
			
			// set the valueCurve, legend, visibility and unit to visible
			setValue(legendObj[i], "visible", true);
			setValue(valueObj[i], "visible", true);
			setValue(unitObj[i], "visible", true);
			
			// if the visibility is enabled then show the curveTime.
			setValue(curveTimeObj[i], "visible", TRUE);
		}

		if(visibility) {
			setValue(visibilityObj,"state", 0, true);
		} else {
			setValue(visibilityObj,"state", 0, false);
		}
		
		setValue(visibilityObj, "visible", true);
		setValue(visibilityObj, "enabled", bEnabledVisibility);
	} else {
		for(i=1; i<=dynlen(dsDpe); i++) {
			setValue(legendObj[i], "visible", false);
			setValue(valueObj[i], "visible", false);
			setValue(unitObj[i], "visible", false);
			setValue(curveTimeObj[i], "visible", TRUE);
		}
		
		setValue(visibilityObj, "visible", false);
		setValue(visibilityObj,"state", 0, false);
	}
}


/** Purpose: initialize the curve of the active trend, the other trend will have no data.

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	Not for reuse.

@par Usage
	Internal

@par PVSS managers
	VISION

@param curveName			input, name of the curve
@param curveNumber			input, curve number
@param ref 					input, reference of the trend
@param dsLegendObj			input names of legend graphical objects
@param dsValueObj			input, names of the valueCurve graphical objects
@param dsCurveDPE			input, DPEs connected to the curves
@param dsCurveLegend		input, legend of the DPEs
@param dsCurveToolTip		input, tool tip text of the DPEs
@param curveColor			input, color of the curve
@param dbScaleVisibility	input, visibility state of the scale of the curves
@param dbIsLogTrend			input, true if log trends
@param curveVisibilityObj	input, name of the visibility check box graphical object
@param dsUnit				input, units of the DPEs
@param dsUnitObj			input, names of the unit graphical objects
@param curveVisibility		input, visibility state of the scale of the curve
@param trendShapeName		input, name of the active trend graphical object
@param curvesType			input, type of the curve
@param dsCurveTimeObj		input, names of the curveTime graphical objects
@param bInitCaption			input, true to initialize the caption
@param exceptionInfo		output, the exception is returned here
@param markerType			input, optional, type of marker (default value = 7 - filled circle);
@param diCurveScalePos  	input, optional, SCALE_LEFT if the scale must be on the left, SCALE_RIGHT if must be on the right
@param iCurveLink  			input, optional, index of the curve, the current curve is supposed to be linked to; derives from a list of indices following this scheme: if curve 1 must be linked to curve 4, and curve 3 to 4, then it should be 4,0,4,0,0,0,0,0
@param sCurveStyle  		input, optional, line style for the curves (default value = fwTrending_DEFAULT_CURVE_STYLE).
@param sLegendValFormat  	input, optional, numeric format of the value shown on the legend. Updated only after value changed.
@param sAxiiYFormat  		input, optional, numeric format of the scale o the Y axis.
*/
_fwTrending_initCurve(string curveName, int curveNumber, string ref, dyn_string dsLegendObj, dyn_string dsValueObj, 
                dyn_string dsCurveDPE, dyn_string dsCurveLegend, dyn_string dsCurveToolTip, string curveColor,
				dyn_bool dbScaleVisibility, dyn_bool dbIsLogTrend, string curveVisibilityObj, dyn_string dsUnit, 
        		dyn_string dsUnitObj, bool curveVisibility, string trendShapeName, int curvesType,
				dyn_string dsCurveTimeObj, bool bInitCaption, dyn_string &exceptionInfo, int markerType = 0,
      			dyn_int diCurveScalePos = 0, int iCurveLink = 0, string sCurveStyle = fwTrending_DEFAULT_CURVE_STYLE,
      			string sLegendValFormat = fwTrending_DEFAULT_LEGEND_VALUE_FORMAT,
      			string sAxiiYFormat = fwTrending_DEFAULT_AXII_Y_FORMAT) {
	bool isConnected, bValidCurve = TRUE, bConnectDPE = TRUE, bConstantLine;
	int i, j, k;
	float currentMax, fConstantValue;
	shape activeTrendShape;
	dyn_float min, max;
	dyn_bool autoscaleRange;
	float value;
	dyn_string ranges;
	dyn_dyn_string ddsCurveParams;
  	dyn_dyn_anytype dpName;

	activeTrendShape = getShape(trendShapeName);

	if(!strlen(sCurveStyle)||sCurveStyle==0) {
		sCurveStyle = fwTrending_DEFAULT_CURVE_STYLE;
	}

	/* start 20/05/2008: Herve */
	isConnected = true;
	/* end 20/05/2008: Herve */
	
	for(i=1; i<=dynlen(dsCurveDPE); i++) {
		if(dsCurveDPE[i] == "") {
			bConnectDPE = FALSE;
			/* start 20/05/2008: Herve */
    		isConnected = false;
			bValidCurve = FALSE;
			bConstantLine = false;
			/* end 20/05/2008: Herve */
		} else {
			if(_fwTrending_isConstantLineValue(dsCurveDPE[i])) {
				bConnectDPE = FALSE;
				isConnected = false;
				bValidCurve = true;
				bConstantLine = true;
				fConstantValue = _fwTrending_getConstantLineValue(dsCurveDPE[i]);
			} else {
				// if DPE does not exist, do not connect.
				bConstantLine = false;
				
				if(!dpExists(dsCurveDPE[i])) {
					bConnectDPE = FALSE;
					isConnected = false;
					dsCurveLegend[i] += getCatStr("fwTrending/FwTrending", "NOTEXIST");
					curveColor = "FwTrendingDataNoAccess";
					dsCurveToolTip[i] += getCatStr("fwTrending/FwTrending", "NOTEXIST");
					fwException_raise(exceptionInfo, "INFO", dsCurveDPE[i] + getCatStr("fwTrending/FwTrending", "NOTEXIST"),"");
				} else {
					/* start 20/05/2008: Herve */
					// check element type to avoid wrong DPE TYPE and errors like
					// The attribute does not exist in this config, DP: ..:_offline.._value
					switch(dpElementType(dsCurveDPE[i])) {
						case DPEL_BOOL:
						case DPEL_FLOAT:
						case DPEL_INT:
						case DPEL_UINT:
							break;
						default:
							bConnectDPE = false;
							break;
					}
					
					if(bConnectDPE) {
						/* end 20/05/2008: Herve */
						_fwTrending_isSystemForDpeConnected(dsCurveDPE[i], isConnected, exceptionInfo);
						
						if(!isConnected) {
							dsCurveLegend[i] += getCatStr("fwTrending/FwTrending", "REMOTEUNAVAILABLE");
							curveColor = "FwTrendingDataNoAccess";
							dsCurveToolTip[i] += getCatStr("fwTrending/FwTrending", "REMOTEUNAVAILABLE");
						} else {
							dsCurveDPE[i] = dsCurveDPE[i] + fwTrending_OFF_VAL;
							if(dsCurveLegend[i] == "") {
								dsCurveLegend[i] = dpGetComment(dsCurveDPE[i]);
								if(dsCurveLegend[i] != "") {
									dsCurveLegend[i] = dsCurveDPE[i];
								}
							}

							// bug with log trend in case of value <=0. CT150306, therefore do not connect
							if((dbIsLogTrend[i]) && (dsCurveDPE[i] != "")) {
								dpGet(dsCurveDPE[i], value);
								
								if(value <= 0) {
									bConnectDPE = FALSE;
									/* start 20/05/2008: Herve */
									isConnected = false;
									/* end 20/05/2008: Herve */
									dsCurveLegend[i] += getCatStr("fwTrending/FwTrending", "LOG0");
									curveColor = "FwTrendingDataNoAccess";
									dsCurveToolTip[i] += getCatStr("fwTrending/FwTrending", "LOG0");
									fwException_raise(exceptionInfo, "INFO", dsCurveDPE[i] + getCatStr("fwTrending/FwTrending", "LOG0"),"");
								}
							}
						}
					} else {
						bConnectDPE = FALSE;
						isConnected = false;
						dsCurveLegend[i] += getCatStr("fwTrending/FwTrending", "NOTEXIST");
						curveColor = "FwTrendingDataNoAccess";
						dsCurveToolTip[i] += getCatStr("fwTrending/FwTrending", "NOTEXIST");
						fwException_raise(exceptionInfo, "INFO", dsCurveDPE[i] + getCatStr("fwTrending/FwTrending", "NOTEXIST"),"");
					}
				}
			}
		}
	}
	
	// initialize the caption if requested
	if(bInitCaption) {
		ddsCurveParams[1]=dsCurveLegend;
		ddsCurveParams[2]=dsCurveToolTip;
		ddsCurveParams[3][1]=curveColor;

		_fwTrending_initTrendCaption(curveNumber, dsCurveDPE, ddsCurveParams, dsLegendObj,
			dsValueObj, curveVisibilityObj, dsUnit, dsUnitObj, curveVisibility, dsCurveTimeObj, bValidCurve);
	}

	if(bValidCurve) {
		//do settings general for both axis
		activeTrendShape.curveLegendVisibility(curveName, TRUE);
		activeTrendShape.curveVisible(curveName, curveVisibility);
		activeTrendShape.curveType(curveName, curvesType);
		activeTrendShape.pointType(curveName, markerType);
		activeTrendShape.curveLineType(curveName, sCurveStyle);
		
		if(curveColor != "") {
			activeTrendShape.curveColor(curveName, curveColor);
		}
		
		/* start 20/05/2008: Herve */
		activeTrendShape.curveLegendShowDate(curveName, true);
		activeTrendShape.curveLegendShowMilli(curveName, true);

		string sFormat, sUnit;

		if(bConnectDPE) {
			sFormat = dpGetFormat(dpSubStr(dsCurveDPE[fwTrending_Y_VALUE], DPSUB_SYS_DP_EL));
			sUnit = dpGetUnit(dpSubStr(dsCurveDPE[fwTrending_Y_VALUE], DPSUB_SYS_DP_EL));
		} else {
			sFormat = "";
			sUnit = "";
		}

		//default value format for legend: get it from the dpe config
		//else: the format of the legend value was customized by the user
		if(sLegendValFormat==fwTrending_DEFAULT_LEGEND_VALUE_FORMAT) {
			// assume UNICOS CORE		
			if(isFunctionDefined("unGenericObject_FormatValue")) {
				int pos;
				string sExp;
				int iExp;

				pos = strpos(sFormat, UN_DISPLAY_VALUE_DIGIT_FLOAT_FORMAT+UN_DISPLAY_VALUE_DIGIT_FLOAT_TYPE);
				
				// fixed display format
				if(pos>0) {
					sExp = substr(sFormat, 0, pos);
					iExp = substr(sExp, 1, strlen(sExp));
					sFormat = "%"+ (iExp -1)+"."+(iExp -1)+UN_DISPLAY_VALUE_DIGIT_FLOAT_TYPE;
				}
				
				pos = strpos(sFormat, "e");
				
				// exp format BUG PVSS --> set %10f
				if(pos > 0) {
					pos = strpos(sFormat, ".");
					sExp = substr(sFormat, 0, pos);
					iExp = substr(sExp, 1, strlen(sExp));
					sFormat = "%"+ (iExp -1)+".10"+UN_DISPLAY_VALUE_DIGIT_FLOAT_TYPE;
				}
			}
		} else {
			sFormat = sLegendValFormat;
		}
	
		// if no format, force it to %f
		if(sFormat == "") {
			sFormat = "%f";
		}

		activeTrendShape.curveLegendFormat(curveName, sFormat);
		activeTrendShape.curveLegendUnit(curveName, sUnit);
		/* end 20/05/2008: Herve */

		//do settings for each axis
		activeTrendShape.curveLegendName(curveName, dsCurveLegend[fwTrending_Y_VALUE]);
		
		if(bConstantLine) {
		  activeTrendShape.curveValue(curveName, fConstantValue, makeTime(0,0,0,0), (bit32)15);
		}

		if(isConnected) {    
			activeTrendShape.connectDirectly(curveName, dsCurveDPE[fwTrending_Y_VALUE]);
      
			if(dynlen(dsCurveDPE) == fwTrending_X_VALUE) {
				activeTrendShape.connectDirectlyX(curveName, dsCurveDPE[fwTrending_X_VALUE]);
			}
		}

		/* start 20/05/2008: Herve */
		if(dynlen(dbScaleVisibility) == fwTrending_Y_VALUE) {
			activeTrendShape.curveScaleVisibility(curveName, curveVisibility && dbScaleVisibility[fwTrending_Y_VALUE]);
		}
		/* end 20/05/2008: Herve */
		
		if(diCurveScalePos[1]!=0) {
		  activeTrendShape.curveScalePosition(curveName, diCurveScalePos[fwTrending_Y_VALUE]);
		}
		
		// reset all links of all curves as WinCCOA Help suggest linkCurves() or unlinkCurves() should not be called twice with the same pair of curves	
		if(curveNumber == 1)
		{
			for(j=1 ; j<=fwTrending_MAX_NUM_CURVES ; j++) {		
				for(k=1 ; k<=fwTrending_MAX_NUM_CURVES ; k++)
				{
					activeTrendShape.unlinkCurves("curve_"+j, "curve_"+k);
				}
			}
		}
			
		// link curve1 to curve2 if different and not zero
		if((iCurveLink != 0) && (iCurveLink != curveNumber)) 
		{
		  	activeTrendShape.linkCurves("curve_"+ iCurveLink, curveName);
		} 
		
		if(dbIsLogTrend[1]) {
			sAxiiYFormat="%1.1e";
		}
		
		activeTrendShape.curveScaleFormat(curveName, sAxiiYFormat);
 	} else {
		activeTrendShape.curveLegendVisibility(curveName, FALSE);
		
		if(dynlen(dbScaleVisibility) == fwTrending_Y_VALUE) {
			activeTrendShape.curveScaleVisibility(curveName, FALSE);
		}
		
		activeTrendShape.curveScalePosition(curveName, 2);//2 = SCALE_LEFT
	}
	
	/* start 20/05/2008: Herve */
	// assume UNICOS reset error
	if(isFunctionDefined("unGenericObject_FormatValue")) {
		exceptionInfo = makeDynString();
	}
	/* end 20/05/2008: Herve */

	//enable/disable plotting of alarms limits
	for(i=1; i<=dynlen(dsCurveDPE); i++) {
    	if(dpExists(dpSubStr(dsCurveDPE[i], DPSUB_SYS_DP_EL))) {
    		  dpName[2][1] = dsCurveDPE[i];        
      		fwTrending_trendUpdateAlarmLimits(ref, dpName);
    	}
	}	
}


/** Updates the alarm limits by calling the fwTrending_toggleAlarmLimits() function.
  	Serves as an artificial layer between initialization of the plot and alarm toggeling in order to realize 
    a dpQueryConnectSingle() listening to any changes related the the _alert_hdl config.

@par Constraints
	This function is meant to be used via dpQueryConnectSingle(), any other usage needs to satisfy its constraints.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref 				input, MANDATORY reference of the trend (any unique identifier possible)
@param value			input, MANDATORY array with information from the SELECT statement of the dpQueryConnectSingle()
*/
fwTrending_trendUpdateAlarmLimits(string ref, dyn_dyn_anytype value) {
  	 dyn_dyn_string plotData;
    dyn_string exceptionInfo, plotShapes, ranges;
    int curveNumber;
    string dpName = dpSubStr(value[2][1], DPSUB_SYS_DP_EL);
    string currentParameterValues, trendRunning, sCurveStyle, sMinMaxRange, curveName;
    bool bAlarmLimitsVisible, bCurveVisible;
    shape activeTrendShape;

	getValue(ref + "trend.parameterValues", "text", currentParameterValues);
	
	fwTrending_getRuntimePlotDataWithExtendedObject(ref, trendRunning, plotShapes, plotData, exceptionInfo, FALSE);    
      	
    _fwTrending_preparePlotObjectForDisplay(plotData, currentParameterValues, exceptionInfo); 

    if(dynlen(exceptionInfo) > 0) {
		fwException_raise(exceptionInfo, "ERROR", "fwTrending_trendUpdateAlarmLimits(): Loading plot data for " + dpSubStr(dpName, DPSUB_SYS_DP_EL) + " after alarm limits changed failed.", "");
    }
    
    curveNumber = dynContains(plotData[fwTrending_PLOT_OBJECT_DPES], dpSubStr(dpName, DPSUB_DP_EL)); 
    if(curveNumber == 0) {
		curveNumber = dynContains(plotData[fwTrending_PLOT_OBJECT_DPES], dpSubStr(dpName, DPSUB_SYS_DP_EL)); 
    } 
    
    if(curveNumber != 0) {
	    curveName = "curve_" + curveNumber;

	    if(plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN][curveNumber] == "FALSE") {
			bCurveVisible = FALSE;
		} else {
			bCurveVisible = TRUE;
		}

	  	bAlarmLimitsVisible = plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW][curveNumber];
	    activeTrendShape = getShape(plotShapes[fwTrending_ACTIVE_TREND_NAME]);

	    sCurveStyle = plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][curveNumber];
		if(!strlen(sCurveStyle)||sCurveStyle==0) {
			sCurveStyle = fwTrending_DEFAULT_CURVE_STYLE;
		}
  
	    fwTrending_toggleAlarmLimits(curveName, dpName, bCurveVisible && bAlarmLimitsVisible,
										 activeTrendShape, exceptionInfo, sCurveStyle, true);  
    } else {
		 fwException_raise(exceptionInfo, "ERROR", "fwTrending_trendUpdateAlarmLimits(): Searched curve does not exist in plot data.", "");   
    }
}


/** Sets the minimum and maximum for the visible y-scales depending on the preferences set by the user

@par Constraints
	This function needs a correctly set up plotData object, access to the active trend shape of a standard trend panel
  	and a corretly initialized alert config. If you got this, use it.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref 				input, reference of the trend
@param plotData			input, detailed information of the plot
@param trendName		input, name of the trend for which to get the shape
@param exceptionInfo	output, the exception is returned here
*/
fwTrending_trendUpdateScales(string ref, dyn_dyn_string plotData, string trendName, dyn_string exceptionInfo) {
  	bool yAxisShown, yIsLog, isLinked, limitsShown, isAuto, alertExists, isActive;
	int alertType;
	string alertPanel, alertHelp, dpName, curveName;
  	float currentMax;
	dyn_float alertLimits, logLimitMin, logLimitMax;
  	dyn_bool autoscaleRange;
	dyn_string alertTexts, alertClasses, summaryDpeList, alertPanelParameters, ranges, linkedRanges;
    shape activeTrendShape = getShape(trendName);
    dyn_string dsCurveDPE = plotData[fwTrending_PLOT_OBJECT_DPES];
    dyn_string minMaxRanges = plotData[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE];
    float minForLog = plotData[fwTrending_PLOT_OBJECT_EXT_MIN_FOR_LOG][1];
	float maxPercentageForLog = plotData[fwTrending_PLOT_OBJECT_EXT_MAX_PERCENTAGE_FOR_LOG][1];
    
    if(plotData[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1] == "TRUE"
       		|| plotData[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1] == TRUE) {
		yIsLog = TRUE;
	} else {
		yIsLog = FALSE;
	}

  	for(int i = 1; i <= dynlen(dsCurveDPE); i++) {
      	if(minMaxRanges[i] != "") {
			ranges = strsplit(minMaxRanges[i], ":");
			sscanf(ranges[1], "%f", logLimitMin[i]);
			sscanf(ranges[2], "%f", logLimitMax[i]);

			if(yIsLog) {
        		if(logLimitMin[i] <= 0) {
					logLimitMin[i] = minForLog;
        		}
				logLimitMax[i] += logLimitMax[i]*maxPercentageForLog/100.0;
			}

			if(logLimitMin[i] >= logLimitMax[i]) {
				autoscaleRange[i] = TRUE;
			} else {
				autoscaleRange[i] = FALSE;
			}
		} else {
			autoscaleRange[i] = TRUE;
		}
    	
      	if(dpExists(dpSubStr(dsCurveDPE[i], DPSUB_SYS_DP_EL))) {
	      	yAxisShown = plotData[fwTrending_PLOT_OBJECT_AXII][i] == "TRUE" || plotData[fwTrending_PLOT_OBJECT_AXII][i] == TRUE;
	    	isLinked = (plotData[fwTrending_PLOT_OBJECT_AXII_LINK][i] != 0) && (plotData[fwTrending_PLOT_OBJECT_AXII_LINK][i] != i);
			limitsShown = plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW] == "TRUE" || plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW][i] == TRUE;
	      	isAuto = minMaxRanges[i] == "0.00:0.00" || minMaxRanges[i] == "0:0";
 			dpName = dpSubStr(dsCurveDPE[i], DPSUB_SYS_DP_EL); 
 			curveName = "curve_" + i;      	
	        fwAlertConfig_get(dpName, alertExists, alertType, alertTexts,
							alertLimits, alertClasses, summaryDpeList,
							alertPanel, alertPanelParameters, alertHelp,
							isActive, exceptionInfo);

  			activeTrendShape.curveAutoscale(curveName, autoscaleRange[i]);
    
          	if(yAxisShown && !isAuto && !isLinked) {
              	ranges = strsplit(minMaxRanges[i], ":");
				activeTrendShape.curveMin(curveName, ranges[1]);
				activeTrendShape.curveMax(curveName, ranges[2]);  	
	      	}
			
			if(yAxisShown && isAuto && isLinked) {
				linkedRanges = strsplit(minMaxRanges[plotData[fwTrending_PLOT_OBJECT_AXII_LINK][i]], ":");
				activeTrendShape.curveMin(curveName, linkedRanges[1]);
				activeTrendShape.curveMax(curveName, linkedRanges[2]);				
			}
        
	        if(yAxisShown && isAuto && limitsShown) {
            	fwTrending_trendZoomToAlarmLimits(ref);	
	      	}
          	
          	if(!isAuto && yIsLog) {
              	currentMax = activeTrendShape.curveMax(curveName);
				if(logLimitMin[fwTrending_Y_VALUE] >= currentMax) {
					activeTrendShape.curveMax(curveName, logLimitMax[fwTrending_Y_VALUE]);
					activeTrendShape.curveMin(curveName, logLimitMin[fwTrending_Y_VALUE]);        		
				} else {
					activeTrendShape.curveMin(curveName, logLimitMin[fwTrending_Y_VALUE]);
					activeTrendShape.curveMax(curveName, logLimitMax[fwTrending_Y_VALUE]);
				}
            }
          	
          	if(alertType == DPCONFIG_ALERT_BINARYSIGNAL) {	
              	activeTrendShape.curveMin(curveName, 0);
				activeTrendShape.curveMax(curveName, 1.1);
        		return;
			}
      	}       
    }

	if(dynlen(autoscaleRange) == fwTrending_X_VALUE) {
		activeTrendShape.curveAutoscaleX(curveName, autoscaleRange[fwTrending_X_VALUE]);
		if(!autoscaleRange[fwTrending_X_VALUE]) {
			currentMax = activeTrendShape.curveMaxX(curveName);
			if(logLimitMin[fwTrending_X_VALUE] >= currentMax) {
				activeTrendShape.curveMaxX(curveName, logLimitMax[fwTrending_X_VALUE]);
				activeTrendShape.curveMinX(curveName, logLimitMin[fwTrending_X_VALUE]);
			} else {
				activeTrendShape.curveMinX(curveName, logLimitMin[fwTrending_X_VALUE]);
				activeTrendShape.curveMaxX(curveName, logLimitMax[fwTrending_X_VALUE]);
			}
		}		
	}
		
}

float _fwTrending_getConstantLineValue(string value) {
	float fValue;
	value = strltrim(strrtrim(value));
	
	if(substr(value, 0,1)=="#") {
		fValue = substr(value,1);
	}

	return fValue;
}


bool _fwTrending_isConstantLineValue(string value) {
	value = strltrim(strrtrim(value));
	
	return (substr(value, 0,1)=="#");
}


/** Remove all the alarm limits from the trending area.

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	Not for reuse.

@par Usage
	Public

@par PVSS managers
	VISION

@param trendShape		input, name of the active trend graphical object
@param curveName		input, name of the curve for which to clear the alarms
@param exceptionInfo		output, the exception is returned here
*/
fwTrending_clearAlarmLimits(shape trendShape, string curveName,
                             dyn_string exceptionInfo) {
	dyn_string existingCurves;
	int i;
	
	//remove all the limits from the plot area
	getValue(trendShape,"curveNames",0,existingCurves);

	for(i=1 ; i<=dynlen(existingCurves) ; i++) {
		if(patternMatch(curveName+"_limit_*",existingCurves[i])) {
		  trendShape.removeCurve(existingCurves[i]);
		}
	}
	
	exceptionInfo = getLastError();
}


/** Show/hide the alarm limits related to a plotted dpe.

@par Constraints
  This function shows only the alarm limits for analog alarms. Binary, discrete and summary alarms are not shown.
  This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
  Not for reuse.

@par Usage
	Public

@par PVSS managers
	VISION

@param curveName				input, name of the curve
@param curveDpeName				input, DPE connected to the curve
@param curveLimitsVisible	input, visibility state of the limits of the curve
@param trendShape				input, name of the active trend graphical object
@param exceptionInfo			output, the exception is returned here
@param sCurveStyle				input, optional, style of the curve. For an example of style, look at fwTrending_DEFAULT_CURVE_STYLE
@param clearLimits				input, optional, if TRUE, then all the limits on the plot area are erased before showing/hiding them
*/
fwTrending_toggleAlarmLimits(string curveName, string curveDpeName, bool curveLimitsVisible, shape trendShape,
                             dyn_string exceptionInfo,
                             string sCurveStyle = fwTrending_DEFAULT_CURVE_STYLE, 
                             bool clearLimits = FALSE) {
	bool alertExists, isActive;
	int alertType, okRange;
	string alertPanel, alertHelp;
	dyn_float alertLimits;
	dyn_string alertTexts, alertClasses, summaryDpeList, alertPanelParameters, existingCurves;
	shape activeTrendShape;
	int i;
	string limitColour;
	string curveLegend, curveUnit;
	float limitMax, limitMin;

	if(clearLimits) {  	
		fwTrending_clearAlarmLimits(trendShape, curveName, exceptionInfo);
		if(!curveLimitsVisible) {
			return;
		}
	}

	activeTrendShape = trendShape;
	curveDpeName = dpSubStr( curveDpeName, DPSUB_SYS_DP_EL);
	
	if(dpExists(curveDpeName)) {
		fwAlertConfig_get(curveDpeName, alertExists, alertType, alertTexts,
						alertLimits, alertClasses, summaryDpeList,
						alertPanel, alertPanelParameters, alertHelp,
						isActive, exceptionInfo);
   
		if(alertType != DPCONFIG_NONE) {
			if(alertType == DPCONFIG_ALERT_BINARYSIGNAL) {				
				return;
			} else if(alertType == DPCONFIG_SUM_ALERT) {
				return;
			}

			okRange = dynContains(alertClasses, "");

			getValue(activeTrendShape,"curveLegendName",curveName, curveLegend);
			getValue(activeTrendShape,"curveLegendUnit",curveName, curveUnit);
			
			if(strlen(curveUnit)) {
				curveUnit = " ["+curveUnit+"]";
			}
			
			for(i = okRange; i <= dynlen(alertLimits); i++) {
				//if curve limit does not exist, create it
        		getValue(activeTrendShape,"curveNames",0,existingCurves);
				if(dynContains(existingCurves, curveName+"_limit_"+i)==0) {
					activeTrendShape.addCurve(0, curveName+"_limit_"+i);
					dpGet(alertClasses[i+1] + ":_alert_class.._color_c_ack", limitColour);
					activeTrendShape.curveColor(curveName+"_limit_" + i, limitColour);
					activeTrendShape.curveValue(curveName+"_limit_" + i, alertLimits[i],
												makeTime(0,0,0,0), (bit32)15);
					activeTrendShape.curveScaleVisibility(curveName+"_limit_"+i, FALSE);
					activeTrendShape.curveLegendVisibility(curveName+"_limit_"+i, FALSE);
					activeTrendShape.curveLegendName(curveName+"_limit_"+i, "Alarm limit: "+curveLegend+curveUnit);
					activeTrendShape.curveAutoscale(curveName+"_limit_"+i, FALSE);
				}
				
				if(curveLimitsVisible) {
          			activeTrendShape.linkCurves(curveName, curveName+"_limit_"+i);
				} else {
					activeTrendShape.unlinkCurves(curveName+"_limit_"+i,curveName);
				}
				
				activeTrendShape.curveVisible(curveName+"_limit_"+i, curveLimitsVisible);
				activeTrendShape.curveLineType(curveName+"_limit_"+i, sCurveStyle);
			}

			for(i = okRange-1; i > 0; i--) {
				getValue(activeTrendShape,"curveNames",0,existingCurves);
				if(dynContains(existingCurves, curveName+"_limit_"+i)==0) {
					activeTrendShape.addCurve(0, curveName+"_limit_" + i);
					dpGet(alertClasses[i] + ":_alert_class.._color_c_ack", limitColour);
					activeTrendShape.curveColor(curveName+"_limit_" + i, limitColour);
					activeTrendShape.curveValue(curveName+"_limit_" + i, alertLimits[i],
												makeTime(0,0,0,0), (bit32)15);
					activeTrendShape.curveScaleVisibility(curveName+"_limit_" + i,FALSE);
					activeTrendShape.curveLegendVisibility(curveName+"_limit_" + i,FALSE);
					activeTrendShape.curveLineType(curveName+"_limit_"+i, sCurveStyle);
					activeTrendShape.curveLegendName(curveName+"_limit_"+i, "Alarm limit: "+curveLegend+curveUnit);
					activeTrendShape.curveAutoscale(curveName+"_limit_"+i, FALSE);
				}
				
				if(curveLimitsVisible) {
          			activeTrendShape.linkCurves(curveName, curveName+"_limit_"+i);
				} else {
					activeTrendShape.unlinkCurves(curveName+"_limit_"+i,curveName);
				}
				
				activeTrendShape.curveVisible(curveName+"_limit_"+i, curveLimitsVisible);
				activeTrendShape.curveLineType(curveName+"_limit_"+i, sCurveStyle);
			}
		}
	} else {
		for(i = 1; i<=dynlen(existingCurves) ; i++) {
		    if(patternMatch(curveName+"_limit_*",existingCurves[i])) {
				activeTrendShape.curveVisible(existingCurves[i], curveLimitsVisible);
			}
		}
	}
	
	exceptionInfo = getLastError();
}


/** Purpose: initialize the trends. This function is called from the initScript of the fwTrending/fwTrendingTrend.pnl and
the log check box of fwTrending/fwTrendingTrendControl.pnl. It stops the standard and log trend, sets the time range of both trends,
initializes all the curves of the active trend and starts if necessary the active trend.

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	Not for reuse.

@par Usage
	Internal

@par PVSS managers
	VISION

@param sRef						input, reference given when adding the corresponding panel, the panel containing the
								fwTrending/fwTrendingTrend.pnl and a caption or
								fwTrending/fwTrendingTrend.pnl must have the reference name of sRef+"trend"
@param trendName				input, active trend name
@param trendShapeStr			input, name of the trend graphical objects,
								[1]: standard trend
								[2]: log trend
								[3]: active trend
@param plotExtendedObject		input, details of the plot are returned here
								(see fwTrending_PLOT_OBJECT.... constants for info on what needs to be passed
								as well as fwTrending_PLOT_OBJECT_EXT.... constants)
@param runTrend					input, "TRUE" if the trend must be in running mode
@param bInitCaption				input, "TRUE" if the trend caption should be initialised
@param exceptionInfo			output, the exception is returned here
@param passingCurveVisible		input {OPTIONAL - default = FALSE},
								TRUE if passing curve visible state
								FALSE if passing curve hidden state
*/
fwTrending_initTrendWithObject(string sRef, string trendName, dyn_string trendShapeStr, dyn_dyn_string plotExtendedObject,
								bool runTrend, bool bInitCaption, dyn_string &exceptionInfo,
								bool passingCurveVisible = FALSE) {
	string activeTrend;
	bool yIsLog, xIsLog, curveVisible, yAxisVisible, xAxisVisible, extendCurveOneLegend;
	shape activeTrendShape;
	shape standardTrendShape;
	int i, timeRange, refXPos, refYPos, oldXPos, oldYPos, markerType;
	string ref, cleanRef = sRef;
	dyn_string ranges, curvesList;
	int iCurveScalePos;

	// get the shape of the standard, log and active trend
	// the active is either standard or log
	activeTrend = trendName;
	standardTrendShape = getShape(trendShapeStr[fwTrending_LINEAR_TREND_NAME]);
	activeTrendShape = getShape(trendShapeStr[fwTrending_ACTIVE_TREND_NAME]);
	
	// set the time interval of both trends
	timeRange = plotExtendedObject[fwTrending_PLOT_OBJECT_TIME_RANGE][1];
	standardTrendShape.timeInterval(timeRange);

	_fwTrending_gotoNow(standardTrendShape, timeRange);

	delay(1,200);

	//set the back colour, fore colour and font
	standardTrendShape.backCol = plotExtendedObject[fwTrending_PLOT_OBJECT_BACK_COLOR][1];
	standardTrendShape.foreCol = plotExtendedObject[fwTrending_PLOT_OBJECT_FORE_COLOR][1];
	standardTrendShape.defaultFont = plotExtendedObject[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1];
	standardTrendShape.scaleFont = plotExtendedObject[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1];
	standardTrendShape.legendFont = plotExtendedObject[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1];

	ref = _fwTrending_adjustRefName(ref);

    standardTrendShape.manageLegend(plotExtendedObject[fwTrending_PLOT_OBJECT_LEGEND_ON][1]);

	if(plotExtendedObject[fwTrending_PLOT_OBJECT_GRID][1] == "TRUE") {
		standardTrendShape.showGrid(TRUE);
	} else {
		standardTrendShape.showGrid(FALSE);
	}

    standardTrendShape.defaultFont(plotExtendedObject[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1]);
	
	if(strlen(plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_X_FORMAT][1])==0
			&& strlen(plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_X_FORMAT][2])==0) {
		standardTrendShape.timeFormat(0,TRUE,fwTrending_DEFAULT_AXII_X_FORMAT,"");
	} else {
		standardTrendShape.timeFormat(0,FALSE,plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_X_FORMAT][1],
										plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_X_FORMAT][2]);
	}
	
	if(plotExtendedObject[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1] == "TRUE") {
		yIsLog = TRUE;
	} else {
		yIsLog = FALSE;
	}
	
	_fwTrending_convertFrameworkToPvssMarkerType(plotExtendedObject[fwTrending_PLOT_OBJECT_MARKER_TYPE][1], markerType, exceptionInfo);

	for(i=1; i<=fwTrending_TRENDING_MAX_CURVE;i++) {
		standardTrendShape.curveScaleBackCol("curve_"+i, plotExtendedObject[fwTrending_PLOT_OBJECT_BACK_COLOR][1]);
		
		if(plotExtendedObject[fwTrending_PLOT_OBJECT_AXII][i] == "TRUE") {
			yAxisVisible = TRUE;
		} else {
			yAxisVisible = FALSE;
		}

		//assume data coming is representing curve in hidden state, we need to change it to curve in visible state
		if(plotExtendedObject[fwTrending_PLOT_OBJECT_CURVES_HIDDEN][i] == "FALSE") {
			curveVisible = !passingCurveVisible;
		} else {
			curveVisible = passingCurveVisible;
		}

		if(plotExtendedObject[fwTrending_PLOT_OBJECT_MODEL][1] != fwTrending_XY_PLOT_MODEL) {
			fwTrending_clearAlarmLimits(standardTrendShape, "curve_"+i, exceptionInfo);
			_fwTrending_initCurve("curve_"+i,
                            	i,
								cleanRef,
								makeDynString(ref+"trendCaption.Text"+i),
								makeDynString(ref+"trendCaption.valueCurve"+i),
								makeDynString(plotExtendedObject[fwTrending_PLOT_OBJECT_DPES][i]),
								makeDynString(plotExtendedObject[fwTrending_PLOT_OBJECT_LEGENDS][i]),
								makeDynString(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS][i]),
								plotExtendedObject[fwTrending_PLOT_OBJECT_COLORS][i],
								makeDynBool(yAxisVisible),
								makeDynBool(yIsLog),
								ref+"trendCaption.visibility"+i,
								makeDynString(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_UNITS][i]),
								makeDynString(ref+"trendCaption.unit"+i),
								curveVisible,
								trendShapeStr[fwTrending_ACTIVE_TREND_NAME],
								plotExtendedObject[fwTrending_PLOT_OBJECT_CURVE_TYPES][i],
								makeDynString(ref+"trendCaption.curveTime"),
								bInitCaption,
								exceptionInfo,
								markerType,
								makeDynString(plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_POS][i]),
								plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_LINK][i],
								plotExtendedObject[fwTrending_PLOT_OBJECT_CURVE_STYLE][1],
								plotExtendedObject[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT][i],
								plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT][i]);

		} else {
			yAxisVisible = FALSE;
			xAxisVisible = FALSE;
			yIsLog = FALSE;
			xIsLog = FALSE;
		
			_fwTrending_initCurve("curve_"+i,
                            	i,
								cleanRef,
								makeDynString(ref+"trendCaption.Text"+i, ref+"trendCaption.Text"+i),
								makeDynString(ref+"trendCaption.valueCurve"+i, ref+"trendCaption.valueCurve"+i),
								makeDynString(plotExtendedObject[fwTrending_PLOT_OBJECT_DPES][i], plotExtendedObject[fwTrending_PLOT_OBJECT_DPES_X][i]),
								makeDynString(plotExtendedObject[fwTrending_PLOT_OBJECT_LEGENDS][i], plotExtendedObject[fwTrending_PLOT_OBJECT_LEGENDS_X][i]),
								makeDynString(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS][i], plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS_X][i]),
								plotExtendedObject[fwTrending_PLOT_OBJECT_COLORS][i],
								makeDynBool(yAxisVisible, xAxisVisible),
								makeDynBool(yIsLog, xIsLog),
								ref+"trendCaption.visibility"+i,
								makeDynString(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_UNITS][i], plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_UNITS_X][i]),
								makeDynString(ref+"trendCaption.unit"+i, ref+"trendCaption.unit"+i),
								curveVisible,
								trendShapeStr[fwTrending_ACTIVE_TREND_NAME],
								plotExtendedObject[fwTrending_PLOT_OBJECT_CURVE_TYPES][i],
								makeDynString(ref+"trendCaption.curveTime", ref+"trendCaption.curveTime"),
								bInitCaption,
								exceptionInfo,
								markerType);
		}
	}

	// if XY then set up 9th curve for the axis
	if(plotExtendedObject[fwTrending_PLOT_OBJECT_MODEL][1] == fwTrending_XY_PLOT_MODEL)	{
		ranges = strsplit(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE][1], ":");
		standardTrendShape.curveAutoscale("curve_9", FALSE);
		standardTrendShape.curveMin("curve_9", ranges[1]);
		standardTrendShape.curveMax("curve_9", ranges[2]);
		ranges = strsplit(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE_X][1], ":");
		standardTrendShape.curveAutoscaleX("curve_9", FALSE);
		standardTrendShape.curveMinX("curve_9", ranges[1]);
		standardTrendShape.curveMaxX("curve_9", ranges[2]);
	} else if(shapeExists(ref+"trendCaption.allowMoving")) {
		// if YT then see if only one curve is shown, if so, and the shape 'allowMoving' exists, then move the legend to maximise space
		extendCurveOneLegend = TRUE;
		curvesList = plotExtendedObject[fwTrending_PLOT_OBJECT_DPES];
		if(curvesList[1] != "") {
			for(i=2; i<=fwTrending_TRENDING_MAX_CURVE; i++) {
				if(curvesList[i] != "") {
					extendCurveOneLegend = FALSE;
				}
			}
		} else {
			extendCurveOneLegend = FALSE;
		}
		
		if(strlen(plotExtendedObject[fwTrending_PLOT_OBJECT_LEGENDS][1]) < 60) {
			extendCurveOneLegend = FALSE;
		}
		
		if(extendCurveOneLegend) {
			getValue("valueCurve1", "position", oldXPos, oldYPos);
			getValue("valueCurve5", "position", refXPos, refYPos);
			setValue("valueCurve1", "position", refXPos, oldYPos);

			getValue("unit1", "position", oldXPos, oldYPos);
			getValue("unit5", "position", refXPos, refYPos);
			setValue("unit1", "position", refXPos, oldYPos);
			
			setValue("Text1", "scale", 2.54, 1);
		} else {
			getValue("valueCurve1", "position", oldXPos, oldYPos);
			getValue("valueCurve2", "position", refXPos, refYPos);
			setValue("valueCurve1", "position", refXPos, oldYPos);

			getValue("unit1", "position", oldXPos, oldYPos);
			getValue("unit2", "position", refXPos, refYPos);
			setValue("unit1", "position", refXPos, oldYPos);

			setValue("Text1", "scale", 1, 1);
		}
    }		
	
	/* added by Herve */
	// start the active trend if necessary
	if(runTrend) {
		setValue(ref + "trendCaption.currentTime.currentTime", "visible", runTrend);
		setValue(ref + "trendCaption.curveTime", "visible", !runTrend);
	}

	// refresh both trends
	standardTrendShape.trendRefresh();
	
	fwTrending_controlBarOnOff(sRef, plotExtendedObject[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1] );
}


/** Purpose: initialize the histogram. This function is called from the initScript of the fwTrending/fwTrendingHistogram.pnl.
It configure the trend with the configuration passed in plotExtendedObject.

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	Not for reuse.

@par Usage
	Internal

@par PVSS managers
	VISION

@param sRef					input, reference given when adding the corresponding panel, the panel containing the
							fwTrending/fwTrendingHistogram.pnl and a caption or
							fwTrending/fwTrendingHistogram.pnl must have the reference name of sRef+"trend"
@param trendName			input, active trend name
@param plotExtendedObject	input, details of the plot are returned here
							(see fwTrending_PLOT_OBJECT.... constants for info on what needs to be passed
							as well as fwTrending_PLOT_OBJECT_EXT.... constants)
@param runTrend				input, "TRUE" if the trend must be in running mode, else FALSE
@param exceptionInfo		output, the exception is returned here
*/
fwTrending_initHistogramWithObject(string sRef, string trendName, dyn_dyn_string plotExtendedObject,
								bool runTrend, dyn_string &exceptionInfo) {
	int i, length;
	shape activeTrendShape;
	string ref = sRef;
	
	// get the shape of the standard, log and active trend
	// the active is either standard or log
	activeTrendShape = getShape(trendName);
	
	activeTrendShape.backCol = plotExtendedObject[fwTrending_PLOT_OBJECT_BACK_COLOR][1];
	activeTrendShape.foreCol = plotExtendedObject[fwTrending_PLOT_OBJECT_FORE_COLOR][1];

	ref = _fwTrending_adjustRefName(ref);
	
	setValue(ref+"trendCaption.legendText", "text", plotExtendedObject[fwTrending_PLOT_OBJECT_LEGENDS][1]);
	setValue(ref+"trendCaption.legendText", "foreCol", plotExtendedObject[fwTrending_PLOT_OBJECT_COLORS][1]);

	if(plotExtendedObject[fwTrending_PLOT_OBJECT_LEGEND_ON][1] == "TRUE") {
		activeTrendShape.xArrayShow(TRUE);
	} else {
		activeTrendShape.xArrayShow(FALSE);
	}
	
	if(plotExtendedObject[fwTrending_PLOT_OBJECT_GRID][1] == "TRUE") {
		activeTrendShape.yGrid(TRUE);
		activeTrendShape.xGrid(TRUE);
	} else {
		activeTrendShape.yGrid(FALSE);
		activeTrendShape.xGrid(FALSE);
	}
	
	activeTrendShape.colorTolOK = plotExtendedObject[fwTrending_PLOT_OBJECT_COLORS][1];
	activeTrendShape.colorTolHigh = plotExtendedObject[fwTrending_PLOT_OBJECT_COLORS][1];
	activeTrendShape.colorTolLow = plotExtendedObject[fwTrending_PLOT_OBJECT_COLORS][1];
	
	activeTrendShape.flush;

	length = dynlen(plotExtendedObject[fwTrending_PLOT_OBJECT_DPES]);
	for(i=1; i<=length; i++) {
		if(dpExists(plotExtendedObject[fwTrending_PLOT_OBJECT_DPES][i])) {
			dpConnect("_fwTrending_updateHistogram", TRUE, plotExtendedObject[fwTrending_PLOT_OBJECT_DPES][i]);
		}
	}

	setValue(ref + "trendCaption.currentTime.currentTime", "visible", runTrend);
	setValue(ref + "trendCaption.curveTime", "visible", !runTrend);
}


/** Show / hide the control menu bar and the bottom caption bar

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	Not for reuse.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref			input, reference of the trend
@param visible		input, visibility state of the control bar.
                    It is used as a bit mask (bit 0 = control bar, bit 1 = caption bar). 0=visible, 1=hidden.
                    int values:
					0: control bar and caption bar visible (default)
					1: control bar hidden, caption bar visible
					2: control bar visible, caption bar hidden
					3: control bar hidden, caption bar hidden
*/
fwTrending_controlBarOnOff(string ref, int visible) {
	int toolBarH,toolBarW, trendH, trendW, refX, refY, trendX, trendY, labelsX, labelsY, bottomY;
	int iLegendX, iLegendY, iLegendH, iLegendW;
	dyn_string exceptionInfo;
	string buttonIcon;
	string isRunning;
	dyn_string plotShapes, plotData;
	shape standardTrendShape;
	string trendShapeName;
	bool bControlBarVisible;
	bool bCaptionBarVisible;
	string cmdRef, refForRuntime;

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);	
	standardTrendShape = getShape(plotShapes[fwTrending_LINEAR_TREND_NAME]);
	
	if(strpos(ref,".")<1 && strlen(ref)>0) {
		ref = ref+".";
	}
	
	//the shape name is different if plot or page
	trendShapeName = ref+standardTrendShape.name;
	if(!shapeExists(trendShapeName)) {
		//it's a page
		cmdRef = ref;
		strreplace(cmdRef,".","");
		refForRuntime = cmdRef;
		cmdRef = cmdRef+"trend.";
		trendShapeName = cmdRef+standardTrendShape.name;
	} else {
		//it's a plot
		cmdRef = ref;
		refForRuntime = ref;
	}
	
	shape trendShape = getShape(trendShapeName);

    if(!shapeExists(trendShapeName)) {
		return;
	}
	
	//get a reference for x,y: TimeCascadeButton is at the origin (0,0) of the object
	getValue(ref+"TimeCascadeButton","position",refX,refY);
	getValue(ref+"TimeCascadeButton","size",toolBarW,toolBarH);
	getValue(trendShapeName,"size",trendW,trendH);
	getValue(trendShapeName,"position",trendX,trendY);
	bottomY = trendY+trendH;//Y position of the bottom of the trend object
	
	//handle faceplate with big legend else handle faceplate with small legend
	if(shapeExists(cmdRef+"Text8")) {
		getValue(cmdRef+"Text8","position",iLegendX,iLegendY);
		getValue(cmdRef+"Text8","size",iLegendW,iLegendH);
	} else {
		getValue(cmdRef+"currentTime","position",iLegendX,iLegendY);
		getValue(cmdRef+"currentTime","size",iLegendW,iLegendH);
	}
	
	bottomY = iLegendY+iLegendH;

	switch(visible) {
		case 3://no bars visible - trend fully stretched
			trendY = refY;
			trendH = bottomY-trendY;
			buttonIcon = "[pattern,[tile,png,expand_icon.png]]";
			bControlBarVisible = false;
			bCaptionBarVisible = false;
			break;
		case 2://control bar visible
			trendY = refY+toolBarH;
			trendH = bottomY-trendY;
			buttonIcon = "[pattern,[tile,png,collapse_icon.png]]";
			bControlBarVisible = true;
			bCaptionBarVisible = false;
			break;
		case 1://captions bar at the bottom visible
			getValue(cmdRef+"currentTime","position",iLegendX,iLegendY);
			trendY = refY;
			trendH = iLegendY-trendY;
			buttonIcon = "[pattern,[tile,png,expand_icon.png]]";
			bControlBarVisible = false;
			bCaptionBarVisible = true;
			break;
		case 0://control bar and captions bar visible
			getValue(cmdRef+"currentTime","position",iLegendX,iLegendY);
			trendY = refY+toolBarH;
			trendH = iLegendY-trendY;
			buttonIcon = "[pattern,[tile,png,collapse_icon.png]]";
			bControlBarVisible = true;
			bCaptionBarVisible = true;
			break;
	}
	
	setMultiValue(
			trendShapeName,"size", trendW,trendH,
			trendShapeName, "position", refX,trendY,
			ref+"TimeCascadeButton","visible",bControlBarVisible,
			ref+"YAxiiCascadeButton","visible",bControlBarVisible,
			ref+"saveSettings","visible",bControlBarVisible,
			ref+"saveSettings","visible",bControlBarVisible,
			ref+"OtherCascadeButton","visible",bControlBarVisible,
			ref+"resetTrendZoomButton","visible",bControlBarVisible,
			ref+"logCheckBox","visible",bControlBarVisible,
			ref+"autoScaleCheckBox","visible",bControlBarVisible,
			ref+"TimeCascadeButton","visible",bControlBarVisible);
			
	if(shapeExists(ref+"toggleControlBar")) {
		setValue(ref+"toggleControlBar","fill",buttonIcon);
	}
	
	plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON] = visible;
	
	fwTrending_setRuntimePlotDataWithStrings(refForRuntime, isRunning, plotData, exceptionInfo, FALSE);
}


/** Show / hide the control menu bar and the bottom caption bar depending on last status

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	Not for reuse.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref				input, reference of the trend
*/
fwTrending_toggleControlBar(string ref) {
	string trendRunning;
	dyn_string exceptionInfo;
	dyn_string plotShapes, plotData;
	int controlBarInt;
	bit32 controlBarBits;
	bool controlBarOn;
	
	delay(0,200);

	fwTrending_getRuntimePlotDataWithStrings(ref, trendRunning, plotShapes, plotData, exceptionInfo, FALSE);
	
	controlBarInt = plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON];
	controlBarBits = controlBarInt;
	controlBarOn = getBit(controlBarBits,0);
	setBit(controlBarBits,0,!controlBarOn);
	controlBarInt = controlBarBits;
	plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON] = controlBarInt;
	
	fwTrending_controlBarOnOff(ref, plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON]);
}


/** Sets the text box txtCurvesDpes with the list of dpes which are plotted together with alarms
  This is used to change online the value of the plotted limits in case the alarm handling setting
 is changed by the user.

@par Constraints
	This function is only for use with the standard trend panel as it makes direct reference to many of the graphical objects.
	Not for reuse.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref			input, reference of the trend
@param plotData     input, details of the plot
					(see fwTrending_PLOT_OBJECT.... constants for info on what needs to be passed
					as well as fwTrending_PLOT_OBJECT_EXT.... constants)
*/
_fwTrending_connectToAlarmHandling(string ref, dyn_dyn_string plotData) {
	//connect to alarms, if shown on the trend
	dyn_string dsCurvesDpes, dsAlarmsLimitsOn, dsDpesWithAlarms, exceptionInfo;
	string sPreviousDpesWithAlarms;
	int i;
	
	if(dynlen(plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW])==1) {
		fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW],dsAlarmsLimitsOn,exceptionInfo);
	} else {
		dsAlarmsLimitsOn = plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW];
	}
	
	if(dynlen(plotData[fwTrending_PLOT_OBJECT_DPES])==1) {
		fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_DPES],dsDpesWithAlarms,exceptionInfo);
	} else {
		dsDpesWithAlarms = plotData[fwTrending_PLOT_OBJECT_DPES];
	}
	
	dynClear(dsCurvesDpes);
	
	for(i=1; i<=fwTrending_MAX_NUM_CURVES; i++) {
		if(dsAlarmsLimitsOn[i]) {
			dynAppend(dsCurvesDpes, dsDpesWithAlarms[i]);
		}
	}
	
	setValue(ref+"trend.txtCurvesDpes","text",dsCurvesDpes);
}


/** Show the standard or log trend

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param visibility		input, visibility state of the standard trend (TRUE to show standard trend, FALSE to show log trend)
@param standardStr		input, name of the standard trend graphical element (with any reference name included e.g. ref.logTrend)
@param logStr			input, name of the log trend graphical element (with any reference name included e.g. ref.standardTrend)
@param plotData			optional	input, plot data
*/
fwTrending_showStandardTrend(bool visibility, string standardStr, string logStr, dyn_dyn_string plotData = "") {
							shape standardTrendShape, logTrendShape;
	int i;
	dyn_string dsScaleFormats, exceptionInfo;

	standardTrendShape = getShape(standardStr);
	standardTrendShape.visible = TRUE;
	
	if(standardTrendShape.shapeType == "TREND") {
		standardTrendShape.logarithmicTrend(!visibility);
		
		if(!visibility) {
			for(i=1 ; i<= fwTrending_TRENDING_MAX_CURVE ; i++) {
				standardTrendShape.curveScaleFormat("curve_"+i,"%2.2e");
			}
		} else if(dynlen(plotData)>1) {
			dsScaleFormats = plotData[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT];
			
			if(dynlen(dsScaleFormats)==1) {
				fwTrending_convertStringToDyn(dsScaleFormats[1],dsScaleFormats,exceptionInfo);
			}
			
			for(i=1 ; i<= fwTrending_TRENDING_MAX_CURVE ; i++) {
				standardTrendShape.curveScaleFormat("curve_"+i,dsScaleFormats[i]);
			}
		} else {
			for(i=1 ; i<= fwTrending_TRENDING_MAX_CURVE ; i++) {
				standardTrendShape.curveScaleFormat("curve_"+i,fwTrending_DEFAULT_AXII_Y_FORMAT);
			}
		}
	}
}


/** Purpose: disconnect the curves of the active trend, this function is called when switching from standard to log and vice-versa,
the non active trend is disconnected to the DPEs

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param dsCurveDPE		input, list of 8 DPEs connected to the curves of the plot
@param activeTrend		input, name of the active trend graphical element (with any reference name included e.g. ref.standardTrend)
*/
fwTrending_disconnectActiveTrend(dyn_string dsCurveDPE, string activeTrend) {
	string sCurveDPE1, sCurveDPE2, sCurveDPE3;
	shape activeTrendShape;
	int i;
	
	activeTrendShape = getShape(activeTrend);

	// disconnect all the curves	
	for(i=1;i<=fwTrending_TRENDING_MAX_CURVE;i++) {
		if(dsCurveDPE[i] != "") {		
			activeTrendShape.disconnectDirectly("curve_"+i);
		}
	}
}


/** Purpose: show/hide a curve, this fucntion is called from the caption.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param ref				input, the name of reference within which the trend objects are being displayed
@param trendName		input, name of the graphical element containing the name of the active trend (usually "trend.activeTrendText")
@param curveNumber		input, curve number to act on (from 1 to 8)
@param visibility		input, visibility state of the curve
*/
fwTrending_ShowCurve(string ref, string trendName, int curveNumber, bool visibility) {
	string isRunning;
	string temp, trendN;
	shape trendShape, yAxisControl;
	dyn_bool curveVisibility = makeDynBool(false, false, false, false, false, false, false, false);
	int i;
	dyn_string plotShapes, plotData, split, exceptionInfo;
	
	// get the name of the active trend and its shape
	getValue(ref+trendName, "text", temp);
	trendShape = getShape(temp);
	trendN = temp;

	// get the previous visibilty state of the 8 curves	

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);
	fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], split, exceptionInfo);
	
	for(i=1;i<=fwTrending_TRENDING_MAX_CURVE;i++) {
		if(split[i] == "TRUE") {
			curveVisibility[i] = true;
		}
	}

	fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_AXII], split, exceptionInfo);
	
	// set the visibility of the curve
	trendShape.curveVisible("curve_"+curveNumber, visibility);
	trendShape.curveScaleVisibility("curve_"+curveNumber, visibility && (split[curveNumber]=="TRUE"));
	fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_AXII_POS], split, exceptionInfo);
	
	// set the position of the curve
	trendShape.curveScalePosition("curve_"+curveNumber, split[curveNumber]);

	// set the new one
	curveVisibility[curveNumber] = visibility;
	// and save it
	plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN] = curveVisibility[1]+fwTrending_CONTENT_DIVIDER+curveVisibility[2]+fwTrending_CONTENT_DIVIDER+curveVisibility[3]+fwTrending_CONTENT_DIVIDER+curveVisibility[4]+fwTrending_CONTENT_DIVIDER+curveVisibility[5]+fwTrending_CONTENT_DIVIDER+curveVisibility[6]+fwTrending_CONTENT_DIVIDER+curveVisibility[7]+fwTrending_CONTENT_DIVIDER+curveVisibility[8]+fwTrending_CONTENT_DIVIDER;

	fwTrending_setRuntimePlotDataWithStrings(ref, isRunning, plotData, exceptionInfo, FALSE);

	getValue(trendN,"curveDataSource","curve_"+curveNumber,temp);
	fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW], split, exceptionInfo);
	fwTrending_toggleAlarmLimits("curve_"+curveNumber, temp, visibility && split[curveNumber],trendShape,
                               exceptionInfo, plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE], false);
}


/** Reads all the page configuration from a page datapoint.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param pageDp				input, the page data point to read
@param pageData				output, details of the page are returned here
							(see fwTrending_PAGE_OBJECT.... constants for info on what is returned)
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_getPage(string pageDp, dyn_dyn_string &pageData, dyn_string &exceptionInfo) {
	if(dpExists(pageDp)) {
		if(dpTypeName(pageDp) == fwTrending_PAGE) {
			dpGet(pageDp + fwTrending_PAGE_MODEL, pageData[fwTrending_PAGE_OBJECT_MODEL][1],
					pageDp + fwTrending_PAGE_TITLE, pageData[fwTrending_PAGE_OBJECT_TITLE][1],
					pageDp + fwTrending_PAGE_NCOLS, pageData[fwTrending_PAGE_OBJECT_NCOLS][1],
					pageDp + fwTrending_PAGE_NROWS, pageData[fwTrending_PAGE_OBJECT_NROWS][1],
					pageDp + fwTrending_PAGE_PLOTS, pageData[fwTrending_PAGE_OBJECT_PLOTS],
					pageDp + fwTrending_PAGE_PLOT_TEMPLATE_PARAMETERS, pageData[fwTrending_PAGE_OBJECT_PLOT_TEMPLATE_PARAMETERS],
					pageDp + fwTrending_PAGE_CONTROLS, pageData[fwTrending_PAGE_OBJECT_CONTROLS][1]);

			if(dpExists(pageDp + fwTrending_PAGE_ACCESS_CONTROL_SAVE)) {
				dpGet(pageDp + fwTrending_PAGE_ACCESS_CONTROL_SAVE, pageData[fwTrending_PAGE_OBJECT_ACCESS_CONTROL_SAVE][1]);
			} else {
				pageData[fwTrending_PAGE_OBJECT_ACCESS_CONTROL_SAVE][1] = "";
			}
		} else {
			fwException_raise(exceptionInfo, "ERROR", "fwTrending_getPage(): " + pageDp + " is not of type " + fwTrending_PAGE, "");
		}
	} else {
		fwException_raise(exceptionInfo, "ERROR", "fwTrending_getPage(): " + pageDp + " does not exist", "");
	}
}


/** Writes all the page configuration data to a page datapoint.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param pageDp				input, the page data point to write to
@param pageData				input, details of the page are passed here
							(see fwTrending_PAGE_OBJECT.... constants for info on what is returned)
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_setPage(string pageDp, dyn_dyn_string pageData, dyn_string &exceptionInfo) {
	dyn_errClass settingError;

	if(dpExists(pageDp)) {
		if(dpTypeName(pageDp) == fwTrending_PAGE) {
			dpSetWait(pageDp + fwTrending_PAGE_MODEL, pageData[fwTrending_PAGE_OBJECT_MODEL][1],
						pageDp + fwTrending_PAGE_TITLE, pageData[fwTrending_PAGE_OBJECT_TITLE][1],
						pageDp + fwTrending_PAGE_NCOLS, pageData[fwTrending_PAGE_OBJECT_NCOLS][1],
						pageDp + fwTrending_PAGE_NROWS, pageData[fwTrending_PAGE_OBJECT_NROWS][1],
						pageDp + fwTrending_PAGE_PLOTS, pageData[fwTrending_PAGE_OBJECT_PLOTS],
						pageDp + fwTrending_PAGE_PLOT_TEMPLATE_PARAMETERS, pageData[fwTrending_PAGE_OBJECT_PLOT_TEMPLATE_PARAMETERS],
						pageDp + fwTrending_PAGE_CONTROLS, pageData[fwTrending_PAGE_OBJECT_CONTROLS][1]);

			settingError = getLastError();
			
			if(dynlen(settingError) > 0) {
				throwError(settingError);
				fwException_raise(exceptionInfo, "ERROR", "fwTrending_setPage(): Could not save page data for " + pageDp, "");
			}

			if(dynlen(pageData)>=fwTrending_PAGE_OBJECT_ACCESS_CONTROL_SAVE) {
				if(dpExists(pageDp + fwTrending_PAGE_ACCESS_CONTROL_SAVE)) {
					dpSetWait(pageDp + fwTrending_PAGE_ACCESS_CONTROL_SAVE, pageData[fwTrending_PAGE_OBJECT_ACCESS_CONTROL_SAVE][1]);
				}
			}
			
			settingError = getLastError();
			
			if(dynlen(settingError) > 0) {
				throwError(settingError);
				fwException_raise(exceptionInfo, "ERROR", "fwTrending_setPage(): Could not save page access control settings for " + pageDp, "");
			}
		} else {
			fwException_raise(exceptionInfo, "ERROR", "fwTrending_setPage(): " + pageDp + " is not of type " + fwTrending_PAGE, "");
		}
	} else {
		fwException_raise(exceptionInfo, "ERROR", "fwTrending_setPage(): " + pageDp + " does not exist", "");
	}
}


/** Reads all the plot configuration from a plot datapoint.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp				input, the plot data point to read
@param plotData				output, details of the plot are returned here
							(see fwTrending_PLOT_OBJECT.... constants for info on what is returned)
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_getPlot(string plotDp, dyn_dyn_string &plotData, dyn_string &exceptionInfo) {
	if(dpExists(plotDp)) {
		if(dpTypeName(plotDp) == fwTrending_PLOT) {
			dpGet(plotDp + fwTrending_PLOT_MODEL, plotData[fwTrending_PLOT_OBJECT_MODEL][1],
					plotDp + fwTrending_PLOT_TITLE, plotData[fwTrending_PLOT_OBJECT_TITLE][1],
					plotDp + fwTrending_PLOT_LEGEND_ON, plotData[fwTrending_PLOT_OBJECT_LEGEND_ON][1],
					plotDp + fwTrending_PLOT_BACK_COLOR, plotData[fwTrending_PLOT_OBJECT_BACK_COLOR][1],
					plotDp + fwTrending_PLOT_FORE_COLOR, plotData[fwTrending_PLOT_OBJECT_FORE_COLOR][1],
					plotDp + fwTrending_PLOT_DPES, plotData[fwTrending_PLOT_OBJECT_DPES],
					plotDp + fwTrending_PLOT_DPES_X, plotData[fwTrending_PLOT_OBJECT_DPES_X],
					plotDp + fwTrending_PLOT_LEGENDS, plotData[fwTrending_PLOT_OBJECT_LEGENDS],
					plotDp + fwTrending_PLOT_LEGENDS_X, plotData[fwTrending_PLOT_OBJECT_LEGENDS_X],
					plotDp + fwTrending_PLOT_COLORS, plotData[fwTrending_PLOT_OBJECT_COLORS],
					plotDp + fwTrending_PLOT_AXII, plotData[fwTrending_PLOT_OBJECT_AXII],
					plotDp + fwTrending_PLOT_AXII_X, plotData[fwTrending_PLOT_OBJECT_AXII_X],
					plotDp + fwTrending_PLOT_IS_TEMPLATE, plotData[fwTrending_PLOT_OBJECT_IS_TEMPLATE][1],
					plotDp + fwTrending_PLOT_CURVES_HIDDEN, plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN],
					plotDp + fwTrending_PLOT_RANGES_MIN, plotData[fwTrending_PLOT_OBJECT_RANGES_MIN],
					plotDp + fwTrending_PLOT_RANGES_MAX, plotData[fwTrending_PLOT_OBJECT_RANGES_MAX],
					plotDp + fwTrending_PLOT_RANGES_MIN_X, plotData[fwTrending_PLOT_OBJECT_RANGES_MIN_X],
					plotDp + fwTrending_PLOT_RANGES_MAX_X, plotData[fwTrending_PLOT_OBJECT_RANGES_MAX_X],
					plotDp + fwTrending_PLOT_TYPE, plotData[fwTrending_PLOT_OBJECT_TYPE][1],
					plotDp + fwTrending_PLOT_TIME_RANGE, plotData[fwTrending_PLOT_OBJECT_TIME_RANGE][1],
					plotDp + fwTrending_PLOT_TEMPLATE_NAME, plotData[fwTrending_PLOT_OBJECT_TEMPLATE_NAME][1],
					plotDp + fwTrending_PLOT_IS_LOGARITHMIC, plotData[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1],
					plotDp + fwTrending_PLOT_GRID, plotData[fwTrending_PLOT_OBJECT_GRID][1],
					plotDp + fwTrending_PLOT_CURVE_TYPES, plotData[fwTrending_PLOT_OBJECT_CURVE_TYPES],
					plotDp + fwTrending_PLOT_MARKER_TYPE, plotData[fwTrending_PLOT_OBJECT_MARKER_TYPE][1]);

      // add the "@" in case trendable information are aliases instead if datapoint names     
      plotData[fwTrending_PLOT_OBJECT_DPES] = _fwTrending_preparePlotObjectDPES(plotData[fwTrending_PLOT_OBJECT_DPES]);
      plotData[fwTrending_PLOT_OBJECT_DPES_X] = _fwTrending_preparePlotObjectDPES(plotData[fwTrending_PLOT_OBJECT_DPES_X]);
      
			if(dpExists(plotDp + fwTrending_PLOT_ACCESS_CONTROL_SAVE)) {
				dpGet(plotDp + fwTrending_PLOT_ACCESS_CONTROL_SAVE, plotData[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE][1]);
			} else {
				plotData[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE][1] = "";
			}
			
			if(dpExists(plotDp + fwTrending_PLOT_CONTROL_BAR_ON)) {
				dpGet(plotDp + fwTrending_PLOT_CONTROL_BAR_ON, plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1]);
			} else {
				plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1] = 0;
			}
			
			if(dpExists(plotDp + fwTrending_PLOT_AXII_POS)) {
				dpGet(plotDp + fwTrending_PLOT_AXII_POS, plotData[fwTrending_PLOT_OBJECT_AXII_POS]);
			} else {
				plotData[fwTrending_PLOT_OBJECT_AXII_POS] = makeDynString(2,2,2,2,2,2,2,2);//2=SCALE_LEFT
			}
			
			if(dpExists(plotDp + fwTrending_PLOT_AXII_LINK)) {
				dpGet(plotDp + fwTrending_PLOT_AXII_LINK, plotData[fwTrending_PLOT_OBJECT_AXII_LINK]);
				if(dynlen(plotData[fwTrending_PLOT_OBJECT_AXII_LINK])==0) {
					plotData[fwTrending_PLOT_OBJECT_AXII_LINK] = makeDynString(0,0,0,0,0,0,0,0);
				}
			} else {
				//if such config does not exist, then link curves to none (0)
				plotData[fwTrending_PLOT_OBJECT_AXII_LINK] = makeDynString(0,0,0,0,0,0,0,0);
			}
			
			if(dpExists(plotDp + fwTrending_PLOT_DEFAULT_FONT)) {
				dpGet(plotDp + fwTrending_PLOT_DEFAULT_FONT, plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1]);
				if(plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1] == "") {
					plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1] = fwTrending_DEFAULT_FONT;
				}
			} else {
				plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1] = fwTrending_DEFAULT_FONT;
			}
			
			if(dpExists(plotDp + fwTrending_PLOT_CURVE_STYLE)) {
				dpGet(plotDp + fwTrending_PLOT_CURVE_STYLE, plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1]);
				if(plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1]=="") {
					plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1] = fwTrending_DEFAULT_CURVE_STYLE;
				}
			} else {
				plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1] = fwTrending_DEFAULT_CURVE_STYLE;
			}

			if(dpExists(plotDp + fwTrending_PLOT_AXII_X_FORMAT)) {
				dpGet(plotDp + fwTrending_PLOT_AXII_X_FORMAT, plotData[fwTrending_PLOT_OBJECT_AXII_X_FORMAT]);
				if(dynlen(plotData[fwTrending_PLOT_OBJECT_AXII_X_FORMAT])<2) {
					plotData[fwTrending_PLOT_OBJECT_AXII_X_FORMAT] = makeDynString(fwTrending_DEFAULT_AXII_X_FORMAT,"","","","","","","");
				}
			} else {
				plotData[fwTrending_PLOT_OBJECT_AXII_X_FORMAT] = makeDynString(fwTrending_DEFAULT_AXII_X_FORMAT,fwTrending_DEFAULT_AXII_X_FORMAT);
			}
			
			if(dpExists(plotDp + fwTrending_PLOT_LEGEND_VALUES_FORMAT)) {
				dpGet(plotDp + fwTrending_PLOT_LEGEND_VALUES_FORMAT, plotData[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT]);
				if(dynlen(plotData[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT])<8) {
					plotData[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT] = makeDynString("","","","","","","","");
				}
			} else {
				plotData[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT] = makeDynString("","","","","","","","");
			}

			if(dpExists(plotDp + fwTrending_PLOT_AXII_Y_FORMAT)) {
				dpGet(plotDp + fwTrending_PLOT_AXII_Y_FORMAT, plotData[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT]);
				if(dynlen(plotData[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT])<8) {
					plotData[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT] = makeDynString("","","","","","","","");
				}
			} else {
				plotData[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT] = makeDynString("","","","","","","","");
			}

			if(dpExists(plotDp + fwTrending_PLOT_ALARM_LIMITS_SHOW)) {
				dpGet(plotDp + fwTrending_PLOT_ALARM_LIMITS_SHOW, plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW]);
				if(dynlen(plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW])<8) {
					plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW] == makeDynString(0,0,0,0,0,0,0,0);
				}
			} else {
				plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW]= makeDynString(0,0,0,0,0,0,0,0);
			}
		} else {
			fwException_raise(exceptionInfo, "ERROR", "fwTrending_getPlot(): " + plotDp + " is not of type " + fwTrending_PLOT, "");
		}
	} else {
		fwException_raise(exceptionInfo, "ERROR", "fwTrending_getPlot(): " + plotDp + " does not exist", "");
	}
	
	if(plotData[fwTrending_PLOT_OBJECT_MODEL][1] == "") {
		plotData[fwTrending_PLOT_OBJECT_MODEL][1] = fwTrending_YT_PLOT_MODEL;
	}
}


/** Writes all the plot configuration data to a plot datapoint.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp				input, the plot data point to write to
@param plotData				input, details of the plot are passed here
							(see fwTrending_PLOT_OBJECT.... constants for info on what is returned)
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_setPlot(string plotDp, dyn_dyn_string plotData, dyn_string &exceptionInfo) {
	dyn_errClass settingError;

	if(dpExists(plotDp)) {
		if(dpTypeName(plotDp) == fwTrending_PLOT) {
      plotData[fwTrending_PLOT_OBJECT_DPES] = _fwTrending_cleanPlotObjectDPES(plotData[fwTrending_PLOT_OBJECT_DPES]);
      plotData[fwTrending_PLOT_OBJECT_DPES_X] = _fwTrending_cleanPlotObjectDPES(plotData[fwTrending_PLOT_OBJECT_DPES_X]);
			dpSetWait(plotDp + fwTrending_PLOT_MODEL, plotData[fwTrending_PLOT_OBJECT_MODEL][1],
					plotDp + fwTrending_PLOT_TITLE, plotData[fwTrending_PLOT_OBJECT_TITLE][1],
					plotDp + fwTrending_PLOT_LEGEND_ON, plotData[fwTrending_PLOT_OBJECT_LEGEND_ON][1],
					plotDp + fwTrending_PLOT_BACK_COLOR, plotData[fwTrending_PLOT_OBJECT_BACK_COLOR][1],
					plotDp + fwTrending_PLOT_FORE_COLOR, plotData[fwTrending_PLOT_OBJECT_FORE_COLOR][1],
					plotDp + fwTrending_PLOT_DPES, plotData[fwTrending_PLOT_OBJECT_DPES],
					plotDp + fwTrending_PLOT_DPES_X, plotData[fwTrending_PLOT_OBJECT_DPES_X],
					plotDp + fwTrending_PLOT_LEGENDS, plotData[fwTrending_PLOT_OBJECT_LEGENDS],
					plotDp + fwTrending_PLOT_LEGENDS_X, plotData[fwTrending_PLOT_OBJECT_LEGENDS_X],
					plotDp + fwTrending_PLOT_COLORS, plotData[fwTrending_PLOT_OBJECT_COLORS],
					plotDp + fwTrending_PLOT_AXII, plotData[fwTrending_PLOT_OBJECT_AXII],
					plotDp + fwTrending_PLOT_AXII_X, plotData[fwTrending_PLOT_OBJECT_AXII_X],
					plotDp + fwTrending_PLOT_IS_TEMPLATE, plotData[fwTrending_PLOT_OBJECT_IS_TEMPLATE][1],
					plotDp + fwTrending_PLOT_CURVES_HIDDEN, plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN],
					plotDp + fwTrending_PLOT_RANGES_MIN, plotData[fwTrending_PLOT_OBJECT_RANGES_MIN],
					plotDp + fwTrending_PLOT_RANGES_MAX, plotData[fwTrending_PLOT_OBJECT_RANGES_MAX],
					plotDp + fwTrending_PLOT_RANGES_MIN_X, plotData[fwTrending_PLOT_OBJECT_RANGES_MIN_X],
					plotDp + fwTrending_PLOT_RANGES_MAX_X, plotData[fwTrending_PLOT_OBJECT_RANGES_MAX_X],
					plotDp + fwTrending_PLOT_TYPE, plotData[fwTrending_PLOT_OBJECT_TYPE][1],
					plotDp + fwTrending_PLOT_TIME_RANGE, plotData[fwTrending_PLOT_OBJECT_TIME_RANGE][1],
					plotDp + fwTrending_PLOT_TEMPLATE_NAME, plotData[fwTrending_PLOT_OBJECT_TEMPLATE_NAME][1],
					plotDp + fwTrending_PLOT_IS_LOGARITHMIC, plotData[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1],
					plotDp + fwTrending_PLOT_GRID, plotData[fwTrending_PLOT_OBJECT_GRID][1],
					plotDp + fwTrending_PLOT_CURVE_TYPES, plotData[fwTrending_PLOT_OBJECT_CURVE_TYPES],
					plotDp + fwTrending_PLOT_MARKER_TYPE, plotData[fwTrending_PLOT_OBJECT_MARKER_TYPE][1]);

			if(dynlen(plotData)>=fwTrending_PLOT_OBJECT_CONTROL_BAR_ON) {
				if(dpExists(plotDp + fwTrending_PLOT_CONTROL_BAR_ON) && dynlen(plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON]) > 0) {
					dpSetWait(plotDp + fwTrending_PLOT_CONTROL_BAR_ON, (int)plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1]);
				}
				
				if(dpExists(plotDp + fwTrending_PLOT_AXII_POS)) {
					dpSetWait(plotDp + fwTrending_PLOT_AXII_POS, plotData[fwTrending_PLOT_OBJECT_AXII_POS]);
				}
				
				if(dpExists(plotDp + fwTrending_PLOT_AXII_LINK)) {
					dpSetWait(plotDp + fwTrending_PLOT_AXII_LINK, plotData[fwTrending_PLOT_OBJECT_AXII_LINK]);
				}
				
				if(dpExists(plotDp + fwTrending_PLOT_DEFAULT_FONT) && dynlen(plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT]) > 0) {
					dpSetWait(plotDp + fwTrending_PLOT_DEFAULT_FONT, plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1]);
				}
				
				if(dpExists(plotDp + fwTrending_PLOT_CURVE_STYLE) && dynlen(plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE]) > 0) {
					dpSetWait(plotDp + fwTrending_PLOT_CURVE_STYLE, plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1]);
				}
				
				if(dpExists(plotDp + fwTrending_PLOT_AXII_X_FORMAT)) {
					dpSetWait(plotDp + fwTrending_PLOT_AXII_X_FORMAT, plotData[fwTrending_PLOT_OBJECT_AXII_X_FORMAT]);
				}
				
				if(dpExists(plotDp + fwTrending_PLOT_LEGEND_VALUES_FORMAT)) {
					dpSetWait(plotDp + fwTrending_PLOT_LEGEND_VALUES_FORMAT, plotData[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT]);
				}
				
				if(dpExists(plotDp + fwTrending_PLOT_AXII_Y_FORMAT)) {
					dpSetWait(plotDp + fwTrending_PLOT_AXII_Y_FORMAT, plotData[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT]);
				}
				
				if(dpExists(plotDp + fwTrending_PLOT_ALARM_LIMITS_SHOW)) {
					dpSetWait(plotDp + fwTrending_PLOT_ALARM_LIMITS_SHOW, plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW]);
				}
				
				settingError = getLastError();
				
				if(dynlen(settingError) > 0) {
					throwError(settingError);
					fwException_raise(exceptionInfo, "ERROR", "fwTrending_setPlot(): Could not save plot data for " + plotDp, "");
				}
			}
			
			if(dynlen(plotData)>=fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE) {
				if(dpExists(plotDp + fwTrending_PLOT_ACCESS_CONTROL_SAVE)) {
					dpSetWait(plotDp + fwTrending_PLOT_ACCESS_CONTROL_SAVE, plotData[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE][1]);
				}
			}

			settingError = getLastError();
			
			if(dynlen(settingError) > 0) {
				throwError(settingError);
				fwException_raise(exceptionInfo, "ERROR", "fwTrending_setPlot(): Could not save plot access control settings for " + plotDp, "");
			}
		} else {
			fwException_raise(exceptionInfo, "ERROR", "fwTrending_setPlot(): " + plotDp + " is not of type " + fwTrending_PLOT, "");
		}
	} else {
		fwException_raise(exceptionInfo, "ERROR", "fwTrending_setPlot(): " + plotDp + " does not exist", "");
	}
}


/** Reads all the plot configuration from a plot datapoint and does some additional processing to get
			all the data required to draw a plot.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the plot data point to read
@param refName					input, reference used in the addSymbol function, this is considered when getting the legend.
@param plotExtendedData			output, details of the plot are returned here
								(see fwTrending_PLOT_OBJECT.... constants for info on what is returned
								as well as fwTrending_PLOT_OBJECT_EXT.... constants)
@param exceptionInfo			output, details of any exceptions are returned here
@param returnCurveVisible		input {OPTIONAL - default = FALSE},
								TRUE to return curve visible state
								FALSE to return curve hidden state
*/
fwTrending_getPlotExtended(string plotDp, string refName, dyn_dyn_string &plotExtendedData, dyn_string &exceptionInfo, bool returnCurveVisible = FALSE) {
	int i, length;
	dyn_string oldStyleObject, temp;
	
	plotExtendedData[fwTrending_getPlotData_LEN_RETURN_DATA] = makeDynString();
	
	//the fwTrending_getPlotData function returns the curve VISIBLE state, not the curve HIDDEN state
	fwTrending_getPlotData(refName, plotDp, oldStyleObject);
	
	if(!returnCurveVisible) {
		fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], plotExtendedData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], exceptionInfo);
		_fwTrending_switchCurvesHiddenVisible(plotExtendedData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], exceptionInfo);
	} else {
		fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], plotExtendedData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], exceptionInfo);
	}
	
	plotExtendedData[fwTrending_PLOT_OBJECT_MODEL][1] = oldStyleObject[fwTrending_PLOT_OBJECT_MODEL];
	plotExtendedData[fwTrending_PLOT_OBJECT_TITLE][1] = oldStyleObject[fwTrending_PLOT_OBJECT_TITLE];
	plotExtendedData[fwTrending_PLOT_OBJECT_LEGEND_ON][1] = oldStyleObject[fwTrending_PLOT_OBJECT_LEGEND_ON];
	plotExtendedData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1] = oldStyleObject[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON];
	plotExtendedData[fwTrending_PLOT_OBJECT_BACK_COLOR][1] = oldStyleObject[fwTrending_PLOT_OBJECT_BACK_COLOR];
	plotExtendedData[fwTrending_PLOT_OBJECT_FORE_COLOR][1] = oldStyleObject[fwTrending_PLOT_OBJECT_FORE_COLOR];
	plotExtendedData[fwTrending_PLOT_OBJECT_IS_TEMPLATE][1] = oldStyleObject[fwTrending_PLOT_OBJECT_IS_TEMPLATE];
	plotExtendedData[fwTrending_PLOT_OBJECT_TYPE][1] = oldStyleObject[fwTrending_PLOT_OBJECT_TYPE];
	plotExtendedData[fwTrending_PLOT_OBJECT_TIME_RANGE][1] = oldStyleObject[fwTrending_PLOT_OBJECT_TIME_RANGE];
	plotExtendedData[fwTrending_PLOT_OBJECT_TEMPLATE_NAME][1] = oldStyleObject[fwTrending_PLOT_OBJECT_TEMPLATE_NAME];
	plotExtendedData[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1] = oldStyleObject[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC];
	plotExtendedData[fwTrending_PLOT_OBJECT_GRID][1] = oldStyleObject[fwTrending_PLOT_OBJECT_GRID];
	plotExtendedData[fwTrending_PLOT_OBJECT_MARKER_TYPE][1] = oldStyleObject[fwTrending_PLOT_OBJECT_MARKER_TYPE];
	plotExtendedData[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE][1] = oldStyleObject[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE];
	plotExtendedData[fwTrending_PLOT_OBJECT_EXT_MIN_FOR_LOG][1] = oldStyleObject[fwTrending_PLOT_OBJECT_EXT_MIN_FOR_LOG];
	plotExtendedData[fwTrending_PLOT_OBJECT_EXT_MAX_PERCENTAGE_FOR_LOG][1] = oldStyleObject[fwTrending_PLOT_OBJECT_EXT_MAX_PERCENTAGE_FOR_LOG];
	plotExtendedData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1] = oldStyleObject[fwTrending_PLOT_OBJECT_DEFAULT_FONT];
	plotExtendedData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1] = oldStyleObject[fwTrending_PLOT_OBJECT_CURVE_STYLE];

	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_DPES], plotExtendedData[fwTrending_PLOT_OBJECT_DPES], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_LEGENDS], plotExtendedData[fwTrending_PLOT_OBJECT_LEGENDS], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_COLORS], plotExtendedData[fwTrending_PLOT_OBJECT_COLORS], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_AXII], plotExtendedData[fwTrending_PLOT_OBJECT_AXII], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_AXII_POS], plotExtendedData[fwTrending_PLOT_OBJECT_AXII_POS], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_AXII_LINK], plotExtendedData[fwTrending_PLOT_OBJECT_AXII_LINK], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_RANGES_MIN], plotExtendedData[fwTrending_PLOT_OBJECT_RANGES_MIN], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_RANGES_MAX], plotExtendedData[fwTrending_PLOT_OBJECT_RANGES_MAX], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_CURVE_TYPES], plotExtendedData[fwTrending_PLOT_OBJECT_CURVE_TYPES], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_EXT_UNITS], plotExtendedData[fwTrending_PLOT_OBJECT_EXT_UNITS], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS], plotExtendedData[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE], plotExtendedData[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_AXII_X_FORMAT], plotExtendedData[fwTrending_PLOT_OBJECT_AXII_X_FORMAT], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT], plotExtendedData[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT], plotExtendedData[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW], plotExtendedData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW], exceptionInfo);

 	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_DPES_X], plotExtendedData[fwTrending_PLOT_OBJECT_DPES_X], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_LEGENDS_X], plotExtendedData[fwTrending_PLOT_OBJECT_LEGENDS_X], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_COLORS], plotExtendedData[fwTrending_PLOT_OBJECT_COLORS], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_AXII_X], plotExtendedData[fwTrending_PLOT_OBJECT_AXII_X], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_RANGES_MIN_X], plotExtendedData[fwTrending_PLOT_OBJECT_RANGES_MIN_X], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_RANGES_MAX_X], plotExtendedData[fwTrending_PLOT_OBJECT_RANGES_MAX_X], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_EXT_UNITS_X], plotExtendedData[fwTrending_PLOT_OBJECT_EXT_UNITS_X], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS_X], plotExtendedData[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS_X], exceptionInfo);
	fwTrending_convertStringToDyn(oldStyleObject[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE_X], plotExtendedData[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE_X], exceptionInfo);
}


/** Get the data from the DP of type FwTrendingPlot and return it in the format for the fwTrending/fwTrendingTrend.pnl
If ref is "" then the legend is taken but if it is not then we assume that this is a multiple plot panel and therefore the legend is
set to the leaf DPE if any.

Please do not call this function directly.  Instead, please use fwTrending_getPlot or fwTrending_getPlotExtended

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param ref				input, reference used in the addSymbol function, this is considered when getting the legend.
@param sDpName			input, the plot data point to read
@param returnValue		output, details of the plot are returned here
*/
fwTrending_getPlotData(string ref, string sDpName, dyn_string &returnValue) {
	dyn_string dsTemp, dsCurvesHidden, split, dsLeg, exceptionInfo, dsLegendFormat, dsAxiiYFormat;
	int len, i, iTemp;
	string temp, dpe, description;
	dyn_float dsYmin, dsYmax;
	bool isLog;
	dyn_bool dsAxii, dbAlarmLimits;
	dyn_int dsCurvesType;
	dyn_dyn_string plotData;
	dyn_int diAxiiPos;
	dyn_int diAxiiLink;

	returnValue[fwTrending_getPlotData_LEN_RETURN_DATA] = "";
	returnValue[fwTrending_PLOT_OBJECT_EXT_MIN_FOR_LOG] = fwTrending_MIN_FOR_LOG;
	returnValue[fwTrending_PLOT_OBJECT_EXT_MAX_PERCENTAGE_FOR_LOG] = fwTrending_MAX_PERCENTAGE_FOR_LOG;
	
	fwTrending_getPlot(sDpName, plotData, exceptionInfo);
	
	returnValue[fwTrending_PLOT_OBJECT_MODEL] = plotData[fwTrending_PLOT_OBJECT_MODEL][1];
	
	// plot title will be used for the zoomed window
	returnValue[fwTrending_PLOT_OBJECT_TITLE] = plotData[fwTrending_PLOT_OBJECT_TITLE][1];

	returnValue[fwTrending_PLOT_OBJECT_BACK_COLOR] = plotData[fwTrending_PLOT_OBJECT_BACK_COLOR][1];
	returnValue[fwTrending_PLOT_OBJECT_FORE_COLOR] = plotData[fwTrending_PLOT_OBJECT_FORE_COLOR][1];
	returnValue[fwTrending_PLOT_OBJECT_LEGEND_ON] = plotData[fwTrending_PLOT_OBJECT_LEGEND_ON][1];
	returnValue[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON] = plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1];
	returnValue[fwTrending_PLOT_OBJECT_GRID] = plotData[fwTrending_PLOT_OBJECT_GRID][1];
	returnValue[fwTrending_PLOT_OBJECT_MARKER_TYPE] = plotData[fwTrending_PLOT_OBJECT_MARKER_TYPE][1];
	returnValue[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE] = plotData[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE][1];
	returnValue[fwTrending_PLOT_OBJECT_DEFAULT_FONT] = plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1];
	returnValue[fwTrending_PLOT_OBJECT_CURVE_STYLE] = plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1];
	returnValue[fwTrending_PLOT_OBJECT_AXII_X_FORMAT] = plotData[fwTrending_PLOT_OBJECT_AXII_X_FORMAT][1]
                                                     + fwTrending_CONTENT_DIVIDER + plotData[fwTrending_PLOT_OBJECT_AXII_X_FORMAT][2];
	
	// get the plot DPEs
	// build the tool tip text by default: dpes [unit]
	// get the unit
	// WARNING UNICOS uses the format: systemName:Alias.DPELeaf and JCOP uses DPE.
	// get the curve visibility, WARNING JCOP trending defines curves hidden and the trend uses curveVisibility (opposite)
	// WARNING if for a cureve number the curveHidden does not exist (no value, the length is less that the curve number) the default is visible
	// but if the DPE is "" then the curve is not visible.
	// get the axii (scale visible) default axii not visible, if the dpe is not existing set the axii to false even if it is true
	dsTemp = plotData[fwTrending_PLOT_OBJECT_DPES];
	dsCurvesHidden = plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN];
	dsAxii = plotData[fwTrending_PLOT_OBJECT_AXII];
	diAxiiPos = plotData[fwTrending_PLOT_OBJECT_AXII_POS];
	diAxiiLink = plotData[fwTrending_PLOT_OBJECT_AXII_LINK];
	dsLegendFormat = plotData[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT];
	dsAxiiYFormat = plotData[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT];
	dbAlarmLimits = plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW];
	
	// get the legends
	dpGet(sDpName+fwTrending_PLOT_LEGENDS, dsLeg);
	len = dynlen(dsTemp);
	
	for(i=1;i<=len;i++) {
		fwTrending_getPlotDataDpeData(dsTemp[i], dpe, temp, description);
		
		if(dpe != "") {
			returnValue[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS] +=dsTemp[i]+" ["+temp+"] "+description+fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_DPES] +=dpe + fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_EXT_UNITS] +=temp+fwTrending_CONTENT_DIVIDER;

			if(dynlen(dsAxii) >=i) {
				returnValue[fwTrending_PLOT_OBJECT_AXII] +=dsAxii[i]+fwTrending_CONTENT_DIVIDER;
			} else {
				returnValue[fwTrending_PLOT_OBJECT_AXII] +="FALSE" + fwTrending_CONTENT_DIVIDER;
			}
			
			if(dynlen(diAxiiPos) >=i) {
				returnValue[fwTrending_PLOT_OBJECT_AXII_POS] +=diAxiiPos[i]+fwTrending_CONTENT_DIVIDER;
			} else {
				returnValue[fwTrending_PLOT_OBJECT_AXII_POS] +=2+fwTrending_CONTENT_DIVIDER;      //2=SCALE_LEFT
			}
			
			if(dynlen(diAxiiLink) >=i)  {
				returnValue[fwTrending_PLOT_OBJECT_AXII_LINK] +=diAxiiLink[i]+fwTrending_CONTENT_DIVIDER;
			} else {
				returnValue[fwTrending_PLOT_OBJECT_AXII_LINK] +="0"+fwTrending_CONTENT_DIVIDER;
			}
			
			if(dynlen(dsLegendFormat) >=i)  {
				returnValue[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT] +=dsLegendFormat[i]+fwTrending_CONTENT_DIVIDER;
			} else {
				returnValue[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT] +=""+fwTrending_CONTENT_DIVIDER;
			}
			
			if(dynlen(dsAxiiYFormat) >=i) {
				returnValue[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT] +=dsAxiiYFormat[i]+fwTrending_CONTENT_DIVIDER;
			} else {
				returnValue[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT] +=""+fwTrending_CONTENT_DIVIDER;
			}
			
			if(dynlen(dbAlarmLimits) >=i) {
				returnValue[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW] +=dbAlarmLimits[i]+fwTrending_CONTENT_DIVIDER;
			} else {
				returnValue[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW] +="0"+fwTrending_CONTENT_DIVIDER;
			}
			
 			if(dynlen(dsLeg) >=i) {
				// if really no legend then put dpe.
				if(dsLeg[i] == "") {
					dsLeg[i] = dsTemp[i];
				}
				
				returnValue[fwTrending_PLOT_OBJECT_LEGENDS] +=dsLeg[i]+fwTrending_CONTENT_DIVIDER;
			} else {
				returnValue[fwTrending_PLOT_OBJECT_LEGENDS] += dsTemp[i]+fwTrending_CONTENT_DIVIDER;
			}
		} else {	// the dpe is not correct -> visibility = false
			returnValue[fwTrending_PLOT_OBJECT_CURVES_HIDDEN] +="FALSE" + fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS] +=fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_DPES] +=fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_EXT_UNITS] +=fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_AXII] +="FALSE" + fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_AXII_POS] +=2 + fwTrending_CONTENT_DIVIDER; //2=SCALE_LEFT
			returnValue[fwTrending_PLOT_OBJECT_AXII_LINK] +=0 + fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_LEGENDS] += fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT] += fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT] += fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW] += 0+fwTrending_CONTENT_DIVIDER;
		}
	}
	
	for(i=len+1;i<=fwTrending_TRENDING_MAX_CURVE; i++) {
		returnValue[fwTrending_PLOT_OBJECT_DPES] +=fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS] +=fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_EXT_UNITS] +=fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_CURVES_HIDDEN] +="FALSE" + fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_AXII] +="FALSE" + fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_LEGENDS] += fwTrending_CONTENT_DIVIDER;
	}

	dsTemp = plotData[fwTrending_PLOT_OBJECT_DPES_X];
	dsAxii = plotData[fwTrending_PLOT_OBJECT_AXII_X];

	// get the legends for x
	dpGet(sDpName+fwTrending_PLOT_LEGENDS_X, dsLeg);
	len = dynlen(dsTemp);
	
	for(i=1;i<=len;i++) {
		fwTrending_getPlotDataDpeData(dsTemp[i], dpe, temp, description);
		
		if(dpe != "") {
			returnValue[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS_X] +=dsTemp[i]+" ["+temp+"] "+description+fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_DPES_X] +=dpe + fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_EXT_UNITS_X] +=temp+fwTrending_CONTENT_DIVIDER;

			if(dynlen(dsAxii) >=i) {
				returnValue[fwTrending_PLOT_OBJECT_AXII_X] +=dsAxii[i]+fwTrending_CONTENT_DIVIDER;
			} else {
				returnValue[fwTrending_PLOT_OBJECT_AXII_X] +="FALSE" + fwTrending_CONTENT_DIVIDER;
			}
			
			if(dynlen(dsLeg) >=i) {
				// if really no legend then put dpe.
				if(dsLeg[i] == "") {
					dsLeg[i] = dsTemp[i];
				}
				
				returnValue[fwTrending_PLOT_OBJECT_LEGENDS_X] +=dsLeg[i]+fwTrending_CONTENT_DIVIDER;
			} else {
				returnValue[fwTrending_PLOT_OBJECT_LEGENDS_X] += dsTemp[i]+fwTrending_CONTENT_DIVIDER;
			}
		} else {
			returnValue[fwTrending_PLOT_OBJECT_DPES_X] +=fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_EXT_UNITS_X] +=fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_AXII_X] +="FALSE" + fwTrending_CONTENT_DIVIDER;
			returnValue[fwTrending_PLOT_OBJECT_LEGENDS_X] += fwTrending_CONTENT_DIVIDER;
		}
	}
	
	for(i=len+1;i<=fwTrending_TRENDING_MAX_CURVE; i++) {
		returnValue[fwTrending_PLOT_OBJECT_DPES_X] +=fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS_X] +=fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_EXT_UNITS_X] +=fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_AXII_X] +="FALSE" + fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_LEGENDS_X] += fwTrending_CONTENT_DIVIDER;
	}

	_fwTrending_switchCurvesHiddenVisible(dsCurvesHidden, exceptionInfo);
	fwTrending_convertDynToString(dsCurvesHidden, returnValue[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], exceptionInfo);

	// get the colors
	dsTemp = plotData[fwTrending_PLOT_OBJECT_COLORS];
	len = dynlen(dsTemp);
	
	for(i=1;i<=len;i++) {
		returnValue[fwTrending_PLOT_OBJECT_COLORS] +=dsTemp[i]+fwTrending_CONTENT_DIVIDER;
	}
	
	for(i=len+1;i<=fwTrending_TRENDING_MAX_CURVE; i++) {
		returnValue[fwTrending_PLOT_OBJECT_COLORS] +=fwTrending_CONTENT_DIVIDER;	
	}

	// get the y-ranges
	dsYmin = plotData[fwTrending_PLOT_OBJECT_RANGES_MIN];
	dsYmax = plotData[fwTrending_PLOT_OBJECT_RANGES_MAX];
	len = dynlen(dsYmin);

	for(i=1;i<=len;i++) {
		returnValue[fwTrending_PLOT_OBJECT_RANGES_MIN] += dsYmin[i] + fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_RANGES_MAX] += dsYmax[i] + fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE] +=dsYmin[i]+":"+dsYmax[i] + fwTrending_CONTENT_DIVIDER;
	}
	
	for(i=len+1;i<=fwTrending_TRENDING_MAX_CURVE; i++) {
		returnValue[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE] += fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_RANGES_MIN] += fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_RANGES_MAX] += fwTrending_CONTENT_DIVIDER;
	}

	// get the y-ranges
	dsYmin = plotData[fwTrending_PLOT_OBJECT_RANGES_MIN_X];
	dsYmax = plotData[fwTrending_PLOT_OBJECT_RANGES_MAX_X];
	len = dynlen(dsYmin);
	
	for(i=1;i<=len;i++) {
		returnValue[fwTrending_PLOT_OBJECT_RANGES_MIN_X] += dsYmin[i] + fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_RANGES_MAX_X] += dsYmax[i] + fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE_X] +=dsYmin[i]+":"+dsYmax[i] + fwTrending_CONTENT_DIVIDER;
	}
	
	for(i=len+1;i<=fwTrending_TRENDING_MAX_CURVE; i++) {
		returnValue[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE_X] += fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_RANGES_MIN_X] += fwTrending_CONTENT_DIVIDER;
		returnValue[fwTrending_PLOT_OBJECT_RANGES_MAX_X] += fwTrending_CONTENT_DIVIDER;
	}

	returnValue[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC] = plotData[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1];

	len = plotData[fwTrending_PLOT_OBJECT_TIME_RANGE][1];
	if(len <= 0) {
		len = fwTrending_SECONDS_IN_ONE_HOUR;
	}
	returnValue[fwTrending_PLOT_OBJECT_TIME_RANGE] = len;

	// get first the plot type, if the plot type is of type unknown set it to fwTrending_PLOT_TYPE_STEPS
	iTemp = plotData[fwTrending_PLOT_OBJECT_TYPE][1];
	switch(iTemp) { // to avoid error with backward compatibility
		case fwTrending_PLOT_TYPE_POINTS:
		case fwTrending_PLOT_TYPE_STEPS:
		case fwTrending_PLOT_TYPE_LINEAR:
		case fwTrending_PLOT_TYPE_INDIVIDUAL:
			break;
		default:
			iTemp = fwTrending_PLOT_TYPE_STEPS;
	}
	returnValue[fwTrending_PLOT_OBJECT_TYPE] = iTemp;
	
	// get the curve type
	dsCurvesType = plotData[fwTrending_PLOT_OBJECT_CURVE_TYPES];
	len = dynlen(dsCurvesType);
	for(i=1;i<=len;i++) {
		if(iTemp == fwTrending_PLOT_TYPE_INDIVIDUAL) {
			switch(dsCurvesType[i]) { // to avoid error with backward compatibility
				case fwTrending_PLOT_TYPE_POINTS:
				case fwTrending_PLOT_TYPE_STEPS:
				case fwTrending_PLOT_TYPE_LINEAR:
					break;
				default:
					dsCurvesType[i] = fwTrending_PLOT_TYPE_STEPS;
			}
			returnValue[fwTrending_PLOT_OBJECT_CURVE_TYPES] +=dsCurvesType[i]+fwTrending_CONTENT_DIVIDER;
		} else {
			returnValue[fwTrending_PLOT_OBJECT_CURVE_TYPES] +=iTemp+fwTrending_CONTENT_DIVIDER;
		}
	}
	
	for(i=len+1;i<=fwTrending_TRENDING_MAX_CURVE; i++) {
		returnValue[fwTrending_PLOT_OBJECT_CURVE_TYPES] +=fwTrending_PLOT_TYPE_STEPS + fwTrending_CONTENT_DIVIDER;
	}
}


/** Get the data related to a specific dpe to be plotted (real DPE, description and unit).
This function is able to deal with DPE or UNICOS format DPE: systemName:AliasName.DPELeaf

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sPlotDpe			input, dpe of the FwTrendingPlot DP, real DP or UNICOS format DPE: systemName:AliasName.DPELeaf
@param sDpe				output, real DPE
@param sUnit			output, unit of the DPE
@param sDescription		output, description of the DPE DPE
*/
fwTrending_getPlotDataDpeData(string sPlotDpe, string &sDpe, string &sUnit, string &sDescription) {
	string tempDpe, localDpe;
	dyn_string dsDpe, exceptionInfo;
	shape parameterStore;
		
	sDpe = "";
	sUnit = "";
	sDescription = "";
		
	if(sPlotDpe != "") 
	{
		if(isDollarDefined("$templateParameters")) {
			//if template parameters are available, do the substitution to get the real dpe values before any dpGetUnit or similar function
			if($sRefName == "") {
				parameterStore = getShape("parameterValues");
			} else {
				parameterStore = getShape($sRefName + "trend.parameterValues");
			}
			
			dsDpe = makeDynString(sPlotDpe);
			_fwTrending_evaluateTemplate(parameterStore.text, dsDpe, exceptionInfo);
			localDpe = dsDpe;
		} else {
			localDpe = sPlotDpe;
		}

		// check if UNICOS format:
		if(isFunctionDefined("unGenericDpFunctions_convert_UNICOSDPE_to_PVSSDPE")) 
		{
			if(fwTrending_isDpName(localDpe))
			{
				unGenericDpFunctions_convert_UNICOSDPE_to_PVSSDPE(localDpe, tempDpe);
				sUnit = dpGetUnit(tempDpe);
			}
				
			sDpe = localDpe;
			sDescription = "";	
      sUnit = dpGetUnit(localDpe);
		} 
		else 
		{
			sDpe = localDpe;
		  sUnit = dpGetUnit(sDpe);
			sDescription = dpGetDescription(sDpe);
		}
	}

	if(isDollarDefined("$templateParameters")) {
		sDpe = sPlotDpe;
	}
}


/** Open a configuration panel to edit the given plot

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param sDpName		input, the data point name of the the plot to configure
*/
fwTrending_editPlot(string sDpName) {
	dyn_string panelsList, exceptionInfo, ds; dyn_float df;

	fwDevice_getDefaultConfigurationPanels(fwTrending_PLOT, panelsList, exceptionInfo);

	ChildPanelOnModalReturn(panelsList[1] + ".pnl","Plot Configuration",
		makeDynString("$Command:edit", "$sDpName:" + sDpName),0,0, df, ds);
}


/** Open a configuration panel to edit the given page

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param sDpName		input, the data point name of the the page to configure
*/
fwTrending_editPage(string sDpName) {
	dyn_string panelsList, exceptionInfo, ds; dyn_float df;

	fwDevice_getDefaultConfigurationPanels(fwTrending_PAGE, panelsList, exceptionInfo);

	ChildPanelOnModalReturn(panelsList[1] + ".pnl","Page Configuration",
		makeDynString("$Command:edit", "$sDpName:" + sDpName, "$WorkPageName:"),0,0, df, ds);
}


/** Get the title of the given plot or page data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sDpName				input, the data point name of the plot or page to read the title from
@param sTitle				output, the title is returned here
@param exceptionInfo		details of any exceptions are returned here
*/
fwTrending_getTitle(string sDpName, string &sTitle, dyn_string &exceptionInfo) {
	string temp, dpe;
	
	if(dpTypeName(sDpName) == fwTrending_PLOT) {
		dpe = fwTrending_PLOT_TITLE;
	} else {
		dpe = fwTrending_PAGE_TITLE;
	}
	
	dpGet(sDpName + dpe, temp);
	
	if(temp == "") {
		temp = sDpName;
	}
	
	sTitle = temp;
}


/** Get the title of the given plot data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sDpPlotName			input, the data point name of the plot to read the title from
@param sPlotTitle			output, the title is returned here
*/
fwTrending_getPlotTitle(string sDpPlotName, string &sPlotTitle) {
	dyn_string exceptionInfo;
	fwTrending_getTitle(sDpPlotName, sPlotTitle, exceptionInfo);
}


/** Get the title of the given page data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sDpPageName			input, the data point name of the page to read the title from
@param sPageTitle			output, the title is returned here
*/
fwTrending_getPageTitle(string sDpPageName, string &sPageTitle) {
	dyn_string exceptionInfo;
	fwTrending_getTitle(sDpPageName, sPageTitle, exceptionInfo);
}


/** Get the template status of the given plot data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sDpPlotName			input, the data point name of the plot to check if template
@param bIsTemplate			output, returns if the plot is flagged as template. TRUE = is template
*/
fwTrending_getPlotIsTemplate(string sDpPlotName, string &bIsTemplate) {
	if(dpExists(sDpPlotName+ fwTrending_PLOT_IS_TEMPLATE)) {
		dpGet(sDpPlotName + fwTrending_PLOT_IS_TEMPLATE , bIsTemplate);
	}
}


/** Set the template status of the given plot data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sDpPlotName			input, the data point name of the plot to check if template
@param bIsTemplate			input, if the plot is flagged as template. TRUE = is template
*/
fwTrending_setPlotIsTemplate(string sDpPlotName, string bIsTemplate) {
	if(dpExists(sDpPlotName+ fwTrending_PLOT_IS_TEMPLATE)) {
		dpSet(sDpPlotName + fwTrending_PLOT_IS_TEMPLATE , bIsTemplate);
	}
}


/** Show the plots at the necessary size and position on a page

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param iNumberOfPlots			input, the number of plots which are to be shown on the current page
@param dsPlotName				input, the list of plot DP Names for this page
@param dsReference				output, list of references of the plot symbols which were added
@param templateParameters		input, contains any template parameter substitutions to be passed to the plots
*/
fwTrending_showPlot(int iNumberOfPlots, dyn_string dsPlotName, dyn_string &dsReference, dyn_string templateParameters) {
	dyn_string dsRef;
	int i, len;
	dyn_int iTrendControlPosX, iTrendControlPosY, iTrendPosX, iTrendPosY;
	dyn_string dsCurveParameters, dsModel;
	string sTrendPanelName, controls, panelType;
	dyn_string dsTemplateParameters, exceptionInfo;

	switch(iNumberOfPlots) {
		case 0:
			break;
		case 1:
			dsRef = makeDynString("");
			// position of the first plot: trendControl and trend
			iTrendControlPosX[1] = fwTrending_ONE_COLUMN;
			iTrendControlPosY[1] = fwTrending_ONE_ROW;
			iTrendPosX[1] = iTrendControlPosX[1];
			iTrendPosY[1] = iTrendControlPosY[1]+fwTrending_TREND_CONTROL_Y_OFFSET;

			// use the correct trend panel name
			sTrendPanelName = "fwTrending/fwTrendingOne";
			break;
		case 2:
			dsRef = makeDynString("1", "2");

			iTrendControlPosX[1] = fwTrending_ONE_COLUMN;
			iTrendControlPosY[1] = fwTrending_TWO_ROW_1;
			iTrendPosX[1] = iTrendControlPosX[1];
			iTrendPosY[1] = iTrendControlPosY[1]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[2] = fwTrending_ONE_COLUMN;
			iTrendControlPosY[2] = fwTrending_TWO_ROW_2;
			iTrendPosX[2] = iTrendControlPosX[2];
			iTrendPosY[2] = iTrendControlPosY[2]+fwTrending_TREND_CONTROL_Y_OFFSET;

			sTrendPanelName = "fwTrending/fwTrendingTwo";
			break;
		case 3:
			dsRef = makeDynString("1", "2", "3");

			iTrendControlPosX[1] = fwTrending_ONE_COLUMN;
			iTrendControlPosY[1] = fwTrending_THREE_ROW_1;
			iTrendPosX[1] = iTrendControlPosX[1];
			iTrendPosY[1] = iTrendControlPosY[1]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[2] = fwTrending_ONE_COLUMN;
			iTrendControlPosY[2] = fwTrending_THREE_ROW_2;
			iTrendPosX[2] = iTrendControlPosX[2];
			iTrendPosY[2] = iTrendControlPosY[2]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[3] = fwTrending_ONE_COLUMN;
			iTrendControlPosY[3] = fwTrending_THREE_ROW_3;
			iTrendPosX[3] = iTrendControlPosX[3];
			iTrendPosY[3] = iTrendControlPosY[3]+fwTrending_TREND_CONTROL_Y_OFFSET;

			sTrendPanelName = "fwTrending/fwTrendingThree";
			break;
		case 4:
			dsRef = makeDynString("1", "2", "3", "4");

			iTrendControlPosX[1] = fwTrending_TWO_COLUMN_1;
			iTrendControlPosY[1] = fwTrending_TWO_ROW_1;
			iTrendPosX[1] = iTrendControlPosX[1];
			iTrendPosY[1] = iTrendControlPosY[1]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[2] = fwTrending_TWO_COLUMN_1;
			iTrendControlPosY[2] = fwTrending_TWO_ROW_2;
			iTrendPosX[2] = iTrendControlPosX[2];
			iTrendPosY[2] = iTrendControlPosY[2]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[3] = fwTrending_TWO_COLUMN_2;
			iTrendControlPosY[3] = fwTrending_TWO_ROW_1;
			iTrendPosX[3] = iTrendControlPosX[3];
			iTrendPosY[3] = iTrendControlPosY[3]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[4] = fwTrending_TWO_COLUMN_2;
			iTrendControlPosY[4] = fwTrending_TWO_ROW_2;
			iTrendPosX[4] = iTrendControlPosX[4];
			iTrendPosY[4] = iTrendControlPosY[4]+fwTrending_TREND_CONTROL_Y_OFFSET;

			sTrendPanelName = "fwTrending/fwTrendingFour";
			break;
		case 5:
			dsRef = makeDynString("1", "2", "3", "4", "5");

			iTrendControlPosX[1] = fwTrending_TWO_COLUMN_1;
			iTrendControlPosY[1] = fwTrending_THREE_ROW_1;
			iTrendPosX[1] = iTrendControlPosX[1];
			iTrendPosY[1] = iTrendControlPosY[1]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[2] = fwTrending_TWO_COLUMN_1;
			iTrendControlPosY[2] = fwTrending_THREE_ROW_2;
			iTrendPosX[2] = iTrendControlPosX[2];
			iTrendPosY[2] = iTrendControlPosY[2]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[3] = fwTrending_TWO_COLUMN_1;
			iTrendControlPosY[3] = fwTrending_THREE_ROW_3;
			iTrendPosX[3] = iTrendControlPosX[3];
			iTrendPosY[3] = iTrendControlPosY[3]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[4] = fwTrending_TWO_COLUMN_2;
			iTrendControlPosY[4] = fwTrending_THREE_ROW_1;
			iTrendPosX[4] = iTrendControlPosX[4];
			iTrendPosY[4] = iTrendControlPosY[4]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[5] = fwTrending_TWO_COLUMN_2;
			iTrendControlPosY[5] = fwTrending_THREE_ROW_2;
			iTrendPosX[5] = iTrendControlPosX[5];
			iTrendPosY[5] = iTrendControlPosY[5]+fwTrending_TREND_CONTROL_Y_OFFSET;

			sTrendPanelName = "fwTrending/fwTrendingSix";
			break;
		case 6:
		default:
			// if more than 6 just take the first six ones and forget the others.
			dsRef = makeDynString("1", "2", "3", "4", "5", "6");

			iTrendControlPosX[1] = fwTrending_TWO_COLUMN_1;
			iTrendControlPosY[1] = fwTrending_THREE_ROW_1;
			iTrendPosX[1] = iTrendControlPosX[1];
			iTrendPosY[1] = iTrendControlPosY[1]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[2] = fwTrending_TWO_COLUMN_1;
			iTrendControlPosY[2] = fwTrending_THREE_ROW_2;
			iTrendPosX[2] = iTrendControlPosX[2];
			iTrendPosY[2] = iTrendControlPosY[2]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[3] = fwTrending_TWO_COLUMN_1;
			iTrendControlPosY[3] = fwTrending_THREE_ROW_3;
			iTrendPosX[3] = iTrendControlPosX[3];
			iTrendPosY[3] = iTrendControlPosY[3]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[4] = fwTrending_TWO_COLUMN_2;
			iTrendControlPosY[4] = fwTrending_THREE_ROW_1;
			iTrendPosX[4] = iTrendControlPosX[4];
			iTrendPosY[4] = iTrendControlPosY[4]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[5] = fwTrending_TWO_COLUMN_2;
			iTrendControlPosY[5] = fwTrending_THREE_ROW_2;
			iTrendPosX[5] = iTrendControlPosX[5];
			iTrendPosY[5] = iTrendControlPosY[5]+fwTrending_TREND_CONTROL_Y_OFFSET;

			iTrendControlPosX[6] = fwTrending_TWO_COLUMN_2;
			iTrendControlPosY[6] = fwTrending_THREE_ROW_3;
			iTrendPosX[6] = iTrendControlPosX[6];
			iTrendPosY[6] = iTrendControlPosY[6]+fwTrending_TREND_CONTROL_Y_OFFSET;

			sTrendPanelName = "fwTrending/fwTrendingSix";
			break;
	}

	len = dynlen(dsRef);
	for(i=1;i<=len;i++) {
		fwDevice_getModel(makeDynString(dsPlotName[i]), dsModel[i], exceptionInfo);
	
		dynClear(dsTemplateParameters);
		dynAppend(dsTemplateParameters, "$templateParameters:"+templateParameters[i]);

		dsCurveParameters = dsTemplateParameters;
		dynAppend(dsCurveParameters, "$dsCurveDPE:"+fwTrending_NOTHING_IN_TREND);
		dynAppend(dsCurveParameters, "$dsCurveLegend:"+fwTrending_NOTHING_IN_TREND);
		dynAppend(dsCurveParameters, "$dsCurveToolTipText:"+fwTrending_NOTHING_IN_TREND);
		dynAppend(dsCurveParameters, "$dsCurveColor:"+fwTrending_NOTHING_IN_TREND);
		dynAppend(dsCurveParameters, "$dsCurveRange:"+fwTrending_NOTHING_IN_TREND);
		dynAppend(dsCurveParameters, "$dsCurveRangeX:"+fwTrending_NOTHING_IN_TREND);
		dynAppend(dsCurveParameters, "$dsUnit:"+fwTrending_NOTHING_IN_TREND);
		dynAppend(dsCurveParameters, "$dsCurveVisible:"+fwTrending_NOTHING_IN_TREND);
		dynAppend(dsCurveParameters, "$dsCurveScaleVisible:"+fwTrending_NOTHING_IN_TREND);
		dynAppend(dsCurveParameters, "$dsCurvesType:"+fwTrending_NOTHING_IN_TREND);
	
		dynAppend(dsCurveParameters, "$ZoomWindowTitle:");
		dynAppend(dsCurveParameters, "$sRefName:"+dsRef[i]);
		dynAppend(dsCurveParameters, "$sDpName:"+dsPlotName[i]);
		dynAppend(dsCurveParameters, "$fMinForLog:");
		dynAppend(dsCurveParameters, "$fMaxPercentageForLog:");
		dynAppend(dsCurveParameters, "$bTrendLog:");
		dynAppend(dsCurveParameters, "$sTimeRange:");
		dynAppend(dsCurveParameters, "$sForeColor:");
		dynAppend(dsCurveParameters, "$sBackColor:");
		dynAppend(dsCurveParameters, "$bShowGrid:");
		dynAppend(dsCurveParameters, "$bShowLegend:");
		dynAppend(dsCurveParameters, "$iMarkerType:");

		if(dsPlotName[i] != "") {
			if(dsModel[i] == fwTrending_HISTOGRAM_PLOT_MODEL) {
				controls = "fwTrending/fwTrendingHistogramControl.pnl";
				panelType = "Histogram";
			} else {
				controls = "fwTrending/fwTrendingTrendControl.pnl";
				panelType = "Plot";
			}
			
			addSymbol(myModuleName(), myPanelName(), controls, dsRef[i], makeDynString("$sRefName:"+dsRef[i], "$templateParameters:" + templateParameters[i]),
					iTrendControlPosX[i], iTrendControlPosY[i], 0, 1.0, 1.0);
		
			addSymbol(myModuleName(), myPanelName(), sTrendPanelName + panelType + ".pnl", dsRef[i]+"trend", dsCurveParameters,
					iTrendPosX[i],
					iTrendPosY[i], 0, 1.0, 1.0);
		}
	}
	
	dsReference = dsRef;
	for(i=dynlen(dsReference); i>=1; i--) {
		if(dsPlotName[i] == "") {
			dynRemove(dsReference, i);
		}
	}
}

					
/** Get the list of plot dps that belong to a page

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sPageName		input, the page DP name
@param dsPlotDps		output, the list of plot DP Names of type FwTrendingPlot
						the dps are ordered by column: plots of column 1, followed by plots of column 2, etc. with no "" between
*/
fwTrending_getPagePlotDps(string sPageName, dyn_string &dsPlotDps) {
	dyn_string exceptionInfo;
	dyn_dyn_string pageData;
	
	fwTrending_getPage(sPageName, pageData, exceptionInfo);
	fwTrending_simplifyPagePlotList(pageData[fwTrending_PAGE_OBJECT_PLOTS],
									pageData[fwTrending_PAGE_OBJECT_NROWS][1],
									pageData[fwTrending_PAGE_OBJECT_NCOLS][1], dsPlotDps, exceptionInfo);
}


/** Simplify the list of plots that comes from the page configuration dp

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsRawPlotList			input, the raw plot list from the page configuration dp
@param rows								input, the number of rows on the page
@param columns						input, the number of columns on the page
@param dsSimplePlotList		output, the simplfied list of plots on the page
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_simplifyPagePlotList(dyn_string dsRawPlotList, int rows, int columns, dyn_string &dsSimplePlotList,
									dyn_string &exceptionInfo) {
	int length;
	int indexRow=1, indexCol=1, indexDpes=1;
	
	length = dynlen(dsRawPlotList);
	for(indexCol=1;indexCol<=columns;indexCol++) {
		for(indexRow=1;indexRow<=rows;indexRow++) {
			if(length >= (indexCol+fwTrending_MAX_COLS*(indexRow -1))) {
				dsSimplePlotList[indexDpes] = dsRawPlotList[indexCol+fwTrending_MAX_COLS*(indexRow -1)];
				indexDpes++;
			}
		}
	}
}

					
/** Opens a progressBar as a childPanel. This function is the same as the openProgressBar from std.ctl but it opens the progress
bar as a childPanel. The difference between this function and the openProgressBar function is the dpSet of "_VarTrendOpen.PanelName:_original.._value"
where "ProgressBar" is replaced byt myModuleName() and the ModuleOnWithPanel replaced with ChildPanelOnCentral().

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param sHeader				input, the hearder of the progress bar
@param sIcon				input, the icon to show in the progress bar
@param text1				input, text to show in the progress bar
@param text2				input, text to show in the progress bar
@param text3				input, text to show in the progress bar
@param iSliderType			input, the slider type, 0.. no slider, 1.. permanent slider, 2..normal slider
*/
_fwTrending_openProgressBar(string sHeader, string sIcon, string text1, string text2, string text3, int iSliderType) {
	int PBreite,PHoehe,x,y;
	dyn_int di;
	string transferstring;
	dyn_string ds;

	ds[1] = text1;
	ds[2] = text2;
	ds[3] = text3;
	ds[4] = -1;
	ds[5] = sIcon;
	ds[6] = iSliderType;

	transferstring = ds;

	addGlobal("gProgressBarTimeStamp", TIME_VAR);
	di=_PanelSize("vision/progressBar.pnl");
	panelSize(myPanelName(),PBreite,PHoehe);
	x=(PBreite-di[1])/2;
	y=(PHoehe-di[2]-20)/2;
	if(x<0) x=0;
	if(y<0) y=0;

	dpSet("_VarTrendOpen.UiNumber:_original.._value",myManNum(),
		"_VarTrendOpen.PanelName:_original.._value",/*"ProgressBar"*/ myModuleName(),
		"_VarTrendOpen.TrendData:_original.._value",transferstring);

	ChildPanelOnCentral("vision/progressBar.pnl",
					sHeader,
					makeDynString());

	delay(0,100);

}


/** Prepare the elements of the plot object dpe (X and Y) arrays for external representation

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION
  
@param plotObjectDPE				input, array of DPEs
@return  dyn_string, cleaned input array
*/
dyn_string _fwTrending_cleanPlotObjectDPES(dyn_string plotObjectDPE)
{
  for(int i = 1; i <= dynlen(plotObjectDPE); i++)
  {
    plotObjectDPE[i] = fwTrending_cleanAliasRepresentation(plotObjectDPE[i]);
  }
  
  return plotObjectDPE;
}


/** Prepare the elements of the plot object dpe (X and Y) arrays for internal alias representation

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION
  
@param plotObjectDPE				input, array of DPEs
@return  dyn_string, prepared input array
*/
dyn_string _fwTrending_preparePlotObjectDPES(dyn_string plotObjectDPE)
{
  for(int i = 1; i <= dynlen(plotObjectDPE); i++)
  {
    if(fwTrending_isAlias(plotObjectDPE[i]))
    {
      plotObjectDPE[i] = fwTrending_createAliasRepresentation(plotObjectDPE[i]);
    }
  }
  
  return plotObjectDPE;
}


/** Add the "@" to the provided string so WinCC can process an alias

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION
  
@param sDp				input, datapoint string
@return  string, prepared input string
*/
string fwTrending_createAliasRepresentation(string sDp)
{
  string newRep;
  dyn_string dsDpElements;
  
  dsDpElements = strsplit(sDp, ":");
  
  if(dynlen(dsDpElements) >= 2)
  {
    newRep = dsDpElements[1] + ":@" + dsDpElements[2];
  }
  else
  {
    newRep = "@" + sDp;
  }

  return newRep;
}


/** Remove the "@" from the provided string to hide the alias prefix from the UI

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION
  
@param sDp				input, datapoint string
@return  string, cleaned input string
*/
string fwTrending_cleanAliasRepresentation(string sDp)
{
  string newRep;
  dyn_string dsDpElements;
  
  dsDpElements = strsplit(sDp, ":");
  
  if(dynlen(dsDpElements) >= 2)
  {
    newRep = dsDpElements[1] + ":" + strltrim(dsDpElements[2], "@");
  }
  else
  {
    newRep = strltrim(sDp, "@");
  }

  return newRep;
}


/** Close the progress bar opend as a child panel. This function is the same as the closeProgressBar from std.ctl.
The difference between this function and the closeProgressBar function is the dpSet of "_VarTrendOpen.PanelName:_original.._value"
where "ProgressBar" is replaced byt myModuleName()

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION
*/
_fwTrending_closeProgressBar() {
	string transferstring;
	dyn_string ds;

	ds[1] = "off";

	transferstring = ds;

	dpSet("_VarTrendOpen.UiNumber:_original.._value",myManNum(),
		"_VarTrendOpen.PanelName:_original.._value",/*"ProgressBar"*/ myModuleName(),
		"_VarTrendOpen.TrendData:_original.._value",transferstring);
	
	delay(0,100);
}


/** Change the time range of the trend which is currently being displayed.
The time range of the inactive trend is also updated.

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref							input, reference of the trend
@param range						input, the time range in seconds
@param refControl					input, reference of the trendControl
@param localTimeRangeObjValue		input, the value in string format of the current time
@param itemPos						input, position of the text in the cascade button that has to be modified
@param itemText						input, the text to set for the entry in the cascade button
*/
void fwTrending_changeTrendTimeRange(string ref, int range, string refControl, string localTimeRangeObjValue,
										int itemPos, string itemText) {
	string isRunning;
	time tb, te;
	int inter;
	string trendRunning;
	string activeTrend;
	shape activeTrendShape, standardTrendShape, logTrendShape, cascadeButton;
	dyn_string plotShapes, plotData, exceptionInfo, texts = makeDynString("10 minutes", "1 hour", "8 hours", "1 day", "10 days", "User Specified");
	int i, len;

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);
	
	if(plotData[fwTrending_PLOT_OBJECT_MODEL] == fwTrending_HISTOGRAM_PLOT_MODEL) {
		return;
	}

	standardTrendShape = getShape(plotShapes[fwTrending_LINEAR_TREND_NAME]);
	activeTrendShape = getShape(plotShapes[fwTrending_ACTIVE_TREND_NAME]);
	cascadeButton = getShape(refControl+"TimeCascadeButton");

	getValue(plotShapes[fwTrending_ACTIVE_TREND_NAME], "visibleTimeRange", 0, tb, te);
	inter = te - tb;
	tb = tb + inter / 2 - range / 2;

	setValue(refControl+"curvesTimeRange","text",localTimeRangeObjValue);

	plotData[fwTrending_PLOT_OBJECT_TIME_RANGE] = range;
	fwTrending_setRuntimePlotDataWithStrings(ref, isRunning, plotData, exceptionInfo, FALSE);

	len = dynlen(texts);
	for(i=1;i<=len;i++) {
		if((i-1) == itemPos) {
			cascadeButton.textItem(i-1, itemText);
		} else {
			cascadeButton.textItem(i-1, texts[i]);
		}
	}

	// get the state of the active trend
	if((isRunning == "FALSE") || (isRunning == FALSE)) {
		standardTrendShape.timeInterval(range);
	} else {
		/* added by Herve */
		standardTrendShape.timeInterval(range);

		_fwTrending_gotoNow(standardTrendShape, range);
		/*end */
	}
}

/** go to the current value of the trend.
Use different functions depending on the PVSS version.

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Internal

@par PVSS managers
	VISION

@param trendName	input, reference of the trend
@param range		input, the time range in seconds
*/
_fwTrending_gotoNow(shape trendName, int range) {
	//all this commented code is needed if the fwTrending must really work with PVSS 3.6

	//   string s_pvssVersion;
	//   dyn_string ds_patches;
	//   float f_version;
	//    s_pvssVersion = fwInstallation_getPvssVersion(ds_patches);
	//    f_version = s_pvssVersion;
	//    if(f_version<3.8)//PVSS earlier than 3.8 does not support the function gotoNow()
	//      trendName.timeBegin() = getCurrentTime() - range + (range/100);
	//    else
    trendName.gotoNow();
}


/** Zoom in or out on the X axis of the trend.

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref				input, reference of the trend
@param bZoomIn		input, TRUE to zoom in, FALSE to zoom out
*/
fwTrending_trendZoomX(string ref, bool bZoomIn) {
	string isRunning;
	dyn_string plotShapes, plotData, exceptionInfo;
	string activeTrend;
	shape activeTrendShape, standardTrendShape, logTrendShape;

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);
	
	if(plotData[fwTrending_PLOT_OBJECT_MODEL] == fwTrending_HISTOGRAM_PLOT_MODEL) {
		return;
	}

	activeTrendShape = getShape(plotShapes[fwTrending_ACTIVE_TREND_NAME]);
	standardTrendShape = getShape(plotShapes[fwTrending_LINEAR_TREND_NAME]);

	if(VERSION >= 3.5) {
	   bZoomIn = !bZoomIn;
    }
	
	if(bZoomIn) {
		standardTrendShape.trendTimePlus();
	} else {
		standardTrendShape.trendTimeMinus();
	}
	
	standardTrendShape.trendRefresh();
}


/** Zoom in or out on the Y axis of the trend.

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref			input, reference of the trend
@param bZoomIn		input, TRUE to zoom in, FALSE to zoom out
*/
fwTrending_trendZoomY(string ref, bool bZoomIn) {
	string isRunning;
	dyn_string plotShapes, plotData, exceptionInfo;
	string activeTrend;
	shape activeTrendShape, standardTrendShape, logTrendShape;

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);
	
	if(plotData[fwTrending_PLOT_OBJECT_MODEL] == fwTrending_HISTOGRAM_PLOT_MODEL) {
		return;
	}

	activeTrendShape = getShape(plotShapes[fwTrending_ACTIVE_TREND_NAME]);
	standardTrendShape = getShape(plotShapes[fwTrending_LINEAR_TREND_NAME]);

	if(VERSION >= 3.5) {
		bZoomIn = !bZoomIn;
	}

	if(bZoomIn) {
		standardTrendShape.trendValuePlus();
	} else {
		standardTrendShape.trendValueMinus();
	}
	
	standardTrendShape.trendRefresh();
}


/** Run or Freeze the trend.  The options in the trend controls are enabled/disable as appropriate

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref				input, reference of the trend
@param bRunTrend		input, TRUE to run, FALSE to freeze
@param refControl		input, reference of the trendControl
*/
fwTrending_trendRun(string ref, bool bRunTrend, string refControl) {
	string isRunning, trendCaption = "";
	dyn_string plotShapes, plotData, exceptionInfo;
	string activeTrend;
	shape activeTrendShape, standardTrendShape, logTrendShape, cascadeButton;
	
	trendCaption = _fwTrending_adjustRefName(ref);
	
	setValue(trendCaption + "trendCaption.currentTime.currentTime", "visible", bRunTrend);
	setValue(trendCaption + "trendCaption.curveTime", "visible", !bRunTrend);

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);
	if(plotData[fwTrending_PLOT_OBJECT_MODEL] == fwTrending_HISTOGRAM_PLOT_MODEL) {	
		ref = _fwTrending_adjustRefName(ref);
		
		if(bRunTrend) {
			setValue(ref +"trendRunningText", "text", "TRUE");
			setValue(refControl+"StopButton", "text", "Freeze");
		} else {
			setValue(ref +"trendRunningText", "text", "FALSE");
			setValue(refControl+"StopButton", "text", "Run");
		}
	}
}


/** Show or hide the grid of the trend

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref					input, reference of the trend
@param bShowGrid			input, TRUE to show grid, FALSE to hide grid
@param refControl			input, reference of the trendControl
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_gridOnOff(string ref, bool bShowGrid, string refControl, dyn_string &exceptionInfo) {
	string isRunning;
	dyn_string plotShapes, plotData;
	string activeTrend;
	shape activeTrendShape, standardTrendShape, logTrendShape, cascadeButton;

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);

	activeTrendShape = getShape(plotShapes[fwTrending_ACTIVE_TREND_NAME]);
	standardTrendShape = getShape(plotShapes[fwTrending_LINEAR_TREND_NAME]);
	cascadeButton = getShape(refControl+"OtherCascadeButton");

	if(bShowGrid) {
		plotData[fwTrending_PLOT_OBJECT_GRID] = "TRUE";
	} else {
		plotData[fwTrending_PLOT_OBJECT_GRID] = "FALSE";
	}
	
	if(plotData[fwTrending_PLOT_OBJECT_MODEL] == fwTrending_HISTOGRAM_PLOT_MODEL) {
		if(bShowGrid) {
			cascadeButton.textItem("5", "Grid  *");
		} else {
			cascadeButton.textItem("5", "Grid");
		}
		
		activeTrendShape.xGrid(bShowGrid);
		activeTrendShape.yGrid(bShowGrid);
		activeTrendShape.flush;
	} else {
		if(bShowGrid) {
			cascadeButton.textItem("6", "Grid  *");
		} else {
			cascadeButton.textItem("6", "Grid");
		}
		
		standardTrendShape.showGrid(bShowGrid);
	}
	
	fwTrending_setRuntimePlotDataWithStrings(ref, isRunning, plotData, exceptionInfo, FALSE);
}


/** Show or hide the markers of all the curves in the trend

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref				input, reference of the trend
@param markerType		input, type of markers:
						fwTrending_MARKER_TYPE_FILLED_CIRCLE
						fwTrending_MARKER_TYPE_UNFILLED_CIRCLE
						fwTrending_MARKER_TYPE_NONE
@param refControl		input, reference of the trendControl
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwTrending_markersOnOff(string ref, int markerType, string refControl, dyn_string &exceptionInfo) {
	string isRunning;
	dyn_string plotShapes, plotData;
	string activeTrend;
	shape activeTrendShape, standardTrendShape, logTrendShape, cascadeButton;
	int i, pvssMarkerType;

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);

	activeTrendShape = getShape(plotShapes[fwTrending_ACTIVE_TREND_NAME]);
	standardTrendShape = getShape(plotShapes[fwTrending_LINEAR_TREND_NAME]);
	cascadeButton = getShape(refControl+"OtherCascadeButton");
	
	switch(markerType) {
		case fwTrending_MARKER_TYPE_FILLED_CIRCLE:
			cascadeButton.textItem("markersFilled","Filled  *");
			cascadeButton.textItem("markersUnfilled","Unfilled");
			cascadeButton.textItem("markersNone","None");
			break;
		case fwTrending_MARKER_TYPE_UNFILLED_CIRCLE:
			cascadeButton.textItem("markersFilled","Filled");
			cascadeButton.textItem("markersUnfilled","Unfilled  *");
			cascadeButton.textItem("markersNone","None");
			break;
		case fwTrending_MARKER_TYPE_NONE:
			cascadeButton.textItem("markersFilled","Filled");
			cascadeButton.textItem("markersUnfilled","Unfilled");
			cascadeButton.textItem("markersNone","None  *");
			break;
		default:
			return;
			break;
	}

	plotData[fwTrending_PLOT_OBJECT_MARKER_TYPE] = markerType;
	_fwTrending_convertFrameworkToPvssMarkerType(markerType, pvssMarkerType, exceptionInfo);
	
	for(i=1 ; i<=fwTrending_MAX_NUM_CURVES ; i++) {
		activeTrendShape.pointType("curve_"+i, pvssMarkerType);
	}

	fwTrending_setRuntimePlotDataWithStrings(ref, isRunning, plotData, exceptionInfo, FALSE);
}




/** Show or hide the legend of the trend

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref					input, reference of the trend
@param bShowLegend			input, TRUE to show legend, FALSE to hide legend
@param refControl			input, reference of the trendControl
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_legendOnOff(string ref, bool bShowLegend, string refControl, dyn_string &exceptionInfo) {
	string isRunning;
	dyn_string plotShapes, plotData;
	string activeTrend;
	shape activeTrendShape, standardTrendShape, logTrendShape, cascadeButton;

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);

	activeTrendShape = getShape(plotShapes[fwTrending_ACTIVE_TREND_NAME]);
	standardTrendShape = getShape(plotShapes[fwTrending_LINEAR_TREND_NAME]);
	cascadeButton = getShape(refControl+"OtherCascadeButton");

	if(bShowLegend) {
		cascadeButton.textItem("4", "Legend  *");
	} else {
		cascadeButton.textItem("4", "Legend");
	}
	
	if(bShowLegend) {
		plotData[fwTrending_PLOT_OBJECT_LEGEND_ON] = "TRUE";
	} else {
		plotData[fwTrending_PLOT_OBJECT_LEGEND_ON] = "FALSE";
	}
	
	fwTrending_setRuntimePlotDataWithStrings(ref, isRunning, plotData, exceptionInfo, FALSE);

	if(plotData[fwTrending_PLOT_OBJECT_MODEL] == fwTrending_HISTOGRAM_PLOT_MODEL) {
		activeTrendShape.xArrayShow(bShowLegend);
		activeTrendShape.flush;
	} else {
        standardTrendShape.manageLegend(bShowLegend);
    }
}


/** Reset the zoom of the trend (1:1)

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref		input, reference of the trend
*/
fwTrending_trendUnzoom(string ref) {
	string isRunning;
	dyn_string plotShapes, plotData, exceptionInfo;
	string activeTrend;
	shape activeTrendShape, standardTrendShape, logTrendShape;

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);
	
	if(plotData[fwTrending_PLOT_OBJECT_MODEL] == fwTrending_HISTOGRAM_PLOT_MODEL) {
		return;
	}

	standardTrendShape = getShape(plotShapes[fwTrending_LINEAR_TREND_NAME]);
	standardTrendShape.trendUnzoom();
}


/** Zoom the trend area to the highest and lowest alarm limits by retaining a certain area visible above
  and below these limits for a better overview.

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref		input, reference of the trend
*/
fwTrending_trendZoomToAlarmLimits(string ref) {
  	string trendRunning, alertPanel, alertHelp, currentParameterValues;
 	dyn_string plotShapes, exceptionInfo, alertTexts, alertClasses, summaryDpeList, alertPanelParameters;
  	dyn_float alertLimits;
  	dyn_dyn_string plotData;
    dyn_dyn_float alertLimitsList;
	bool alertExists, isActive;
	int alertType;
    shape trendShape;

	getValue(ref + "trend.parameterValues", "text", currentParameterValues);
	fwTrending_getRuntimePlotDataWithExtendedObject(ref, trendRunning, plotShapes, plotData, exceptionInfo, FALSE);        	        	
	_fwTrending_preparePlotObjectForDisplay(plotData, currentParameterValues, exceptionInfo);  

	trendShape = getShape(plotShapes[fwTrending_ACTIVE_TREND_NAME]);

	int index = 1;
	for(int i = 1; i <= dynlen(plotData[fwTrending_PLOT_OBJECT_DPES]); i++) {
		  
		if(plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW][i]) {
			string curveDpeName = dpSubStr(plotData[fwTrending_PLOT_OBJECT_DPES][i], DPSUB_SYS_DP_EL);  
				
			if(dpExists(curveDpeName) ) {
				fwAlertConfig_get(curveDpeName, alertExists, alertType, alertTexts,
				alertLimits, alertClasses, summaryDpeList,
				alertPanel, alertPanelParameters, alertHelp,
				isActive, exceptionInfo);
			}  

			alertLimitsList[index] = alertLimits;
			index++;
					
			if(dynlen(alertLimitsList) > 0) {
				float limitMin=_fwTrending_getMin(alertLimitsList);
				float limitMax=_fwTrending_getMax(alertLimitsList);

				trendShape.curveMin("curve_" + i,limitMin-fabs((limitMax-limitMin)/5));
				trendShape.curveMax("curve_" + i,limitMax+fabs((limitMax-limitMin)/5));
			}   
		} 
	}	
}


float _fwTrending_getMin(dyn_dyn_float alertLimitsList) {
  	float minimum = dynMin(alertLimitsList[1]);
    
  	for(int i = 2; i <= dynlen(alertLimitsList); i++) {
      	if(dynMin(alertLimitsList[i]) < minimum) {
			minimum = dynMin(alertLimitsList[i]);        
        }    
    } 
    
    return minimum;
}


float _fwTrending_getMax(dyn_dyn_float alertLimitsList) {
  	float maximum = dynMax(alertLimitsList[1]);
    
  	for(int i = 2; i <= dynlen(alertLimitsList); i++) {
      	if(dynMax(alertLimitsList[i]) > maximum) {
			maximum = dynMax(alertLimitsList[i]);        
        }    
    } 
    
    return maximum;
}


/** Refreshes the data displayed by the trend

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref		input, reference of the trend
*/
fwTrending_trendRefresh(string ref) {
	string isRunning;
	dyn_string plotShapes, plotData, exceptionInfo;
	string activeTrend;
	shape activeTrendShape, standardTrendShape, logTrendShape;

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);
	
	if(plotData[fwTrending_PLOT_OBJECT_MODEL] == fwTrending_HISTOGRAM_PLOT_MODEL) {
		activeTrendShape = getShape(plotShapes[fwTrending_ACTIVE_TREND_NAME]);
		activeTrendShape.flush;
	} else {	
		standardTrendShape = getShape(plotShapes[fwTrending_LINEAR_TREND_NAME]);
		standardTrendShape.trendRefresh();
	}
}
					

/** Set the time begin of a trend back or forward from the current time begin

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref			input, reference of the trend
@param bTimeBack	input, true go back in time, false go forward in time
					back in time: newTimeBegin=currentTimeBegin-(period(currentTimeEnd)-period(currentTimeBegin))/fwTrending_TIME_BACK_RESOLUTION
					forward in time: newTimeBegin=currentTimeBegin+(period(currentTimeEnd)-period(currentTimeBegin))/fwTrending_TIME_FORWARD_RESOLUTION
					if newTYimeBegin > current time, no newTimeBegin is set.
*/
// TODO Bad name for method
fwTrending_trendTimeBack(string ref, bool bTimeBack) {
	string isRunning;
	dyn_string plotShapes, plotData, exceptionInfo;
	string activeTrend;
	shape activeTrendShape, standardTrendShape, logTrendShape;	
	time tBegin, tInterval, tEnd;
	string trend;

	fwTrending_getRuntimePlotDataWithStrings(ref, isRunning, plotShapes, plotData, exceptionInfo, FALSE);
	
	if(plotData[fwTrending_PLOT_OBJECT_MODEL] == fwTrending_HISTOGRAM_PLOT_MODEL) {
		return;
	}

	// get the reference of the standardtrend
	trend = plotShapes[fwTrending_LINEAR_TREND_NAME];

	getValue(trend, "visibleTimeRange", 0, tBegin, tEnd);
	getValue(trend, "timeInterval", tInterval);
	
	if(bTimeBack) {
		// go back in time
		// calculate the new period
		setPeriod(tBegin, period(tBegin) - ((period(tEnd) - period(tBegin))*fwTrending_TIME_BACK_RESOLUTION));
	} else {
		// go forward in time
		// calculate the new period
		setPeriod(tBegin, period(tBegin) + ((period(tEnd) - period(tBegin))*fwTrending_TIME_FORWARD_RESOLUTION));
	}

	// set the new time begin, if (new time begin + time interval) < current time
	if(period(tBegin+tInterval) < period(getCurrentTime())) {
		setValue(trend, "timeBegin", tBegin);
	}
}


/** Reads the current visible time range and picks a scale format (dates or times) that best suits the range.
Currently the switch between times and dates occurs around a time range of 2 days.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param trendName		input, the name of the trend widget to work on
@param exceptionInfo	input, details of any exceptions are returned here
*/
fwTrending_setTimeScaleFormat(string trendName, dyn_string &exceptionInfo) {
	int tries = 0, iStartTime = 0, iEndTime, iRange;
	string format;
	
	while((iStartTime == 0) && (tries < 100)) {
		getValue(trendName, "visibleTimeRange", 0, iStartTime, iEndTime);
		delay(0,100);
		tries++;
	}
	
	iRange = iEndTime - iStartTime;
	
	if(iRange>(60*60*24*2.1)) {
		format = "%x";
	} else {
		format = "%X";
	}

    setValue(trendName, "timeFormat", 0, FALSE, "%X", "%x");
}


/** Take the sDpName of the plot configuration and save the plot settings of a plot

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref				input, reference of the trend
*/
fwTrending_pageSavePlotSettings(string ref) {
	string sDpName;
	dyn_string exceptionInfo;

	getValue(ref+"trend.dpNameText", "text", sDpName);

	fwTrending_saveCurrentSettings(ref, sDpName, fwTrending_PLOT, FALSE, TRUE, exceptionInfo);
	
	if(dynlen(exceptionInfo)>0) {
		fwExceptionHandling_display(exceptionInfo);
	}
}


/** Save the current runtime plot configuration to a plot data point

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param ref							input, reference of the trend
@param sDpName						input, the data point name to save the plot configuration to
@param sDpType						input, the dp type of the data point to save the plot configuration to
@param createNewDpIfRequired		input, TRUE to create new dp if sDpName does not exist, else FALSE
@param overwriteExisting			input, TRUE to overwrite any existing contents of sDpName, else FALSE
@param exceptionInfo				output, details of any exceptions are returned here
@param useDpNameForTitle			input, Optional parameter - default FALSE
									FALSE - use plot title from currently displayed instance
									TRUE - change plot title of new plot to the same as sDpName
*/
fwTrending_saveCurrentSettings(string ref, string sDpName, string sDpType, bool createNewDpIfRequired,
								bool overwriteExisting, dyn_string &exceptionInfo, bool useDpNameForTitle = FALSE) {
	bool newDp = FALSE, fromDp;
	int i, length;
	dyn_dyn_string objectData;
	string isRunning, originalDpName;
	dyn_string plotShapes;

	if(sDpName == "") {
		fwException_raise(exceptionInfo, "ERROR", "The data point to save the configuration to was not specified.", "");
		return;
	}
	
	if(!dpExists(sDpName)) {
		if(createNewDpIfRequired) {
			if(sDpType == fwTrending_PLOT) {
				fwTrending_createPlot(sDpName, exceptionInfo);
			} else if(sDpType == fwTrending_PAGE) {
				fwTrending_createPage(sDpName, exceptionInfo);
			}
			
			newDp = TRUE;
			
			if(dynlen(exceptionInfo)>0) {
				return;
			}
		} else {
			fwException_raise(exceptionInfo, "ERROR", "The data point to save the configuration to does not exist.", "");
			return;
		}
	} else if(!overwriteExisting) {
		fwException_raise(exceptionInfo, "ERROR", "The data point to save the configuration to already exists.", "");
		return;
	}
	
	if(dpTypeName(sDpName) != sDpType) {
		fwException_raise(exceptionInfo, "ERROR", "The data point to save the configuration to is not a Plot data point.", "");
		return;
	}

	if(sDpType == fwTrending_PLOT) {
		fwTrending_getRuntimePlotDataWithExtendedObject(ref, isRunning, plotShapes, objectData, exceptionInfo, FALSE);
	
		//invert hidden/visible settings
		_fwTrending_switchCurvesHiddenVisible(objectData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], exceptionInfo);

		if(useDpNameForTitle) {
			objectData[fwTrending_PLOT_OBJECT_TITLE] = sDpName;
		}
		
		// save the settings
		fwTrending_setPlot(sDpName, objectData, exceptionInfo);

		getValue(ref+"trend.dpNameText", "text", originalDpName);
		
		if(originalDpName == "") {
			fromDp = FALSE;
		} else {
			fromDp = TRUE;
		}
	} else if(sDpType == fwTrending_PAGE) {
		fwTrending_getRuntimePageDataWithObject(objectData, exceptionInfo);
		
		if(useDpNameForTitle) {
			objectData[fwTrending_PAGE_OBJECT_TITLE] = sDpName;
		}
		
		fwTrending_setPage(sDpName, objectData, exceptionInfo);

		fromDp = TRUE;
	}
	
	if(sDpType == fwTrending_PLOT) {
		if(isFunctionDefined("unTrendTree_savePlotAs")) {
			unTrendTree_savePlotAs(sDpName, newDp, fromDp, exceptionInfo);
		}
	} else if(sDpType == fwTrending_PAGE) {
		if(isFunctionDefined("unTrendTree_savePageAs")) {
			unTrendTree_savePageAs(sDpName, newDp, fromDp, exceptionInfo);
		}
	}
}


/** Export the data displayed in all the plots of a page to a CSV file

@par Constraints
	Depends heavily on the standard trend window graphical objects.

@par Usage
	Public

@par PVSS managers
	VISION

@param dsRef					input, list of reference of the trends
@param templateParameters		input, any template parameter substitutions
*/
fwTrending_pageExportTrend(dyn_string dsRef, string templateParameters) {
	string fileStr, tempDpe;
	time tStart, tEnd;
	dyn_time dstStart, dstEnd, tempdstStart, tempdstEnd;
	bool fillGaps, noArch = false;
	int archive;
	int nbRef, countRef, i;
	string temp, activeTrend;
	dyn_string dsTemp, dsDpe, dsLegend, exceptionInfo, dsTempLegend;
	string isRunning;
	dyn_float df;
	dyn_string plotShapes, plotData, saveOptions, messageReturn;
	dyn_bool dbVisible;
	bool bOnlyVisibleCurves;

	nbRef = dynlen(dsRef);

	// select the file
	ChildPanelOnCentralReturn("fwTrending/fwTrendingExportFileSelector.pnl", "Export data to CSV", makeDynString(), df, saveOptions);
	
	if(saveOptions[1]=="cancel") {
		return;
	}
	
	bOnlyVisibleCurves = saveOptions[5];

	for(countRef = 1; countRef <= nbRef; countRef++) {
		fwTrending_getRuntimePlotDataWithStrings(dsRef[countRef], isRunning, plotShapes, plotData, exceptionInfo, FALSE);
		
		if(plotData[fwTrending_PLOT_OBJECT_MODEL] == fwTrending_HISTOGRAM_PLOT_MODEL) {
			continue;
		}

		_fwTrending_evaluateTemplate(templateParameters, plotData[fwTrending_PLOT_OBJECT_DPES], exceptionInfo);
		_fwTrending_evaluateTemplate(templateParameters, plotData[fwTrending_PLOT_OBJECT_LEGENDS], exceptionInfo);
		_fwTrending_evaluateTemplate(templateParameters, plotData[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS], exceptionInfo);

		fwTrending_convertUnicosDpeStringToPvssDpeString(plotData[fwTrending_PLOT_OBJECT_DPES],
														plotData[fwTrending_PLOT_OBJECT_DPES], exceptionInfo);

		activeTrend = plotShapes[fwTrending_ACTIVE_TREND_NAME];
		getValue(activeTrend, "visibleTimeRange", 0, tStart, tEnd);
			
		// get the list of DPE and check if they have an archive config
		temp = plotData[fwTrending_PLOT_OBJECT_DPES];
		fwTrending_convertStringToDyn(temp, dsTemp, exceptionInfo);
		fwTrending_convertStringToDyn(plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], dbVisible, exceptionInfo);

		for(i=1;i<=fwTrending_TRENDING_MAX_CURVE;i++) {
			// make the start and end time
			tempdstStart[i] = tStart;
			tempdstEnd[i] = tEnd;
			if(dsTemp[i] != "") {
				tempDpe = dpSubStr(dsTemp[i], DPSUB_SYS_DP_EL);
				if(tempDpe != "") {
					dpGet(tempDpe + ":_archive.._type", archive);	
					noArch = noArch || (archive == DPCONFIG_NONE ? true : false);
				}
			}
		}
		
		temp = plotData[fwTrending_PLOT_OBJECT_LEGENDS];
		fwTrending_convertStringToDyn(temp, dsTempLegend, exceptionInfo);
		
		for(i=1;i<=fwTrending_TRENDING_MAX_CURVE;i++) {
			if(dbVisible[i] || !bOnlyVisibleCurves) {
				dynAppend(dstStart, tempdstStart[i]);
				dynAppend(dstEnd, tempdstEnd[i]);
				dynAppend(dsDpe, dsTemp[i]);
				dynAppend(dsLegend, dsTempLegend[i]);
			}
		}
	}

	if(noArch) {
		ChildPanelOnCentralReturn("fwGeneral/fwOkCancel.pnl", "Export data to CSV",
									makeDynString("$text:Some of the data point elements do not have\n"
									+ "archiving configured. The data may not be\n"
									+ "exported correctly.  Do you wish to continue?"), df, messageReturn);
		if(messageReturn[1] != "ok") {
			return;
		}
	}

	// if no archive then raise an error
	if(saveOptions[1] == "ok") {
		if(strpos(saveOptions[2], ".csv") == (strlen(saveOptions[2]) - 4)) {
			saveOptions[2] = substr(saveOptions[2], 0, strlen(saveOptions[2]) - 4);
		}
		
		if((saveOptions == "") || isdir(saveOptions[2])) {
			fwException_raise(exceptionInfo, "ERROR", "You must specify a file name for the export data. Please enter a file name and try again.", "");
		} else {
			saveOptions[2] += ".csv";
	
			if(saveOptions[3] == "TRUE") {
				fillGaps = TRUE;
			} else {
				fillGaps = FALSE;
			}
				
			// added by Herve 10/09/2003
			_fwTrending_openProgressBar("Trend tool", "", "Exporting data to", saveOptions[2], "Please be patient!", 1);
			// end added by Herve 10/09/2003
			
			// export the data
			fwTrending_exportTrend(saveOptions[2], dsDpe, dsLegend, dstStart, dstEnd, templateParameters, exceptionInfo, fillGaps);		
			if(dynlen(exceptionInfo) == 0) {
				if(_WIN32 && (saveOptions[4] == "TRUE")) {
					strreplace(saveOptions[2], "/", "\\" );
					system("%COMSPEC% /c assoc .xls>nul 2>nul && start excel \"" + saveOptions[2] + "\"");
				}
			}
			
			// added by Herve 10/09/2003
			_fwTrending_closeProgressBar();
			// end added by Herve 10/09/2003
		}

		if(dynlen(exceptionInfo)>0) {
			fwExceptionHandling_display(exceptionInfo);
		}
	}
}


/** Export the history of the given dpes, between the given times to a CSV file

@par Constraints
	Can be slow if lots of data is returned and put in the file

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param fileName					input: file name to export the data to
@param dsCurveDPE				input, list of DPEs to export the data from
@param dsLegendCurve			input, list of associated legends to use a headers in the file
@param dtStart					input, start time for the query of the DPEs (one time per dpe)
@param dtEnd					input, end time for the query of the DPEs (one time per dpe)
@param templateParameters		input, any template parameter substitutions
@param exceptionInfo			output, details of any exceptions are returned here
@param fillEmptyCells			input, Optional parameter - default FALSE
								FALSE - just put data from history into file
								TRUE - apply 0th order interpolation to fill all cells in file (easier for automatic analysis)
*/
fwTrending_exportTrend(string fileName, dyn_string dsCurveDPE, dyn_string dsLegendCurve,
                       dyn_time dtStart, dyn_time dtEnd, string templateParameters,
                       dyn_string &exceptionInfo, bool fillEmptyCells = FALSE)
{
	file f;
	time firstTime, lastTime;
	dyn_string dpes, leg, fileDpe;
	int i, length;
	int width, j, count, lenDpe;

	dyn_time tStart, tEnd;
	dyn_time dt;
	dyn_float df;
	dyn_int de, di;	
	dyn_dyn_time ddt;
	dyn_dyn_float ddf;
	dyn_dyn_int dde;
	dyn_dyn_bool ddb;
	string tempDpe;

	//SMS template mechanism
	_fwTrending_evaluateTemplate(templateParameters, dsCurveDPE, exceptionInfo);
	_fwTrending_evaluateTemplate(templateParameters, dsLegendCurve, exceptionInfo);

	fwTrending_convertUnicosDpeListToPvssDpeList(dsCurveDPE, dsCurveDPE, exceptionInfo);

	if(dynlen(exceptionInfo)>0) {
		return;
	}

	i=1;
	lenDpe = dynlen(dsCurveDPE);
	for(count=1;count<=lenDpe; count++) {
		if(dsCurveDPE[count] != "") {
			dpes[i] = dsCurveDPE[count];
			leg[i] = dsLegendCurve[count];
			tStart[i] = dtStart[count];
			tEnd[i] = dtEnd[i];
			i++;
		}
	}
		
	firstTime = dynMin(tStart);
	lastTime = dynMax(tEnd);	
	
	width = dynlen(dpes);
	if(width == 0) {
		return;
	}

	// rebuild the DPE to UNICOS format if necessary	
	fwTrending_rebuildDpeUNICOS(dpes, fileDpe);
	
	for(i = 1; i <= width; i++) {
		tempDpe = dpSubStr(dpes[i], DPSUB_SYS_DP_EL);
		
		if(tempDpe != "") {
			dpGetPeriod(tStart[i], tEnd[i],  0, tempDpe + ":_offline.._value", df, dt, de);
			// in case there were no values in the timerange selected
			if(dynlen(df) == 0) {
				if(fillEmptyCells) {
					dpGetAsynch(firstTime, tempDpe + ":_offline.._value", ddf[i][1]);
					ddt[i][1] = firstTime - makeTime(0,0,0,0,0,0,1);
				} else {
					dpGet(tempDpe + ":_offline.._value", ddf[i][1],
								tempDpe + ":_offline.._stime", ddt[i][1]);
				}
			} else {
				ddt[i] = dt;
				ddf[i] = df;
				dde[i] = de;
			}
			di[i] = 1;
		} else {
			ddf[i][1] = 0.0;
			ddt[i][1] = 0;
			di[i] = 1;
		}
	}	
	
	f = fopen(fileName, "w");
	
	if(f == 0) {
        fwException_raise(exceptionInfo , "WARNING",
						"fwTrending: the file specified cannot be opened: "+fileName, "");
        return;
    }

	//create file header with list of dpes
	fputs(",", f);
	
	for(i = 1; i <= width; i++) {
		fputs(fileDpe[i] + ",", f);
	}
	
	fputs("\n,", f);
	
	for(i = 1; i <= width; i++) {
		fputs(leg[i] + ",", f);
	}
	
	fputs("\n", f);

	// sort events by time
	// dt will contain list of sorted time stamps
	// ddb will contain lists of bools that represent which dpes had a value at that time
	fwTrending_eventsSort(ddt, ddb, dt);

	//write data out to file in rows for each timestamp
	length = dynlen(dt);
	for(j = 1; j <= length; j++) {
		//write time and a comma
		string tim, date;
		tim = formatTime("%H:%M:%S", dt[j], ".%03d");
		date = formatTime("%Y/%m/%d", dt[j]);

		if(fillEmptyCells && (j != length)) {
			if((dt[j] < firstTime) || (dt[j] > lastTime)) {
				continue;
			}
		}

		fputs(date + " " + tim + ",", f);
		
		//check and write out values that have timestamp, dt[j]
		for(i = 1; i <= width; i++) {
			if(ddb[j][i]) {
				//write out data and increment counter for next value to read for each dpe
				fputs(ddf[i][di[i]++] + ",", f);
			} else {
				if(fillEmptyCells) {
					//implement filling of empty cells here
					if((di[i]-1) == 0) {
						fputs(ddf[i][1] + ",", f);
					} else {
						fputs(ddf[i][di[i]-1] + ",", f);
					}
				} else {
					fputs(",", f);
				}
			}
		}
		
		fputs("\n", f);	
	}
	
	fflush(f);
	fclose(f);
}


/** Sort the data of multiple dpGetPeriod calls.  Data is reorganised into order of time stamp.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param ddt			input, list of the time stamps from each dpGetPeriod call
@param events		output, a 2-dimensional giving a dyn_bool for each timestamp in 'times'.
					Each dyn_bool contains a list of bools, one for each dpGetPeriod to say if the dpGetPeriod returned
					data for that given timestamp and hence which dpe had a value at that timestamp.
@param times		output, a sorted list of the timestamps in ddt
*/
fwTrending_eventsSort(dyn_dyn_time ddt, dyn_dyn_bool & events, dyn_time & times) {
	dyn_time dtemp;
	dyn_bool emptyList;
	dyn_dyn_bool eventsList, temp;
	int i, width, length, numberOfDpes, numberOfTimeStamps;

	numberOfDpes = dynlen(ddt);
	length = dynlen(ddt[1]);
	
	if(numberOfDpes == 0) {
		return;
	}

	if(numberOfDpes == 1) {
		for(i = 1; i <= length; i++) {
			eventsList[i][1] = TRUE;
		}
		
		events = eventsList;
		times = ddt[1];
		
		return;
	}

	for(width = 1; width <= numberOfDpes; width++) {
		emptyList[width] = FALSE;
	}

	for(i = 1; i <= length; i++) {
		temp[i] = emptyList;
		temp[i][1] = TRUE;
	}
	
	dtemp = ddt[1];

	for(i = 2; i <= numberOfDpes; i++) {
		int j = 1; int k = 1; int l = 1;	
		numberOfTimeStamps = dynlen(dtemp);
		length = dynlen(ddt[i]);
		times = makeDynTime();
		
		while(j <= numberOfTimeStamps && k <= length) {
			while(j <= numberOfTimeStamps && k <= length && dtemp[j] < ddt[i][k]) {
				times[l] = dtemp[j];
				eventsList[l++] = temp[j++];
			}
			
			while(j <= numberOfTimeStamps && k <= length && dtemp[j] > ddt[i][k]) {
				times[l] = ddt[i][k];
				eventsList[l] = emptyList;
				eventsList[l++][i] = TRUE; k++;
			}
			
			while(j <= numberOfTimeStamps && k <= length && dtemp[j] == ddt[i][k]) {
				times[l] = dtemp[j];
				eventsList[l] = temp[j++];
				eventsList[l++][i] = TRUE;
				k++;
			}
		}
		
		// remainers (only one of two is executed each time)
		while(j <= numberOfTimeStamps) {
			times[l] = dtemp[j];
			eventsList[l++] = temp[j++];
		}
		
		while(k <= length) {
			times[l] = ddt[i][k];
			eventsList[l] = emptyList;
			eventsList[l++][i] = TRUE; k++;
		}

		temp = eventsList;
		dtemp = times;
	}

	events = eventsList;
}


/** Convert a string which is seperated by the fwTrending_CONTENT_DIVIDER into a dyn_string.
The resulting dyn_string will always have at least fwTrending_TRENDING_MAX_CURVE entries.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param valueString			input, string to be split
@param valueList			output, the dyn_string containing the parts of the original string
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_convertStringToDyn(string valueString, dyn_anytype &valueList, dyn_string &exceptionInfo) {
	if(valueString != "") {
		valueList = strsplit(valueString, fwTrending_CONTENT_DIVIDER);
		if(dynlen(valueList) < fwTrending_TRENDING_MAX_CURVE) {
			valueList[fwTrending_TRENDING_MAX_CURVE] = "";
		}
	} else {
		valueList = makeDynAnytype("","","","","","","","");
	}
}


/** Convert a dyn_string to a string which is seperated by the fwTrending_CONTENT_DIVIDER.
The resulting string will always have at least fwTrending_TRENDING_MAX_CURVE dividers.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param valueList			input, the dyn_string to be put into the string
@param valueString			output, the fwTrending_CONTENT_DIVIDER seperated string
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_convertDynToString(dyn_anytype valueList, string &valueString, dyn_string &exceptionInfo) {
	int i, length;
	
	valueString = "";
	length = dynlen(valueList);
	
	if(length == 1) {
		valueString = valueList[1];
		return;
	}
	
	for(i=1; i<=length; i++) {
		valueString += valueList[i] + fwTrending_CONTENT_DIVIDER;
	}

	for(i=length+1; i<=fwTrending_TRENDING_MAX_CURVE; i++) {
		valueString += fwTrending_CONTENT_DIVIDER;
	}
}


/** Find all the template parameters required to display a given plot or page.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param configurationData		input, the configuration data for the plot or page
@param configurationType		input, the type of configuration, either fwTrending_PLOT or fwTrending_PAGE
@param templateParameters		output, the list of required template parameters is returned here
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_getAllTemplateParametersForConfiguration(dyn_dyn_string configurationData, string configurationType,
                                                    dyn_string &templateParameters, dyn_string &exceptionInfo) {
	bool isConnected;
	int i, j, length, numberOfPlots, pos;
	string dpType;
	dyn_string newParameters, plotsOnPage;
	dyn_dyn_string plotData, parameters;

	templateParameters = makeDynString();

	if(configurationType == fwTrending_PAGE) {
		_fwTrending_findTemplateParameters(configurationData, templateParameters, exceptionInfo);
		numberOfPlots = dynlen(configurationData[fwTrending_PAGE_OBJECT_PLOTS]);
		
		for(i=1; i<=numberOfPlots; i++) {
			if(dpExists(configurationData[fwTrending_PAGE_OBJECT_PLOTS][i])) {
				_fwTrending_isSystemForDpeConnected(configurationData[fwTrending_PAGE_OBJECT_PLOTS][i], isConnected, exceptionInfo);
				
				if(isConnected) {
					fwTrending_getPlot(configurationData[fwTrending_PAGE_OBJECT_PLOTS][i], plotData, exceptionInfo);
					fwTrending_getAllTemplateParametersForConfiguration(plotData, fwTrending_PLOT, newParameters, exceptionInfo);
					
					if(dynlen(configurationData[fwTrending_PAGE_OBJECT_PLOT_TEMPLATE_PARAMETERS]) >= i) {
						_fwTrending_splitParameters(configurationData[fwTrending_PAGE_OBJECT_PLOT_TEMPLATE_PARAMETERS][i], parameters);
					} else {
						parameters[1] = makeDynString();
						parameters[2] = makeDynString();
					}
	
					length = dynlen(parameters[1]);
					for(j=1; j<=length; j++) {
						pos = dynContains(newParameters, parameters[1][j]);
						if(pos > 0) {
							dynRemove(newParameters, pos);
						}
					}
					
					dynAppend(templateParameters, newParameters);
				} else {
					fwException_raise(exceptionInfo, "ERROR", "A remote plot was unavailable to analyse for template parameters", "");
				}
			}
		}
	} else {
		dynClear(configurationData[fwTrending_PLOT_OBJECT_FORE_COLOR]);
		dynClear(configurationData[fwTrending_PLOT_OBJECT_BACK_COLOR]);
		dynClear(configurationData[fwTrending_PLOT_OBJECT_COLORS]);
				
		_fwTrending_findTemplateParameters(configurationData, newParameters, exceptionInfo);
		dynAppend(templateParameters, newParameters);
	}
	
	length = dynUnique(templateParameters);
	dynSortAsc(templateParameters);

	//workaround for CT307146/#70676 - problem with using dynIntersect() after dynSortAsc()
	for(i=1; i<=length; i++) {
		templateParameters[i] = templateParameters[i];
	}
	//end workaround for CT307146/#70676
}


/** Substitute the values of template parameters into a given list of string.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param givenParametersString	input, the string which contains the definitions of the template parameters
@param expressionList			input/output, the list of values that might need substitutions is passed
								and the version with the necessary substitutions is returned.
@param exceptionInfo			output, details of any exceptions are returned here
*/
_fwTrending_evaluateTemplate(string givenParametersString, dyn_string & expressionList, dyn_string & exceptionInfo) {
	int i, j, length, numberOfParams;
	string tempString, parameterString, parameterContent, expressionString;
	dyn_dyn_string givenParameters;
	dyn_string parametersNeeded, temp;

	_fwTrending_splitParameters(givenParametersString, givenParameters);

	length = dynlen(expressionList);
	for(i=1; i<=length; i++) {
		_fwTrending_findTemplateParameters(expressionList[i], temp, exceptionInfo);
		dynAppend(parametersNeeded, temp);
	}
	
	dynUnique(parametersNeeded);
	numberOfParams = dynlen(parametersNeeded);
	for(i=1; i<=numberOfParams; i++) {
		//evaluate only when the given parameters are passed
		if(givenParameters[1]!="parameterValues" && dynContains(givenParameters[1], parametersNeeded[i]) <= 0) {
			fwException_raise(exceptionInfo, "WARNING", "The parameter "+parametersNeeded[i]+" was not specified", "");
		}
	}

	numberOfParams = dynlen(givenParameters[1]);
	length = dynlen(expressionList);
	for(i=1; i<=length; i++) {
		for(j=1; j<=numberOfParams; j++) {
			strreplace(expressionList[i], fwTrending_TEMPLATE_OPEN + givenParameters[1][j] + fwTrending_TEMPLATE_CLOSE, givenParameters[2][j]);
		}
	}
}


/** Convert a list of PVSS style dpes to UNICOS style dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes			input, list of PVSS dpes
@param fileDpe		output, list of UNICOS format dpes
*/
fwTrending_rebuildDpeUNICOS(dyn_string dpes, dyn_string &fileDpe) {
	int i, len, pos;
	string deviceName, deviceSystemName, deviceAlias, tempDp;
	dyn_string split, exceptionInfo;
	
	fwTrending_convertPvssDpeListToUnicosDpeList(dpes, fileDpe, exceptionInfo);
}


/** Convert a fwTrending_CONTENT_DIVIDER seperated string of UNICOS style dpes
to a fwTrending_CONTENT_DIVIDER seperated string of PVSS style dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param unicosDpes			input, the fwTrending_CONTENT_DIVIDER seperated string of UNICOS dpes
@param pvssDpes				output, a fwTrending_CONTENT_DIVIDER seperated string of PVSS style dpes is returned here
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_convertUnicosDpeStringToPvssDpeString(string unicosDpes, string &pvssDpes, dyn_string &exceptionInfo) {
	int i, length;
	dyn_string split;
	
	if(isFunctionDefined("unGenericDpFunctions_convert_UNICOSDPE_to_PVSSDPE")) {
		fwTrending_convertStringToDyn(unicosDpes, split, exceptionInfo);
		fwTrending_convertUnicosDpeListToPvssDpeList(split, split, exceptionInfo);
		fwTrending_convertDynToString(split, pvssDpes, exceptionInfo);
	} else {
		pvssDpes = unicosDpes;
	}
}


/** Convert a list of PVSS style dpes to a list of UNICOS style dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param pvssDpes				input, a list of PVSS style dpes
@param unicosDpes			output, a list of UNICOS dpes is returned here
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_convertPvssDpeListToUnicosDpeList(dyn_string pvssDpes, dyn_string &unicosDpes, dyn_string &exceptionInfo) {
	int i, length;
	dyn_string split;
	
	if(isFunctionDefined("unGenericDpFunctions_convert_PVSSDPE_to_UNICOSDPE")) {
		length = dynlen(pvssDpes);
		for(i=1; i<=length; i++) {
			unGenericDpFunctions_convert_PVSSDPE_to_UNICOSDPE(pvssDpes[i], unicosDpes[i]);
		}
	} else {
		unicosDpes = pvssDpes;
	}
}


/** Convert a list of UNICOS style dpes to a list of PVSS style dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param unicosDpes			input, a list of UNICOS dpes
@param pvssDpes				output, a list of PVSS style dpes is returned here
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_convertUnicosDpeListToPvssDpeList(dyn_string unicosDpes, dyn_string &pvssDpes, dyn_string &exceptionInfo) {
	int i, length;
	dyn_string split;
	
	if(isFunctionDefined("unGenericDpFunctions_convert_UNICOSDPE_to_PVSSDPE")) {
		length = dynlen(unicosDpes);
		for(i=1; i<=length; i++) {
      if(fwTrending_isDpName(unicosDpes[i]))
      {
			  unGenericDpFunctions_convert_UNICOSDPE_to_PVSSDPE(unicosDpes[i], pvssDpes[i]);
      }
		}
	} else {
		pvssDpes = unicosDpes;
	}
}


/** Check a given curve name is a legal data point name.  Template parameter markers are allowed.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe					input, the dpe name to check
@param tempBool				output, TRUE if valid, else FALSE
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_checkCurveName(string dpe, bool & tempBool, dyn_string & exceptionInfo) {
	string tempString = dpe;
	
	tempBool = TRUE;
	
	// is template used at all?
	if(strpos(tempString, fwTrending_TEMPLATE_OPEN) > 0) {
		if(strpos(tempString, fwTrending_TEMPLATE_CLOSE) > 0) {
			strreplace(tempString, fwTrending_TEMPLATE_OPEN, "_");
			strreplace(tempString, fwTrending_TEMPLATE_CLOSE, "_");
		} else {
			fwException_raise(exceptionInfo, "ERROR", "The expression "+dpe+" cannot be evaluated", "");
			tempBool = FALSE;
		}
	}
	
	if(dpe != "") {
		if(tempBool) {
			tempBool = dpIsLegalName(tempString);
		}
	}
}


/** Split the template parameter definition string into a list of template parameter names and values

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param parameters			input, the list which contains the definitions of the template parameters
@param dsParameters			output, dsParameters[1] = list of names of parameters
							dsParameters[2] = list of values of parameters
*/
_fwTrending_splitParameters(string parameters, dyn_dyn_string & dsParameters) {
	dyn_string tempDyn1, tempDyn2;
	string tempString;
	int i;
	
	dynClear(dsParameters[1]);
	dynClear(dsParameters[2]);
	
	tempString = parameters;
	tempDyn1 = strsplit(parameters, ",");

	if(dynlen(tempDyn1) > 0) {
		for(i=1; i<=dynlen(tempDyn1); i++) {
			tempString = tempDyn1[i];
			tempDyn2 = strsplit(tempString, "=");
			if(dynlen(tempDyn2) == 2) {
				dynAppend(dsParameters[1], strltrim(strrtrim(tempDyn2[1], " "), " "));
				dynAppend(dsParameters[2], strltrim(strrtrim(tempDyn2[2], " "), " "));
			} else if(dynlen(tempDyn2) == 1) {
				dynAppend(dsParameters[1], strltrim(strrtrim(tempDyn2[1], " "), " "));
				dynAppend(dsParameters[2], "");
			}
		}
	}
}


/** Compare the template parameters required by the given configuration with the current defined template parameters

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param uniqueIdentifier				input, a unique identifier for this plot on the panel.  e.g. the reference name
@param configurationData			input, the configuration data for the plot or page
@param configurationType			input, the type of configuration, either fwTrending_PLOT or fwTrending_PAGE
@param currentParameters			input/output, the currently defined template parameters is passed here in string format
									the updated list is returned here when the function is finished
@param exceptionInfo				output, details of any exceptions are returned here
@param relativePosition				input, Optional parameter - default value = FALSE
									FALSE - show the dialog in the centre
									TRUE - show the dialog relative to the calling object
@param returnDefaultIfCancel		input, Optional parameter - default value = FALSE
									FALSE - if the user presses cancel, leave currentParameters as it was passed
									TRUE - if the user presses cancel, set each parameter to its default value (i.e. the name of the parameter)
*/
fwTrending_checkAndGetAllTemplateParameters(string uniqueIdentifier, dyn_dyn_string configurationData, string configurationType,
											string &currentParameters, dyn_string &exceptionInfo,
											bool relativePosition = FALSE, bool returnDefaultIfCancel = FALSE) {
	bool isOk;
	int i, type;
	dyn_float df;
	dyn_string ds, parameters;

	fwTrending_getAllTemplateParametersForConfiguration(configurationData, configurationType, parameters, exceptionInfo);
	
	if(dynlen(parameters) > 0) {
		fwTrending_checkAllTemplateParameters(parameters, currentParameters, isOk, exceptionInfo);
		
		if(!isOk) {
			if(relativePosition) {
				type = 8;
			} else {
				type = 10;
			}
			
			ChildPanelReturnValue("fwTrending/fwTrendingSetTemplateParameters.pnl",
									uniqueIdentifier + ": Undefined plot template parameters",
									myPanelName(), myModuleName(),
									makeDynString("$requiredParameters:" + parameters,
													"$templateParameters:" + currentParameters,
													"$mode:" + "set"),
									0, 0, df, ds, type);

			if(ds[1] == "ok") {
				if(strpos(currentParameters, fwTrending_TEMPLATE_DIVIDER) != (strlen(currentParameters) - 1))
					currentParameters += fwTrending_TEMPLATE_DIVIDER;

				currentParameters += ds[2];
			} else if(returnDefaultIfCancel) {
				currentParameters = "";
				
				for(i=1; i<=dynlen(parameters); i++) {
					currentParameters += parameters[i] + "=" + fwTrending_TEMPLATE_OPEN + parameters[i] + fwTrending_TEMPLATE_CLOSE + fwTrending_TEMPLATE_DIVIDER;
				}
			}
		}
	}
}


/** Allows for modification of the values of the template parameters.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param uniqueIdentifier				input, a unique identifier for this plot on the panel.  e.g. the reference name
@param configurationData			input, the configuration data for the plot or page
@param configurationType			input, the type of configuration, either fwTrending_PLOT or fwTrending_PAGE
@param currentParameters			input/output, the currently defined template parameters is passed here in string format
									the updated list is returned here when the function is finished
@param exceptionInfo				output, details of any exceptions are returned here
@param relativePosition				input, Optional parameter - default value = FALSE
									FALSE - show the dialog in the centre
									TRUE - show the dialog relative to the calling object
*/
fwTrending_modifyAllTemplateParameters(string uniqueIdentifier, dyn_dyn_string configurationData,
                                       string configurationType, string &currentParameters,
                                       dyn_string &exceptionInfo, bool relativePosition = FALSE) {
	bool isOk;
	int i, type;
	dyn_float df;
	dyn_string ds, parameters;

	fwTrending_getAllTemplateParametersForConfiguration(configurationData, configurationType, parameters, exceptionInfo);
	
	if(dynlen(parameters) > 0) {
		if(relativePosition) {
			type = 8;
		} else {
			type = 10;
		}

		ChildPanelReturnValue("fwTrending/fwTrendingSetTemplateParameters.pnl",
								uniqueIdentifier + ": Undefined plot template parameters",
								myPanelName(), myModuleName(),
									makeDynString("$requiredParameters:" + parameters,
													"$templateParameters:" + currentParameters,
													"$mode:" + "modify"),
								0, 0, df, ds, type);

		if(ds[1] == "ok") {
			currentParameters = ds[2];
		}
	}
}


/** Compare the list of the required template parameters with the contents of the $templateParameters

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param requiredParameters			input/output, the list of required template parameters
@param givenParameterString			input, the contents of $templateParameter in the standard string format
@param gotValuesForAll				output, the configuration data to find the parameters in
@param exceptionInfo				output, details of any exceptions are returned here
*/
fwTrending_checkAllTemplateParameters(dyn_string &requiredParameters, string givenParameterString,
										bool &gotValuesForAll, dyn_string &exceptionInfo) {
	int length, i, pos;
	string dpType;
	dyn_dyn_string givenParameters;

	_fwTrending_splitParameters(givenParameterString, givenParameters);
		
	length = dynlen(givenParameters[2]);
	for(i=1; i<=length; i++) {
		if((strpos(givenParameters[2][i], fwTrending_TEMPLATE_OPEN) == 0) &&
				(strpos(givenParameters[2][i], fwTrending_TEMPLATE_CLOSE) == (strlen(givenParameters[2][i]) - 1))) {		
			pos = dynContains(requiredParameters, givenParameters[1][i]);
			
			if(pos > 0) {
				requiredParameters[pos] = strltrim(strrtrim(givenParameters[2][i], fwTrending_TEMPLATE_CLOSE), fwTrending_TEMPLATE_OPEN);
				givenParameters[1][i] = "";
			}
		}
	}

	dynUnique(requiredParameters);
	dynUnique(givenParameters[1]);
	
	length = dynlen(requiredParameters);
	if(length == dynlen(dynIntersect(givenParameters[1], requiredParameters))) {
		gotValuesForAll = TRUE;
	} else {
		gotValuesForAll = FALSE;
	}
}


/** Merge two lists of template parameters into a single string.
If a value is specified in both lists, the value from the first list has precedence,
unless the value in the first list starts with { and ends with } (i.e. is an undefined template parameter)

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param firstList			input, one list of template parameters in string format
@param secondList			input, another list of template parameters in string format
@param returnedList			output, the merged list is returned here is string format
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_mergeParameterLists(string firstList, string secondList, string &returnedList, dyn_string &exceptionInfo) {
	int pos, i, length;
	dyn_dyn_string firstParameters, secondParameters, all;
	
	returnedList = "";
	
	_fwTrending_splitParameters(firstList, firstParameters);
	_fwTrending_splitParameters(secondList, secondParameters);
	
	length = dynlen(secondParameters[1]);
	for(i=1; i<=length; i++) {
		pos = dynContains(firstParameters[1], secondParameters[1][i]);
		if(pos <= 0) {
			dynAppend(firstParameters[1], secondParameters[1][i]);
			dynAppend(firstParameters[2], secondParameters[2][i]);
		} else if((strpos(firstParameters[2][pos], fwTrending_TEMPLATE_OPEN) == 0) &&
		 		(strpos(firstParameters[2][pos], fwTrending_TEMPLATE_CLOSE) == (strlen(firstParameters[2][pos]) - 1))) {
			firstParameters[2][pos] = secondParameters[2][i];
		}
	}
	
	length = dynlen(firstParameters[1]);
	for(i=1; i<=length; i++) {
		returnedList += firstParameters[1][i] + "=" + firstParameters[2][i] + fwTrending_TEMPLATE_DIVIDER;
	}
}


/** Find the template parameters required for a given plot or page configuration.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param data					input, the configuration data to find the parameters in
@param parametersFound		output, a list of all the template parameters which were found
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwTrending_findTemplateParameters(dyn_dyn_string data, dyn_string &parametersFound, dyn_string &exceptionInfo) {
	int position, i, j, k, length, width, possibleParams;
	dyn_string temp, parameter;
	
	dynClear(parametersFound);
	
	length = dynlen(data);
	for(i=1; i<=length; i++) {
		width = dynlen(data[i]);
		for(j=1; j<=width; j++) {
			temp = strsplit(data[i][j], fwTrending_TEMPLATE_OPEN);

			possibleParams = dynlen(temp);			
			for(k=2; k<=possibleParams; k++) {
				position = strpos(temp[k], fwTrending_TEMPLATE_CLOSE);

				if(position > 0) {
					parameter = strsplit(temp[k], fwTrending_TEMPLATE_CLOSE);
					dynAppend(parametersFound, parameter[1]);
				} else if (position == 0) {
					//no parameter name e.g. {}
					fwException_raise(exceptionInfo, "WARNING", "Invalid template parameter: name has zero length: " + data[i][j], "");
				} else {
					//no closing bracket
					fwException_raise(exceptionInfo, "WARNING", "Invalid template parameter: no closing bracket: " + data[i][j], "");
				}
			}
		}
	}
}


/** Set the runtime plot data with the given extended plot configuration.

@par Constraints
	Dependant on graphical objects of standard plot panel

@par Usage
	Public

@par PVSS managers
	VISION

@param refName					input, the reference name of the trend
@param isRunning				input, "TRUE" if the plot should be running, else "FALSE"
@param plotExtendedObject		input, the extended plot object to set as the runtime data (as defined by fwTrending_PLOT_OBJECT_... constants)
@param exceptionInfo			output, details of any exceptions are returned here
@param runningInsideTrend		input, Optional parameter - default TRUE
								TRUE if call is from within the same referecne as the trend, else FALSE
*/
fwTrending_setRuntimePlotDataWithExtendedObject(string refName, string isRunning, dyn_dyn_string plotExtendedObject,
												dyn_string &exceptionInfo, bool runningInsideTrend = TRUE) {
	dyn_string convertedValues;

	convertedValues[fwTrending_PLOT_OBJECT_EXT_MIN_FOR_LOG] = plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_MIN_FOR_LOG][1];
	convertedValues[fwTrending_PLOT_OBJECT_EXT_MAX_PERCENTAGE_FOR_LOG] = plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_MAX_PERCENTAGE_FOR_LOG][1];
	convertedValues[fwTrending_PLOT_OBJECT_TITLE] = plotExtendedObject[fwTrending_PLOT_OBJECT_TITLE][1];
	convertedValues[fwTrending_PLOT_OBJECT_MODEL] = plotExtendedObject[fwTrending_PLOT_OBJECT_MODEL][1];
					
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_DPES], convertedValues[fwTrending_PLOT_OBJECT_DPES], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_LEGENDS], convertedValues[fwTrending_PLOT_OBJECT_LEGENDS], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS], convertedValues[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_DPES_X], convertedValues[fwTrending_PLOT_OBJECT_DPES_X], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_LEGENDS_X], convertedValues[fwTrending_PLOT_OBJECT_LEGENDS_X], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS_X], convertedValues[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS_X], exceptionInfo);

	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_COLORS], convertedValues[fwTrending_PLOT_OBJECT_COLORS], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], convertedValues[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW], convertedValues[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE], convertedValues[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_UNITS], convertedValues[fwTrending_PLOT_OBJECT_EXT_UNITS], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_AXII], convertedValues[fwTrending_PLOT_OBJECT_AXII], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_POS], convertedValues[fwTrending_PLOT_OBJECT_AXII_POS], exceptionInfo);
 	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_LINK], convertedValues[fwTrending_PLOT_OBJECT_AXII_LINK], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE_X], convertedValues[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE_X], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_UNITS_X], convertedValues[fwTrending_PLOT_OBJECT_EXT_UNITS_X], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_X], convertedValues[fwTrending_PLOT_OBJECT_AXII_X], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_X_FORMAT], convertedValues[fwTrending_PLOT_OBJECT_AXII_X_FORMAT], exceptionInfo);					
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_CURVE_TYPES], convertedValues[fwTrending_PLOT_OBJECT_CURVE_TYPES], exceptionInfo);
 	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT], convertedValues[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT], exceptionInfo);
	fwTrending_convertDynToString(plotExtendedObject[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT], convertedValues[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT], exceptionInfo);					
	
	convertedValues[fwTrending_PLOT_OBJECT_TIME_RANGE] = plotExtendedObject[fwTrending_PLOT_OBJECT_TIME_RANGE][1];
	convertedValues[fwTrending_PLOT_OBJECT_TYPE] = plotExtendedObject[fwTrending_PLOT_OBJECT_TYPE][1];
	convertedValues[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC] = plotExtendedObject[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1];
	convertedValues[fwTrending_PLOT_OBJECT_BACK_COLOR] = plotExtendedObject[fwTrending_PLOT_OBJECT_BACK_COLOR][1];
	convertedValues[fwTrending_PLOT_OBJECT_FORE_COLOR] = plotExtendedObject[fwTrending_PLOT_OBJECT_FORE_COLOR][1];
							
	convertedValues[fwTrending_PLOT_OBJECT_LEGEND_ON] = plotExtendedObject[fwTrending_PLOT_OBJECT_LEGEND_ON][1];
	convertedValues[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON] = plotExtendedObject[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1];
	convertedValues[fwTrending_PLOT_OBJECT_GRID] = plotExtendedObject[fwTrending_PLOT_OBJECT_GRID][1];					
	convertedValues[fwTrending_PLOT_OBJECT_MARKER_TYPE] = plotExtendedObject[fwTrending_PLOT_OBJECT_MARKER_TYPE][1];					
	convertedValues[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE] = plotExtendedObject[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE][1];					
	convertedValues[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC] = plotExtendedObject[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1];					
	convertedValues[fwTrending_PLOT_OBJECT_DEFAULT_FONT] = plotExtendedObject[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1];					
	convertedValues[fwTrending_PLOT_OBJECT_CURVE_STYLE] = plotExtendedObject[fwTrending_PLOT_OBJECT_CURVE_STYLE][1];					

	fwTrending_setRuntimePlotDataWithStrings(refName, isRunning, convertedValues, exceptionInfo, runningInsideTrend);
}


/** Set the runtime plot data with the given plot configuration (in dyn_string format)

@par Constraints
	Dependant on graphical objects of standard plot panel

@par Usage
	Public

@par PVSS managers
	VISION

@param refName					input, the reference name of the trend
@param isRunning				input, "TRUE" if the plot should be running, else "FALSE"
@param plotData					input, the plot data to set as the runtime data (as defined by fwTrending_PLOT_OBJECT_... constants)
@param exceptionInfo			output, details of any exceptions are returned here
@param runningInsideTrend		input, Optional parameter - default TRUE
								TRUE if call is from within the same referecne as the trend, else FALSE
*/
fwTrending_setRuntimePlotDataWithStrings(string refName, string isRunning, dyn_string plotData,
										dyn_string &exceptionInfo, bool runningInsideTrend = TRUE) {
	bool isLog;
	int i, length;
	string activeTrend, objectAddress;
	dyn_string rangeValues, limits;

	if(runningInsideTrend) {
		objectAddress = "";
	} else {
		if(refName != "") {
			objectAddress = refName + "trend.";
		} else {
			objectAddress = "trend.";
		}
	}

	_fwTrending_syncDifferentRangeFormats(plotData[fwTrending_PLOT_OBJECT_RANGES_MIN],
						plotData[fwTrending_PLOT_OBJECT_RANGES_MAX],
						plotData[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE], exceptionInfo);

	_fwTrending_syncDifferentRangeFormats(plotData[fwTrending_PLOT_OBJECT_RANGES_MIN_X],
						plotData[fwTrending_PLOT_OBJECT_RANGES_MAX_X],
						plotData[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE_X], exceptionInfo);

	setValue(objectAddress + "standardTrendText", "text", refName + "trend.standardTrend");
	setValue(objectAddress + "trendRunningText", "text", "TRUE");
	setValue(objectAddress + "trendInfo", "items", plotData);
  
	if(plotData[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC] == "TRUE") {
		//start 20/05/2008: Herve		activeTrend = "trend.logTrend";
		activeTrend = "trend.standardTrend";
		//end 20/05/2008: Herve
	} else {
		activeTrend = "trend.standardTrend";
	}
		
	setValue(objectAddress + "activeTrendText", "text", refName + activeTrend);
	setValue(objectAddress + "trendRunningText", "text", isRunning);
}


/** Set the runtime page data with the given page configuration

@par Constraints
	Dependant on graphical objects of standard page panel

@par Usage
	Public

@par PVSS managers
	VISION

@param pageObject			input, the page object to set as the runtime data (as defined by fwTrending_PAGE_OBJECT_... constants)
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_setRuntimePageDataWithObject(dyn_dyn_string pageObject, dyn_string &exceptionInfo) {
	dyn_string convertedValues;

	convertedValues[fwTrending_PAGE_OBJECT_MODEL] = pageObject[fwTrending_PAGE_OBJECT_MODEL][1];
	convertedValues[fwTrending_PAGE_OBJECT_TITLE] = pageObject[fwTrending_PAGE_OBJECT_TITLE][1];
	convertedValues[fwTrending_PAGE_OBJECT_NCOLS] = pageObject[fwTrending_PAGE_OBJECT_NCOLS][1];
	convertedValues[fwTrending_PAGE_OBJECT_NROWS] = pageObject[fwTrending_PAGE_OBJECT_NROWS][1];
	convertedValues[fwTrending_PAGE_OBJECT_CONTROLS] = pageObject[fwTrending_PAGE_OBJECT_CONTROLS][1];
	convertedValues[fwTrending_PAGE_OBJECT_ACCESS_CONTROL_SAVE] = pageObject[fwTrending_PAGE_OBJECT_ACCESS_CONTROL_SAVE][1];
					
	fwTrending_convertDynToString(pageObject[fwTrending_PAGE_OBJECT_PLOT_TEMPLATE_PARAMETERS], convertedValues[fwTrending_PAGE_OBJECT_PLOT_TEMPLATE_PARAMETERS], exceptionInfo);
	fwTrending_convertDynToString(pageObject[fwTrending_PAGE_OBJECT_PLOTS], convertedValues[fwTrending_PAGE_OBJECT_PLOTS], exceptionInfo);

	fwTrending_setRuntimePageDataWithStrings(convertedValues, exceptionInfo);
}


/** Get the runtime page data

@par Constraints
	Dependant on graphical objects of standard page panel

@par Usage
	Public

@par PVSS managers
	VISION

@param pageObject		output, the runtime data is returned in this page object (as defined by fwTrending_PAGE_OBJECT_... constants)
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwTrending_getRuntimePageDataWithObject(dyn_dyn_string &pageObject, dyn_string &exceptionInfo) {
	int i;
	dyn_string pageData;

	pageObject[fwTrending_SIZE_PAGE_OBJECT] = makeDynString();

	fwTrending_getRuntimePageDataWithStrings(pageData, exceptionInfo);

	for(i=1; i<=fwTrending_SIZE_PAGE_OBJECT; i++) {
		fwTrending_convertStringToDyn(pageData[i], pageObject[i], exceptionInfo);
	}	
}


/** Set the runtime page data with the given page configuration (in dyn_string format)

@par Constraints
	Dependant on graphical objects of standard page panel

@par Usage
	Public

@par PVSS managers
	VISION

@param pageData			input, the page data to set as the runtime data (as defined by fwTrending_PAGE_OBJECT_... constants)
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwTrending_setRuntimePageDataWithStrings(dyn_string pageData, dyn_string &exceptionInfo) {
	setValue("pageInfo", "items", pageData);
}


/** Get the runtime page data

@par Constraints
	Dependant on graphical objects of standard page panel

@par Usage
	Public

@par PVSS managers
	VISION

@param pageData			output, the runtime data is returned here in dyn_string format (as defined by fwTrending_PAGE_OBJECT_... constants)
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwTrending_getRuntimePageDataWithStrings(dyn_string &pageData, dyn_string &exceptionInfo) {
	getValue("pageInfo", "items", pageData);
}


/** Get the runtime plot data

@par Constraints
	Dependant on graphical objects of standard plot panel

@par Usage
	Public

@par PVSS managers
	VISION

@param refName					input, the reference name of the trend
@param isRunning				output, "TRUE" if the plot is be running, else "FALSE"
@param plotShapes				output, the list of plot shapes is returned here - standard, log and active
@param plotData					output, the plot data is returned here (in dyn_string format) (as defined by fwTrending_PLOT_OBJECT_... constants)
@param exceptionInfo			output, details of any exceptions are returned here
@param runningInsideTrend		input, Optional parameter - default TRUE
								TRUE if call is from within the same referecne as the trend, else FALSE
*/
fwTrending_getRuntimePlotDataWithStrings(string refName, string &isRunning, dyn_string &plotShapes,
									dyn_string &plotData, dyn_string &exceptionInfo, bool runningInsideTrend = TRUE) {
	bool isLog;
	string activeTrend, objectAddress;

	if(runningInsideTrend) {
		objectAddress = "";
	} else {
		if(refName != "") {
			objectAddress = refName + "trend.";
		} else {
			objectAddress = "trend.";
		}
	}

	getValue(objectAddress + "trendInfo", "items", plotData);
		
	if(dynlen(plotData) < fwTrending_SIZE_PLOT_OBJECT) {
		plotData[fwTrending_SIZE_PLOT_OBJECT] = "";
	}
	
	getValue(objectAddress + "standardTrendText", "text", plotShapes[fwTrending_LINEAR_TREND_NAME]);
	getValue(objectAddress + "activeTrendText", "text", plotShapes[fwTrending_ACTIVE_TREND_NAME]);
	getValue(objectAddress + "trendRunningText", "text", isRunning);
}


/** Get the runtime plot data

@par Constraints
	Dependant on graphical objects of standard plot panel

@par Usage
	Public

@par PVSS managers
	VISION

@param refName					input, the reference name of the trend
@param isRunning				output, "TRUE" if the plot is be running, else "FALSE"
@param plotShapes				output, the list of plot shapes is returned here - standard, log and active
@param plotExtendedObject		output, the plot object is returned here (as defined by fwTrending_PLOT_OBJECT_... constants)
@param exceptionInfo			output, details of any exceptions are returned here
@param runningInsideTrend		input, Optional parameter - default TRUE
								TRUE if call is from within the same referecne as the trend, else FALSE
*/
fwTrending_getRuntimePlotDataWithExtendedObject(string refName, string &isRunning, dyn_string &plotShapes,
												dyn_dyn_string &plotExtendedObject,
												dyn_string &exceptionInfo,
												bool runningInsideTrend = TRUE) {
	int i;
	dyn_string split, plotData;
	
	plotExtendedObject[fwTrending_SIZE_PLOT_OBJECT] = makeDynString();

	fwTrending_getRuntimePlotDataWithStrings(refName, isRunning, plotShapes, plotData, exceptionInfo, runningInsideTrend);

	for(i=1; i<=fwTrending_SIZE_PLOT_OBJECT; i++) {
		fwTrending_convertStringToDyn(plotData[i], plotExtendedObject[i], exceptionInfo);
	}	

 	for(i=1; i<=fwTrending_TRENDING_MAX_CURVE; i++) {
	 	split = strsplit(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE][i] , ":");
	 	if(dynlen(split) == 2) {
			plotExtendedObject[fwTrending_PLOT_OBJECT_RANGES_MIN][i] = split[1];
			plotExtendedObject[fwTrending_PLOT_OBJECT_RANGES_MAX][i] = split[2];
 		} else {
			plotExtendedObject[fwTrending_PLOT_OBJECT_RANGES_MIN][i] = "";
			plotExtendedObject[fwTrending_PLOT_OBJECT_RANGES_MAX][i] = "";
 		}

 		split = strsplit(plotExtendedObject[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE_X][i] , ":");
 		if(dynlen(split) == 2) {
			plotExtendedObject[fwTrending_PLOT_OBJECT_RANGES_MIN_X][i] = split[1];
			plotExtendedObject[fwTrending_PLOT_OBJECT_RANGES_MAX_X][i] = split[2];
  		} else {
			plotExtendedObject[fwTrending_PLOT_OBJECT_RANGES_MIN_X][i] = "";
			plotExtendedObject[fwTrending_PLOT_OBJECT_RANGES_MAX_X][i] = "";
 		}
 	}
}


/** The min max range is stored in two ways in the plot object for legacy reasons.
One way is with the min and max ranges stored in two different places, the second is with both min and max ranges combined together.
This function ensures that the data is consistent between the two places.
By passing fwTrending_CONTENT_DIVIDER seperated lists of the minranges, maxranges and combined min:maxranges
the function makes them consistent.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param minRange				input, fwTrending_CONTENT_DIVIDER seperated list of min ranges
@param maxRange				input, fwTrending_CONTENT_DIVIDER seperated list of max ranges
@param combinedRange		input, fwTrending_CONTENT_DIVIDER seperated list of combined min/max ranges
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwTrending_syncDifferentRangeFormats(string &minRange, string &maxRange,
										string &combinedRange, dyn_string &exceptionInfo) {
	int i, length;
	dyn_string dsMinRange, dsMaxRange, dsCombinedRange, rangeParts;

	fwTrending_convertStringToDyn(minRange, dsMinRange, exceptionInfo);
	fwTrending_convertStringToDyn(maxRange, dsMaxRange, exceptionInfo);
	fwTrending_convertStringToDyn(combinedRange, dsCombinedRange, exceptionInfo);

	if(dynlen(dsMinRange) != dynlen(dsMinRange)) {
		fwException_raise(exceptionInfo, "ERROR", "The given min and max ranges are invalid", "");
		return;
	}

	if((dynlen(dsCombinedRange) < dynlen(dsMinRange)) || (dsCombinedRange[1] == "")) {
		//copy data to combined range
		for(i=1; i<=dynlen(dsMinRange); i++) {
			if((dsMinRange[i] == "") || (dsMaxRange[i] == "")) {
				dsMinRange[i] = "0";
				dsMaxRange[i] = "0";
				dsCombinedRange[i] = "0" + fwTrending_AXIS_LIMITS_DIVIDER + "0";		
			} else {
				dsCombinedRange[i] = dsMinRange[i] + fwTrending_AXIS_LIMITS_DIVIDER + dsMaxRange[i] + fwTrending_CONTENT_DIVIDER;
			}
		}
	} else if((dynlen(dsMinRange) < dynlen(dsCombinedRange)) || (dsMinRange[1] == "")) {
		//copy data to individual ranges
		for(i=1; i<=dynlen(dsCombinedRange); i++) {
			if(dsCombinedRange[i] == "") {
				dsMinRange[i] = "0";
				dsMaxRange[i] = "0";
				dsCombinedRange[i] = "0" + fwTrending_AXIS_LIMITS_DIVIDER + "0";		
			} else {
				rangeParts = strsplit(dsCombinedRange[i], fwTrending_AXIS_LIMITS_DIVIDER);
				dsMinRange[i] = rangeParts[1];
				dsMaxRange[i] = rangeParts[2];
			}
		}
	}

	fwTrending_convertDynToString(dsMinRange, minRange, exceptionInfo);
	fwTrending_convertDynToString(dsMaxRange, maxRange, exceptionInfo);
	fwTrending_convertDynToString(dsCombinedRange, combinedRange, exceptionInfo);	
}


/** In some situations, curve visibility is used and in some curve hidden state is given.  These are logical opposites.
This function swtiches between the two by inverting all the entries in the given list.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param currentCurveStatus		input/output, the list of values is passed here and is returned inverted
@param exceptionInfo			output, details of any exceptions are returned here
*/
_fwTrending_switchCurvesHiddenVisible(dyn_string &currentCurveStatus, dyn_string &exceptionInfo) {
	int i, length;
	
	length = dynlen(currentCurveStatus);
	for(i=1; i<=length; i++) {
		if(currentCurveStatus[i] == "TRUE") {
			currentCurveStatus[i] = "FALSE";
		} else {
			currentCurveStatus[i] = "TRUE";
		}
	}
	
	for(i=length+1; i<=fwTrending_TRENDING_MAX_CURVE; i++) {
		currentCurveStatus[i] = "FALSE";
	}
}


/** Gets the number of curves that are defined in a plot configuration data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the name of the plot configuration data point
@param numberOfCurves			output, the number of defined curves in the configuration is returned here
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_getNumberOfCurves(string plotDp, int &numberOfCurves, dyn_string &exceptionInfo) {
	int numberOfEntries, numberOfBlanks;
	dyn_dyn_string plotData;

	fwTrending_getPlot(plotDp, plotData, exceptionInfo);

	numberOfEntries = dynlen(plotData[fwTrending_PLOT_OBJECT_DPES]);
	numberOfBlanks = dynlen(dynPatternMatch("", plotData[fwTrending_PLOT_OBJECT_DPES]));
	
	numberOfCurves = numberOfEntries - numberOfBlanks;
}


/** Gets the position of the first undefined curve in a plot configuration data point.
If there are no free curves, the position -1 is returned.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the name of the plot configuration data point
@param position					output, the position of first undefined curve in the configuration is returned here
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_getFirstFreeCurve(string plotDp, int &position, dyn_string &exceptionInfo) {
	dyn_int freePositions;

	fwTrending_getFreeCurves(plotDp, freePositions, exceptionInfo);
	
	if(dynlen(freePositions)<=0) {
		position = -1;
	} else {
		position = freePositions[1];
	}
}


/** Gets a list of the positions of undefined curves in a plot configuration data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the name of the plot configuration data point
@param positions				output, a list of the positions of undefined curve in the configuration is returned here
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_getFreeCurves(string plotDp, dyn_int &positions, dyn_string &exceptionInfo) {
	int i, length;
	dyn_dyn_string plotData;

	dynClear(positions);
	fwTrending_getPlot(plotDp, plotData, exceptionInfo);

	length = dynlen(plotData[fwTrending_PLOT_OBJECT_DPES]);
	for(i=1; (i<=length) && (i<=fwTrending_MAX_NUM_CURVES); i++) {
		if(plotData[fwTrending_PLOT_OBJECT_DPES][i] == "") {
			dynAppend(positions, i);
		}
	}
	
	for(i=(length+1); i<=fwTrending_MAX_NUM_CURVES; i++) {
		dynAppend(positions, i);
	}
}


/** Sets a given curve configuration to a certain curve position of a plot configuration data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the name of the plot configuration data point
@param curveData				input, a curve data object (as defined by fwTrending_CURVE_OBJECT_... constants)
@param curveToSet				input, the position in which to set this curve
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_setCurve(string plotDp, dyn_string curveData, int curveToSet, dyn_string &exceptionInfo) {
	dyn_dyn_string curvesData;
	
	curvesData[1] = curveData;
	fwTrending_setManyCurves(plotDp, curvesData, makeDynInt(curveToSet), exceptionInfo);
}


/** Sets many curve configurations to certain curve positions of a plot configuration data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the name of the plot configuration data point
@param curvesData				input, a list of curve data objects (as defined by fwTrending_CURVE_OBJECT_... constants)
@param curvesToSet				input, the positions in which to set these curves
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_setManyCurves(string plotDp, dyn_dyn_string curvesData, dyn_int curvesToSet, dyn_string &exceptionInfo) {
	int i, length, j, objectSize;
	dyn_string curveObjectIndexes, plotObjectIndexes;
	dyn_dyn_string plotData;

	if(dynMax(curvesToSet) > fwTrending_MAX_NUM_CURVES) {
		fwException_raise(exceptionInfo, "ERROR", "Curve number " + dynMax(curvesToSet) + " is outside the range of valid curve numbers", "");
		return;
	}

	fwTrending_getPlot(plotDp, plotData, exceptionInfo);
	
	length = dynlen(curvesData);
	for(i=1; i<=length; i++) {
		_fwTrending_checkCurveData(curvesData[i], curvesToSet[i], exceptionInfo);
		if(dynlen(exceptionInfo)>0) {
			return;
		}
		
		objectSize = _fwTrending_getCurveObjectIndexes(curveObjectIndexes, plotObjectIndexes, exceptionInfo);
		for(j=1; j<=objectSize; j++) {
			plotData[plotObjectIndexes[j]][curvesToSet[i]] = curvesData[i][curveObjectIndexes[j]];
		}
	}
	
	fwTrending_setPlot(plotDp, plotData, exceptionInfo);
}


/** Get the curve configuration from a specified curve position of a plot configuration data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the name of the plot configuration data point
@param isCurveDefined			output, TRUE is curve is defined, else FALSE
@param curveData				output, the curve data configuration object is returned here (as defined by fwTrending_CURVE_OBJECT_... constants)
@param curveToGet				input, the position of the curve to get
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_getCurve(string plotDp, bool &isCurveDefined, dyn_string &curveData,
					int curveToGet, dyn_string &exceptionInfo) {
	int i, objectSize;
	dyn_string curveObjectIndexes, plotObjectIndexes;
	dyn_dyn_string plotData;

	if(curveToGet > fwTrending_MAX_NUM_CURVES) {
		fwException_raise(exceptionInfo, "ERROR", "Curve number " + curveToGet + " is outside the range of valid curve numbers", "");
		return;
	}

	fwTrending_getPlot(plotDp, plotData, exceptionInfo);
	
	isCurveDefined = FALSE;
	objectSize = _fwTrending_getCurveObjectIndexes(curveObjectIndexes, plotObjectIndexes, exceptionInfo);
	for(i=1; i<=objectSize; i++) {
		curveData[curveObjectIndexes[i]] = "";
	}

	if(dynlen(plotData[fwTrending_PLOT_OBJECT_DPES]) >= curveToGet) {
		if(plotData[fwTrending_PLOT_OBJECT_DPES][curveToGet] != "") {
			isCurveDefined = TRUE;
			for(i=1; i<=objectSize; i++) {
				curveData[curveObjectIndexes[i]] = plotData[plotObjectIndexes[i]][curveToGet];
			}
		}
	}
}


/** Appends a curve configuration to the first undefined curve position of a plot configuration data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the name of the plot configuration data point
@param curveData				input, a curve data object (as defined by fwTrending_CURVE_OBJECT_... constants)
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_appendCurve(string plotDp, dyn_string curveData, dyn_string &exceptionInfo) {
	dyn_dyn_string curvesData;

	curvesData[1] = curveData;
	fwTrending_appendManyCurves(plotDp, curvesData, exceptionInfo);
}


/** Appneds many curve configurations to the first undefined curve positions of a plot configuration data point

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the name of the plot configuration data point
@param curvesData				input, a list of curve data objects (as defined by fwTrending_CURVE_OBJECT_... constants)
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_appendManyCurves(string plotDp, dyn_dyn_string curvesData, dyn_string &exceptionInfo) {
	dyn_int positions;
	int numberOfCurves, i, length;

	fwTrending_getFreeCurves(plotDp, positions, exceptionInfo);
	if(dynlen(curvesData) > dynlen(positions)) {
		fwException_raise(exceptionInfo, "ERROR", "There are not enough free curves available", "");
		return;
	}
	
	fwTrending_setManyCurves(plotDp, curvesData, positions, exceptionInfo);
}


/** Inserts a given curve configuration to a certain curve position of a plot configuration data point.
The previous curve from that position and curves from later positions are moved one position along to provide space
for the new curve. Similar in concept to dynInsertAt().

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp				input, the name of the plot configuration data point
@param curveData			input, a curve data object (as defined by fwTrending_CURVE_OBJECT_... constants)
@param position				input, the position in which to insert this curve
@param exceptionInfo		output, details of any exceptions are returned here
@param forceInsert			OPTIONAL PARAMETER - default value FALSE
							If TRUE, if the 8th curve is in use, it will be lost when the new curve is inserted
							If FALSE, if the 8th curve is in use, an exception will be raised and no curve inserted
*/
fwTrending_insertCurveAt(string plotDp, dyn_string curveData, int position, dyn_string &exceptionInfo,
						bool forceInsert = FALSE) {
	int i, length, objectSize;
	dyn_int positions, curveObjectIndexes, plotObjectIndexes;
	dyn_dyn_string plotData;

	if(!forceInsert) {
		fwTrending_getFreeCurves(plotDp, positions, exceptionInfo);
		if(dynMax(positions) != fwTrending_MAX_NUM_CURVES) {
			fwException_raise(exceptionInfo, "ERROR", "Insertion of curve failed. " +
			+ "There is a curve in the final curve position, so inserting a new curve would cause the existing curve to be lost.", "");
			return;
		}
	}
	
	fwTrending_getPlot(plotDp, plotData, exceptionInfo);
	
	_fwTrending_checkCurveData(curveData, position, exceptionInfo);
	if(dynlen(exceptionInfo)>0) {
		return;
	}
	
	objectSize = _fwTrending_getCurveObjectIndexes(curveObjectIndexes, plotObjectIndexes, exceptionInfo);
	for(i=1; i<=objectSize; i++) {
		length = dynInsertAt(plotData[plotObjectIndexes[i]], curveData[curveObjectIndexes[i]], position);
		while(length > fwTrending_MAX_NUM_CURVES) {
			dynRemove(plotData[plotObjectIndexes[i]], length);
			length = dynlen(plotData[plotObjectIndexes[i]]);
		}
	}
	
	fwTrending_setPlot(plotDp, plotData, exceptionInfo);
}


/** Delete a curve configuration from the specified curve position of a plot configuration data point.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the name of the plot configuration data point
@param curveToDelete			input, the position of the curve to delete
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_deleteCurve(string plotDp, int curveToDelete, dyn_string &exceptionInfo) {
	fwTrending_deleteManyCurves(plotDp, makeDynInt(curveToDelete), exceptionInfo);
}


/** Delete many curve configurations from the specified curve positions of a plot configuration data point.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the name of the plot configuration data point
@param curvesToDelete			input, the positions of the curves to delete
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_deleteManyCurves(string plotDp, dyn_int curvesToDelete, dyn_string &exceptionInfo) {
	int i, length, objectSize;
	dyn_string curveData, curveObjectIndexes, plotObjectIndexes;
	dyn_dyn_string curvesData;

	if(dynMax(curvesToDelete) > fwTrending_MAX_NUM_CURVES) {
		fwException_raise(exceptionInfo, "ERROR", "Curve number " + dynMax(curvesToDelete) + " is outside the range of valid curve numbers", "");
		return;
	}

	objectSize = _fwTrending_getCurveObjectIndexes(curveObjectIndexes, plotObjectIndexes, exceptionInfo);
	for(i=1; i<=objectSize; i++) {
		curveData[curveObjectIndexes[i]] = "";
	}

	length = dynlen(curvesToDelete);
	for(i=1; i<=length; i++) {
		curvesData[i] = curveData;
	}

	fwTrending_setManyCurves(plotDp, curvesData, curvesToDelete, exceptionInfo);
}


/** Remove a curve configuration from the specified curve position of a plot configuration data point.
The curves from later positions are moved one position back to remove the space left by the removal of the curve.
Similar in concept to dynRemove().

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param plotDp					input, the name of the plot configuration data point
@param curveToRemove			input, the position of the curve to remove
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwTrending_removeCurve(string plotDp, int curveToRemove, dyn_string &exceptionInfo) {
	int numberOfCurves, i, objectSize;
	dyn_string curveObjectIndexes, plotObjectIndexes;
	dyn_dyn_string plotData;

	fwTrending_getNumberOfCurves(plotDp, numberOfCurves, exceptionInfo);
	if(numberOfCurves < curveToRemove) {
		fwException_raise(exceptionInfo, "ERROR", "Curve number " + curveToRemove + " does not exist in the plot", "");
		return;
	}
	
	fwTrending_getPlot(plotDp, plotData, exceptionInfo);

	objectSize = _fwTrending_getCurveObjectIndexes(curveObjectIndexes, plotObjectIndexes, exceptionInfo);
	for(i=1; i<=objectSize; i++) {
		dynRemove(plotData[plotObjectIndexes[i]], curveToRemove);
	}
	
	fwTrending_setPlot(plotDp, plotData, exceptionInfo);
}


/** Checks curve object and fills in any missing values with default data.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param curveData				input/output, the curve object to check
@param position					input, the intended position of the curve (used for making default data e.g. curve colour)
@param exceptionInfo			output, details of any exceptions are returned here
*/
_fwTrending_checkCurveData(dyn_string &curveData, int position, dyn_string &exceptionInfo) {
	int i, length;
	string legend, sTempDpe;
	dyn_string defaultCurve;
	
	if(curveData[fwTrending_CURVE_OBJECT_DPE] == "") {
		return;
	}
	
	defaultCurve[fwTrending_CURVE_OBJECT_DPE] = "";
	defaultCurve[fwTrending_CURVE_OBJECT_TYPE] = fwTrending_PLOT_TYPE_STEPS;
	defaultCurve[fwTrending_CURVE_OBJECT_COLOR] = "FwTrendingCurve" + position;
	defaultCurve[fwTrending_CURVE_OBJECT_LEGEND] = "";
	defaultCurve[fwTrending_CURVE_OBJECT_AXIS] = "TRUE";
	defaultCurve[fwTrending_CURVE_OBJECT_HIDDEN] = "FALSE";
	defaultCurve[fwTrending_CURVE_OBJECT_Y_MIN] = "0";
	defaultCurve[fwTrending_CURVE_OBJECT_Y_MAX] = "0";

	length = dynlen(curveData);
	for(i=1; i<=length; i++) {
		if(curveData[i] != "") {
			defaultCurve[i] = curveData[i];
		}
	}
	
	sTempDpe = curveData[fwTrending_CURVE_OBJECT_DPE];
	if(isFunctionDefined("unGenericDpFunctions_convert_UNICOSDPE_to_PVSSDPE")) {
    if(fwTrending_isDpName(curveData[fwTrending_CURVE_OBJECT_DPE]))
    {
  		unGenericDpFunctions_convert_UNICOSDPE_to_PVSSDPE(curveData[fwTrending_CURVE_OBJECT_DPE], sTempDpe);
    }
	}
	
	if(!dpExists(sTempDpe)) {
		fwException_raise(exceptionInfo, "ERROR", "Curve data point element does not exist.", "");
	} else {
		if(defaultCurve[fwTrending_CURVE_OBJECT_LEGEND] == "") {
			legend = dpGetComment(defaultCurve[fwTrending_CURVE_OBJECT_DPE]);
			if(legend == "") {
				defaultCurve[fwTrending_CURVE_OBJECT_LEGEND] = dpSubStr(defaultCurve[fwTrending_CURVE_OBJECT_DPE], DPSUB_DP_EL);
			} else {
				defaultCurve[fwTrending_CURVE_OBJECT_LEGEND] = legend;
			}
		}
	}

	curveData = defaultCurve;
}


/** This function returns two lists of integers representing certain indexes of the curveData object and the plotData object.
All the curveData object indexes are returned, and the corresponding indexes of the plotData object where the curveData should
be stored are also returned.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param 	curveObjectIndexes		output, The indexes of the curveData object are returned here
@param 	plotObjectIndexes		output, The corresponding indexes of the plotData object are returned here
@param 	exceptionInfo			output, details of any exceptions are returned here
@return							The length of the curveData object is returned here
*/
int _fwTrending_getCurveObjectIndexes(dyn_int &curveObjectIndexes, dyn_int &plotObjectIndexes,
										dyn_string &exceptionInfo) {
	int objectSize;

	plotObjectIndexes = makeDynInt(fwTrending_PLOT_OBJECT_DPES, fwTrending_PLOT_OBJECT_CURVE_TYPES,
									fwTrending_PLOT_OBJECT_COLORS, fwTrending_PLOT_OBJECT_LEGENDS,
									fwTrending_PLOT_OBJECT_AXII, fwTrending_PLOT_OBJECT_CURVES_HIDDEN,
									fwTrending_PLOT_OBJECT_RANGES_MIN, fwTrending_PLOT_OBJECT_RANGES_MAX);
				
	curveObjectIndexes = makeDynInt(fwTrending_CURVE_OBJECT_DPE, fwTrending_CURVE_OBJECT_TYPE,
									fwTrending_CURVE_OBJECT_COLOR, fwTrending_CURVE_OBJECT_LEGEND,
									fwTrending_CURVE_OBJECT_AXIS, fwTrending_CURVE_OBJECT_HIDDEN,
									fwTrending_CURVE_OBJECT_Y_MIN, fwTrending_CURVE_OBJECT_Y_MAX);

	objectSize = dynlen(curveObjectIndexes);
							
	return objectSize;
}

/** Opens a plot display with various options as to how it is opened.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sPlotDpName				input, the plot data point name to show
@param sPanelFileName			input, the file name of the panel to use (use constants such as fwTrending_PANEL_PLOT_STANDARD)
@param bAsNewModule				input, should the display be opened in a new module, TRUE = new module, FALSE = child panel
@param bStayOnTopOrModal		input, for a new module - TRUE = stay on top, FALSE = normal behaviour
								for a child panel - TRUE = modal child panel, FALSE = normal behaviour
@param sModuleName				input, the name of the new module (if required)
@param sPanelName				input, the name of the new panel
@param x						input, Optional parameter - default value 0.  X position of the new display
@param y						input, Optional parameter - default value 0.  Y position of the new display
@param sResizeMode    			input, Optional parameter - default value "". "" Default from the config file (see config entry visionResizeMode chapter User interface on PVSS Help)
								"None" ... Scaling not possible in the VISION module.
								"Scale" ... Scaling possible in the VISION module by changing the size of the window.
								"Zoom" ... Scaling only possible with the Navigator
*/
fwTrending_openPlotDisplay(string sPlotDpName, string sPanelFileName, bool bAsNewModule, bool bStayOnTopOrModal,
                           string sModuleName, string sPanelName, unsigned x = 0, unsigned y = 0, string sResizeMode="") {
	dyn_string dollarParams;

	switch(sPanelFileName) {
		case fwTrending_PANEL_PLOT_STANDARD:
			dollarParams = makeDynString("$PlotName:" + sPlotDpName);
			break;
		case fwTrending_PANEL_PLOT_FACEPLATE:
		case fwTrending_PANEL_PLOT_FACEPLATE_FULLCAPTION:
		case fwTrending_PANEL_PLOT_ZOOMED:
			dollarParams = makeDynString("$sDpName:" + sPlotDpName,
								        "$ZoomWindowTitle:",
										"$bShowGrid:",
										"$iMarkerType:",
										"$bShowLegend:",
										"$bTrendLog:",
										"$dsCurveColor:",
										"$dsCurveDPE:",
										"$dsCurveLegend:",
										"$dsCurveRange:",
										"$dsCurveScaleVisible:",
										"$dsCurveToolTipText:",
										"$dsCurveVisible:",
										"$dsCurvesType:",
										"$dsUnit:",
										"$fMaxPercentageForLog:",
										"$fMinForLog:",
										"$sBackColor:",
										"$sDpName:",
										"$sForeColor:",
										"$sRefName:",
										"$sTimeRange:",
										"$templateParameters:");
			break;
		default:
			dollarParams = makeDynString("$sDpName:" + sPlotDpName);
	}
	
	if(bAsNewModule) {
		ModuleOnWithPanel(sModuleName,
		                   x, y, 0, 0, 0, 0, sResizeMode,
		                   sPanelFileName,
		                   sPanelName,
		                   dollarParams);
		               		
		stayOnTop(bStayOnTopOrModal, sModuleName);
	} else {
		if(!bStayOnTopOrModal) {
		  ChildPanelOn(sPanelFileName,
							sPanelName,
							dollarParams,
							x, y);
		} else {
		  ChildPanelOnModal(sPanelFileName,
							sPanelName,
							dollarParams,
							x, y);
		}
	}
}


/** Check if the system that a dpe is on is connected or not

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param curveDpe					input, the data point element that you want to access
@param isConnected				output, TRUE if required system is connected, else FALSE
@param exceptionInfo			output, details of any exceptions are returned here
*/
_fwTrending_isSystemForDpeConnected(string curveDpe, bool &isConnected, dyn_string &exceptionInfo) {
	string systemName;

	systemName = dpSubStr(curveDpe, DPSUB_SYS);

	_fwTrending_isSystemConnected(systemName, isConnected, exceptionInfo);
}


/** Check if the given system ID is of a system which is connected or not

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param systemName				input, name of the system that you want to access
@param isConnected				output, TRUE if required system is connected, else FALSE
@param exceptionInfo			output, details of any exceptions are returned here
*/
_fwTrending_isSystemConnected(string systemName, bool &isConnected, dyn_string &exceptionInfo) {
	if(systemName == getSystemName()) {
		isConnected = TRUE;
	} else {
		unDistributedControl_isConnected(isConnected, systemName);
	}
}


/** Get a list of the IDs of all connected systems (including local system)

@par Constraints
	None

@par Usage
	DEPCRECATED - Use unDistributedControl DPs and functions instead

@par PVSS managers
	VISION, CTRL

@param systemIds				output, list of IDs of all connected systems
@param exceptionInfo			output, details of any exceptions are returned here
*/
_fwTrending_getConnectedSystemIds(dyn_int &systemIds, dyn_string &exceptionInfo) {
	time time1, time2;
	dyn_int connectedDistMans, connectedSystemIds;

	systemIds = makeDynInt();

	dpGet("_Connections.Dist.ManNums:_online.._value", connectedDistMans);
	if(dynlen(connectedDistMans) > 0) {
		dpGet("_Connections.Dist.ManNums:_online.._stime", time1,
					"_DistManager.State.SystemNums:_online.._stime", time2,
					"_DistManager.State.SystemNums:_online.._value", connectedSystemIds);
					
		if(time1 <= time2) {
			systemIds = connectedSystemIds;
		}
	}
	
	dynAppend(systemIds, getSystemId());
	dynSortAsc(systemIds);
	dynUnique(systemIds);
}


/** Work function called to update the histogram display when the data source dyn_dpe is modified.

@par Constraints
	Not for reuse, only used by Histogram display as a callback function.

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpa			The name of the dpa that changed
@param value		The new value of the dpe
*/
_fwTrending_updateHistogram(string dpa, dyn_float value) {
	bool someNegative, somePositive, userSpecifiedRange;
	int i, length, order, precision, doubleRange =1, iMultiple;
	float min, max, maxValue, multiple;
	string currentParameterValues, trendRunning, dpe, updateTime, ref=$sRefName;
	dyn_float valuesArray, range;
	dyn_string valuesColour, valuesText, plotShapes, exceptionInfo;
	dyn_dyn_string plotData;
	shape activeTrendShape;
	time update;

    //do not update histogram if it is frozen
	if(trendRunningText.text == "FALSE") {
		return;
	}
		
	dpe = dpSubStr(dpa, DPSUB_SYS_DP_EL);
	dpGet(dpe + ":_online.._stime", update);

	ref = _fwTrending_adjustRefName(ref);
	
    //read plot config and parameter substitution data from graphical widgets in panel
	getValue(ref+"parameterValues", "text", currentParameterValues);
	fwTrending_getRuntimePlotDataWithExtendedObject($sRefName, trendRunning, plotShapes, plotData, exceptionInfo);
	
  	//if a dpe was passed, and not a parameter in {}, add system name if missing
	if(strpos(plotData[fwTrending_PLOT_OBJECT_DPES][1], ":") < 0
			&& strpos(plotData[fwTrending_PLOT_OBJECT_DPES][1],fwTrending_TEMPLATE_OPEN ) < 0) {
		plotData[fwTrending_PLOT_OBJECT_DPES][1] = getSystemName() + plotData[fwTrending_PLOT_OBJECT_DPES][1];
	}

	_fwTrending_evaluateTemplate(currentParameterValues, plotData[fwTrending_PLOT_OBJECT_DPES], exceptionInfo);
	
	if(plotData[fwTrending_PLOT_OBJECT_DPES][1] != dpSubStr(dpa, DPSUB_SYS_DP_EL)) {
		//if no system name was passed, add the local sys name
		if(plotData[fwTrending_PLOT_OBJECT_DPES][1] == dpSubStr(dpa, DPSUB_DP_EL)) {
			  plotData[fwTrending_PLOT_OBJECT_DPES][1] = getSystemName() + plotData[fwTrending_PLOT_OBJECT_DPES][1];		
		} else {
			//if the dpe has no element, exit
			return;
		}
    }
		
	activeTrendShape = getShape(plotShapes[fwTrending_ACTIVE_TREND_NAME]);

	//clear the histogram if "value" contains no data
	if(!dynlen(value)) {
		activeTrendShape.data(makeDynFloat(0));
		activeTrendShape.flush;
		return;
	}	

	//check the Y axis range and see if it set to autoscale (0,0)
	range = strsplit(plotData[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE][1], fwTrending_AXIS_LIMITS_DIVIDER);
	if((range[1] == 0) && (range[2] == 0)) {
		min = dynMin(value);
		max = dynMax(value);
		userSpecifiedRange = FALSE;
	} else {
		min = range[1];
		max = range[2];
		userSpecifiedRange = TRUE;
	}	

    //identify if all of range is negative, positive or mixed
	if(min < 0) {
		someNegative = TRUE;
	} else {
		someNegative = FALSE;
	}
	
	if(max > 0) {
		somePositive = TRUE;
	} else {
		somePositive = FALSE;
	}
	
    //always show 0 in histogram even if it is not covered by range - all bars start from 0
	activeTrendShape.yCenter(0);

	//choose if bars should start from bottom, top or middle of histogram display
	if(someNegative && somePositive) {
		activeTrendShape.yOrigin = BAR_CENTER;
	} else if(someNegative) {
		activeTrendShape.yOrigin = BAR_TOP;
	} else {
		activeTrendShape.yOrigin = BAR_BOTTOM;
	}
	
	//find greatest magnitude scale
	min = 0 - min;
	if(min>max) {
		max = min;
	}
	
	//calculate order of magnitude of max scale and deduce required decimal places (precision) in axis
	maxValue = max;
	order = 0;
	if(maxValue >= 10) {
		while((maxValue/=10) >= 1) {
			order++;
		}
	} else if(maxValue < 1) {
		while((maxValue*=10) <= 10) {
			order--;
		}
	}

	precision = 2 - order;
	if(precision < 0) {
		precision = 0;
	}
		
	activeTrendShape.yPrec(precision);
	multiple = max/(pow(10, order));
	iMultiple = multiple;
	activeTrendShape.yStep(iMultiple * pow(10, order-1)*4);
	multiple *= 1.1;

    //set Y range size from specified or calculated value - double the range if both above and below 0 are shown
	if(someNegative && somePositive) {
		doubleRange = 2;
	}
	
	if(userSpecifiedRange) {
		activeTrendShape.yRange = doubleRange * max;
	} else {
		activeTrendShape.yRange = doubleRange * multiple * (pow(10, order));
	}
	
    //ensure that no parts of the bars are coloured due to ref value
	activeTrendShape.refValue(0);
	
    //count the number of entries in the dyn_variable to display
	length = dynlen(value);

    //check the Y axis range and see if it set to autoscale (0,0)
	range = strsplit(plotData[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE_X][1], fwTrending_AXIS_LIMITS_DIVIDER);
	if((range[1] == 0) && (range[2] == 0)) {
		min = 0;
		max = length;
		userSpecifiedRange = FALSE;
	} else {
		min = range[1];
		max = range[2];
		userSpecifiedRange = TRUE;
	}	

	//prepare one dimensional array data (legend)
    //this first dummy entry is required to ensure correct positioning
	valuesArray = makeDynFloat(min);
	valuesColour = makeDynString(plotData[fwTrending_PLOT_OBJECT_BACK_COLOR][1]);
	valuesText = makeDynString("");
	
	//fill in the other values of the dyn_variable to show in 1-D array
	for(i=1; i<=length; i++) {
		dynAppend(valuesArray, min + i*(max-min)/length);
		dynAppend(valuesColour, plotData[fwTrending_PLOT_OBJECT_BACK_COLOR][1]);
		dynAppend(valuesText, value[i]);
	}

	//configure X axis with desired or default min and max range
	//also set width of each bar
	//the default is bar width 1 and range 0 -> dynlen(values)
	activeTrendShape.xStart = min;
	activeTrendShape.xCenter = min;
	activeTrendShape.xStep = (max-min)/length;
	activeTrendShape.xWidth = (max-min)/length;
	activeTrendShape.xRange = max-min;

	//set data in the histogram and 1-D array and flush the buffer
	activeTrendShape.data(value);
	activeTrendShape.xArray(valuesArray, valuesColour, valuesText);
	activeTrendShape.flush;
	
	updateTime = formatTime("%c.", update, "%03d");
	setValue(ref + "trendCaption.curveTime", "text", updateTime);
}


/** Convert a plotData object to a list of $params ready to pass to a trend display.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param plotData					input, The plot data object (dyn_dyn_string)
@param dollarParameters			output, The list of $ parameters to be passed to a trend display based on the data in plotData
@param exceptionInfo			output, details of any exceptions are returned here
*/
_fwTrending_convertPlotDataToDollars(dyn_dyn_string plotData, dyn_string &dollarParameters, dyn_string &exceptionInfo) {
	int i, pos, currentTimeRange;
	float fTemp;
	string stringValue,stringValue2,stringValue3,stringValue4;
	dyn_string curveTypes;

	dynClear(dollarParameters);

	fTemp = plotData[fwTrending_PLOT_OBJECT_EXT_MIN_FOR_LOG][1];
	if(fTemp <= 0) {
		dynAppend(dollarParameters, "$fMinForLog:" + fwTrending_MIN_FOR_LOG);
	} else {
		dynAppend(dollarParameters, "$fMinForLog:" + plotData[fwTrending_PLOT_OBJECT_EXT_MIN_FOR_LOG][1]);
	}
	
	fTemp = plotData[fwTrending_PLOT_OBJECT_EXT_MAX_PERCENTAGE_FOR_LOG][1];
	if(fTemp <= 0) {
		dynAppend(dollarParameters, "$fMaxPercentageForLog:" + fwTrending_MAX_PERCENTAGE_FOR_LOG);
	} else {
		dynAppend(dollarParameters, "$fMaxPercentageForLog:" + plotData[fwTrending_PLOT_OBJECT_EXT_MAX_PERCENTAGE_FOR_LOG][1]);
	}
	
	dynAppend(dollarParameters, "$ZoomWindowTitle:" + plotData[fwTrending_PLOT_OBJECT_TITLE][1]);
	dynAppend(dollarParameters, "$bTrendLog:" + plotData[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1]);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_DPES], stringValue, exceptionInfo);
	dynAppend(dollarParameters, "$dsCurveDPE:" + stringValue);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_LEGENDS], stringValue, exceptionInfo);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT], stringValue2, exceptionInfo);
	dynAppend(dollarParameters, "$dsCurveLegend:" + stringValue+stringValue2);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS], stringValue, exceptionInfo);
	dynAppend(dollarParameters, "$dsCurveToolTipText:" + stringValue);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_COLORS], stringValue, exceptionInfo);
	dynAppend(dollarParameters, "$dsCurveColor:" + stringValue);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_EXT_MIN_MAX_RANGE], stringValue, exceptionInfo);
	dynAppend(dollarParameters, "$dsCurveRange:" + stringValue);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_EXT_UNITS], stringValue, exceptionInfo);
	dynAppend(dollarParameters, "$dsUnit:" + stringValue);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN], stringValue, exceptionInfo);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW], stringValue2, exceptionInfo);
	dynAppend(dollarParameters, "$dsCurveVisible:" + stringValue+stringValue2);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_AXII], stringValue, exceptionInfo);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_AXII_POS], stringValue2, exceptionInfo);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_AXII_LINK], stringValue3, exceptionInfo);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT], stringValue4, exceptionInfo);
	dynAppend(dollarParameters, "$dsCurveScaleVisible:" + stringValue+stringValue2+stringValue3+stringValue4);
	fwTrending_convertDynToString(plotData[fwTrending_PLOT_OBJECT_CURVE_TYPES], stringValue, exceptionInfo);
	dynAppend(dollarParameters, "$dsCurvesType:" + stringValue);
	dynAppend(dollarParameters, "$sBackColor:" + plotData[fwTrending_PLOT_OBJECT_BACK_COLOR][1]);
	dynAppend(dollarParameters, "$sForeColor:" + plotData[fwTrending_PLOT_OBJECT_FORE_COLOR][1]+fwTrending_CONTENT_DIVIDER+plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1]);
	dynAppend(dollarParameters, "$bShowGrid:" + plotData[fwTrending_PLOT_OBJECT_GRID][1]);
	dynAppend(dollarParameters, "$bShowLegend:" + plotData[fwTrending_PLOT_OBJECT_LEGEND_ON][1]+fwTrending_CONTENT_DIVIDER+plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1]);
	dynAppend(dollarParameters, "$iMarkerType:" + plotData[fwTrending_PLOT_OBJECT_MARKER_TYPE][1]+fwTrending_CONTENT_DIVIDER+plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1]);
	dynAppend(dollarParameters, "$sTimeRange:" + plotData[fwTrending_PLOT_OBJECT_TIME_RANGE][1]+fwTrending_CONTENT_DIVIDER+plotData[fwTrending_PLOT_OBJECT_AXII_X_FORMAT][1]+fwTrending_CONTENT_DIVIDER+plotData[fwTrending_PLOT_OBJECT_AXII_X_FORMAT][2]);
}


/** Prepare a plot data object to display.
This involves:
1) Substituting the template parameters for the known values.
2) Re-getting the extended plot information.  This updates the legend texts, units and descriptions with the latest values of the template parameters.
3) Converting any UNICOS style DPEs to PVSS DPEs

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param plotData				input/output, The plot data object (dyn_dyn_string)
@param parameterString		output, The string containing the template parameters and values
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwTrending_preparePlotObjectForDisplay(dyn_dyn_string &plotData, string parameterString, dyn_string &exceptionInfo) {
	int i;
	string dpe, unit, description;
	_fwTrending_evaluateTemplate(parameterString, plotData[fwTrending_PLOT_OBJECT_DPES], exceptionInfo);
	_fwTrending_evaluateTemplate(parameterString, plotData[fwTrending_PLOT_OBJECT_LEGENDS], exceptionInfo);
	_fwTrending_evaluateTemplate(parameterString, plotData[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS], exceptionInfo);

	for(i=1; i<=fwTrending_MAX_NUM_CURVES; i++) {
		fwTrending_getPlotDataDpeData(plotData[fwTrending_PLOT_OBJECT_DPES][i], dpe, unit, description);
		if(dpe != "") {
			plotData[fwTrending_PLOT_OBJECT_EXT_TOOLTIPS][i] = plotData[fwTrending_PLOT_OBJECT_DPES][i] + " ["+unit+"] " + description;
			plotData[fwTrending_PLOT_OBJECT_EXT_UNITS][i] = unit;
		}
	}

	fwTrending_convertUnicosDpeListToPvssDpeList(plotData[fwTrending_PLOT_OBJECT_DPES], plotData[fwTrending_PLOT_OBJECT_DPES], exceptionInfo);
}

/** This function provides an easy way of adding a faceplate to plot a given list of dpes
 to a panel as a symbol (instead of using addSymbol() directly).

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param moduleName			the name of the module on which the faceplate should be added
@param panelName			the name of the module on which the faceplate should be added
@param refName				the reference name of the new symbol to be added to the panel (can not be "")
							This name is used as the faceplate plot title
@param dpesToPlot			the list of dpes to show in the plot
@param x					the x position on the panel to add the symbol
@param y					the y position on the panel to add the symbol
@param exceptionInfo		output, details of any exceptions are returned here
@param plotDpName			OPTIONAL PARAMETER: The plot dp name to use a a template from which the plot configuration is read
							(all configuration of the plot except the dpes to plot).
							If not specified the standard QuickPlot defaults data point is used.
@param xScale				OPTIONAL PARAMETER: A scaling factor to be applied in the X axis, default value 1.0
@param yScale				OPTIONAL PARAMETER: A scaling factor to be applied in the Y axis, default value 1.0
*/
fwTrending_addQuickFaceplate(string moduleName, string panelName, string refName, dyn_string dpesToPlot,
				        int x, int y, dyn_string &exceptionInfo, string plotDpName = "_FwTrendingQuickPlotDefaults",
						float xScale = 1.0, float yScale = 1.0) {
	int i, length;
	dyn_string templateParameterNames, templateParameterValues;
	
	length = dynlen(dpesToPlot);
	if(length > fwTrending_MAX_NUM_CURVES) {
		fwException_raise(exceptionInfo, "ERROR",
						"fwTrending_addQuickFaceplate(): The maximum number of dpes to plot on one faceplate is "
						+ fwTrending_MAX_NUM_CURVES + ".", "");
		return;
	}

	for(i=1; i<=fwTrending_MAX_NUM_CURVES; i++) {
		templateParameterNames[i] = "dpe" + i;

		if(i<=length) {
			templateParameterValues[i] = dpesToPlot[i];
		} else {
			templateParameterValues[i] = "";
		}
	}

	fwTrending_addFaceplate(moduleName, panelName, refName, plotDpName,
							templateParameterNames, templateParameterValues,
							x, y, exceptionInfo, xScale, yScale);
}


/** This function provides an easy way of adding a faceplate to show a given predefined plot dp
 to a panel as a symbol (instead of using addSymbol() directly).

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param moduleName								the name of the module on which the faceplate should be added
@param panelName								the name of the module on which the faceplate should be added
@param refName									the reference name of the new symbol to be added to the panel (can not be "")
												This name is used as the faceplate plot title
@param plotDpName								the plot data point to use for the configuration of the faceplate
@param templateParameterNames					a list of any template parameters that you wish to pass
@param templateParameterValues					a list of value for template parameters named in templateParameterNames
@param x										the x position on the panel to add the symbol
@param y										the y position on the panel to add the symbol
@param exceptionInfo							output, details of any exceptions are returned here
@param xScale									optional, scaling factor for x (default=1)
@param yScale									optional, scaling factor for y (default=1)
*/
fwTrending_addFaceplate(string moduleName, string panelName, string refName, string plotDpName,
			dyn_string templateParameterNames,
			dyn_string templateParameterValues,
			int x, int y, dyn_string &exceptionInfo, float xScale = 1.0, float yScale = 1.0) {
	int i, length;
	string templateParameters;
	dyn_string dollarParameters;
	dyn_dyn_string plotData;

	if(refName == "") {
		fwException_raise(exceptionInfo, "ERROR", "fwTrending_addFaceplate(): A reference name must be given.", "");
		return;
	} else {
		refName = strrtrim(refName, ".");
	}

	fwTrending_getPlotExtended(plotDpName, "", plotData, exceptionInfo, TRUE);

	plotData[fwTrending_PLOT_OBJECT_TITLE][1] = refName;

	length = dynlen(templateParameterNames);
	if(length != dynlen(templateParameterValues)) {
		fwException_raise(exceptionInfo, "ERROR", "fwTrending_addFaceplate(): The template parameter lists of names and values must be of equal length.", "");
		return;
	}
	
	for(i=1; i<=length; i++) {
		templateParameters += templateParameterNames[i] + "=" + templateParameterValues[i] + fwTrending_TEMPLATE_DIVIDER;
	}
	
	_fwTrending_convertPlotDataToDollars(plotData, dollarParameters, exceptionInfo);

    if(plotDpName == fwTrending_QUICKPLOT_DEFAULTS)	{
		dynAppend(dollarParameters, "$sDpName:");
	} else {
        dynAppend(dollarParameters, "$sDpName:" + plotDpName);
	}

    dynAppend(dollarParameters, "$sRefName:" + refName + ".");
	dynAppend(dollarParameters, "$templateParameters:" + templateParameters);

	addSymbol(moduleName, panelName, fwTrending_PANEL_PLOT_FACEPLATE_FULLCAPTION, refName, dollarParameters, x, y, 0, xScale, yScale);
}


/** This function provides an easy way of removing a faceplate that was addded with the fwTrending_addFaceplate
or fwTrending_addQuickFaceplate functions.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param moduleName			the name of the module on which the faceplate is displayed
@param panelName			the name of the module on which the faceplate is displayed
@param refName				the reference name of the faceplate to remove
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwTrending_removeFaceplate(string moduleName, string panelName, string refName, dyn_string &exceptionInfo) {
	removeSymbol(moduleName, panelName, refName);
}


/** This function checks if the Trending Tool is running in a project where UNICOS FW is installed.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param 	exceptionInfo		output, details of any exceptions are returned here
@return 					return value - TRUE if UNICOS is installed, else FALSE
*/
bool _fwTrending_isUnicosEnvironment(dyn_string &exceptionInfo) {
	bool isUnicos;
	
	isUnicos = isFunctionDefined("unTree_EventInitializeConfiguration");

	return isUnicos;
}


_fwTrending_convertFrameworkToPvssMarkerType(int frameworkType, int &pvssType, dyn_string &exceptionInfo) {
	switch(frameworkType) {
		case fwTrending_MARKER_TYPE_FILLED_CIRCLE:
			pvssType = 7;
			break;
		case fwTrending_MARKER_TYPE_UNFILLED_CIRCLE:
			pvssType = 5;
			break;
		case fwTrending_MARKER_TYPE_NONE:
			pvssType = 0;
			break;
		default:
			fwException_raise(exceptionInfo, "ERROR", "Unsupported marker type: " + frameworkType, "");
			pvssType = 7;
			break;
	}
}


/** This function returns the list of Trending Tool Plot configuration attributes (i.e. dpe names)
    corresponding to the indexes as defined in the constants definitions.
    This function is needed by unTree during import/export of trending settings.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@return the array of Plot configuration attributes (i.e. dpe names)
@see fwTrending_getPageTreeTagNames()
*/
dyn_string fwTrending_getPlotTreeTagNames() {
    dyn_string ds_treeTagNames;

    ds_treeTagNames[fwTrending_PLOT_OBJECT_MODEL] = fwTrending_PLOT_MODEL;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_TITLE] = fwTrending_PLOT_TITLE;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_LEGEND_ON] = fwTrending_PLOT_LEGEND_ON;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_BACK_COLOR] = fwTrending_PLOT_BACK_COLOR;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_FORE_COLOR] = fwTrending_PLOT_FORE_COLOR;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_DPES_X] = fwTrending_PLOT_DPES_X;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_DPES] = fwTrending_PLOT_DPES;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_LEGENDS_X] = fwTrending_PLOT_LEGENDS_X;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_LEGENDS] = fwTrending_PLOT_LEGENDS;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_COLORS] = fwTrending_PLOT_COLORS;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_AXII_X] = fwTrending_PLOT_AXII_X;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_AXII] = fwTrending_PLOT_AXII;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_IS_TEMPLATE] = fwTrending_PLOT_IS_TEMPLATE;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_CURVES_HIDDEN] = fwTrending_PLOT_CURVES_HIDDEN;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_RANGES_MIN_X] = fwTrending_PLOT_RANGES_MIN_X;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_RANGES_MAX_X] = fwTrending_PLOT_RANGES_MAX_X;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_RANGES_MIN] = fwTrending_PLOT_RANGES_MIN;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_RANGES_MAX] = fwTrending_PLOT_RANGES_MAX;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_TYPE] = fwTrending_PLOT_TYPE;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_TIME_RANGE] = fwTrending_PLOT_TIME_RANGE;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_TEMPLATE_NAME] = fwTrending_PLOT_TEMPLATE_NAME;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC] = fwTrending_PLOT_IS_LOGARITHMIC;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_GRID] = fwTrending_PLOT_GRID;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_CURVE_TYPES] = fwTrending_PLOT_CURVE_TYPES;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_MARKER_TYPE] = fwTrending_PLOT_MARKER_TYPE;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE] = fwTrending_PLOT_ACCESS_CONTROL_SAVE;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON] = fwTrending_PLOT_CONTROL_BAR_ON;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_AXII_POS] = fwTrending_PLOT_AXII_POS;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_AXII_LINK] = fwTrending_PLOT_AXII_LINK;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_DEFAULT_FONT] = fwTrending_PLOT_DEFAULT_FONT;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_CURVE_STYLE] = fwTrending_PLOT_CURVE_STYLE;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_AXII_X_FORMAT] = fwTrending_PLOT_AXII_X_FORMAT;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_AXII_Y_FORMAT] = fwTrending_PLOT_AXII_Y_FORMAT;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_LEGEND_VALUES_FORMAT] = fwTrending_PLOT_LEGEND_VALUES_FORMAT;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_LEGEND_DATE_FORMAT] = fwTrending_PLOT_LEGEND_DATE_FORMAT;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_LEGEND_DATE_ON] = fwTrending_PLOT_LEGEND_DATE_ON;
    ds_treeTagNames[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW] = fwTrending_PLOT_ALARM_LIMITS_SHOW;

    return ds_treeTagNames;
}


/** This function returns the list of Trending Tool Page configuration attributes (i.e. dpe names)
    corresponding to the indexes as defined in the constants definitions.
    This function is needed by unTree during import/export of trending settings.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@return the array of Page configuration attributes (i.e. dpe names)
@see fwTrending_getPlotTreeTagNames()
*/
dyn_string fwTrending_getPageTreeTagNames() {
    dyn_string ds_treeTagNames;

    ds_treeTagNames[fwTrending_PAGE_OBJECT_MODEL] = fwTrending_PAGE_MODEL;
    ds_treeTagNames[fwTrending_PAGE_OBJECT_TITLE] = fwTrending_PAGE_TITLE;
    ds_treeTagNames[fwTrending_PAGE_OBJECT_NCOLS] = fwTrending_PAGE_NCOLS;
    ds_treeTagNames[fwTrending_PAGE_OBJECT_NROWS] = fwTrending_PAGE_NROWS;
    ds_treeTagNames[fwTrending_PAGE_OBJECT_PLOTS] = fwTrending_PAGE_PLOTS;
    ds_treeTagNames[fwTrending_PAGE_OBJECT_CONTROLS] = fwTrending_PAGE_CONTROLS;
    ds_treeTagNames[fwTrending_PAGE_OBJECT_PLOT_TEMPLATE_PARAMETERS] = fwTrending_PAGE_PLOT_TEMPLATE_PARAMETERS;
    ds_treeTagNames[fwTrending_PAGE_OBJECT_ACCESS_CONTROL_SAVE] = fwTrending_PAGE_ACCESS_CONTROL_SAVE;

    return ds_treeTagNames;
}


/** This function checks if the index corresponding to a specific item of
    Trending Tool Plot configuration attributes (i.e. dpe names) can be exported or not.
    It accepts all the constants like fwTrending_PLOT_OBJECT_...
    This function is needed by unTree during import/export of trending settings.

@par Example

\code
  bool canExport;
  canExport = fwTrending_isPlotTreeTagExportable(fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE);//canExport is false
  canExport = fwTrending_isPlotTreeTagExportable(fwTrending_PLOT_OBJECT_TYPE);//canExport is true
\endcode

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param 	tagIndex	index corresponding to the Plot configuration attribute.
        Any of the constants like fwTrending_PLOT_OBJECT_...
@return TRUE, if the index corresponding to the Plot configuration attribute can be exported. FALSE if not
*/
bool fwTrending_isPlotTreeTagExportable(int tagIndex) {
	if(tagIndex > fwTrending_SIZE_PLOT_OBJECT) {
		return false;
	}
	
	switch(tagIndex) {
		//add here all the attributes that should not be exported when exporting the trending configuration
		case fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE:
			return false;
			break;
		default:
			return true;
			break;
	}
}


/** Purpose: Checks if the provided info is a datapoint name

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param sDp		input, name of the datapoint to be checked
@return bool, result of the check
*/
bool fwTrending_isDpName(string sDp) {
	return dpAliasToName(sDp) == "";
}


/** Purpose: Checks if the provided info is an alias

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param sDp		input, name of the datapoint to be checked
@return bool, result of the check
*/
bool fwTrending_isAlias(string sDp) {
	return dpAliasToName(sDp) != "";
}


/** This function checks if the index corresponding to a specific item of
    Trending Tool Page configuration attributes (i.e. dpe names) can be exported or not.
    It accepts all the constants like fwTrending_PAGE_OBJECT_...
    This function is needed by unTree during import/export of trending settings.

@par Example

\code
  bool canExport;
  canExport = fwTrending_isPageTreeTagExportable(fwTrending_PAGE_OBJECT_ACCESS_CONTROL_SAVE);//canExport is false
  canExport = fwTrending_isPageTreeTagExportable(fwTrending_PAGE_OBJECT_TITLE);//canExport is true
\endcode

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param 	tagIndex	index corresponding to the Page configuration attribute.
        Any of the constants like fwTrending_PAGE_OBJECT_...
@return TRUE, if the index corresponding to the Page configuration attribute can be exported. FALSE if not
*/
bool fwTrending_isPageTreeTagExportable(int tagIndex) {
	if(tagIndex > fwTrending_SIZE_PAGE_OBJECT) {
		return false;
	}
	
	switch(tagIndex) {
		//add here all the attributes that should not be exported when exporting the trending configuration
		case fwTrending_PAGE_OBJECT_ACCESS_CONTROL_SAVE:
			return false;
			break;
		default:
			return true;
			break;
	}
}


/** Purpose: Append a dot "." to the refName because this function is called from the fwTrending/fwTrendingTrend.pnl 

@par Constraints
	None

@par Usage
	Only in scope of fwTrending CONTROL library

@par PVSS managers
	VISION, CTRL

@param 	ref		the name of the used reference
*/
string _fwTrending_appendDotTo(string ref) {
	if(ref != "") {
		ref = ref+".";
	}
	
	return ref;
}


/** Purpose: Append  "trend." to the refName because of a multiple plot and the ref will be ref+"trend."

@par Constraints
	None

@par Usage
	Only in scope of fwTrending CONTROL library

@par PVSS managers
	VISION, CTRL

@param 	ref		the name of the used reference
*/
string _fwTrending_adjustRefName(string ref) {
	if(ref != "") {
		ref = ref+"trend.";
	}
	
	return ref;
}

//@}
