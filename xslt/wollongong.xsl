<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" exclude-result-prefixes="dc">

    
    <xsl:template match="/">
        <registryObjects xmlns="http://ands.org.au/standards/rif-cs/registryObjects" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd">
            <xsl:apply-templates select="//oai:record"/>
        </registryObjects>
    </xsl:template>

    <!--xsl:template match="record">
        <xsl:variable name="key" select="header/identifier/text()"/>
        <xsl:variable name="class" select="substring-after(oai:header/oai:setSpec[starts-with(text(),'class:')]/text(),'class:')"/>
            <xsl:apply-templates select="oai:metadata/dc:dc">
                <xsl:with-param name="key" select="$key"/>
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
    </xsl:template-->

    <xsl:template match="oai:setSpec">
        <xsl:variable name="key" select="oai:header/oai:identifier/text()"/>
        <xsl:variable name="class" select="oai:header/oai:identifier/text()"/>
        <xsl:apply-templates select="oai:metadata/dc:dc">
            <xsl:with-param name="key" select="$key"/>
        </xsl:apply-templates>
    </xsl:template>
    

    <xsl:template match="oai:record">

        <xsl:param name="key" select="oai:header/oai:identifier/text()"/>
        <xsl:param name="class" select="'collection'"/>
        <xsl:param name="type" select="'dataset'"/>
        <xsl:param name="originatingSource" select="'University of Wollongong'"/>

        <registryObject xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="group"><xsl:value-of select="$originatingSource"/></xsl:attribute>
            <key xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:value-of select="$key"/>
            </key>
            <originatingSource><xsl:value-of select="$originatingSource"/></originatingSource>
            <xsl:element name="{$class}">
                <xsl:attribute name="type"><xsl:value-of select="$type"/></xsl:attribute>               
                <xsl:apply-templates select="oai:metadata/document-export/documents/document/title"/>
                <xsl:apply-templates select="oai:metadata/document-export/documents/document/fields/field[@name='persistent_identifier']/value"/>
                <xsl:apply-templates select="oai:metadata/document-export/documents/document/abstract"/>
                <xsl:apply-templates select="oai:metadata/document-export/documents/document/fields/field[@name='rights']/value"/>
                <xsl:apply-templates select="oai:metadata/document-export/documents/document/fields/field[@name='date_range']/value"/>
                <xsl:apply-templates select="oai:metadata/document-export/documents/document/keywords"/>
                <xsl:apply-templates select="oai:metadata/document-export/documents/document/fields/field[@name='for']"/>
                <xsl:apply-templates select="oai:metadata/document-export/documents/document/fields/field[@name='longitude']/value"/>
            </xsl:element>
        </registryObject>
    </xsl:template>

    <xsl:template match="title">
        <name type="full" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <namePart>
                <xsl:value-of select="."/>
            </namePart>
        </name>
    </xsl:template>

    <xsl:template match="field[@name='persistent_identifier']/value">
        
        <xsl:variable name="identifier">
            <xsl:choose>
                <xsl:when test="contains(text(), ')')">
                    <xsl:value-of select="substring-after(text(),') ')"/>
                </xsl:when>
                <xsl:when test="contains(text(), 'href=')">
                    <xsl:value-of select="substring-before(substring-after(text(),'href=&quot;'), '&quot;')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="identifierType">
            <xsl:choose>
                <xsl:when test="contains(text(), ')')">
                    <xsl:value-of select="substring-after(substring-before(text(),')'),'(')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'uri'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <identifier type="{$identifierType}" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:value-of select="$identifier"/>
        </identifier>
    </xsl:template>

    <!--
    <xsl:template match="authors">
        <relatedObject xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:variable name="relatedKey">
                <xsl:choose>
                    <xsl:when test="contains(text(), '(')">
                        <xsl:value-of select="substring-before(text(),' (')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="text()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="relationType">
                <xsl:choose>
                    <xsl:when test="contains(text(), '(')">
                        <xsl:value-of select="substring-before(substring-after(text(),' ('),')')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'hasAssociationWith'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <key><xsl:value-of select="$relatedKey"/></key>
            <relation type="{$relationType}"/>
        </relatedObject>
    </xsl:template>
    -->

    <xsl:template match="abstract">
        <description type="full" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:value-of select="."/>
        </description>
    </xsl:template>

    <xsl:template match="field[@name='rights']/value">
        <description type="right" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:value-of select="."/>
        </description>
    </xsl:template>

    <xsl:template match="field[@name='date_range']/value">
        <coverage xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <temporal>
                <text>
                    <xsl:value-of select="."/>
                </text>
            </temporal>
        </coverage>
    </xsl:template>

    <!--
    <xsl:template match="dc:coverage[starts-with(.,'Spatial: ')]">
        <coverage xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <spatial type="text">
                <xsl:value-of select="substring-after(.,'Spatial:')"/>
            </spatial>
        </coverage>
    </xsl:template>
    -->

    <xsl:template match="field[@name='longitude']/value">
        <location xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <spatial type="kmlPolyCoords">
                <xsl:value-of select="."/>,<xsl:value-of select="//field[@name='latitude']/value"/>
            </spatial>
        </location>
    </xsl:template>

    <xsl:template match="keywords">

        <xsl:for-each select="keyword">
            <subject type="local" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:value-of select="."/>
            </subject>
        </xsl:for-each>

    </xsl:template>

    <xsl:template match="field[@name='for']">

        <xsl:for-each select="value">
            <subject type="anzsrc-for" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:value-of select="."/>
            </subject>
        </xsl:for-each>

    </xsl:template>

    <xsl:template match="node() | text() | @*" priority="-999"/>



</xsl:stylesheet>