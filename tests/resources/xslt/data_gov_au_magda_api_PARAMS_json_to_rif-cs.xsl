<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:custom="http://custom.nowhere.yet"
    xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
    <!-- stylesheet to convert data.aurin.gov.au xml (transformed from json with python script) to RIF-CS -->
    <xsl:import href="MagdaAPI_json_to_rif-cs.xsl"/>
    
    <xsl:strip-space elements="*"/>
    <xsl:param name="global_acronym" select="'data.gov.au'"/>
    <xsl:param name="global_originatingSource" select="'http://data.gov.au'"/>
    <xsl:param name="global_baseURI" select="'http://data.gov.au/'"/>
    <xsl:param name="global_group" select="'data.gov.au'"/>
    <xsl:param name="global_contributor" select="'data.gov.au'"/>
    <xsl:param name="global_publisherName" select="'data.gov.au'"/>
    <xsl:param name="global_publisherPlace" select="'Australia'"/>
    <xsl:param name="global_includeDownloadLinks" select="false()"/>

    <xsl:template match="/">
        <!-- include all records except those with scopecode 'Document'-->
        <registryObjects>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd</xsl:text>
            </xsl:attribute>
            <xsl:for-each select="//*[contains(local-name(), 'dataSets')]">
                <xsl:apply-templates select="." mode="all"/>
            </xsl:for-each>
        </registryObjects>
    </xsl:template>
    
    <!--
    <xsl:template match="*[contains(local-name(), 'dataSets')]"  mode="extras">
        <xsl:message select="'Template extras override in top-level custom xslt'"/>
        <xsl:for-each select="extras">
            <xsl:apply-templates select=".[contains(key, 'spatial')]" mode="spatial"/>
            <xsl:apply-templates select=".[contains(key, 'Coordinate Ref. System')]" mode="CRS"/>
            <xsl:apply-templates select=".[contains(key, 'Copyright Notice')]" mode="copyright"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="extras" mode="spatial">
        <xsl:for-each select="value">
            <xsl:call-template name="spatial_coordinates"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="extras" mode="CRS">
        <xsl:for-each select="value">
            <coverage>
                <spatial type="text">
                    <xsl:value-of select="."/>
                </spatial>
            </coverage>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="extras" mode="copyright">
        <xsl:for-each select="value">
            <rights>
                <rightsStatement>
                    <xsl:value-of select="."/>
                </rightsStatement>
            </rights>
        </xsl:for-each>
    </xsl:template>
    
    -->
</xsl:stylesheet>

