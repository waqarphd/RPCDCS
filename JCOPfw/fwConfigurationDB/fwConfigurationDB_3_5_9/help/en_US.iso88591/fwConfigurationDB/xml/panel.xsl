<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			      xmlns:html="http://www.w3.org/1999/xhtml"
			      xmlns:exsl="http://exslt.org/common"
			      extension-element-prefixes="exsl" >



<xsl:include href="htmlparts.xsl"/>



<xsl:template match="description">
	<xsl:apply-templates />  
</xsl:template> 

<xsl:template match="button">
    [ <xsl:value-of select="@text"/> ]
</xsl:template> 


<xsl:template match="link">
	    <xsl:text disable-output-escaping="yes">&lt;a href="</xsl:text> <!-- opening: '<a href=" '    -->
	    <xsl:value-of select="@url"/>                                   <!-- url itself               -->
	    <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>        <!-- closing                  -->
	    <xsl:value-of select="@text"/>                                   <!-- visible text of the link -->
	    <xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>  <!-- close the tag: '</a>     -->
	    <xsl:value-of select="."/>                                  <!-- append the content of this tag -->
</xsl:template> 

<xsl:template match="picture">
    <li>
	    <xsl:text disable-output-escaping="yes">&lt;img src="</xsl:text> <!-- opening: '<img src=" '    -->
	    <xsl:value-of select="@url"/>                                   <!-- url itself               -->
	    <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>        <!-- closing                  -->
	    <br/>
	    Figure <xsl:value-of select="@id"/>: <xsl:value-of select="@caption"/>
	    <br/>
    </li>
</xsl:template> 



<!-- this template will produce a single entry for a <panel> in the
 parrent element (<component>), then it will trigger the production of the
 file for this <panel> element
 -->
<xsl:template match="panel">

    <tr>
	<td class="desc"><xsl:value-of select="@fullname"/> </td>    
	<td class="link">
	    <xsl:text disable-output-escaping="yes">&lt;a href="panels/</xsl:text> <!-- opening: '<a href=" '    -->
	    <xsl:value-of select="../@name"/>/<xsl:value-of select="@fname"/>.html <!-- url itself               -->
	    <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>        <!-- closing                  -->
	    <xsl:value-of select="../@name"/>/<xsl:value-of select="@name"/><!-- visible text of the link -->
	    <xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>  <!-- close the tag: '</a>     -->
	</td>
    </tr>

    <xsl:call-template name="make-panel-htmldoc"/>

</xsl:template>



<xsl:template name="make-panel-htmldoc">

    <!-- WEBPAGE BEGIN -->
<exsl:document href="panels/{../@name}/{@fname}.html" method="html" >

<!--XML HEADER-->
<xsl:text disable-output-escaping="yes">&lt;!DOCTYPE </xsl:text>HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"<xsl:text disable-output-escaping="yes">&gt;
&lt;html xmlns="http://www.w3.org/TR/REC-html40"&gt; 
</xsl:text>
<!-- HTML Header -->
<head>
<title><xsl:value-of select="@name"/> panel</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>
<link rel="StyleSheet" HREF="style.css" TYPE="text/css" MEDIA="screen,print"/>
</head>

<xsl:call-template name="newline"/>

<body>


<table width="95%" border="1">
  <tbody>
  <tr vAlign="top">
    <td width="22%" bgColor="#00cc00"><strong>Panel Name</strong></td>
    <td width="78%" colSpan="2"><xsl:value-of select="../@name"/>/<xsl:value-of select="@name"/></td>
  </tr>
  <tr vAlign="top">
    <td bgColor="#00cc00"><strong>Introduction<br/></strong></td>
    <td colSpan="2">
	<p>
	     <xsl:value-of select="@fullname"/>
	</p>
        <p> <strong>Documentation of this panel is not yet completed</strong></p>

	<xsl:if test="count(description) > 0">
	    <p>
	    <xsl:apply-templates select="description"/> 
	    </p>
	</xsl:if>
	<br/>

	<xsl:if test="count(picture) > 0">
	    <ul>
		<xsl:apply-templates select="picture"/> 
	    </ul>
	</xsl:if>

    </td>
  </tr>
  <tr vAlign="top">
    <td bgColor="#00cc00"><strong>Instructions</strong></td><td colSpan="2"></td>
  </tr>
  <tr vAlign="top">
    <td bgColor="#00cc00"><strong>Restrictions</strong></td><td colSpan="2"></td>
  </tr>
</tbody>
</table>

<xsl:call-template name="newline"/>

<br/>
<table width="95%" border="1">
  <tbody>
  <tr bgColor="#00cc00"><td colSpan="3"><strong>Dollar Parameters</strong></td></tr>
  <tr bgColor="#00cc00">
    <td width="23%"><strong>Name</strong></td>
    <td width="62%"><strong>Description</strong></td>
    <td width="15%"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></td>
  </tr>
 </tbody>
</table>
<br/>

<xsl:call-template name="newline"/>

  <table width="95%" border="1">
    <tbody>
      <tr bgColor="#00cc00"><td colSpan="3"><strong>Global Variables</strong></td></tr>
      <tr bgColor="#00cc00">
        <td width="30%"><strong>Name</strong></td>
        <td width="10%"><strong>Type</strong></td>
        <td width="60%"><strong>Description</strong></td>
      </tr>
      <tr>
      </tr>
      </tbody>
    </table>

<xsl:call-template name="newline"/>

<xsl:call-template name="make-html-footer"/>
	
</body>
<!-- </html> -->
<xsl:text disable-output-escaping="yes">&lt;/html&gt;</xsl:text>
</exsl:document>


    
</xsl:template>




</xsl:stylesheet>