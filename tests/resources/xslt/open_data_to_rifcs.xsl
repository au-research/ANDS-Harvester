<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <!-- stylesheet to convert data.gov.au xml (transformed from json with python script) to RIF-CS -->
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:param name="global_originatingSource" select="'http://data.gov.au'"/>
    <xsl:param name="global_baseURI" select="'http://data.gov.au/'"/>
    <xsl:param name="globalLocalIndicator" select="'upload'"/> <!-- used to determine whether content is local -->
    <xsl:param name="global_group" select="'data.gov.au'"/>
    <xsl:param name="global_contributor" select="'data.gov.au'"/>
    <xsl:param name="global_publisherName" select="'data.gov.au'"/>
    <xsl:param name="global_publisherPlace" select="'Canberra'"/>
    <xsl:param name="global_localParentCollectionPostfix" select="'dataset'"/>
    
    <!-- =========================================== -->
    <!-- dataset (datasets) Template             -->
    <!-- =========================================== -->
    
    
    <xsl:template match="datasets">
        <registryObjects>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="dataset"/>
        </registryObjects>
    </xsl:template>
       
    <xsl:template match="dataset">
        <xsl:variable name="metadataURL">
            <xsl:variable name="name" select="normalize-space(name)"/>
            <xsl:if test="string-length($name)">
                <xsl:value-of select="concat($global_baseURI, 'dataset/', $name)"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="harvestSourceID" select="normalize-space(harvest_source_id)"/>
        <registryObject>
            <xsl:attribute name="group">
                <xsl:value-of select="$global_group"/>
            </xsl:attribute>
            
            <xsl:element name="key">
                <xsl:variable name="guid" select="normalize-space(extras[key = 'guid']/value)"/>
                <xsl:choose>
                    <xsl:when test="string-length($guid) > 0">
                        <xsl:value-of select="$guid"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space(id)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
            
            <originatingSource>
                <xsl:choose>
                    <xsl:when test="string-length(normalize-space(organization/title)) > 0">
                        <xsl:value-of select="normalize-space(organization/title)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$global_originatingSource"/>
                    </xsl:otherwise>
                </xsl:choose>
            </originatingSource>
            
            <collection>
                
                <xsl:variable name="collectionType" select="normalize-space(type)"/>
                <xsl:attribute name="type">
                    <xsl:choose>
                        <xsl:when test="string-length($collectionType)">
                            <xsl:value-of select="$collectionType"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>dataset</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                
                <xsl:if test="string-length(normalize-space(metadata_created))">
                    <xsl:attribute name="dateAccessioned">
                        <xsl:value-of select="normalize-space(metadata_created)"/>
                    </xsl:attribute>
                </xsl:if>
                
                <xsl:if test="string-length(normalize-space(metadata_modified))">
                    <xsl:attribute name="dateModified">
                        <xsl:value-of select="normalize-space(metadata_modified)"/>
                    </xsl:attribute>
                </xsl:if>               
            </collection>
        </registryObject>
    </xsl:template>
    
</xsl:stylesheet>
