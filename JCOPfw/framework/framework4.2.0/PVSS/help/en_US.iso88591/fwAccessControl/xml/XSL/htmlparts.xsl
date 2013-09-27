<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			      xmlns:html="http://www.w3.org/1999/xhtml"
			      xmlns:exsl="http://exslt.org/common"
			      extension-element-prefixes="exsl" >



<!-- __________________________________________________________________________
This is to transform all the <html:xxx> tags to the appropriate <xxx> HTML tags
_______________________________________________________________________________ -->
<xsl:template match="html:*">
  <xsl:element name="{local-name()}">
    <xsl:for-each select="@html:*">
      <xsl:attribute name="{local-name()}">
        <xsl:value-of select="." />
      </xsl:attribute>
    </xsl:for-each>
    <xsl:apply-templates />
  </xsl:element>
</xsl:template>


<xsl:template name="make-html-footer">
<br/>
<hr/>
<font size="-1"> Piotr Golonka, <a href="cern.ch/itcobe">CERN IT/CO-BE</a></font>
</xsl:template>


<xsl:template name="newline">
<xsl:text disable-output-escaping="yes">
</xsl:text>
</xsl:template>

</xsl:stylesheet>