<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" exclude-result-prefixes="dc">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <xsl:template match="/">
        <registryObjects xmlns="http://ands.org.au/standards/rif-cs/registryObjects" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd">
            <xsl:apply-templates select="//oai:record" mode="collection"/>
            <xsl:apply-templates select="//oai:record" mode="activity"/>
        </registryObjects>
    </xsl:template>

    <!--
    <xsl:template match="record">
        <xsl:variable name="key" select="header/identifier/text()"/>
        <xsl:variable name="class" select="substring-after(oai:header/oai:setSpec[starts-with(text(),'class:')]/text(),'class:')"/>
            <xsl:apply-templates select="oai:metadata/dc:dc">
                <xsl:with-param name="key" select="$key"/>
                <xsl:with-param name="class" select="$class"/>
            </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="oai:setSpec">
        <xsl:variable name="key" select="oai:header/oai:identifier/text()"/>
        <xsl:variable name="class" select="oai:header/oai:identifier/text()"/>
        <xsl:apply-templates select="oai:metadata/dc:dc">
            <xsl:with-param name="key" select="$key"/>
        </xsl:apply-templates>
    </xsl:template>
    -->

    <xsl:template match="oai:record" mode="collection">

        <xsl:param name="key" select="oai:header/oai:identifier/text()"/>
        <xsl:param name="class" select="'collection'"/>
        <xsl:param name="type" select="'dataset'"/>
        <xsl:param name="originatingSource" select="'Edith Cowan University'"/>

        <registryObject xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="group"><xsl:value-of select="$originatingSource"/></xsl:attribute>
            <key xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:value-of select="$key"/>
            </key>
            <originatingSource><xsl:value-of select="$originatingSource"/></originatingSource>
            <xsl:element name="{$class}">

                <xsl:attribute name="type"><xsl:value-of select="$type"/></xsl:attribute>
                <xsl:apply-templates select="oai:metadata" mode="collection"/>

            </xsl:element>
        </registryObject>
    </xsl:template>

    <xsl:template match="oai:record" mode="activity">

        <xsl:param name="key" select="oai:header/oai:identifier/text()"/>
        <xsl:param name="class" select="'activity'"/>
        <xsl:param name="type" select="'project'"/>
        <xsl:param name="originatingSource" select="'Edith Cowan University'"/>


        <xsl:choose>
            <xsl:when test=".//field[@name='research_title']/value">
                <xsl:choose>
                    <xsl:when test=".//field[@name='research_description']/value">
                        <registryObject xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                            <xsl:attribute name="group"><xsl:value-of select="$originatingSource"/></xsl:attribute>
                            <key xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                                <xsl:value-of select="concat($key, ':activity')"/>
                            </key>
                            <originatingSource><xsl:value-of select="$originatingSource"/></originatingSource>
                            <xsl:element name="{$class}">
                                <xsl:attribute name="type"><xsl:value-of select="$type"/></xsl:attribute>
                                <xsl:apply-templates select="oai:metadata" mode="activity"/>
                                <relatedObject>
                                  <key><xsl:value-of select="$key"/></key>
                                  <relation type="hasOutput"/>
                                </relatedObject>
                            </xsl:element>
                        </registryObject>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="oai:metadata | document-export | documents"
                  mode="collection">
      <xsl:apply-templates mode="collection"/>
    </xsl:template>

    <xsl:template match="oai:metadata | document-export | documents"
                  mode="activity">
      <xsl:apply-templates mode="activity"/>
    </xsl:template>

    <xsl:template match="document" mode="collection">
      <xsl:apply-templates select="title"/>
      <xsl:apply-templates select="fields/field[@name='doi']/value"/>
      <xsl:apply-templates select="abstract"/>
      <xsl:apply-templates select="fields/field[@name='addl_info']/value"/>
      <xsl:apply-templates select="fields/field[@name='rights']/value"/>
      <xsl:apply-templates select="fields/field[@name='coverage']/value"/>
      <xsl:apply-templates select="keywords"/>
      <xsl:apply-templates select="disciplines"/>
      <xsl:apply-templates select="fields/field[@name='for_code']"/>
      <xsl:apply-templates select="fields/field[@name='longitude']"/>
      <xsl:apply-templates select="fields/field[@name='custom_citation']/value"/>
      <xsl:apply-templates select="fields/field[@name='related_content']"/>
      <xsl:apply-templates select="fields/field[@name='project_links']"/>
      <xsl:apply-templates select="fields/field[@name='contact']"/>
      <xsl:apply-templates select="fields/field[@name='comments']/value"/>
      <xsl:apply-templates select="coverpage-url"/>
    </xsl:template>

    <xsl:template match="document" mode="activity">
      <xsl:apply-templates select="fields/field[@name='research_title']/value"/>
      <xsl:apply-templates select="fields/field[@name='research_description']/value"/>
      <xsl:apply-templates select="keywords"/>
      <xsl:apply-templates select="disciplines"/>
      <xsl:apply-templates select="fields/field[@name='for_code']"/>
      <xsl:apply-templates select="fields/field[@name='related_content']"/>
      <xsl:apply-templates select="fields/field[@name='project_links']"/>
      <xsl:apply-templates select="fields/field[@name='contact']"/>
      <xsl:apply-templates select="fields/field[@name='comments']/value"/>
      <xsl:apply-templates select="coverpage-url"/>
    </xsl:template>

    
    <xsl:template match="title">
        <name type="full" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <namePart>
                <xsl:value-of select="."/>
            </namePart>
        </name>
    </xsl:template>

    <xsl:template match="field[@name='research_title']/value">
        <name type="primary" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <namePart>
                <xsl:value-of select="."/>
            </namePart>
        </name>
    </xsl:template>

    <xsl:template match="field[@name='research_description']/value">
        <description type="full" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:value-of select="."/>
        </description>
    </xsl:template>


    <!--
    <xsl:template match="document-type">
        <type xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:value-of select="."/>
        </type>
    </xsl:template>
    -->

    <xsl:template match="field[@name='doi']/value">
        <identifier type="doi" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:value-of select="."/>
        </identifier>
    </xsl:template>

    <xsl:template match="field[@name='comments']/value">

        <xsl:for-each select="p/a">
            <xsl:choose>
                <xsl:when test="contains(./@href, 'scopus')">
                    <relatedInfo type="party" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                        <identifier type="uri">
                            <xsl:value-of select="./@href"/>
                        </identifier>
                    </relatedInfo>
                </xsl:when>
                <xsl:when test="contains(./@href, 'researcherid')">
                    <relatedInfo type="party" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                        <identifier type="uri">
                            <xsl:value-of select="./@href"/>
                        </identifier>
                    </relatedInfo>
                </xsl:when>
                <xsl:when test="contains(./@href, 'orchid')">
                    <relatedInfo type="party" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                        <identifier type="orchid">
                            <xsl:value-of select="./@href"/>
                        </identifier>
                    </relatedInfo>
                </xsl:when>
                <xsl:when test="contains(./@href, 'nla')">
                    <relatedInfo type="party" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                        <identifier type="AU-ANL:PEAU">
                            <xsl:value-of select="./@href"/>
                        </identifier>
                    </relatedInfo>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>

    </xsl:template>

    <!--
    <xsl:template match="field[@name='persistent_identifier']/value">
        <xsl:variable name="identifier">
            <xsl:choose>
                <xsl:when test="contains(text(), ')')">
                    <xsl:value-of select="substring-after(text(),') ')"/>
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
    -->
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

    <xsl:template match="field[@name='addl_info']/value">
        <description type="note" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:value-of select="."/>
        </description>
    </xsl:template>

    <xsl:template match="field[@name='rights']/value">
        <description type="accessRights" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:value-of select="."/>
        </description>
    </xsl:template>

    <xsl:template match="field[@name='coverage']/value">
        <coverage xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <temporal type="text">
                <xsl:value-of select="."/>
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

    <xsl:template match="field[@name='longitude']">
        <location xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <spatial type="kmlPolyCoords">
                <xsl:value-of select="value"/>,<xsl:value-of select="preceding-sibling::field[@name='latitude']/value"/>
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

    <xsl:template match="disciplines">

        <xsl:for-each select="discipline">
            <subject type="local" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:value-of select="."/>
            </subject>
        </xsl:for-each>

    </xsl:template>

    <xsl:template match="field[@name='for_code']">

        <xsl:for-each select="value">
            <subject type="anzsrc-for" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:value-of select="."/>
            </subject>
        </xsl:for-each>

    </xsl:template>

    <xsl:template match="field[@name='custom_citation']/value">

        <citationInfo xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <fullCitation xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:value-of select="."/>
            </fullCitation>
        </citationInfo>

    </xsl:template>

    <xsl:template match="field[@name='related_content']">

        <xsl:analyze-string select="value" regex="href=&quot;(http.+?)&quot;">
          <xsl:matching-substring>
            <relatedInfo type="publication" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <identifier type="uri">
                    <xsl:value-of select="regex-group(1)"/>
                </identifier>
            </relatedInfo>
          </xsl:matching-substring>
        </xsl:analyze-string>

    </xsl:template>

    <xsl:template match="field[@name='project_links']">

        <xsl:analyze-string select="value" regex="href=&quot;(http.+?)&quot;">
          <xsl:matching-substring>
            <relatedInfo type="activity" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <identifier type="uri">
                    <xsl:value-of select="regex-group(1)"/>
                </identifier>
            </relatedInfo>
          </xsl:matching-substring>
        </xsl:analyze-string>
        
    </xsl:template>

    <xsl:template match="field[@name='contact']">

        <xsl:for-each select="value">
            <location xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <address >
                    <electronic type="email">
                        <value>
                            <xsl:value-of select="."/>
                        </value>
                    </electronic>
                </address>
            </location>
        </xsl:for-each>

    </xsl:template>

    <xsl:template match="coverpage-url">
        <location xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <address >
                <electronic type="url">
                    <value>
                        <xsl:value-of select="."/>
                    </value>
                </electronic>
            </address>
        </location>
    </xsl:template>

    <xsl:template match="node() | text() | @*"/>

</xsl:stylesheet>
