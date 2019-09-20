<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0">

<xsl:import href="schemadotorg2rif.xsl"/>
    <!-- 
    westlimit=-3.5; southlimit=-56; eastlimit=-2.25; northlimit=-54; projection=WGS84
    southlimit=-3.5; westlimitt=-56; northlimit=-2.25; eastlimit=-54; projection=WGS84
    
    westlimit=52.9; southlimit=-106.91; eastlimit=54.78; northlimit=-103.43; projection=WGS84
    southlimit=52.9; westlimitt=-106.91; northlimit=54.78; eastlimit=-103.43;
    
    -->
    <xsl:template match="box">
        <xsl:attribute name="type">
            <xsl:text>iso19139dcmiBox</xsl:text>
        </xsl:attribute>
        <xsl:variable name="coords" select="tokenize(text(),'\s?[, ]\s?')" as="xs:string*"/>
        <xsl:value-of select="concat('southlimit=',$coords[1], '; westlimit=', $coords[2], '; northlimit=', $coords[3], '; eastlimit=', $coords[4],'; projection=WGS84')"/>
    </xsl:template>
    
</xsl:stylesheet>