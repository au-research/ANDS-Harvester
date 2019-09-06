<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0">
    <xsl:output indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:param name="originatingSource">'NO ORIGINATING SOURCE FOUND'</xsl:param>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="datasets">
        <registryObjects xmlns="http://ands.org.au/standards/rif-cs/registryObjects"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd">
            <xsl:apply-templates select="dataset"/>
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
                <xsl:apply-templates select="identifier"/>
                <xsl:apply-templates select="title"/>
                <xsl:apply-templates select="description"/>
                <xsl:element name="location">
                    <xsl:element name="address">
                        <xsl:apply-templates select="distribution"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="type">
        <xsl:attribute name="type">
            <xsl:value-of select="substring-after(text(), 'dcat:')"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="licence">
        <xsl:element name="rights"
            xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:element name="licenc">
                <xsl:attribute name="rightsUri"><xsl:value-of select="text()"></xsl:value-of></xsl:attribute>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="getOriginatingSource">
        <xsl:element name="originatingSource"
            xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:choose>
                <xsl:when test="publisher">
                    <xsl:value-of select="publisher/name/text()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$originatingSource"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="landinPage">
        <xsl:element name="electronic" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>url</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="target">
                <xsl:text>landingPage</xsl:text>
            </xsl:attribute>
            <xsl:element name="value"><xsl:value-of select="text()"/></xsl:element>
        </xsl:element>
    </xsl:template>
    
    
    <xsl:template match="identifier">
        <xsl:element name="identifier" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>url</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="text()"/>
        </xsl:element>
    </xsl:template>
    
    
    <xsl:template match="distribution">
        <xsl:element name="electronic" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>url</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="target">
                <xsl:text>directDownload</xsl:text>
            </xsl:attribute>
            <xsl:element name="value"><xsl:value-of select="downloadURL/text()"/></xsl:element>
            <xsl:element name="mediaType"><xsl:value-of select="mediaType/text()"/></xsl:element>
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
                    <xsl:value-of select="identifier/text()"/>
                </xsl:when>
                <xsl:when test="landingPage">
                    <xsl:value-of select="landingPage/text()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="id(current())"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="name | title">
        <xsl:element name="name" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>primary</xsl:text>
            </xsl:attribute>
            <xsl:element name="namePart" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:value-of select="text()"/>
            </xsl:element>
        </xsl:element>
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
