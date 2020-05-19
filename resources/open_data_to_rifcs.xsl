<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <!-- stylesheet to convert data.gov.au xml (transformed from json with python script) to RIF-CS -->
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>

    
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
            <xsl:value-of select="normalize-space(webUri)"/>
        </xsl:variable>
        <registryObject>
            <xsl:attribute name="group">
                <xsl:value-of select="normalize-space(attribution)"/>
            </xsl:attribute>
            
            <xsl:element name="key">
                 <xsl:value-of select="normalize-space(id)"/>
            </xsl:element>
            
            <originatingSource>
                  <xsl:value-of select="normalize-space(domain)"/>
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
                
                <xsl:if test="string-length(normalize-space(createdAt))">
                    <xsl:attribute name="dateAccessioned">
                        <xsl:value-of select="normalize-space(createdAt)"/>
                    </xsl:attribute>
                </xsl:if>
                
                <xsl:if test="string-length(normalize-space(dataUpdatedAt))">
                    <xsl:attribute name="dateModified">
                        <xsl:value-of select="normalize-space(dataUpdatedAt)"/>
                    </xsl:attribute>
                </xsl:if>  
                <name type="primary">
                    <namePart><xsl:value-of select="normalize-space(name)"/></namePart>
                </name>
                <location>
                    <address>
                        <electronic type="url" target="landingPage">
                            <value><xsl:value-of select="normalize-space(webUri)"/></value>
                        </electronic>
                    </address>
                    <address>
                        <electronic type="url" target="directDownload">
                            <value><xsl:value-of select="normalize-space(dataUri)"/></value>
                        </electronic>
                    </address>
                </location>
                <xsl:for-each select="tags">
                    <subject type="local"><xsl:value-of select="normalize-space(.)"/></subject>
                </xsl:for-each>
                <description type="brief">
                    <xsl:value-of select="normalize-space(description)"/>
                </description>
            </collection>
        </registryObject>
    </xsl:template>
    
</xsl:stylesheet>
