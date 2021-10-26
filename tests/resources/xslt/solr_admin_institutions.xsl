<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output method="xml" version="1.0" encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>    
    
    <xsl:template match="/">
        <xsl:apply-templates select="/response/result"/>
    </xsl:template>
    
    
    <xsl:template match="result">
        <institutions>
       <xsl:apply-templates select="doc"/> 
        </institutions>
    </xsl:template>
    
    <!-- 
    
  <doc>
    <str name="title">Australian Maritime College</str>
    <str name="group">Trove - People and Organisations</str>
    <arr name="identifier_value">
      <str>http://nla.gov.au/nla.party-620215</str>
    </arr>
    <str name="key">http://nla.gov.au/nla.party-620215</str></doc>
  <doc>
    
    -->  
    
    <xsl:template match="doc">
        <!-- don't add duplicate institutions to the output document -->
        <xsl:if test="not(preceding-sibling::doc/str[@name='title'] = str[@name='title'])">
            <institution>
                <name><xsl:value-of select="str[@name='title']/text()"/></name>
                <key><xsl:value-of select="str[@name='key']/text()"/></key>
            </institution>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>