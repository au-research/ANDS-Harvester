<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rif="http://ands.org.au/standards/rif-cs/registryObjects" xmlns:oai="http://www.openarchives.org/OAI/2.0/" version="2.0">
    <xsl:output encoding="UTF-8" indent="yes" media-type="xml" omit-xml-declaration="yes"/>
    <xsl:template match='/'>
            <xsl:apply-templates select="response/zone/records/work"/>
    </xsl:template>
    
    <xsl:template match="work">
        <xsl:message><xsl:text>work is </xsl:text><xsl:value-of select="title"/></xsl:message>
        <xsl:apply-templates select="version/record/metadata"/>
    </xsl:template>
    
    <xsl:template match="metadata">
        <xsl:message><xsl:text>Metadata for </xsl:text><xsl:value-of select=".//title"/></xsl:message>
        <xsl:variable name="title" select=".//title"/>
        <xsl:variable name="identifier" select=".//identifier[contains(text(),'http')]"/>
        <xsl:variable name="bibnotes" select=".//bibliographicCitation"/>
        <xsl:variable name="notes" select=".//description"/>
        <xsl:for-each select=".//relation[contains(text(),'au-research/grants')]">
            <xsl:element name="grantPubInfo">
                <xsl:element name="grantKey"><xsl:value-of select="normalize-space(.)"/></xsl:element>
                <xsl:element name="relatedInfo" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                    <xsl:attribute name="type"><xsl:text>publication</xsl:text></xsl:attribute> 
                    <xsl:element name="title"><xsl:value-of select="$title"/></xsl:element>
                    <xsl:element name="identifier">
                        <xsl:attribute name="type"><xsl:text>url</xsl:text></xsl:attribute>
                        <xsl:value-of select="$identifier[position()=1]"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>  
    </xsl:template>
    
</xsl:stylesheet>