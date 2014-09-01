<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:custom="http://custom.nowhere.yet"
    xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
    <!-- stylesheet to convert data.gov.au xml (transformed from json with python script) to RIF-CS -->
    <xsl:output method="xml" version="1.0" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
    <xsl:strip-space elements='*'/>
    <xsl:param name="global_originatingSource" select="'http://data.gov.au'"/>
    <xsl:param name="global_baseURI" select="'http://data.gov.au/'"/>
    <xsl:param name="global_group" select="'data.gov.au'"/>
    <xsl:param name="global_contributor" select="'data.gov.au'"/>
    <xsl:param name="global_publisherName" select="'data.gov.au'"/>
    <xsl:param name="global_publisherPlace" select="'Canberra'"/>

    <xsl:template match="datasets/help"/>
    <xsl:template match="datasets/success"/>

    <!-- =========================================== -->
    <!-- dataset (root) Template             -->
    <!-- =========================================== -->

    <xsl:template match="datasets">
        <registryObjects>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="result"/>
        </registryObjects>
    </xsl:template>

    <xsl:template match="result">
        <xsl:apply-templates select="." mode="collection"/>
        <xsl:apply-templates select="." mode="party"/>
        <xsl:apply-templates select="." mode="service"/>
    </xsl:template>

    <xsl:template match="datasets/result" mode="collection">

        <xsl:variable name="metadataURL">
            <xsl:variable name="name" select="normalize-space(name)"/>
            <xsl:if test="string-length($name)">
                <xsl:value-of select="concat($global_baseURI, 'dataset/', $name)"/>
            </xsl:if>
        </xsl:variable>

        <registryObject>
            <xsl:attribute name="group">
                <xsl:value-of select="$global_group"/>
            </xsl:attribute>
            <xsl:apply-templates select="id" mode="collection_key"/>

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

              <xsl:apply-templates select="id"
                    mode="collection_identifier"/>

                <xsl:apply-templates select="name"
                    mode="collection_identifier"/>

                <xsl:apply-templates select="title"
                    mode="collection_name"/>

                <xsl:apply-templates select="name"
                    mode="collection_location_name"/>

                <xsl:apply-templates select="url"
                    mode="collection_location_url"/>

                <xsl:apply-templates select="organization"
                        mode="collection_related_object"/>

                <xsl:apply-templates select="author"
                    mode="collection_related_object"/>

                <xsl:apply-templates select="tags"
                    mode="collection_subject"/>

               <xsl:apply-templates select="notes"
                    mode="collection_description"/>

                <xsl:apply-templates select="spatial_coverage"
                    mode="collection_coverage_spatial"/>

                <xsl:apply-templates select="resources"
                    mode="collection_relatedInfo"/>

                <xsl:apply-templates select="."
                    mode="relatedInfo_services"/>

                <xsl:call-template name="collection_license">
                    <xsl:with-param name="title" select="license_title"/>
                    <xsl:with-param name="id" select="license_id"/>
                    <xsl:with-param name="url" select="license_url"/>
                </xsl:call-template>

                <!--xsl:apply-templates select=""
                    mode="collection_relatedInfo"/-->

                <!--xsl:call-template name="collection_citation">
                    <xsl:with-param name="title" select="title"/>
                    <xsl:with-param name="id" select="id"/>
                    <xsl:with-param name="url" select="$metadataURL"/>
                    <xsl:with-param name="author" select="author"/>
                    <xsl:with-param name="organisation" select="organisation/title"/>
                    <xsl:with-param name="date" select="metadata_created"/>
                    </xsl:call-template-->
            </collection>

        </registryObject>
    </xsl:template>

    <!-- =========================================== -->
    <!-- Party RegistryObject Template          -->
    <!-- =========================================== -->

    <xsl:template match="datasets/result" mode="party">

        <xsl:apply-templates select="organization"/>

        <!-- If the author differs from the organisation -->
        <xsl:variable name="authorName" select="author"/>
        <xsl:if test="not(contains(lower-case(organization/title), lower-case($authorName)))">
            <!-- name of author differs from name of organisation, so construct an author record and relate it to the organization-->
            <xsl:apply-templates select="." mode="party_author"/>
        </xsl:if>
    </xsl:template>

    <!-- =========================================== -->
    <!-- Collection RegistryObject - Child Templates -->
    <!-- =========================================== -->

    <!-- Collection - Key Element  -->
    <xsl:template match="id" mode="collection_key">
        <xsl:if test="string-length(normalize-space(.))">
            <key>
                <xsl:value-of select="concat($global_group,'/', lower-case(normalize-space(.)))"/>
            </key>
        </xsl:if>
    </xsl:template>

    <!-- Collection - Identifier Element  -->
    <xsl:template match="id" mode="collection_identifier">
         <xsl:if test="string-length(normalize-space(.))">
            <identifier>
                <xsl:attribute name="type">
                     <xsl:text>local</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="normalize-space(.)"/>
            </identifier>
        </xsl:if>
    </xsl:template>

    <xsl:template match="name" mode="collection_identifier">
        <xsl:if test="string-length(normalize-space(.))">
              <identifier>
                <xsl:attribute name="type">
                    <xsl:text>uri</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="concat($global_baseURI, 'dataset/', normalize-space(.))"/>
            </identifier>
        </xsl:if>
    </xsl:template>

    <!-- Collection - Name Element  -->
    <xsl:template match="title" mode="collection_name">
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

    <!-- Collection - Location Element  -->
    <xsl:template match="name" mode="collection_location_name">
        <xsl:variable name="name" select="normalize-space(.)"/>
        <xsl:if test="string-length($name)">
           <location>
                <address>
                    <electronic>
                        <xsl:attribute name="type">
                            <xsl:text>url</xsl:text>
                        </xsl:attribute>
                        <value>
                            <xsl:value-of select="concat($global_baseURI, 'dataset/', $name)"/>
                        </value>
                    </electronic>
                </address>
            </location>
        </xsl:if>
    </xsl:template>

    <xsl:template match="url" mode="collection_location_url">
        <xsl:variable name="url" select="normalize-space(.)"/>
        <xsl:if test="string-length($url)">
            <location>
                <address>
                    <electronic>
                        <xsl:attribute name="type">
                            <xsl:text>url</xsl:text>
                        </xsl:attribute>
                        <value>
                            <xsl:value-of select="$url"/>
                        </value>
                    </electronic>
                </address>
            </location>
        </xsl:if>
    </xsl:template>

    <!-- Collection - Related Object (Organisation or Individual) Element -->
    <xsl:template match="organization" mode="collection_related_object">
        <xsl:if test="string-length(normalize-space(title))">
            <xsl:variable name="transformedName">
                <xsl:call-template name="transform">
                    <xsl:with-param name="inputString" select="normalize-space(title)"/>
                </xsl:call-template>
            </xsl:variable>
            <relatedObject>
                <key>
                    <xsl:value-of select="concat($global_group,'/', translate(lower-case($transformedName),' ',''))"/>
                </key>
                <relation>
                    <xsl:attribute name="type">
                        <xsl:text>owner</xsl:text>
                    </xsl:attribute>
                </relation>
            </relatedObject>

            <xsl:apply-templates select="../."
                mode="relatedInfo_services"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="author" mode="collection_related_object">
        <xsl:if test="string-length(normalize-space(.))">
            <xsl:variable name="transformedName">
                <xsl:call-template name="transform">
                    <xsl:with-param name="inputString" select="normalize-space(.)"/>
                </xsl:call-template>
            </xsl:variable>
            <relatedObject>
                <key>
                    <xsl:value-of select="concat($global_group,'/', translate(normalize-space(lower-case($transformedName)),' ',''))"/>
                </key>
                <relation>
                    <xsl:attribute name="type">
                        <xsl:text>author</xsl:text>
                    </xsl:attribute>
                </relation>
            </relatedObject>
        </xsl:if>
    </xsl:template>

    <!-- Collection - Subject Element -->
    <xsl:template match="tags" mode="collection_subject">
        <xsl:if test="string-length(normalize-space(display_name))">
            <subject>
                <xsl:attribute name="type">local</xsl:attribute>
                <xsl:value-of select="normalize-space(display_name)"/>
            </subject>
        </xsl:if>
    </xsl:template>

   <!-- Collection - Decription (brief) Element -->
    <xsl:template match="notes" mode="collection_description">
        <xsl:if test="string-length(normalize-space(.))">
            <description type="brief">
               <xsl:value-of select="normalize-space(.)"/>
            </description>
        </xsl:if>
    </xsl:template>

   <!-- Collection - Coverage Spatial Element -->
    <!--xsl:template match="spatial_coverage" mode="collection_coverage_spatial">
        <xsl:if test="string-length(normalize-space(.)) > 0">
            <xsl:variable name="spatial_sequence" as="xs:string*">
                <xsl:call-template name="splitText">
                    <xsl:with-param name="string" select="normalize-space(.)"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each select="$spatial_sequence">
                <xsl:variable name="spatial" select='.'/>
                <xsl:if test="(string-length($spatial) > 0) and not(boolean(contains(lower-case($spatial), 'not specified')))">
                    <coverage>
                         <spatial>
                             <xsl:attribute name="type">
                                 <xsl:text>text</xsl:text>
                             </xsl:attribute>
                             <xsl:value-of select="."/>
                         </spatial>
                    </coverage>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template-->

    <xsl:template match="spatial_coverage" mode="collection_coverage_spatial">
        <xsl:variable name="spatial" select='normalize-space(.)'/>
        <xsl:variable name="coordinate_sequence" as="xs:string*">
            <xsl:if test="contains($spatial, 'Polygon') and contains($spatial, 'coordinates')">
                <xsl:analyze-string select="$spatial" regex="\[([^\[]*?)\]">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(0)"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:if>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="count($coordinate_sequence) = 0">
                <xsl:if test="string-length($spatial)">
                    <xsl:if test="(string-length($spatial) > 0) and not(contains(lower-case($spatial), 'not specified'))">
                        <coverage>
                            <spatial>
                                <xsl:attribute name="type">
                                    <xsl:text>text</xsl:text>
                                </xsl:attribute>
                                <xsl:value-of select="$spatial"/>
                            </spatial>
                        </coverage>
                    </xsl:if>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <coverage>
                    <spatial>
                        <xsl:attribute name="type">
                            <xsl:text>gmlKmlPolyCoords</xsl:text>
                        </xsl:attribute>
                        <xsl:for-each select="$coordinate_sequence">
                            <xsl:value-of select="translate(., ' |[|]', '')"/>
                            <xsl:if test="position() != count($coordinate_sequence)">
                                <xsl:text> </xsl:text>
                            </xsl:if>
                        </xsl:for-each>
                    </spatial>
                </coverage>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

  <!-- Collection - Related Info Element - Services -->
    <xsl:template match="result" mode="relatedInfo_services">
        <!-- Related Services -->
        <xsl:variable name="serviceURI_sequence" as="xs:string*">
            <xsl:call-template name="getServiceURI_sequence">
                <xsl:with-param name="parent" select="."/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:for-each select="distinct-values($serviceURI_sequence)">
            <relatedInfo type="service">
                <identifier type="uri">
                    <xsl:value-of select="."/>
                </identifier>
                <relation type="isSupportedBy"/>
            </relatedInfo>
        </xsl:for-each>
    </xsl:template>

    <!-- Collection - Related Info Element -->
    <xsl:template match="resources" mode="collection_relatedInfo">
        <relatedInfo type="resource">
            <xsl:if test="string-length(normalize-space(url))">
                <identifier type="uri">
                    <xsl:value-of select="normalize-space(url)"/>
                </identifier>
            </xsl:if>
            <relation>
                <xsl:attribute name="type">
                    <xsl:text>hasPart</xsl:text>
                </xsl:attribute>
            </relation>
            <xsl:variable name="format" select="normalize-space(format)"/>
            <xsl:variable name="name" select="normalize-space(name)"/>
            <title>
                <xsl:choose>
                    <xsl:when test="string-length($name)">
                        <xsl:choose>
                            <xsl:when test="string-length($format)">
                                <xsl:value-of select="concat($name, ' (',$format, ')')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$name"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="string-length($format)">
                            <xsl:value-of select="concat('(',$format, ')')"/>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </title>
            <xsl:if test="string-length(normalize-space(description))">
                <notes>
                     <xsl:value-of select="normalize-space(description)"/>
                </notes>
            </xsl:if>
        </relatedInfo>

        <xsl:if test="contains(lower-case(webstore_url), 'active')">
            <relatedInfo type="resource">
                 <xsl:variable name="id" select="normalize-space(id)"/>
                 <xsl:if test="string-length($id)">
                     <identifier type="uri">
                         <xsl:value-of select="concat($global_baseURI, 'api/3/action/datastore_search?resource_id=', $id)"/>
                     </identifier>
                 </xsl:if>
                 <xsl:variable name="format" select="'Tabular data in JSON'"/>
                 <title>
                     <xsl:choose>
                         <xsl:when test="string-length(normalize-space(name))">
                             <xsl:value-of select="concat(normalize-space(name), ' (',$format, ')')"/>
                         </xsl:when>
                         <xsl:otherwise>
                             <xsl:value-of select="concat('(',$format, ')')"/>
                         </xsl:otherwise>
                     </xsl:choose>
                 </title>
                 <xsl:if test="string-length(normalize-space(description))">
                     <notes>
                         <xsl:value-of select="normalize-space(description)"/>
                     </notes>
                 </xsl:if>
            </relatedInfo>
        </xsl:if>
    </xsl:template>

    <!-- Collection - CitationInfo Element -->
    <xsl:template name="collection_citation">
        <xsl:param name="title"/>
        <xsl:param name="id"/>
        <xsl:param name="url"/>
        <xsl:param name="author"/>
        <xsl:param name="organisation"/>
        <xsl:param name="date"/>

        <xsl:variable name="identifier" select="normalize-space($id)"/>
        <citationInfo>
            <citationMetadata>
                <xsl:choose>
                    <xsl:when test="string-length($identifier) and contains(lower-case($identifier), 'doi')">
                        <identifier>
                            <xsl:attribute name="type">
                                <xsl:text>doi</xsl:text>
                            </xsl:attribute>
                            <xsl:value-of select="$identifier"/>
                        </identifier>
                    </xsl:when>
                    <xsl:otherwise>
                        <identifier>
                             <xsl:attribute name="type">
                                 <xsl:text>uri</xsl:text>
                             </xsl:attribute>
                            <xsl:value-of select="$url"/>
                        </identifier>
                    </xsl:otherwise>
               </xsl:choose>

                <title>
                    <xsl:value-of select="$title"/>
                </title>
                <date>
                    <xsl:attribute name="type">
                       <xsl:text>publicationDate</xsl:text>
                    </xsl:attribute>
                    <xsl:value-of select="$date"/>
                </date>

                <contributor>
                    <namePart>
                        <xsl:value-of select="$author"/>
                    </namePart>
                </contributor>

                <xsl:if test="$author != $organisation">
                    <contributor>
                        <namePart>
                            <xsl:value-of select="$organisation"/>
                        </namePart>
                    </contributor>
                </xsl:if>

                <publisher>
                    <xsl:value-of select="$organisation"/>
                </publisher>

            </citationMetadata>
        </citationInfo>
    </xsl:template>


    <!-- ====================================== -->
    <!-- Party RegistryObject - Child Templates -->
    <!-- ====================================== -->

    <!-- Party Registry Object (Individuals (person) and Organisations (group)) -->
    <xsl:template match="organization">
        <xsl:variable name="title" select="normalize-space(title)"/>
        <xsl:if test="string-length($title) > 0">
            <registryObject group="{$global_group}">

                <xsl:variable name="transformedName">
                    <xsl:call-template name="transform">
                        <xsl:with-param name="inputString" select="$title"/>
                    </xsl:call-template>
                </xsl:variable>


                <key>
                    <xsl:value-of select="concat($global_group, '/', translate(lower-case($transformedName),' ',''))"/>
                </key>

                <originatingSource>
                    <xsl:choose>
                        <xsl:when test="string-length(normalize-space(title)) > 0">
                            <xsl:value-of select="normalize-space(title)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$global_originatingSource"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </originatingSource>

                <party type="group">

                    <xsl:variable name="name" select="normalize-space(name)"/>
                    <xsl:if test="string-length($name)">
                        <identifier type="uri">
                            <xsl:value-of select="concat($global_baseURI,'organization/', $name)"/>
                        </identifier>
                    </xsl:if>

                    <name type="primary">
                        <namePart>
                            <xsl:value-of select="$transformedName"/>
                        </namePart>
                    </name>

                    <xsl:if test="string-length($name)">
                        <location>
                            <address>
                                <electronic>
                                    <xsl:attribute name="type">
                                        <xsl:text>url</xsl:text>
                                    </xsl:attribute>
                                    <value>
                                        <xsl:value-of select="concat($global_baseURI, 'organization/', $name)"/>
                                    </value>
                                </electronic>
                            </address>
                        </location>
                    </xsl:if>

                    <xsl:if test="string-length(normalize-space(image_url))">
                        <description>
                            <xsl:attribute name="type">
                                <xsl:text>logo</xsl:text>
                            </xsl:attribute>
                            <xsl:value-of select="normalize-space(image_url)"/>
                        </description>
                    </xsl:if>

                    <xsl:if test="string-length(normalize-space(description))">
                        <description>
                            <xsl:attribute name="type">
                                <xsl:text>brief</xsl:text>
                            </xsl:attribute>
                            <xsl:value-of select="normalize-space(description)"/>
                        </description>
                    </xsl:if>
                </party>
            </registryObject>
        </xsl:if>
    </xsl:template>

    <!-- Party Registry Object (Individuals (person) and Organisations (group)) -->
    <xsl:template match="datasets/result" mode="party_author">
        <xsl:variable name="name" select="author"/>
        <xsl:if test="string-length($name) > 0">
            <registryObject group="{$global_group}">

                <xsl:variable name="transformedName">
                    <xsl:call-template name="transform">
                        <xsl:with-param name="inputString" select="$name"/>
                    </xsl:call-template>
                </xsl:variable>

                <key>
                    <xsl:value-of select="concat($global_group, '/', translate(lower-case($transformedName),' ',''))"/>
                </key>

                <originatingSource>
                    <xsl:choose>
                        <xsl:when test="string-length(normalize-space($name)) > 0">
                            <xsl:value-of select="normalize-space($name)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$global_originatingSource"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </originatingSource>

                <party type="group">
                    <name type="primary">
                        <namePart>
                            <xsl:value-of select="$transformedName"/>
                        </namePart>
                    </name>

                    <xsl:if test="string-length(normalize-space(author_email))">
                        <location>
                            <address>
                                <electronic type="email">
                                    <value>
                                        <xsl:value-of select="normalize-space(author_email)"/>
                                    </value>
                                </electronic>
                            </address>
                        </location>
                    </xsl:if>

                    <xsl:variable name="orgName" select="organization/title"/>
                    <xsl:if test="boolean(string-length($orgName))">
                        <xsl:variable name="transformedOrgName">
                            <xsl:call-template name="transform">
                                <xsl:with-param name="inputString" select="$orgName"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <relatedObject>
                            <key>
                                <xsl:value-of select="concat($global_group,'/', translate(lower-case($transformedOrgName),' ',''))"/>
                            </key>
                            <relation>
                                <xsl:attribute name="type">
                                    <xsl:text>isMemberOf</xsl:text>
                                </xsl:attribute>
                            </relation>
                        </relatedObject>
                    </xsl:if>
                </party>
            </registryObject>
        </xsl:if>
    </xsl:template>

    <!-- ====================================== -->
    <!-- Service RegistryObject - Template -->
    <!-- ====================================== -->

    <!-- Service Registry Object -->
    <xsl:template match="datasets/result" mode="service">
        <xsl:variable name="organizationTitle" select="normalize-space(organization/title)"/>
        <xsl:variable name="organizationName" select="normalize-space(organization/name)"/>
        <xsl:variable name="organizationDescription" select="normalize-space(organization/description)"/>
        <xsl:variable name="transformedTitle">
            <xsl:call-template name="transform">
                <xsl:with-param name="inputString" select="$organizationTitle"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="serviceURI_sequence" as="xs:string*">
            <xsl:call-template name="getServiceURI_sequence">
                <xsl:with-param name="parent" select="."/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="distinct-values($serviceURI_sequence)">
            <xsl:variable name="serviceURI" select="normalize-space(.)"/>
            <xsl:if test="string-length($serviceURI)">

                <registryObject group="{$global_group}">

                    <key>
                        <xsl:value-of select="$serviceURI"/>
                    </key>

                    <originatingSource>
                        <xsl:value-of select="$global_originatingSource"/>
                    </originatingSource>

                    <service type="webservice">

                        <identifier type="uri">
                            <xsl:value-of select="$serviceURI"/>
                        </identifier>

                        <xsl:variable name="serviceName">
                            <xsl:call-template name="getServiceName">
                                <xsl:with-param name="url" select="$serviceURI"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <name type="primary">
                            <namePart>
                                <xsl:choose>
                                    <xsl:when test="string-length($serviceName)">
                                        <xsl:value-of select="concat($serviceName, ' - ', $transformedTitle)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat('Service linked to ', $transformedTitle)"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </namePart>
                        </name>

                        <xsl:if test="string-length($organizationDescription)">
                            <description>
                                <xsl:attribute name="type">
                                    <xsl:text>brief</xsl:text>
                                </xsl:attribute>
                                <xsl:value-of select="concat('Description of organisation that provides this service: ',  $organizationDescription)"/>
                            </description>
                        </xsl:if>


                        <location>
                            <address>
                                <electronic>
                                    <xsl:attribute name="type">
                                        <xsl:text>url</xsl:text>
                                    </xsl:attribute>
                                    <value>
                                        <xsl:value-of select="$serviceURI"/>
                                    </value>
                                </electronic>
                            </address>
                        </location>

                        <xsl:if test="string-length($organizationName)">
                            <relatedInfo type="party">
                                <identifier type="uri">
                                    <xsl:value-of select="concat($global_baseURI,'organization/', $organizationName)"/>
                                </identifier>
                            </relatedInfo>
                        </xsl:if>
                    </service>
                </registryObject>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- Modules -->
    <xsl:template name="getServiceURI_sequence" as="xs:string*">
        <xsl:param name="parent"/>
        <xsl:for-each select="$parent/resources">
            <xsl:variable name="url" select="normalize-space(url)"/>
            <xsl:message>url: <xsl:value-of select="$url"/></xsl:message>
            <xsl:if test="string-length($url)">
                <xsl:choose>
                    <xsl:when test="contains($url, '?')"> <!-- Indicates parameters -->
                        <xsl:variable name="baseURL" select="substring-before($url, '?')"/>
                        <xsl:choose>
                            <xsl:when test="substring($baseURL, string-length($baseURL), 1) = '/'">
                                <xsl:value-of select="substring($baseURL, 1, string-length($baseURL)-1)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$baseURL"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="contains(lower-case(normalize-space(resource_type)), 'api')">
                            <!--xsl:variable name="serviceName">
                                <xsl:call-template name="getServiceName">
                                    <xsl:with-param name="url" select="$url"/>
                                </xsl:call-template>
                            </xsl:variable-->
                            <!--xsl:if test="not(contains($serviceName, '.'))"-->
                                <xsl:value-of select="$url"/>
                            <!--/xsl:if-->
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="collection_license">
        <xsl:param name="title"/>
        <xsl:param name="id"/>
        <xsl:param name="url"/>
        <rights>
            <licence>
                <xsl:attribute name="type">
                    <xsl:value-of select="upper-case($id)"/>
                </xsl:attribute>
                <xsl:attribute name="rightsUri">
                    <xsl:value-of select="$url"/>
                </xsl:attribute>
                <xsl:value-of select="$title"/>
            </licence>
        </rights>
    </xsl:template>

    <!-- This is a placeholder function for if you want to transform something, e.g. from ANU to Australian National University -->
    <xsl:template name="transform">
        <xsl:param name="inputString"/>
        <xsl:value-of select="normalize-space($inputString)"/>
    </xsl:template>


    <xsl:template name="getServiceName">
        <xsl:param name="url"/>
        <xsl:choose>
            <xsl:when test="contains($url, 'rest/services/')">
                <xsl:value-of select="concat(substring-after($url, 'rest/services/'), ' service')"/>
            </xsl:when>
            <xsl:when test="contains($url, $global_baseURI)">
                <xsl:value-of select="concat(substring-after($url, $global_baseURI), ' ', $global_group, ' service')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="tokenize($url, '/')">
                    <xsl:if test="position() = count(tokenize($url, '/'))">
                        <xsl:value-of select="concat(normalize-space(.), ' service')"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="splitText" as="xs:string*">
        <xsl:param name="string"/>
        <xsl:param name="separator" select="','"/>
        <xsl:choose>
            <xsl:when test="contains($string, $separator)">
                <xsl:if test="not(starts-with($string, $separator))">
                    <xsl:value-of select="substring-before($string, $separator)"/>
                </xsl:if>
                <xsl:call-template name="splitText">
                    <xsl:with-param name="string" select="normalize-space(substring-after($string,$separator))"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="string-length(normalize-space($string)) > 0">
                    <xsl:value-of select="$string"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>