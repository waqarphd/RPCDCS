<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			      xmlns:html="http://www.w3.org/1999/xhtml"
			      xmlns:exsl="http://exslt.org/common"
			      extension-element-prefixes="exsl" >



<xsl:include href="htmlparts.xsl"/>



<xsl:template match="description">
	<xsl:apply-templates />  
</xsl:template> 



<xsl:template match="instruction">
	<dt><xsl:value-of select="@action"/>:</dt>
	<dd><xsl:apply-templates /></dd>
</xsl:template> 


<xsl:template match="restriction">
	<li>
	    <xsl:if test="@id"><strong><xsl:value-of select="@id"/>:</strong> </xsl:if>
	    <xsl:apply-templates />
	</li>
</xsl:template> 


<xsl:template match="df">
    <tr>
	<td><code>df[<xsl:value-of select="@idx"/>]</code></td>
	<td><code><xsl:value-of select="@val"/></code></td>
	<td><xsl:apply-templates /></td>
    </tr>
</xsl:template> 

<xsl:template match="ds">
    <tr>
	<td><code>ds[<xsl:value-of select="@idx"/>]</code></td>
	<td><code><xsl:value-of select="@val"/></code></td>
	<td><xsl:apply-templates /></td>
    </tr>
</xsl:template> 



<xsl:template match="dollarParam">
    <tr>
	<td>$<xsl:value-of select="@name"/></td>
	<td><xsl:apply-templates /></td>
	<td><xsl:value-of select="@scope"/></td>
    </tr>
</xsl:template> 

<xsl:template match="globalVar">
    <tr>
	<td><xsl:value-of select="@name"/></td>
	<td><xsl:value-of select="@type"/></td>
	<td><xsl:apply-templates /></td>
    </tr>
</xsl:template> 

<xsl:template match="button">

    <xsl:choose>
	<xsl:when test="@img">
    	    <xsl:text disable-output-escaping="yes">&lt;img class="button" align="center" src="</xsl:text> <!-- opening: '<img src=" '    -->
	    <xsl:value-of select="@img"/>                                   <!-- url itself               -->
	    <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>        <!-- closing                  -->
	</xsl:when>
	<xsl:otherwise>
	    <xsl:choose>
		<xsl:when test="@type!='pressed'">
		    <span class="button"><xsl:value-of select="@name"/><xsl:apply-templates /></span>
		</xsl:when>
		<xsl:otherwise>
		    <span class="selbutton"><xsl:value-of select="@name"/><xsl:apply-templates /></span>
		</xsl:otherwise>
		</xsl:choose>
	</xsl:otherwise>
    </xsl:choose>

</xsl:template> 


<xsl:template match="link">
	    <xsl:text disable-output-escaping="yes">&lt;a href="</xsl:text> <!-- opening: '<a href=" '    -->
	    <xsl:value-of select="@url"/>                                   <!-- url itself               -->
	    <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>        <!-- closing                  -->
	    <xsl:value-of select="@text"/>                                   <!-- visible text of the link -->
	    <xsl:text disable-output-escaping="yes">&lt;/a&gt; </xsl:text>  <!-- close the tag: '</a>     -->
	    <xsl:value-of select="."/>                                  <!-- append the content of this tag -->
</xsl:template> 

<xsl:template match="otherPanel"> 

    <xsl:choose>
    <xsl:when test="@component">
	<xsl:text disable-output-escaping="yes">&lt;a href="../../../</xsl:text><xsl:value-of select="@component"/>/panels/<xsl:value-of select="@component"/>/<xsl:value-of select="@name"/>.htm<xsl:text disable-output-escaping="yes">"&gt;</xsl:text>

	<xsl:choose>
	    <xsl:when test="@text"> <xsl:value-of select="@text"/></xsl:when>
	    <xsl:otherwise><xsl:value-of select="@component"/>/<xsl:value-of select="@name"/></xsl:otherwise>
	</xsl:choose>

	<xsl:text disable-output-escaping="yes">&lt;/a&gt; </xsl:text> <xsl:value-of select="."/>
    </xsl:when>
    <xsl:otherwise>
	<xsl:text disable-output-escaping="yes">&lt;a href="</xsl:text><xsl:value-of select="@name"/>.htm<xsl:text disable-output-escaping="yes">"&gt;</xsl:text>

	<xsl:choose>
	    <xsl:when test="@text"> <xsl:value-of select="@text"/></xsl:when>
	    <xsl:otherwise><xsl:value-of select="@name"/></xsl:otherwise>
	</xsl:choose>
	
	<xsl:text disable-output-escaping="yes">&lt;/a&gt; </xsl:text> <xsl:value-of select="."/>
    </xsl:otherwise>
    </xsl:choose>
</xsl:template> 


<xsl:template match="picture">




<div class="figure">
<table align="center">
<tr>
<td>
	    <xsl:text disable-output-escaping="yes">&lt;img src="</xsl:text> <!-- opening: '<img src=" '    -->
	    <xsl:value-of select="@url"/>                                   <!-- url itself               -->
	    <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>        <!-- closing                  -->
</td>
</tr>
<tr>
    <td><span class="caption">Figure <xsl:value-of select="@id"/>: <xsl:value-of select="@caption"/></span></td>
</tr>
</table>
</div>
</xsl:template> 



<!-- this template will produce a single entry for a <panel> in the
 parrent element (<component/panels>), then it will trigger the production of the
 file for this <panel> element
 -->
<xsl:template match="panel">

    <tr>
	<td class="desc"><xsl:value-of select="@fullname"/> </td>    
	<td class="link">
	    <xsl:text disable-output-escaping="yes">&lt;a href="panels/</xsl:text> <!-- opening: '<a href=" '    -->
	    <xsl:value-of select="../../@name"/>/<xsl:value-of select="@fname"/>.htm <!-- url itself               -->
	    <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>
		<!-- visible text of the link -->
	        <xsl:choose>
		    <xsl:when test="@subdir">
			<xsl:value-of select="@subdir"/>/<xsl:value-of select="@name"/>
		    </xsl:when>
		    <xsl:otherwise>
			<xsl:value-of select="../../@name"/>/<xsl:value-of select="@name"/>
		    </xsl:otherwise>
		</xsl:choose>
	    <xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>  <!-- close the tag: '</a>     -->
	</td>
    </tr>

    <xsl:call-template name="make-panel-htmldoc"/>

</xsl:template>



<xsl:template name="make-panel-htmldoc">

    <!-- WEBPAGE BEGIN -->
<exsl:document href="panels/{../../@name}/{@fname}.htm" method="html" >

<!--XML HEADER-->
<xsl:text disable-output-escaping="yes">&lt;!DOCTYPE </xsl:text>HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"<xsl:text disable-output-escaping="yes">&gt;
&lt;html xmlns="http://www.w3.org/TR/REC-html40"&gt; 
</xsl:text>
<!-- HTML Header -->
<head>
<title>


<xsl:value-of select="@name"/> 
panel</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>
<link rel="StyleSheet" HREF="style.css" TYPE="text/css" MEDIA="screen,print"/>
</head>

<xsl:call-template name="newline"/>

<body>


<table width="95%" border="1">
  <tbody>
  <tr vAlign="top">
    <td width="22%" bgColor="#00cc00"><strong>Panel Name</strong></td>
    <td width="78%" colSpan="2">
    	        <xsl:choose>
		    <xsl:when test="@subdir">
			<xsl:value-of select="@subdir"/>/<xsl:value-of select="@name"/>
		    </xsl:when>
		    <xsl:otherwise>
			<xsl:value-of select="../../@name"/>/<xsl:value-of select="@name"/>
		    </xsl:otherwise>
		</xsl:choose>
    </td>
  </tr>
  <tr vAlign="top">
    <td bgColor="#00cc00"><strong>Introduction<br/></strong></td>
    <td colSpan="2">
	<p>
	     <xsl:value-of select="@fullname"/>
	</p>

	<xsl:if test="count(description) > 0">
	    <p>
	    <xsl:apply-templates select="description"/> 
	    </p>
	</xsl:if>
	<br/>

    </td>
  </tr>
  <tr vAlign="top">
    <td bgColor="#00cc00"><strong>Instructions</strong></td>
    <td colSpan="2">
	<dl>
	          <xsl:apply-templates select="instruction"/> 
	</dl>
    </td>
  </tr>
  <tr vAlign="top">
    <td bgColor="#00cc00"><strong>Restrictions</strong></td>
	<td colSpan="2">
		<ul>
	          <xsl:apply-templates select="restriction"/> 
	    </ul>
	</td>
  </tr>
</tbody>
</table>

<xsl:call-template name="newline"/>
<br/>


<xsl:if test="count(dollarParam) > 0">

<table width="95%" border="1">
  <tbody>
  <tr bgColor="#00cc00"><td colSpan="3"><strong>Dollar Parameters</strong></td></tr>
  <tr bgColor="#00cc00">
    <td width="23%"><strong>Name</strong></td>
    <td width="62%"><strong>Description</strong></td>
    <td width="15%"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></td>
  </tr>
    <xsl:apply-templates select="dollarParam"/> 
 </tbody>
</table>
<br/>
</xsl:if>

<xsl:call-template name="newline"/>

<xsl:if test="count(globalVar) > 0">

  <table width="95%" border="1">
    <tbody>
      <tr bgColor="#00cc00"><td colSpan="3"><strong>Global Variables</strong></td></tr>
      <tr bgColor="#00cc00">
        <td width="30%"><strong>Name</strong></td>
        <td width="10%"><strong>Type</strong></td>
        <td width="60%"><strong>Description</strong></td>
      </tr>
          <xsl:apply-templates select="globalVar"/> 
      </tbody>
    </table>

<xsl:call-template name="newline"/>
<br/>

</xsl:if>

<xsl:if test="count(returns) > 0">


  <table width="95%" border="1">
    <tbody>
      <tr bgColor="#00cc00"><td colSpan="3"><strong>Return Values from panel</strong></td></tr>

    <tr> <td colspan="3"><xsl:apply-templates select="returns/description"/> </td></tr> 

      <tr bgColor="#00cc00">
        <td width="60"><strong>Variable</strong></td>
        <td width="10%"><strong>Value(s)</strong></td>
        <td><strong>Description</strong></td>
      </tr>

      <tr bgColor="#ccffcc"><td colspan="3" align="center"> <code>dyn_float</code>  parameter (<code>df[]</code>)</td></tr> 
          <xsl:apply-templates select="returns/df"/>
      <tr bgColor="#ccffcc"><td colspan="3" align="center"> <code>dyn_string</code> parameter (<code>ds[]</code>)</td></tr> 
          <xsl:apply-templates select="returns/ds"/>
      </tbody>
    </table>

</xsl:if>

<xsl:call-template name="newline"/>
<br/>

	    <xsl:text disable-output-escaping="yes">&lt;a href="../../</xsl:text>
	    <xsl:value-of select="../../@name"/><xsl:text disable-output-escaping="yes">.htm"&gt;</xsl:text>        <!-- closing                  -->
Back to the documentation of the
	    <xsl:value-of select="../../@name"/>                                   <!-- visible text of the link -->
component.
	    <xsl:text disable-output-escaping="yes">&lt;/a&gt; </xsl:text>  <!-- close the tag: '</a>     -->

<xsl:call-template name="make-html-footer"/>
	
</body>
<!-- </html> -->
<xsl:text disable-output-escaping="yes">&lt;/html&gt;</xsl:text>
</exsl:document>


    
</xsl:template>




</xsl:stylesheet>