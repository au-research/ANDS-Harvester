<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ro="http://ands.org.au/standards/rif-cs/registryObjects" exclude-result-prefixes="ro">

    <!-- stylesheet to convert discover.data.vic.gov.au xml (transformed from json with python script) to RIF-CS -->
    <xsl:output method="xml" version="1.0" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
    <xsl:strip-space elements="*"/>

    <!-- ARC GRANTs Publications are harvested from Trove and cached for 30 days -->
    <xsl:param name="arc_grantpubs_file" select="'/media/leo/work/ARC_XSLT/arc_grantpubs_2021.xml'"/>
    <!-- Administering Institutions are pulled from SOLR every time a harvest is run (shouldn't be cached)-->
    <xsl:param name="admin_institutions_file" select="'arc_admin_institutions.xml'"/>


    <xsl:variable name="adminInstitutions" select="document($admin_institutions_file)"/>
    <xsl:variable name="grantpubs" select="document($arc_grantpubs_file)"/>

    <!-- these files should be added at the dtatasource setting page as supporting XML documents -->
    <xsl:variable name="titles" select="document('/media/leo/work/ARC_XSLT/arc_project_titles.xml')"/>

    <xsl:variable name="global_originatingSource"
        >https://dataportal.arc.gov.au/NCGP/API/grants/</xsl:variable>
    <xsl:variable name="purl_url">http://purl.org/au-research/grants/arc/</xsl:variable>
    <xsl:variable name="global_baseURI"
        >https://dataportal.arc.gov.au/NCGP/API/grants/</xsl:variable>
    <xsl:variable name="global_group">Australian Research Council</xsl:variable>
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- =========================================== -->
    <!-- grant (grants) Template             -->
    <!-- =========================================== -->

    <xsl:template match="grants">
        <registryObjects xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="grant" mode="activity"/>
        </registryObjects>
    </xsl:template>


    <xsl:template match="grant" mode="activity">
        <xsl:variable name="ro_key" select="concat($purl_url, normalize-space(id))"/>
        <xsl:variable name="grant_id" select="normalize-space(id)"/>
        <registryObject xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="group">
                <xsl:value-of select="$global_group"/>
            </xsl:attribute>
            <key>
                <xsl:value-of select="$ro_key"/>
            </key>
            <originatingSource>
                <xsl:value-of select="$global_originatingSource"/>
            </originatingSource>

            <activity xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:variable name="activityType" select="normalize-space(type)"/>
                <xsl:attribute name="type">
                    <xsl:text>grant</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="id" mode="activity_identifier"/>

                
                <xsl:variable name="title" select="$titles/root/row[Project_ID/text()=$grant_id]/Project_Title"/>
                
                <xsl:choose>
                    <xsl:when test="$title != ''">
                        <xsl:message><xsl:value-of select="$title"/></xsl:message>
                        <xsl:element name="name">
                            <xsl:attribute name="type">primary</xsl:attribute>
                            <xsl:element name="namePart">
                                <xsl:value-of  select="$title"/>
                            </xsl:element>
                        </xsl:element>                       
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="name">
                            <xsl:attribute name="type">primary</xsl:attribute>
                            <xsl:element name="namePart"><xsl:value-of select="attributes/scheme-name"/><xsl:text> - Grant ID: </xsl:text><xsl:value-of select="id"/></xsl:element>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:apply-templates select="id" mode="activity_url"/>
                
                <xsl:apply-templates select="attributes/grant-summary"/>
                <!-- related publications -->
                <xsl:variable name="pubinfo"
                    select="$grantpubs/troveGrants/grantPubInfo[grantKey = $ro_key]"/>
                <xsl:if test="$pubinfo">
                    <xsl:text>&#xA;</xsl:text>
                    <xsl:copy-of select="$pubinfo/ro:relatedInfo"/>

                </xsl:if>

            </activity>

        </registryObject>
    </xsl:template>



    <!-- =========================================== -->
    <!-- Activity RegistryObject - Child Templates -->
    <!-- =========================================== -->

    <!-- Collection - Identifier Element  -->
    <xsl:template match="id" mode="activity_identifier">
        <identifier xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>arc</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="normalize-space(.)"/>
        </identifier>
        <identifier xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>purl</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="concat($purl_url, normalize-space(.))"/>
        </identifier>
    </xsl:template>

    <!-- Collection - Name Element  -->
    <xsl:template match="id" mode="activity_name">
        <xsl:if test="string-length(normalize-space(.))">
            <name xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
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
        <location xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <address>
                <electronic>
                    <xsl:attribute name="type">
                        <xsl:text>url</xsl:text>
                    </xsl:attribute>
                    <value>
                        <xsl:value-of select="$global_baseURI"/>
                        <xsl:value-of select="normalize-space(.)"/>
                    </value>
                </electronic>
            </address>
        </location>
    </xsl:template>

    <xsl:template match="grant-summary">
        <description xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>brief</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="."/>
        </description>
    </xsl:template>


</xsl:stylesheet>
