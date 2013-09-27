<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		 xmlns:exsl="http://exslt.org/common"
                 extension-element-prefixes="exsl"
>



<xsl:include href="panel.xsl"/>

<xsl:template match="library"> 
    <tr>
      <td class="desc"><xsl:value-of select="@name"/></td>
      <td class="link"><xsl:apply-templates select="link"/></td>
    </tr>
</xsl:template>

<xsl:template match="libraries"> 
<br/>
<table border="1">
  <tbody>
    <tr> <td class="tableHead" colspan="2">Libraries</td> </tr>
    <xsl:apply-templates select="library"/>	
  </tbody>
</table>
<br/>
</xsl:template>

<xsl:template match="panels"> 
<br/>
<table border="1">
  <tbody>
    <tr> <td class="tableHead" colspan="2">Panels</td> </tr>
    <xsl:apply-templates select="panel"/>
  </tbody>
</table>
<br/>

</xsl:template>

<xsl:template match="dependency"> 
    <li><xsl:apply-templates/></li>
</xsl:template>

<xsl:template match="requirement"> 
    <li><xsl:apply-templates/></li>
</xsl:template>




<xsl:template match="component"> 

    <li>
    Component: 
           <xsl:text disable-output-escaping="yes">&lt;a href="</xsl:text><!-- opening: '<a href=" '    -->
	    <xsl:value-of select="@name"/>.htm<!-- url itself               -->
            <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>       <!-- closing                  -->
            <xsl:value-of select="@name"/>                                 <!-- visible text of the link -->
            <xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>  <!-- close the tag: '</a>     -->
    </li>
    
    <!-- now call a template to produce module individual webpage -->
    <xsl:call-template name="make-component-htmldoc"/>

</xsl:template>




<!-- MAIN WEB PAGE IS PRODUCED HERE -->
<xsl:template name="make-component-htmldoc">

    <!-- WEBPAGE BEGIN -->
    <exsl:document href="{@name}.htm" method="html" >
    
    <html>
    <head>
    <title><xsl:value-of select="@name"/> component</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>
    <meta content="Piotr Golonka" name="author"/>

  <style type="text/css">
    <xsl:text disable-output-escaping="yes">
table {width : 95%;}
tr {vertical-align:top;}
td.headLegend {
    background-color : #00cc00;
    vertical-align : top;
    width : 22%;
    font-weight:bold;
}
td.headComponentName {
    vertical-align:top;
    text-align:center;
    font-weight:bold;
}
td.headContent {width: 78%;}
td.tableHead {background-color : #00CC00;font-weight:bold;}
td.desc {width : 50%;}
td.link {width : 50%;}
    </xsl:text>
</style>


    </head>
    
    <body>

<table border="1">
  <tbody>
    <tr>
        <td class="headLegend">Component Name</td>
        <td class="headComponentName"><xsl:value-of select="@name"/></td>
    </tr>
    <tr>
      <td class="headLegend">Description</td>
      <td class="headContent"><p><xsl:value-of select="@desc"/></p>
        <xsl:apply-templates select="description"/>
      </td>
    </tr>
    <tr>
      <td class="headLegend">Dependencies</td>
      <td class="headContent"><ul><xsl:apply-templates select="dependency"/></ul></td>
    </tr>
    <tr>
      <td class="headLegend">Additional software required</td>
      <td class="headContent"><ul><xsl:apply-templates select="requirement"/></ul></td>
    </tr>
  </tbody>
</table>


<br/>



    <xsl:apply-templates select="panels" />	
    <xsl:apply-templates select="libraries"/>	

<br/>


    <xsl:call-template name="make-html-footer"/>

    </body>
    </html>

    </exsl:document>
    <!-- MAIN WEBPAGE END -->

    
</xsl:template>



</xsl:stylesheet>