<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:ns2="https://igsn.csiro.au/schemas/3.0"
    version="1.0" exclude-result-prefixes="oai">
<xsl:output indent="yes" method="xml"/>    
    
    <xsl:template match="/">
        <resources xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="https://igsn.csiro.au/schemas/3.0 https://test.ands.org.au/igsn/schemas/3.0/igsn-csiro-v3.0.xsd">
            <xsl:apply-templates select="//ns2:resource"/>
        </resources>
    </xsl:template>
    
    <xsl:template match="node()">
        <xsl:element name="{local-name()}">
            <xsl:apply-templates select="node()|@*"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="ns2:landingPage">
        <xsl:element name="{local-name()}">
            <xsl:value-of select="concat('https://test.identifiers.ardc.edu.au/igsn/#/meta/', preceding-sibling::ns2:resourceIdentifier/text())"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="@*">
        <xsl:copy/>
    </xsl:template>
    
    
    <xsl:template match="text()" priority="1">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    
    
</xsl:stylesheet>