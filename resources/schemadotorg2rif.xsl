<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0">
    <xsl:output indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:param name="originatingSource">'NO ORIGINATING SOURCE FOUND'</xsl:param>

    <xsl:template match="/">
        <registryObjects xmlns="http://ands.org.au/standards/rif-cs/registryObjects"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd">
            <xsl:apply-templates select="//dataset[type = 'Dataset']"/>
        </registryObjects>
    </xsl:template>

    <xsl:template match="dataset">
        <xsl:element name="registryObject"
            xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="group">
                <xsl:call-template name="getGroup"/>
            </xsl:attribute>
            <xsl:call-template name="getKey"/>
            <xsl:call-template name="getOriginatingSource"/>
            <xsl:element name="collection">
                <xsl:apply-templates select="type"/>
                <xsl:apply-templates select="name"/>
                <xsl:apply-templates select="description"/>

            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template name="getOriginatingSource">
        <xsl:element name="originatingSource"
            xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:choose>
                <xsl:when test="sourceOrganization">
                    <xsl:value-of select="sourceOrganization/name/text()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$originatingSource"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template name="getGroup">
        <xsl:choose>
            <xsl:when test="sourceOrganization">
                <xsl:value-of select="sourceOrganization/name/text()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$originatingSource"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template name="getKey">
        <xsl:element name="key" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:choose>
                <xsl:when test="identifier">
                    <xsl:value-of select="identifier[1]/value/text()"/>
                </xsl:when>
                <xsl:when test="url">
                    <xsl:value-of select="url/text()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="id(current())"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="name">
        <xsl:element name="name" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>primary</xsl:text>
            </xsl:attribute>
            <xsl:element name="namePart" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:value-of select="text()"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="type">
        <xsl:attribute name="type">
            <xsl:text>dataset</xsl:text>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="description">
        <xsl:element name="description" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">brief</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>


    <xsl:template match="@xml:lang">
        <xsl:attribute name="xml:lang">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="@xsi:schemaLocation"/>


</xsl:stylesheet>
