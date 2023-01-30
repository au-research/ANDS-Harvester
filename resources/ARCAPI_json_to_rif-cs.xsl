<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ro="http://ands.org.au/standards/rif-cs/registryObjects" exclude-result-prefixes="ro">

    <!-- stylesheet to convert discover.data.vic.gov.au xml (transformed from json with python script) to RIF-CS -->
    <xsl:output method="xml" version="1.0" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
    <xsl:strip-space elements="*"/>

    <!-- ARC GRANTs Publications are harvested from Trove and cached for 30 days -->
    <xsl:param name="arc_grantpubs_file" select="'/var/data/harvester/harvested_contents/arc_grantpubs.xml'"/>
    <!-- Administering Institutions are pulled from SOLR every time a harvest is run (shouldn't be cached)-->
    <xsl:param name="admin_institutions_file" select="'/var/data/harvester/harvested_contents/arc_admin_institutions.xml'"/>

    <xsl:variable name="adminInstitutions" select="document($admin_institutions_file)"/>
    
    <xsl:variable name="grantpubs" select="document($arc_grantpubs_file)"/>

    <!-- these files should be added at the datatasource setting page as supporting XML documents -->
    <xsl:variable name="titles" select="document('arc_project_titles.xml')"/>

    <xsl:variable name="global_originatingSource"
        >https://dataportal.arc.gov.au/NCGP/API/grants/</xsl:variable>
    <xsl:variable name="purl_url">http://purl.org/au-research/grants/arc/</xsl:variable>
    <xsl:variable name="global_baseURI"
        >https://dataportal.arc.gov.au/NCGP/Web/Grant/Grant/</xsl:variable>
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
                <xsl:text>http://ands.org.au/standards/rif-cs/registryObjects https://researchdata.edu.au/documentation/rifcs/schema/registryObjects.xsd</xsl:text>
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

<!-- title added if found in an existing list we stored before ARC stopped providing them -->
                <xsl:variable name="title" select="$titles/root/row[Project_ID/text() = $grant_id]/Project_Title"/>

                <xsl:choose>
                    <xsl:when test="$title != ''">
                        <!--xsl:message>
                            <xsl:value-of select="$title"/>
                        </xsl:message-->
                        <xsl:element name="name">
                            <xsl:attribute name="type">primary</xsl:attribute>
                            <xsl:element name="namePart">
                                <xsl:value-of select="$title"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="name">
                            <xsl:attribute name="type">primary</xsl:attribute>
                            <xsl:element name="namePart">
                                <xsl:value-of select="attributes/scheme-name"/>
                                <xsl:text> - Grant ID: </xsl:text>
                                <xsl:value-of select="id"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>

                <!-- add electronic address to the grant page not the API endpoint -->
                <xsl:apply-templates select="id" mode="activity_url"/>

                <!--   existenceDates are added from project-start-date and anticipated-end-date -->           

                <xsl:if test="attributes/project-start-date/text() != ''">
                    <xsl:element name="existenceDates" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                        <xsl:element name="startDate">
                            <xsl:attribute name="dateFormat">W3CDTF</xsl:attribute>
                            <xsl:value-of select="attributes/project-start-date/text()"/>
                        </xsl:element>
                        <xsl:if test="attributes/anticipated-end-date">
                            <xsl:element name="endDate">
                                <xsl:attribute name="dateFormat">W3CDTF</xsl:attribute>
                                <xsl:value-of select="attributes/anticipated-end-date/text()"/>
                            </xsl:element>
                        </xsl:if>
                    </xsl:element>
                </xsl:if>


                <!-- grant summary and cheme added as descriptions -->
                <xsl:apply-templates select="attributes/grant-summary"/>
                <xsl:apply-templates select="attributes/funding-at-announcement"/>
                <xsl:apply-templates select="attributes/scheme-name"/>
                <!-- investigators without ORCID go in to descriptions -->
                <!--xsl:apply-templates select="attributes/investigators-at-announcement[orcidIdentifier = 'null'][1]" mode="description"/-->
                <!-- FOR and SEO codes added as subjects -->
                <xsl:apply-templates select="attributes/field-of-research"/>
                <xsl:apply-templates select="attributes/socio-economic-objective"/>


                <!-- add ARC as Funder-->
                <relatedObject>
                    <key>http://dx.doi.org/10.13039/501100000923</key>
                    <relation type="isFundedBy"/>
                </relatedObject>


                <!-- administering institution -->

                <xsl:apply-templates select="attributes/announcement-administering-organisation"/>
                <!-- investigators with ORCID added as related info -->
                <xsl:apply-templates select="attributes/investigators-at-announcement" mode="relatedInfo"/>

                <!-- related publications that were harvested from Trove are added as relatedInfo type publication to the activity -->
                <xsl:for-each select="$grantpubs/troveGrants/grantPubInfo[grantKey = $ro_key]">
                    <xsl:copy-of select="ro:relatedInfo"/>
                </xsl:for-each>
            </activity>

        </registryObject>
    </xsl:template>



    <!-- =========================================== -->
    <!-- Activity RegistryObject - Child Templates -->
    <!-- =========================================== -->


    <xsl:template match="field-of-research">
        <xsl:element name="subject" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">anzsrc-for</xsl:attribute>
            <xsl:value-of select="normalize-space(code)"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="socio-economic-objective">
        <xsl:element name="subject" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">anzsrc-seo</xsl:attribute>
            <xsl:value-of select="normalize-space(code)"/>
        </xsl:element>
    </xsl:template>



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

    <!-- Name Element  -->
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
                    <xsl:attribute name="target">
                        <xsl:text>landingPage</xsl:text>
                    </xsl:attribute>
                    <value>
                        <xsl:value-of select="$global_baseURI"/>
                        <xsl:value-of select="normalize-space(.)"/>
                    </value>
                </electronic>
            </address>
        </location>
    </xsl:template>


    <xsl:template match="investigators-at-announcement" mode="relatedInfo">
        <xsl:element name="relatedInfo" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">party</xsl:attribute> 
            <xsl:element name="title"><xsl:value-of select="concat(title, ' ' , firstName, ' ', familyName)"/></xsl:element>
            <xsl:choose>
                <xsl:when test="normalize-space(orcidIdentifier/text()) = 'null' or normalize-space(orcidIdentifier/text()) = ''">
                    <xsl:variable name="local_identifier" select="lower-case(concat(title, '_' , firstName, '_', familyName))"/>
                    <xsl:variable name="remove">",'%!;>/\</xsl:variable> 
                    <xsl:element name="identifier">
                        <xsl:attribute name="type"><xsl:text>local</xsl:text></xsl:attribute>
                        <xsl:value-of select='normalize-space(translate($local_identifier, $remove, "_________"))'/>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="identifier">
                        <xsl:attribute name="type"><xsl:text>orcid</xsl:text></xsl:attribute>
                        <xsl:value-of select="normalize-space(orcidIdentifier/text())"/>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:element name="relation">
                <xsl:attribute name="type"><xsl:value-of select="roleName"/></xsl:attribute>
            </xsl:element>
        </xsl:element>
    </xsl:template>



    <!--xsl:template match="investigators-at-announcement" mode="description">
        <description xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>researchers</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="concat(title, ' ' , firstName, ' ', familyName)"/>
            <xsl:apply-templates select="following-sibling::investigators-at-announcement[orcidIdentifier = 'null']" mode="name"/>
        </description>
    </xsl:template-->


    <!--xsl:template match="investigators-at-announcement" mode="name">
            <xsl:text>; </xsl:text><xsl:value-of select="concat(title, ' ' , firstName, ' ', familyName)"/>
    </xsl:template-->




    <xsl:template match="funding-at-announcement">
        <xsl:if test="normalize-space(.) != ''">
            <description xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:attribute name="type">
                    <xsl:text>fundingAmount</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="concat('$', format-number(., '###,###,###'))"/>
            </description>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="grant-summary">
        <xsl:if test="normalize-space(.) != ''">
            <description xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:attribute name="type">
                    <xsl:text>brief</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="normalize-space(.)"/>
            </description>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="scheme-name">
        <xsl:if test="normalize-space(.) != ''">
            <description xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:attribute name="type">
                    <xsl:text>fundingScheme</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="normalize-space(.)"/>
            </description>
        </xsl:if>
    </xsl:template>


    <xsl:template match="attributes/announcement-administering-organisation">

        <!-- This section uses a lookup table 'arc_admin_institutions.xml' -->

        <xsl:variable name="admin_inst" select="normalize-space(.)"/>
        <!-- we may have more than one match;
                the group order is Trove first then the rest 
                so pick the first one -->
        <xsl:variable name="inst_key" select="$adminInstitutions/institutions/institution[name = $admin_inst][1]/key"/>
        <xsl:choose>
        <xsl:when test="$inst_key">
            <xsl:element name="relatedObject" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:element name="key">
                    <xsl:value-of select="$inst_key"/>
                </xsl:element>
                <xsl:element name="relation">
                    <xsl:attribute name="type">isManagedBy</xsl:attribute>
                </xsl:element>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>
                <xsl:value-of select="$admin_inst"/>
            </xsl:message>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
