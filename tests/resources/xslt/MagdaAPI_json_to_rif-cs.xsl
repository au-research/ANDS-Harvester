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
    
    <xsl:param name="global_originatingSource" select="'{requires override}'"/>
    <xsl:param name="global_baseURI" select="'{requires override}'"/>
    <xsl:param name="global_acronym" select="'{requires override}'"/>
    <xsl:param name="global_group" select="'{requires override}'"/>
    <xsl:param name="global_contributor" select="'{requires override}'"/>
    <xsl:param name="global_publisherName" select="'{requires override}'"/>
    <xsl:param name="global_publisherPlace" select="'{requires override}'"/>
    <xsl:param name="global_includeDownloadLinks" select="true()"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="//datasets/help"/>
    <xsl:template match="//datasets/success"/>

    <!-- =========================================== -->
    <!-- dataset (datasets) Template             -->
    <!-- =========================================== -->

    <xsl:template match="datasets">
        <registryObjects>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="*[contains(local-name(), 'dataSets')]" mode="all"/>
         </registryObjects>
    </xsl:template>
    
    <xsl:template match="*[contains(local-name(), 'dataSets')]" mode="all">
        <xsl:apply-templates select="." mode="collection"/>
        <xsl:apply-templates select="." mode="party"/>
        <xsl:apply-templates select="." mode="service"/>
    </xsl:template>

    <xsl:template match="*[contains(local-name(), 'dataSets')]" mode="collection">

        <xsl:variable name="metadataURL">
            <xsl:variable name="identifier" select="normalize-space(identifier)"/>
            <xsl:if test="string-length($identifier)">
                <xsl:value-of select="concat($global_baseURI, 'dataset/', $identifier)"/>
            </xsl:if>
        </xsl:variable>

        <registryObject>
            <xsl:attribute name="group">
                <xsl:value-of select="$global_group"/>
            </xsl:attribute>
            <xsl:apply-templates select="identifier" mode="collection_key"/>

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

                <xsl:if test="string-length(normalize-space(indexed))">
                    <xsl:attribute name="dateAccessioned">
                        <xsl:value-of select="normalize-space(indexed)"/>
                    </xsl:attribute>
                </xsl:if>

                <xsl:if test="string-length(normalize-space(modified))">
                    <xsl:attribute name="dateModified">
                        <xsl:value-of select="normalize-space(modified)"/>
                    </xsl:attribute>
                </xsl:if>

                <xsl:apply-templates select="identifier" mode="collection_identifier"/>

                <xsl:apply-templates select="name" mode="collection_identifier"/>

                <xsl:apply-templates select="title" mode="collection_name"/>

                <xsl:apply-templates select="identifier" mode="collection_location_id"/>

                <!--xsl:apply-templates select="url" mode="collection_location_url"/-->

                <xsl:apply-templates select="publisher" mode="collection_related_object"/>

                <!--xsl:apply-templates select="author" mode="collection_related_object"/-->

                <xsl:apply-templates select="keywords" mode="collection_subject"/>

                <xsl:apply-templates select="description" mode="collection_description_brief"/>
                
                <!--xsl:apply-templates select="." mode="collection_description_full"/-->

                <xsl:if test="$global_includeDownloadLinks">
                    <xsl:apply-templates select="." mode="collection_location_download"/>
                </xsl:if>
                
                <xsl:apply-templates select="spatial_coverage" mode="collection_coverage_spatial"/>
               <xsl:apply-templates select="spatial" mode="collection_coverage_spatial"/>
               <!-- Override the following in top-level xslt to handle custom extras -->
                <!--xsl:apply-templates select="."  mode="extras"/-->

                <xsl:apply-templates select="isopen" mode="collection_rights_accessRights"/>
                
                <xsl:apply-templates select="issued[string-length(.) > 0]" mode="collection_dates"/>

                <xsl:apply-templates select="distributions" mode="collection_license"/>
                
                <!--xsl:apply-templates select="." mode="collection_relatedInfo"/-->


                <!--xsl:apply-templates select="" 
                    mode="collection_relatedInfo"/-->

                <!--xsl:call-template name="collection_citation">
                    <xsl:with-param name="title" select="title"/>
                    <xsl:with-param name="identifier" select="identifier"/>
                    <xsl:with-param name="url" select="$metadataURL"/>
                    <xsl:with-param name="author" select="author"/>
                    <xsl:with-param name="publisher" select="publisher/name"/>
                    <xsl:with-param name="date" select="metadata_created"/>
                    </xsl:call-template-->
            </collection>

        </registryObject>
    </xsl:template>

    <!-- =========================================== -->
    <!-- Party RegistryObject Template          -->
    <!-- =========================================== -->

    <xsl:template match="*[contains(local-name(), 'dataSets')]" mode="party">

        <xsl:apply-templates select="publisher"/>

        <!-- name of author differs from name of publisher, so construct an author record and relate it to the publisher-->
        <!--xsl:variable name="authorName" select="author"/>
        <xsl:if test="not(contains(lower-case(publisher/title), lower-case($authorName)))">
            <xsl:apply-templates select="." mode="party_author"/>
        </xsl:if-->
    </xsl:template>

    <!-- =========================================== -->
    <!-- Collection RegistryObject - Child Templates -->
    <!-- =========================================== -->

    <!-- Collection - Key Element  -->
    <xsl:template match="identifier" mode="collection_key">
        <xsl:if test="string-length(normalize-space(.))">
            <key>
                <xsl:value-of select="concat($global_acronym,'/', lower-case(normalize-space(.)))"/>
            </key>
        </xsl:if>
    </xsl:template>

    <!-- Collection - Identifier Element  -->
    <xsl:template match="identifier" mode="collection_identifier">
        <xsl:if test="string-length(normalize-space(.))">
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

    <!-- Collection - Identifier Element  -->
    <xsl:template match="name" mode="collection_identifier">
        <xsl:if test="string-length(normalize-space(.))">
            <identifier>
                <xsl:attribute name="type">
                    <xsl:text>local</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="normalize-space(.)"/>
            </identifier>
        </xsl:if>
    </xsl:template>

    <!-- Collection - Location Element  -->
    <xsl:template match="identifier" mode="collection_location_id">
        <xsl:variable name="identifier" select="normalize-space(.)"/>
        <xsl:if test="string-length($identifier)">
            <location>
                <address>
                    <electronic>
                        <xsl:attribute name="type">
                            <xsl:text>url</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="target">
                            <xsl:text>landingPage</xsl:text>
                        </xsl:attribute>
                        <value>
                            <xsl:value-of select="concat($global_baseURI, 'dataset/', $identifier)"/>
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
                        <xsl:attribute name="target">
                            <xsl:text>landingPage</xsl:text>
                        </xsl:attribute>
                        <value>
                            <xsl:value-of select="$url"/>
                        </value>
                    </electronic>
                </address>
            </location>
        </xsl:if>
    </xsl:template>

    <!-- Collection - Related Object (Publisher or Individual) Element -->
    <xsl:template match="publisher" mode="collection_related_object">
        <xsl:if test="string-length(normalize-space(title))">
            <relatedObject>
                <key>
                    <xsl:value-of
                        select="concat($global_acronym,'/', translate(lower-case(normalize-space(identifier)),' ',''))"
                    />
                </key>
                <relation>
                    <xsl:attribute name="type">
                        <xsl:text>isOwnedBy</xsl:text>
                    </xsl:attribute>
                </relation>
            </relatedObject>

            <!--xsl:apply-templates select="../." mode="collection_relatedInfo"/-->
        </xsl:if>
    </xsl:template>

    <!--xsl:template match="author" mode="collection_related_object">
        <xsl:if test="string-length(normalize-space(.))">
            <relatedObject>
                <key>
                    <xsl:value-of
                        select="concat($global_group,'/', translate(normalize-space(lower-case(normalize-space(.))),' ',''))"
                    />
                </key>
                <relation>
                    <xsl:attribute name="type">
                        <xsl:text>author</xsl:text>
                    </xsl:attribute>
                </relation>
            </relatedObject>
        </xsl:if>
    </xsl:template-->

    <!-- Collection - Subject Element -->
    <xsl:template match="keywords" mode="collection_subject">
        <xsl:if test="string-length(normalize-space(.))">
            <subject>
                <xsl:attribute name="type">local</xsl:attribute>
                <xsl:value-of select="normalize-space(.)"/>
            </subject>
        </xsl:if>
    </xsl:template>

    <!-- Collection - Decription (brief) Element -->
    <xsl:template match="description" mode="collection_description_brief">
        <xsl:if test="string-length(normalize-space(.))">
            <description type="full">
                <xsl:value-of select="."/>
            </description>
        </xsl:if>
    </xsl:template>
    
     <!-- Collection - Decription (full) Element -->
    <!--xsl:template match="*[contains(local-name(), 'dataSets')]" mode="collection_description_full">
        <description type="full">
             <xsl:for-each select="distributions">
                <xsl:if test="string-length(normalize-space(name)) > 0">
                    <xsl:value-of select="concat(normalize-space(name), ' - ', custom:reformatHyperlinks(normalize-space(description)), '&lt;br/&gt;')"/>
                </xsl:if>
            </xsl:for-each>
        </description>
    </xsl:template-->
    
    <xsl:template match="*[contains(local-name(), 'dataSets')]" mode="collection_location_download">
        <xsl:for-each select="distributions[string-length(downloadURL) > 0]">
                <xsl:if test="string-length(normalize-space(url)) > 0">
                    <location>
                        <address>
                            <electronic type="url" target="directDownload">
                                <value>
                                    <xsl:value-of select="downloadURL"/>
                                </value>
			<xsl:if test="string-length(description) > 0">
             			<title>
             			 <xsl:value-of select="description"/>
             			</title>
			</xsl:if>
                                <xsl:if test="string-length(format) > 0">
                                    <mediaType>
                                        <xsl:value-of select="format"/>
                                     </mediaType>
                                </xsl:if>
                            </electronic>
                         </address>
                    </location>
                </xsl:if>
            </xsl:for-each>
    </xsl:template>
    
    


    <xsl:template match="isopen" mode="collection_rights_accessRights">
        <xsl:if test="contains(lower-case(.), 'true')">
            <rights>
                <accessRights type="open"/>
            </rights>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="issued" mode="collection_dates">
        <dates type="dc.issued">
            <date type="dateFrom" dateFormat="W3CDTF">
                <xsl:value-of select="."/>
            </date>
        </dates>
    </xsl:template>
    
    <xsl:template match="extras"  mode="extras">
        <xsl:message select="'Override this template in top-level custom xslt to handle custom extras'"/>
    </xsl:template>
    
    <xsl:template match="spatial_coverage" mode="collection_coverage_spatial">
        <xsl:call-template name="spatial_coordinates"/>
    </xsl:template>
     
    <xsl:template match="spatial" mode="collection_coverage_spatial">
        <xsl:call-template name="spatial_coordinates"/>
    </xsl:template>
     
    <xsl:template name="spatial_coordinates">
        
        <xsl:if test="string-length(text) > 0">
            <coverage>
                <spatial>
                      <xsl:attribute name="type">
                          <xsl:text>text</xsl:text>
                      </xsl:attribute>
                      <xsl:value-of select="text"/>
                  </spatial>
            </coverage>
        </xsl:if>
        
        <xsl:variable name="coordinate_sequence" as="xs:string*">
            <xsl:analyze-string select="text" regex="[\d.-]+">
                <xsl:matching-substring>
                    <xsl:value-of select="regex-group(0)"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        
        <xsl:variable name="coordinate_sequence_swappedLatLongs" as="xs:string*">
            <xsl:for-each select="$coordinate_sequence">
                <xsl:variable name="postInt" select="position()" as="xs:integer"/>
                <xsl:if test="$postInt &lt; count($coordinate_sequence)">
                    <xsl:if test="($postInt mod 2) = 1">
                        <xsl:value-of select="concat(., ',', $coordinate_sequence[$postInt + 1])"/>
                    </xsl:if>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:if test="count($coordinate_sequence_swappedLatLongs) > 0">
            <coverage>
                <spatial>
                    <xsl:attribute name="type">
                        <xsl:text>gmlKmlPolyCoords</xsl:text>
                    </xsl:attribute>
                    <xsl:value-of select="string-join($coordinate_sequence_swappedLatLongs, ' ')"/>
                 </spatial>
            </coverage>
        </xsl:if>
        
    
        <!--xsl:if test="count($coordinate_sequence) > 0">
            <coverage>
                <spatial>
                    <xsl:attribute name="type">
                        <xsl:text>gmlKmlPolyCoords</xsl:text>
                    </xsl:attribute>
                    <xsl:for-each select="$coordinate_sequence">
                        <xsl:variable name="postfixSeparator">
                            <xsl:choose>
                                <xsl:when test="position() = last()">
                                    <xsl:text></xsl:text>
                                </xsl:when>
                                <xsl:when test="(position() mod 2) = 0">
                                    <xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>,</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        
                        </xsl:variable>
                        <xsl:value-of select="concat(.,$postfixSeparator)"/>
                    </xsl:for-each>
                 </spatial>
            </coverage>
        </xsl:if-->
        
        
    </xsl:template>
    
    <xsl:template match="distributions" mode="collection_license">
         <rights>
            <licence>
                <xsl:value-of select="normalize-space(license/name)"/>
            </licence>
        </rights>
    </xsl:template>

    <!-- Collection - Related Info Element - Services -->
    <xsl:template match="*[contains(local-name(), 'dataSets')]" mode="collection_relatedInfo">
        <xsl:variable name="publisherName" select="publisher/name"/>
        <!-- Related Services -->
        <xsl:for-each select="resources">
            <xsl:variable name="url" select="normalize-space(url)"/>
            <xsl:if test="string-length($url)">
                <xsl:variable name="serviceUrl" select="custom:getServiceUrl(.)"/>
                <xsl:variable name="serviceName" select="custom:getServiceName($serviceUrl)"/>
                
                <xsl:choose>
                    <xsl:when test="string-length($serviceUrl) > 0">
                        <relatedInfo type="service">
                            <identifier type="uri">
                                <xsl:value-of select="$serviceUrl"/>
                            </identifier>
                            <relation type="supports">
                                <xsl:if test="string-length(name) > 0">
                                    <description>
                                        <xsl:value-of select="name"/>
                                    </description>
                                </xsl:if>
                                <xsl:if
                                    test="not(contains($url, '?')) or string-length(substring-after($url, '?')) > 0">
                                    <url>
                                        <xsl:choose>
                                            <xsl:when test="contains($url, '?')">
                                                <xsl:value-of select="substring-before($url, '?')"/> <!-- before trailing ? -->
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="$url"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </url>
                                </xsl:if>
                            </relation>
                            <xsl:if
                                test="string-length($publisherName) > 0 or string-length($serviceName) > 0">
                                <title>
                                    <xsl:choose>
                                        <xsl:when test="string-length($serviceName)">
                                            <xsl:value-of
                                                select="concat($serviceName, ' for access to ', $publisherName, ' data')"
                                            />
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of
                                                select="concat('Service for access to ', $publisherName, ' data')"
                                            />
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </title>
                            </xsl:if>
                        </relatedInfo>
                    </xsl:when>
                    <xsl:otherwise>
                        
                        <xsl:if test="contains(lower-case(webstore_url), 'active')">
                            <relatedInfo type="service">
                                <xsl:variable name="identifier" select="normalize-space(identifier)"/>
                                <xsl:if test="string-length($identifier)">
                                    <identifier type="uri">
                                        <xsl:value-of
                                            select="concat($global_baseURI, 'api/3/action/datastore_search')"
                                        />
                                    </identifier>
                                </xsl:if>
                                <xsl:variable name="format" select="'Tabular data in JSON'"/>
                                <xsl:variable name="description">
                                    <xsl:choose>
                                        <xsl:when test="string-length(normalize-space(name))">
                                            <xsl:value-of
                                                select="concat(normalize-space(name), ' (',$format, ')')"
                                            />
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="concat('(',$format, ')')"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:if test="string-length(normalize-space(description))">
                                        <xsl:value-of
                                            select="concat(' ', normalize-space(description))"/>
                                    </xsl:if>
                                </xsl:variable>
                                <relation type="supports">
                                    <xsl:if test="string-length(normalize-space($description)) > 0">
                                        <description>
                                            <xsl:value-of select="$description"/>
                                        </description>
                                    </xsl:if>
                                    <url>
                                        <xsl:value-of
                                            select="concat($global_baseURI, 'api/3/action/datastore_search?resource_id=', $identifier)"
                                        />
                                    </url>
                                </relation>
                                <xsl:if
                                    test="string-length($publisherName) > 0 or string-length($serviceName) > 0">
                                    <title>
                                        <xsl:choose>
                                            <xsl:when test="string-length($serviceName)">
                                                <xsl:value-of
                                                    select="concat($serviceName, ' for access to ', $publisherName, ' data')"
                                                />
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of
                                                    select="concat('Service at ', $global_baseURI)"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </title>
                                </xsl:if>
                            </relatedInfo>
                            
                        </xsl:if>
                        <!--location>
                            <address>
                                <electronic type="url" target="directDownload">
                                    <value>
                                        <xsl:value-of select="normalize-space(url)"/>
                                    </value>
                                    <xsl:if test="string-length(name) > 0">
                                    <title>
                                        <xsl:value-of select="name"/>
                                    </title>
                 </xsl:if>
                 <xsl:if test="string-length(normalize-space(description))">
                                        <notes>
                                            <xsl:value-of select="normalize-space(description)"/>
                 </notes>
                     </xsl:if>
                         <xsl:if test="string-length(mimetype) > 0">
                             <mediaType>
                         <xsl:value-of select="mimetype"/>
                         </mediaType>
                     </xsl:if>
                 <xsl:if test="string-length(size) > 0">
                     <byteSize>
                         <xsl:value-of select="size"/>
                     </byteSize>
                 </xsl:if>
            </electronic>
        </address>
                        </location-->
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- Collection - CitationInfo Element -->
    <xsl:template name="collection_citation">
        <xsl:param name="title"/>
        <xsl:param name="identifier"/>
        <xsl:param name="url"/>
        <xsl:param name="author"/>
        <xsl:param name="publisher"/>
        <xsl:param name="date"/>

        <xsl:variable name="identifier" select="normalize-space($identifier)"/>
        <citationInfo>
            <citationMetadata>
                <xsl:choose>
                    <xsl:when
                        test="string-length($identifier) and contains(lower-case($identifier), 'doi')">
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

                <xsl:if test="$author != $publisher">
                    <contributor>
                        <namePart>
                            <xsl:value-of select="$publisher"/>
                        </namePart>
                    </contributor>
                </xsl:if>

                <publisher>
                    <xsl:value-of select="$publisher"/>
                </publisher>

            </citationMetadata>
        </citationInfo>
        
    </xsl:template>


    <!-- ====================================== -->
    <!-- Party RegistryObject - Child Templates -->
    <!-- ====================================== -->

    <!-- Party Registry Object (Individuals (person) and Publishers (group)) -->
    <xsl:template match="publisher">
        <xsl:variable name="name" select="normalize-space(name)"/>
        <xsl:variable name="identifier" select="normalize-space(identifier)"/>
        <xsl:if test="string-length($name) > 0">
            <registryObject group="{$global_group}">

                <key>
                    <xsl:value-of select="concat($global_acronym, '/', translate(lower-case($identifier),' ',''))"/>
                </key>
                
                <originatingSource>
                    <xsl:choose>
                        <xsl:when test="string-length(normalize-space($name)) > 0">
                            <xsl:value-of select="normalize-space($name)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="source/name"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </originatingSource>

                <party type="group">
                    
                    <xsl:if test="string-length(normalize-space($identifier))">
                        <identifier type="local">
                            <xsl:value-of select="$identifier"/>
                        </identifier>
                    </xsl:if>
                    
                    <xsl:if test="string-length($identifier)">
                        <identifier type="uri">
                            <xsl:value-of select="concat($global_baseURI,'organisations/', $identifier)"/>
                        </identifier>
                    </xsl:if>

                    <name type="primary">
                        <namePart>
                            <xsl:value-of select="$name"/>
                        </namePart>
                    </name>
                    
                    <description type="full">
                        <xsl:value-of select="description"/>
                    </description>

                    <xsl:if test="string-length($identifier)">
                        <location>
                            <address>
                                <electronic>
                                    <xsl:attribute name="type">
                                        <xsl:text>url</xsl:text>
                                    </xsl:attribute>
                                    <value>
                                        <xsl:value-of select="concat($global_baseURI, 'organisations/', $identifier)"/>
                                    </value>
                                </electronic>
                            </address>
                        </location>
                    </xsl:if>
                    
                    <xsl:if test="string-length(normalize-space(email))">
                        <location>
                            <address>
                                <electronic type="email">
                                    <value>
                                        <xsl:value-of select="normalize-space(email)"/>
                                    </value>
                                </electronic>
                            </address>
                        </location>
                    </xsl:if>
                    
                    <xsl:if test="string-length(normalize-space(website))">
                        <location>
                            <address>
                                <electronic type="url">
                                    <value>
                                        <xsl:value-of select="normalize-space(website)"/>
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
                    <!--xsl:for-each select="../resources">
                        <xsl:variable name="serviceUrl" select="custom:getServiceUrl(.)"/>
                        <xsl:variable name="serviceName" select="custom:getServiceName($serviceUrl)"/>
                        <xsl:if test="string-length($serviceUrl) > 0">
                            <relatedInfo type="service">
                                <identifier type="uri">
                                    <xsl:value-of select="$serviceUrl"/>
                                </identifier>
                                <relation type="isManagerOf"/>
                                <xsl:if
                                    test="string-length($title) > 0 or string-length($serviceName) > 0">
                                    <title>
                                        <xsl:choose>
                                            <xsl:when test="string-length($serviceName)">
                                                <xsl:value-of
                                                  select="concat($serviceName, ' for access to ', $title, ' data')"
                                                />
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of
                                                  select="concat('Service for access to ', $title, ' data')"
                                                />
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </title>
                                </xsl:if>
                            </relatedInfo>
                        </xsl:if>
                    </xsl:for-each-->

                </party>
            </registryObject>
        </xsl:if>
    </xsl:template>

    <!-- Party Registry Object (Individuals (person) and Publishers (group)) -->
    <!--xsl:template match="datasets/result" mode="party_author">
        <xsl:variable name="name" select="author"/>
        <xsl:if test="string-length($name) > 0">
            <registryObject group="{$global_group}">

                <key>
                    <xsl:value-of
                        select="concat($global_group, '/', translate(lower-case($name),' ',''))"/>
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
                            <xsl:value-of select="$name"/>
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

                    <xsl:variable name="orgName" select="publisher/title"/>
                    <xsl:if test="boolean(string-length($orgName))">
                        <relatedObject>
                            <key>
                                <xsl:value-of
                                    select="concat($global_group,'/', translate(lower-case($name),' ',''))"
                                />
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
    </xsl:template-->

    <!-- ====================================== -->
    <!-- Service RegistryObject - Template -->
    <!-- ====================================== -->

    <!-- Service Registry Object -->
    <xsl:template match="*[contains(local-name(), 'dataSets')]" mode="service">
        <xsl:variable name="publisherName" select="normalize-space(publisher/name)"/>
        <xsl:variable name="publisherDescription"
            select="normalize-space(publisher/description)"/>
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

                        <xsl:variable name="serviceName" select="custom:getServiceName($serviceURI)"/>

                        <name type="primary">
                            <namePart>
                                <xsl:choose>
                                    <xsl:when test="string-length($serviceName)">
                                        <xsl:value-of
                                            select="concat($serviceName, ' for access to ', $publisherName, ' data')"
                                        />
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of
                                            select="concat('Service for access to ', $publisherName, ' data')"
                                        />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </namePart>
                        </name>

                        <xsl:if test="string-length($publisherDescription)">
                            <description>
                                <xsl:attribute name="type">
                                    <xsl:text>brief</xsl:text>
                                </xsl:attribute>
                                <xsl:value-of
                                    select="concat('Service for access to ', $publisherName, ' data')"
                                />
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

                        <xsl:if test="string-length($publisherName)">
                            <relatedInfo type="party">
                                <identifier type="uri">
                                    <xsl:value-of
                                        select="concat($global_baseURI,'organisations/', $publisherName)"
                                    />
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
            <xsl:if test="string-length($url)">
                <!--xsl:choose-->
                    <!-- Indicates parameters -->
                        <!--xsl:when test="contains($url, '?')"> 
                        <xsl:variable name="baseURL" select="substring-before($url, '?')"/>
                        <xsl:choose>
                            <xsl:when test="substring($baseURL, string-length($baseURL), 1) = '/'">
                                <xsl:value-of
                                    select="substring($baseURL, 1, string-length($baseURL)-1)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$baseURL"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when-->
                        <!--xsl:otherwise-->
                            <xsl:if test="contains(lower-case(normalize-space(resource_type)), 'api')">
                            <xsl:variable name="serviceUrl">
                                <xsl:choose>
                                    <xsl:when test="contains($url, '?')">
                                        <!-- Indicates parameters -->
                                        <xsl:variable name="baseURL"
                                            select="substring-before($url, '?')"/>
                                        <!-- obtain base url before '?' and parameters -->
                                        <xsl:choose>
                                            <xsl:when
                                                test="substring($baseURL, string-length($baseURL), 1) = '/'">
                                                <!-- remove trailing backslash if there is one -->
                                                <xsl:value-of
                                                  select="substring($baseURL, 1, string-length($baseURL)-1)"
                                                />
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="$baseURL"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- retrieve url before file name and extension if there is one-->
                                        <xsl:value-of                                            select="string-join(tokenize($url,'/')[position()!=last()],'/')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:value-of select="$serviceUrl"/>
                        </xsl:if>
                    <!--/xsl:otherwise-->
                <!--/xsl:choose-->
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

   
    
   <!-- Change input from:
            [link-text](http://link)
         to:
            <a href="http://link">link-text</a>  
    -->
    <xsl:function name="custom:reformatHyperlinks" as="xs:string">
        <xsl:param name="input"/>
	<xsl:variable name="result" as="xs:string*">
        <xsl:analyze-string regex="(\[[^\]]*\])(\([^\)]*\))" select="$input">
            <xsl:matching-substring>
                <xsl:variable name="text_sequence" select="regex-group(1)" as="xs:string*"/>
                <xsl:variable name="link_sequence" select="regex-group(2)" as="xs:string*"/>
		<xsl:for-each select="$text_sequence">
                	<xsl:if test="(string-length(.) > 0) and (string-length($link_sequence[position()]) > 0)">
                    	<xsl:value-of select="concat('&lt;a href=&quot;', substring($link_sequence[position()], 2, string-length($link_sequence[position()])-2), '&quot;&gt;', substring(., 2, string-length(.)-2), '&lt;/a&gt;')"/>
                	</xsl:if>
		</xsl:for-each>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="."/>  
            </xsl:non-matching-substring> 
        </xsl:analyze-string>
	</xsl:variable>
	<xsl:copy-of select="string-join($result, '')"/>
    </xsl:function> 

    <xsl:function name="custom:getServiceName">
        <xsl:param name="url"/>
        <xsl:choose>
            <xsl:when test="contains($url, 'rest/services/')">
                <xsl:value-of select="concat(substring-after($url, 'rest/services/'), ' service')"/>
            </xsl:when>
            <xsl:when test="contains($url, $global_baseURI)">
                <xsl:value-of
                    select="concat(substring-after($url, $global_baseURI), ' ', $global_group, ' service')"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="tokenize($url, '/')">
                    <xsl:if test="position() = count(tokenize($url, '/'))">
                        <xsl:value-of select="concat(normalize-space(.), ' service')"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="custom:getServiceUrl">
        <xsl:param name="resources"/>
        <xsl:variable name="url" select="$resources/url"/>
        <!--xsl:choose-->
        <!-- Indicates parameters -->
        <!--xsl:when test="contains($url, '?')">
                <xsl:variable name="baseURL" select="substring-before($url, '?')"/>
                <xsl:choose>
                    <xsl:when test="substring($baseURL, string-length($baseURL), 1) = '/'">
                        <xsl:value-of select="substring($baseURL, 1, string-length($baseURL)-1)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$baseURL"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when-->
        <!--xsl:otherwise-->
        <xsl:if
            test="contains(lower-case(normalize-space($resources/resource_type)), 'api')">
            <xsl:choose>
                <xsl:when test="contains($url, '?')">
                    <!-- Indicates parameters -->
                    <xsl:variable name="baseURL" select="substring-before($url, '?')"/>
                    <!-- obtain base url before '?' and parameters -->
                    <xsl:choose>
                        <xsl:when
                            test="substring($baseURL, string-length($baseURL), 1) = '/'">
                            <!-- remove trailing backslash if there is one -->
                            <xsl:value-of
                                select="substring($baseURL, 1, string-length($baseURL)-1)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$baseURL"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <!-- retrieve url before file name and extension if there is one-->
                    <xsl:value-of
                        select="string-join(tokenize($url,'/')[position()!=last()],'/')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!--/xsl:otherwise-->
        <!--/xsl:choose-->
    </xsl:function>
    
    
</xsl:stylesheet>
