<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			      xmlns:exsl="http://exslt.org/common"
			      extension-element-prefixes="exsl" >


<xsl:include href="component.xsl"/>

<xsl:template match="/components/description">
        <xsl:apply-templates />
</xsl:template>


<!-- MAIN WEB PAGE IS PRODUCED HERE -->
<xsl:template name="make-main-htmldoc">
    <xsl:param name="filename" />
    <xsl:param name="header"   />

    <!-- WEBPAGE BEGIN -->

    <exsl:document href="{$filename}" method="html" >
    
    <html>
    <head>
	<link rel="StyleSheet" href="style.css" type="text/css" media="screen,print" />
    </head>
    
    <body>
	<h1> <xsl:value-of select="$header"/> </h1>
	<hr/>
	    <xsl:apply-templates select="/components/description"/>
	<ul>
	    <xsl:apply-templates select="/components/component"/>
	</ul>
<xsl:call-template name="make-html-footer"/>

    </body>
    </html>

    </exsl:document>

    
</xsl:template>





<!-- MAIN CODE COMES HERE -->

<xsl:template match="/">

    <xsl:call-template name="make-main-htmldoc">
	<xsl:with-param name="filename">../index-PG.html</xsl:with-param>
	<xsl:with-param name="header">JCOP Framework</xsl:with-param>    
    </xsl:call-template>


</xsl:template>

</xsl:stylesheet>