<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
	<html>
	<body>
		<h2>Alarm Help</h2>
		<xsl:for-each select="alarm">
			<h3>
				<xsl:value-of select="title"/>
			</h3>
			<xsl:for-each select="details">
				<xsl:value-of select="general"/>
				<br/><br/>
				<table width="600" border="2" cellpadding="8">
				<xsl:for-each select="level">
					<tr>
					<xsl:variable name="backColour">
					<xsl:choose>
						<xsl:when test="@severity='Warning'">
							<xsl:text>#FFFF00</xsl:text>
						</xsl:when>
						<xsl:when test="@severity='Error'">
							<xsl:text>#FF9900</xsl:text>
						</xsl:when>
						<xsl:when test="@severity='Fatal'">
							<xsl:text>#FF0000</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>#FFFFFF</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
					</xsl:variable>
					<td height="60" bgcolor="{$backColour}"> 
						<b><xsl:value-of select="@severity"/></b>
					</td>
					<td>
						<xsl:value-of select="."/>
					</td>
					</tr>
				</xsl:for-each>
				</table>
				<br/>
			</xsl:for-each>
			<h3>Action</h3>
			<xsl:value-of select="action"/>
			<br/>
			<h3>Contact details</h3>
			<b>Name:</b>&#160;<xsl:value-of select="contact/firstname"/>&#160;<xsl:value-of select="contact/lastname"/><br/>
			<b>Email:</b>&#160;<a href="mailto:{contact/email}" target="blank"><xsl:value-of select="contact/email"/></a><br/>
			<b>Phone:</b>&#160;<xsl:value-of select="contact/phone"/>
		</xsl:for-each>
	</body>
	</html>
</xsl:template>
</xsl:stylesheet>