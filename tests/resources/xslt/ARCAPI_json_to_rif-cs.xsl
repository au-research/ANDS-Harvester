<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:custom="http://custom.nowhere.yet"   
    xmlns:local="http://local.nowhere.yet"   
    xmlns="http://ands.org.au/standards/rif-cs/registryObjects"
    exclude-result-prefixes="custom">
    
    <!-- stylesheet to convert discover.data.vic.gov.au xml (transformed from json with python script) to RIF-CS -->
    <xsl:output method="xml" version="1.0" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:variable name="global_originatingSource">ARC dataportal API</xsl:variable>
    <xsl:variable name="global_baseURI">https://dataportal.arc.gov.au/NCGP/API/grants/</xsl:variable>
    <xsl:variable name="global_group">ARC_Grants</xsl:variable>     
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

     <!-- =========================================== -->
    <!-- grant (grants) Template             -->
    <!-- =========================================== -->

    <xsl:template match="grants">
        <registryObjects>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="grant" mode="activity"/>
         </registryObjects>
    </xsl:template>
   

    <xsl:template match="grant" mode="activity">
        
        <registryObject>
            <xsl:attribute name="group">
                <xsl:value-of select="$global_group"/>
            </xsl:attribute>
            <xsl:apply-templates select="id" mode="activity_key"/>

            <originatingSource>
                <xsl:choose>
                    <xsl:when test="string-length(normalize-space(publisher/source/name)) > 0">
                        <xsl:value-of select="normalize-space(publisher/source/name)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$global_originatingSource"/>
                    </xsl:otherwise>
                </xsl:choose>
            </originatingSource>

            <activity>
                <xsl:variable name="activityType" select="normalize-space(type)"/>
                <xsl:attribute name="type">
                      <xsl:text>grant</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="id" mode="activity_identifier"/>
                <xsl:apply-templates select="id" mode="activity_name"/>
                <xsl:apply-templates select="id" mode="activity_url"/>
                <xsl:apply-templates select="attributes" mode="activity_description"/>
                           
            </activity>

        </registryObject>
    </xsl:template>



    <!-- =========================================== -->
    <!-- Activity RegistryObject - Child Templates -->
    <!-- =========================================== -->

    <!-- Collection - Key Element  -->
    <xsl:template match="id" mode="activity_key">
        <xsl:if test="string-length(normalize-space(.))">
            <key>
                <xsl:value-of select="."/>
            </key>
        </xsl:if>
    </xsl:template>

    <!-- Collection - Identifier Element  -->
    <xsl:template match="id" mode="activity_identifier">
            <identifier>
                <xsl:attribute name="type">
                    <xsl:text>local</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="normalize-space(.)"/>
            </identifier>
            <identifier>
                <xsl:attribute name="type">
                    <xsl:text>uri</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$global_baseURI"/><xsl:value-of select="normalize-space(.)"/>
            </identifier>      
    </xsl:template>

    <!-- Collection - Name Element  -->
    <xsl:template match="id" mode="activity_name">
        <xsl:if test="string-length(normalize-space(.))">
            <name>
                <xsl:attribute name="type">
                    <xsl:text>primary</xsl:text>
                </xsl:attribute>
                <namePart>
                    <xsl:value-of select="normalize-space(.)"/>
                    
                </namePart>
            </name>
        </xsl:if>
    </xsl:template>

    <xsl:template match="id" mode="activity_url">
            <location>
                <address>
                    <electronic>
                        <xsl:attribute name="type">
                            <xsl:text>url</xsl:text>
                        </xsl:attribute>
                         <value>
                            <xsl:value-of select="$global_baseURI"/><xsl:value-of select="normalize-space(.)"/>
                        </value>
                    </electronic>
                </address>
            </location>
    </xsl:template>
    
    <xsl:template match="attributes" mode="activity_description">
        <description>
            <xsl:attribute name="type">
                <xsl:text>brief</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="./grant-summary"/>
        </description>
    </xsl:template>

    
</xsl:stylesheet>
