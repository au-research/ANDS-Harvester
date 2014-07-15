<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:mcp="http://bluenet3.antcrc.utas.edu.au/mcp" xmlns:gmd="http://www.isotc211.org/2005/gmd"
    xmlns:srv="http://www.isotc211.org/2005/srv"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:gml="http://www.opengis.net/gml"
    xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:gts="http://www.isotc211.org/2005/gts"
    xmlns:geonet="http://www.fao.org/geonetwork" xmlns:gmx="http://www.isotc211.org/2005/gmx"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://ands.org.au/standards/rif-cs/registryObjects"
    exclude-result-prefixes="geonet gmx oai xsi gmd srv gml gco gts">
    <!-- stylesheet to convert iso19139 in OAI-PMH ListRecords response to RIF-CS -->
    <xsl:output method="xml" version="1.0" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:param name="global_originatingSource" select="'http://e-atlas.org.au:80'"/>
    <xsl:param name="global_group" select="'e-Atlas'"/>
    <xsl:param name="global_publisherName" select="'e-Atlas'"/>
    <xsl:param name="global_publisherPlace" select="'Canberra'"/>
    <xsl:variable name="anzsrcCodelist" select="document('anzsrc-codelist.xml')"/>
    <xsl:variable name="licenseCodelist" select="document('license-codelist.xml')"/>
    <xsl:variable name="gmdCodelists" select="document('codelists.xml')"/>

    <xsl:template match="oai:responseDate"/>
    <xsl:template match="oai:resumptionToken"/>
    <xsl:template match="oai:request"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:identifier"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:datestamp"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:setSpec"/>

    <!-- =========================================== -->
    <!-- RegistryObjects (root) Template             -->
    <!-- =========================================== -->

    <xsl:template match="/">
        <registryObjects>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="//mcp:MD_Metadata"/>
        </registryObjects>
    </xsl:template>

    <!-- =========================================== -->
    <!-- RegistryObject RegistryObject Template          -->
    <!-- =========================================== -->

    <xsl:template match="mcp:MD_Metadata">

        <xsl:variable name="metadataURL">
            <xsl:call-template name="getMetadataURL">
                <xsl:with-param name="transferOptions"
                    select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions"
                />
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="scopeCode">
            <xsl:choose>
                <xsl:when test="string-length(normalize-space(gmd:hierarchyLevel/gmx:MX_ScopeCode/@codeListValue)) > 0">
                    <xsl:value-of select="normalize-space(gmd:hierarchyLevel/gmx:MX_ScopeCode/@codeListValue)"/>
                </xsl:when>
                <xsl:when test="string-length(normalize-space(gmd:hierarchyLevel/gmd:MD_ScopeCode/@codeListValue)) > 0">
                    <xsl:value-of select="normalize-space(gmd:hierarchyLevel/gmd:MD_ScopeCode/@codeListValue)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>dataset</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        

        <xsl:message>metadataURL: <xsl:value-of select="$metadataURL"/></xsl:message>
        <xsl:if
            test="contains($metadataURL, 'http://e-atlas.org.au')">

            <registryObject>
                <xsl:attribute name="group">
                    <xsl:value-of select="$global_group"/>
                </xsl:attribute>
                <xsl:apply-templates select="gmd:fileIdentifier" mode="registryObject_key"/>

                <xsl:variable name="metadataCreationDate" select="normalize-space(gmd:dateStamp/gco:DateTime)"/>
               
                <xsl:apply-templates
                    select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions"
                    mode="registryObject_originating_source"/>

                <xsl:variable name="registryObjectType">
                    <xsl:call-template name="getRegistryObjectType">
                        <xsl:with-param name="scopeCode" select="$scopeCode"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:element name="{$registryObjectType}">

                    <xsl:variable name="registryObjectSubType">
                        <xsl:call-template name="getRegistryObjectSubType">
                            <xsl:with-param name="scopeCode" select="$scopeCode"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <xsl:if test="string-length($registryObjectSubType)">
                        <xsl:attribute name="type">
                            <xsl:value-of select="$registryObjectSubType"/>
                        </xsl:attribute>
                    </xsl:if>

                    <xsl:apply-templates select="gmd:fileIdentifier" mode="registryObject_identifier"/>

                    <xsl:apply-templates
                        select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions"
                        mode="registryObject_identifier"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title"
                        mode="registryObject_name"/>

                    <xsl:apply-templates select="gmd:parentIdentifier"
                        mode="registryObject_related_object"/>

                    <xsl:apply-templates
                        select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions"
                        mode="registryObject_location"/>
                    
                    <xsl:for-each-group
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
                     (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
                     gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
                     (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
                     gmd:identificationInfo/mcp:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
                     (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                        group-by="gmd:individualName">
                        <xsl:apply-templates select="." mode="registryObject_related_object"/>
                    </xsl:for-each-group>

                    <xsl:for-each-group
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName)) and not(string-length(normalize-space(gmd:individualName)))) and 
                     (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
                     gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName)) and not(string-length(normalize-space(gmd:individualName)))) and 
                     (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
                     gmd:identificationInfo/mcp:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName)) and not(string-length(normalize-space(gmd:individualName)))) and 
                     (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                        group-by="gmd:organisationName">
                        <xsl:apply-templates select="." mode="registryObject_related_object"/>
                    </xsl:for-each-group>

                    <xsl:apply-templates select="mcp:children/mcp:childIdentifier"
                        mode="registryObject_related_object"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode"
                        mode="registryObject_subject"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:keyword"
                        mode="registryObject_subject"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:keyword"
                        mode="registryObject_subject_anzsrc"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:abstract"
                        mode="registryObject_description"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox"
                        mode="registryObject_coverage_spatial"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_BoundingPolygon"
                        mode="registryObject_coverage_spatial"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/mcp:EX_TemporalExtent"
                        mode="registryObject_coverage_temporal"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent"
                        mode="registryObject_coverage_temporal"/>

                    <xsl:apply-templates
                        select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions"
                        mode="registryObject_relatedInfo"/>

                    <xsl:apply-templates select="mcp:children/mcp:childIdentifier"
                        mode="registryObject_relatedInfo"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:resourceConstraints/mcp:MD_CreativeCommons[
                     exists(mcp:licenseLink) and string-length(mcp:licenseLink)]"
                        mode="registryObject_rights_licence_creative"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:resourceConstraints/mcp:MD_CreativeCommons"
                        mode="registryObject_rights_rightsStatement_creative"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints[
                     exists(gmd:useLimitation) and string-length(gmd:useLimitation)]"
                        mode="registryObject_rights_rightsStatement"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints[
                     exists(gmd:accessConstraints) and string-length(gmd:accessConstraints)]"
                        mode="registryObject_rights_accessRights"/>

                    <xsl:apply-templates
                        select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints[
                     exists(gmd:useConstraints) and string-length(gmd:useConstraints)]"
                        mode="registryObject_rights_licence"/>

                    <xsl:if test="$registryObjectType = 'collection'">
                      
                        <xsl:variable name="pointOfContactNode_sequence" as="node()*">
                            <xsl:call-template name="getPointOfContactSequence">
                                <xsl:with-param name="parent" select="gmd:identificationInfo/mcp:MD_DataIdentification"/>
                            </xsl:call-template>
                        </xsl:variable>
                        
                        <xsl:variable name="distributorContactNode_sequence" as="node()*">
                            <xsl:call-template name="getDistributorContactSequence">
                                <xsl:with-param name="parent" select="gmd:distributionInfo/gmd:MD_Distribution"/>
                            </xsl:call-template>
                        </xsl:variable>
                        
                        <xsl:apply-templates
                             select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date"
                             mode="registryObject_dates"/>
                         
                         <xsl:for-each
                             select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:citation/gmd:CI_Citation">
                             <xsl:call-template name="registryObject_citationMetadata_citationInfo">
                                 <xsl:with-param name="metadataURL" select="$metadataURL"/>
                                 <xsl:with-param name="citation" select="."/>
                                 <xsl:with-param name="pointOfContactNode_sequence" select="$pointOfContactNode_sequence" as="node()*"/>
                                 <xsl:with-param name="distributorContactNode_sequence" select="$distributorContactNode_sequence" as="node()*"/>
                                 <xsl:with-param name="metadataCreationDate" select="$metadataCreationDate"/>
                             </xsl:call-template>
                         </xsl:for-each>
                    </xsl:if>

                </xsl:element>
            </registryObject>

            <!-- =========================================== -->
            <!-- Party RegistryObject Template          -->
            <!-- =========================================== -->

            <xsl:for-each-group
                select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
             gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
             gmd:identificationInfo/mcp:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                group-by="gmd:individualName">
                <xsl:call-template name="party">
                    <xsl:with-param name="type">person</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each-group>

            <xsl:for-each-group
                select="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
             gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
             gmd:identificationInfo/mcp:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                group-by="gmd:organisationName">
                <xsl:call-template name="party">
                    <xsl:with-param name="type">group</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each-group>

        </xsl:if>

    </xsl:template>

    <!-- =========================================== -->
    <!-- RegistryObject RegistryObject - Child Templates -->
    <!-- =========================================== -->

    <!-- RegistryObject - Key Element  -->
    <xsl:template match="gmd:fileIdentifier" mode="registryObject_key">
        <key>
            <xsl:value-of select="concat($global_group,'/', normalize-space(.))"/>
        </key>
    </xsl:template>

    <!-- RegistryObject - Originating Source Element  -->
    <xsl:template match="gmd:MD_DigitalTransferOptions" mode="registryObject_originating_source">
        <xsl:for-each select="gmd:onLine/gmd:CI_OnlineResource">
            <xsl:if test="contains(gmd:protocol, 'http--metadata-URL')">
                <originatingSource>
                    <!-- Match will match the uri up to the third forward slash, e.g. it will match "http(s)://data.aims.gov.au/"
                        from examples like the following:  http(s)://data.aims.gov.au/ http(s)://data.aims.gov.au/morethings http(s)://data.aims.gov.au/more/stuff/-->
                    <xsl:variable name="match">
                        <xsl:analyze-string select="normalize-space(gmd:linkage/gmd:URL)"
                            regex="(http:|https:)//(\S+?)(/)">
                            <xsl:matching-substring>
                                <xsl:value-of select="regex-group(0)"/>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when
                            test="(string-length($match) > 0) and (substring($match, string-length($match), 1) = '/')">
                            <xsl:value-of select="substring($match, 1, string-length($match)-1)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- If we didn't match that pattern, just include the entire thing - rare but possible -->
                            <xsl:value-of select="normalize-space(gmd:linkage/gmd:URL)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </originatingSource>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- RegistryObject - Identifier Element  -->
    <xsl:template match="gmd:fileIdentifier" mode="registryObject_identifier">
        <xsl:variable name="identifier" select="normalize-space(.)"/>
        <xsl:if test="string-length($identifier)">
            <identifier>
                <xsl:attribute name="type">
                    <xsl:text>local</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$identifier"/>
            </identifier>
            <identifier>
                <xsl:attribute name="type">
                    <xsl:text>global</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="concat($global_group,'/', $identifier)"/>
            </identifier>
        </xsl:if>
    </xsl:template>

    <!-- RegistryObject - Identifier Element  -->
    <xsl:template match="gmd:MD_DigitalTransferOptions" mode="registryObject_identifier">
        <xsl:for-each select="gmd:onLine/gmd:CI_OnlineResource">
            <xsl:if test="contains(gmd:protocol, 'WWW:LINK-1.0-http--metadata-URL')">
                <xsl:if test="string-length(normalize-space(gmd:linkage/gmd:URL)) > 0">
                    <identifier>
                        <xsl:attribute name="type">
                            <xsl:text>uri</xsl:text>
                        </xsl:attribute>
                        <xsl:value-of select="normalize-space(gmd:linkage/gmd:URL)"/>
                    </identifier>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- RegistryObject - Name Element  -->
    <xsl:template
        match="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title"
        mode="registryObject_name">
        <name>
            <xsl:attribute name="type">
                <xsl:text>primary</xsl:text>
            </xsl:attribute>
            <namePart>
                <xsl:value-of select="."/>
            </namePart>
        </name>
    </xsl:template>
    
    <!-- RegistryObject - Point of Contact Sequence  -->
    
    <xsl:template name="getPointOfContactSequence" as="node()*">
       <xsl:param name="parent" as="node()"/>
       <xsl:for-each select="$parent/descendant::gmd:pointOfContact">
           <xsl:copy-of select="."/>
       </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="getDistributorContactSequence" as="node()*">
        <xsl:param name="parent"/>
        <xsl:for-each select="$parent/descendant::gmd:distributorContact">
            <xsl:copy-of select="."/>
        </xsl:for-each>
    </xsl:template>

    <!-- RegistryObject - Dates Element  -->
    <xsl:template
        match="gmd:identificationInfo/mcp:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date"
        mode="registryObject_dates">
        <xsl:variable name="dateTime" select="normalize-space(gmd:CI_Date/gmd:date/gco:DateTime)"/>
        <xsl:variable name="dateCode"
            select="normalize-space(gmd:CI_Date/gmd:dateType/gmd:CI_DateTypeCode/@codeListValue)"/>
        <xsl:variable name="transformedDateCode">
            <xsl:choose>
                <xsl:when test="contains($dateCode, 'creation')">
                    <xsl:text>created</xsl:text>
                </xsl:when>
                <xsl:when test="contains($dateCode, 'publication')">
                    <xsl:text>issued</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:if
            test="
            (string-length($dateTime) > 0) and
            (string-length($transformedDateCode) > 0)">
            <dates>
                <xsl:attribute name="type">
                    <xsl:value-of select="$transformedDateCode"/>
                </xsl:attribute>
                <date>
                    <xsl:attribute name="type">
                        <xsl:text>dateFrom</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="dateFormat">
                        <xsl:text>W3CDTF</xsl:text>
                    </xsl:attribute>
                    <xsl:value-of select="$dateTime"/>
                </date>
            </dates>
        </xsl:if>
    </xsl:template>
    
    <!-- RegistryObject - Related Object Element  -->
    <xsl:template match="gmd:parentIdentifier" mode="registryObject_related_object">
        <xsl:variable name="identifier" select="normalize-space(.)"/>
        <xsl:if test="string-length($identifier)">
            <relatedObject>
                <key>
                    <xsl:value-of select="concat($global_group,'/', $identifier)"/>
                </key>
                <relation>
                    <xsl:attribute name="type">
                        <xsl:text>isPartOf</xsl:text>
                    </xsl:attribute>
                </relation>
            </relatedObject>
        </xsl:if>
    </xsl:template>
    
    <!-- RegistryObject - Location Element  -->
    <xsl:template match="gmd:MD_DigitalTransferOptions" mode="registryObject_location">
        <xsl:for-each select="gmd:onLine/gmd:CI_OnlineResource">
            <xsl:if test="contains(gmd:protocol, 'WWW:LINK-1.0-http--metadata-URL')">
                <xsl:if test="string-length(normalize-space(gmd:linkage/gmd:URL)) > 0">
                    <location>
                        <address>
                            <electronic>
                                <xsl:attribute name="type">
                                    <xsl:text>url</xsl:text>
                                </xsl:attribute>
                                <value>
                                    <xsl:value-of select="normalize-space(gmd:linkage/gmd:URL)"/>
                                </value>
                            </electronic>
                        </address>
                    </location>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- RegistryObject - Related Object (Organisation or Individual) Element -->
    <xsl:template match="gmd:CI_ResponsibleParty" mode="registryObject_related_object">
        <xsl:variable name="transformedName">
            <xsl:call-template name="getTransformed">
                <xsl:with-param name="inputString" select="current-grouping-key()"/>
            </xsl:call-template>
        </xsl:variable>
        <relatedObject>
            <key>
                <xsl:value-of
                    select="concat($global_group,'/', translate(normalize-space($transformedName),' ',''))"
                />
            </key>
            <xsl:for-each-group select="current-group()/gmd:role"
                group-by="gmd:CI_RoleCode/@codeListValue">
                <xsl:variable name="code">
                    <xsl:value-of select="current-grouping-key()"/>
                </xsl:variable>
                <relation>
                    <xsl:attribute name="type">
                        <xsl:value-of select="$code"/>
                    </xsl:attribute>
                </relation>
            </xsl:for-each-group>
        </relatedObject>
    </xsl:template>

    <!-- RegistryObject - Related Object Element  -->
    <xsl:template match="mcp:childIdentifier" mode="registryObject_related_object">
        <xsl:message>mcp:children</xsl:message>
        <xsl:variable name="identifier" select="normalize-space(.)"/>
        <xsl:if test="string-length($identifier)">
            <relatedObject>
                <key>
                    <xsl:value-of select="concat($global_group,'/', $identifier)"/>
                </key>
                <relation>
                    <xsl:attribute name="type">
                        <xsl:text>hasPart</xsl:text>
                    </xsl:attribute>
                </relation>
            </relatedObject>
        </xsl:if>
    </xsl:template>

    <!-- RegistryObject - Subject Element -->
    <xsl:template match="gmd:keyword" mode="registryObject_subject">
        <xsl:call-template name="getSplitText">
            <xsl:with-param name="string" select="."/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="gmd:MD_TopicCategoryCode" mode="registryObject_subject">
        <xsl:call-template name="getSplitText">
            <xsl:with-param name="string" select="."/>
        </xsl:call-template>
    </xsl:template>

    <!-- RegistryObject - Subject (anzsrc) Element -->
    <xsl:template match="gmd:keyword" mode="registryObject_subject_anzsrc">
        <xsl:variable name="keyword" select="string(gco:CharacterString)"/>
        <xsl:variable name="code"
            select="(normalize-space($anzsrcCodelist//gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='ANZSRCCode']/gmx:codeEntry/gmx:CodeDefinition/gml:identifier[following-sibling::gml:name = $keyword]))[1]"/>
        <xsl:if test="string-length($code)">
            <subject>
                <xsl:attribute name="type">
                    <xsl:value-of select="'anzsrc-for'"/>
                </xsl:attribute>
                <xsl:value-of select="$code"/>
            </subject>
        </xsl:if>
    </xsl:template>

    <!-- RegistryObject - Decription Element -->
    <xsl:template match="gmd:abstract" mode="registryObject_description">
        <description type="brief">
            <xsl:value-of select="."/>
        </description>
    </xsl:template>

    <!-- RegistryObject - Coverage Spatial Element -->
    <xsl:template match="gmd:EX_GeographicBoundingBox" mode="registryObject_coverage_spatial">
        <xsl:if
            test="
            (string-length(normalize-space(gmd:northBoundLatitude/gco:Decimal))) and
            (string-length(normalize-space(gmd:southBoundLatitude/gco:Decimal))) and
            (string-length(normalize-space(gmd:westBoundLongitude/gco:Decimal))) and
            (string-length(normalize-space(gmd:eastBoundLongitude/gco:Decimal)))">
            <coverage>
                <spatial>
                    <xsl:attribute name="type">
                        <xsl:text>iso19139dcmiBox</xsl:text>
                    </xsl:attribute>
                    <xsl:value-of
                        select="normalize-space(concat('northlimit=',gmd:northBoundLatitude/gco:Decimal,'; southlimit=',gmd:southBoundLatitude/gco:Decimal,'; westlimit=',gmd:westBoundLongitude/gco:Decimal,'; eastLimit=',gmd:eastBoundLongitude/gco:Decimal))"/>

                    <xsl:if
                        test="
                        (string-length(normalize-space(gmd:EX_VerticalExtent/gmd:maximumValue/gco:Real))) and
                        (string-length(normalize-space(gmd:EX_VerticalExtent/gmd:minimumValue/gco:Real)))">
                        <xsl:value-of
                            select="normalize-space(concat('; uplimit=',gmd:EX_VerticalExtent/gmd:maximumValue/gco:Real,'; downlimit=',gmd:EX_VerticalExtent/gmd:minimumValue/gco:Real))"
                        />
                    </xsl:if>
                    <xsl:text>; projection=WGS84</xsl:text>
                </spatial>
                <spatial>
                    <xsl:attribute name="type">
                        <xsl:text>text</xsl:text>
                    </xsl:attribute>
                    <xsl:value-of
                        select="normalize-space(concat('northlimit=',gmd:northBoundLatitude/gco:Decimal,'; southlimit=',gmd:southBoundLatitude/gco:Decimal,'; westlimit=',gmd:westBoundLongitude/gco:Decimal,'; eastLimit=',gmd:eastBoundLongitude/gco:Decimal))"/>
                    
                    <xsl:if
                        test="
                        (string-length(normalize-space(gmd:EX_VerticalExtent/gmd:maximumValue/gco:Real))) and
                        (string-length(normalize-space(gmd:EX_VerticalExtent/gmd:minimumValue/gco:Real)))">
                        <xsl:value-of
                            select="normalize-space(concat('; uplimit=',gmd:EX_VerticalExtent/gmd:maximumValue/gco:Real,'; downlimit=',gmd:EX_VerticalExtent/gmd:minimumValue/gco:Real))"
                        />
                    </xsl:if>
                    <xsl:text>; projection=WGS84</xsl:text>
                </spatial>
            </coverage>
        </xsl:if>
    </xsl:template>


    <!-- RegistryObject - Coverage Spatial Element -->
    <xsl:template match="gmd:EX_BoundingPolygon" mode="registryObject_coverage_spatial">
        <xsl:for-each select="gmd:polygon/gml:Polygon/gml:exterior/gml:LinearRing/gml:coordinates">
            <xsl:if
                test="boolean(string-length(normalize-space(.)))">
                <coverage>
                    <spatial>
                        <xsl:attribute name="type">
                            <xsl:text>gmlKmlPolyCoords</xsl:text>
                        </xsl:attribute>
                        <xsl:value-of
                            select="replace(normalize-space(.), ',0', '')"
                        />
                    </spatial>
                </coverage>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- RegistryObject - Coverage Temporal Element -->
    <xsl:template match="mcp:EX_TemporalExtent" mode="registryObject_coverage_temporal">
        <xsl:if
            test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:begin/gml:TimeInstant/gml:timePosition)) or
                      string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:end/gml:TimeInstant/gml:timePosition))">
            <coverage>
                <temporal>
                    <xsl:if
                        test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:begin/gml:TimeInstant/gml:timePosition)) > 0">
                        <date>
                            <xsl:attribute name="type">
                                <xsl:text>dateFrom</xsl:text>
                            </xsl:attribute>
                            <xsl:attribute name="dateFormat">
                                <xsl:text>W3CDTF</xsl:text>
                            </xsl:attribute>
                            <xsl:value-of
                                select="normalize-space(gmd:extent/gml:TimePeriod/gml:begin/gml:TimeInstant/gml:timePosition)"
                            />
                        </date>
                    </xsl:if>
                    <xsl:if
                        test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:end/gml:TimeInstant/gml:timePosition)) > 0">
                        <date>
                            <xsl:attribute name="type">
                                <xsl:text>dateTo</xsl:text>
                            </xsl:attribute>
                            <xsl:attribute name="dateFormat">
                                <xsl:text>W3CDTF</xsl:text>
                            </xsl:attribute>
                            <xsl:value-of
                                select="normalize-space(gmd:extent/gml:TimePeriod/gml:end/gml:TimeInstant/gml:timePosition)"
                            />
                        </date>
                    </xsl:if>
                </temporal>
            </coverage>
        </xsl:if>
    </xsl:template>

    <!-- RegistryObject - Coverage Temporal Element -->
    <xsl:template match="gmd:EX_TemporalExtent" mode="registryObject_coverage_temporal">
        <xsl:if
            test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:beginPosition)) or
            string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:endPosition))">
            <coverage>
                <temporal>
                    <xsl:if
                        test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:beginPosition)) > 0">
                        <date>
                            <xsl:attribute name="type">
                                <xsl:text>dateFrom</xsl:text>
                            </xsl:attribute>
                            <xsl:attribute name="dateFormat">
                                <xsl:text>W3CDTF</xsl:text>
                            </xsl:attribute>
                            <xsl:value-of
                                select="normalize-space(gmd:extent/gml:TimePeriod/gml:beginPosition)"
                            />
                        </date>
                    </xsl:if>
                    <xsl:if
                        test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:endPosition)) > 0">
                        <date>
                            <xsl:attribute name="type">
                                <xsl:text>dateTo</xsl:text>
                            </xsl:attribute>
                            <xsl:attribute name="dateFormat">
                                <xsl:text>W3CDTF</xsl:text>
                            </xsl:attribute>
                            <xsl:value-of
                                select="normalize-space(gmd:extent/gml:TimePeriod/gml:endPosition)"
                            />
                        </date>
                    </xsl:if>
                </temporal>
            </coverage>
        </xsl:if>
    </xsl:template>

    <!-- RegistryObject - RelatedInfo Element  -->
    <xsl:template match="gmd:MD_DigitalTransferOptions" mode="registryObject_relatedInfo">
        <xsl:for-each select="gmd:onLine/gmd:CI_OnlineResource">

            <xsl:variable name="protocol" select="normalize-space(gmd:protocol)"/>
            <!-- metadata-URL was added as electronic address and possibly citation identifier, too
                 (if there was no alternative identifier - e.g. DOI - specified in CI_Citation)
                 Add all other online resources here as relatedInfo -->
            <xsl:if test="string-length($protocol) and not(contains($protocol, 'metadata-URL'))">

                <xsl:variable name="identifierValue" select="normalize-space(gmd:linkage/gmd:URL)"/>
                <xsl:if test="string-length($identifierValue) > 0">
                    <relatedInfo>
                        <xsl:choose>
                            <xsl:when test="contains($protocol, 'get-map')">
                                <xsl:attribute name="type">
                                    <xsl:value-of select="'service'"/>
                                </xsl:attribute>

                                <identifier>
                                    <xsl:attribute name="type">
                                        <xsl:choose>
                                            <xsl:when test="contains($identifierValue, 'doi')">
                                                <xsl:text>doi</xsl:text>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:text>uri</xsl:text>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                    <xsl:value-of select="$identifierValue"/>
                                </identifier>

                                <relation>
                                    <xsl:attribute name="type">
                                        <xsl:text>isAvailableThrough</xsl:text>
                                    </xsl:attribute>
                                </relation>

                            </xsl:when>
                            <xsl:when test="contains($protocol, 'related')">
                                <xsl:attribute name="type">
                                    <xsl:choose>
                                        <xsl:when test="contains($identifierValue, 'extpubs')">
                                            <xsl:text>publication</xsl:text>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>website</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>

                                <identifier>
                                    <xsl:attribute name="type">
                                        <xsl:choose>
                                            <xsl:when test="contains($identifierValue, 'doi')">
                                                <xsl:text>doi</xsl:text>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:text>uri</xsl:text>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                    <xsl:value-of select="$identifierValue"/>
                                </identifier>

                                <relation>
                                    <xsl:attribute name="type">
                                        <xsl:choose>
                                            <xsl:when test="contains($identifierValue, 'extpubs')">
                                                <xsl:text>isReferencedBy</xsl:text>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:text>hasAssociationWith</xsl:text>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                </relation>
                            </xsl:when>
                            <xsl:when test="contains($protocol, 'link')">
                                <xsl:attribute name="type">
                                    <xsl:choose>
                                        <xsl:when test="contains($identifierValue, 'datatool')">
                                            <xsl:text>service</xsl:text>
                                        </xsl:when>
                                        <xsl:when test="contains($identifierValue, 'rss')">
                                            <xsl:text>service</xsl:text>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>website</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>

                                <identifier>
                                    <xsl:attribute name="type">
                                        <xsl:choose>
                                            <xsl:when test="contains($identifierValue, 'doi')">
                                                <xsl:text>doi</xsl:text>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:text>uri</xsl:text>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                    <xsl:value-of select="$identifierValue"/>
                                </identifier>

                                <relation>
                                    <xsl:attribute name="type">
                                        <xsl:choose>
                                            <xsl:when
                                                test="contains($identifierValue, 'datatool') or contains($identifierValue, 'rss')">
                                                <xsl:text>isAvailableThrough</xsl:text>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:text>hasAssociationWith</xsl:text>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                </relation>
                            </xsl:when>
                        </xsl:choose>
                        
                        <xsl:choose>
                            <!-- Use name as title if we have it... -->
                            <xsl:when test="string-length(normalize-space(gmd:name))">
                                <title>
                                    <xsl:value-of select="normalize-space(gmd:name)"/>
                                </title>
                                <!-- ...and then description as notes -->
                                <xsl:if
                                    test="string-length(normalize-space(gmd:description))">
                                    <notes>
                                        <xsl:value-of
                                            select="normalize-space(gmd:description)"/>
                                    </notes>
                                </xsl:if>
                            </xsl:when>
                            <!-- No name, so use description as title if we have it -->
                            <xsl:otherwise>
                                <xsl:if
                                    test="string-length(normalize-space(gmd:description))">
                                    <title>
                                        <xsl:value-of
                                            select="normalize-space(gmd:description)"/>
                                    </title>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                    </relatedInfo>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- RegistryObject - RelatedInfo Element  -->
    <xsl:template match="mcp:childIdentifier" mode="registryObject_relatedInfo">
        <xsl:variable name="identifier" select="normalize-space(.)"/>
        <xsl:if test="string-length($identifier)">
            <relatedInfo type="collection">
                <identifier type="uri">
                    <xsl:value-of
                        select="concat('http://e-atlas.org.au/geonetwork/srv/en/metadata.show?uuid=', $identifier)"
                    />
                </identifier>
                <relation>
                    <xsl:attribute name="type">
                        <xsl:text>hasPart</xsl:text>
                    </xsl:attribute>
                </relation>
                <xsl:if test="string-length(normalize-space(@title))"/>
                <title>
                    <xsl:value-of select="normalize-space(@title)"/>
                </title>
            </relatedInfo>
        </xsl:if>
    </xsl:template>

    <!-- Variable - Individual Name -->
    <xsl:template match="mcp:MD_DataIdentification" mode="variable_individual_name">
        <xsl:message>Seeking owner...</xsl:message>
        <xsl:call-template name="getChildValueForRole">
            <xsl:with-param name="roleSubstring">
                <xsl:text>owner</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="childElementName">
                <xsl:text>individualName</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <!-- RegistryObject - Rights Licence - From CreativeCommons -->
    <xsl:template match="mcp:MD_CreativeCommons" mode="registryObject_rights_licence_creative">
        <xsl:variable name="licenseLink" select="mcp:licenseLink"/>
        <xsl:for-each
            select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
            <xsl:if test="string-length(normalize-space(gml:remarks))">
                <xsl:if test="contains($licenseLink, gml:remarks)">
                    <rights>
                        <licence>
                            <xsl:attribute name="type" select="gml:identifier"/>
                            <xsl:attribute name="rightsUri" select="$licenseLink"/>
                            <xsl:variable name="licenceText"
                                select="normalize-space(following-sibling::mcp:licenseName)"/>
                            <xsl:if test="string-length($licenceText)">
                                <xsl:value-of select="$licenceText"/>
                            </xsl:if>
                        </licence>
                    </rights>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>

        <!--xsl:for-each select="gmd:otherConstraints">
            <xsl:if test="string-length(normalize-space(.))">
                <rights>
                    <licence>
                        <xsl:value-of select='normalize-space(.)'/>
                    </licence>
                </rights>
            </xsl:if>
        </xsl:for-each-->
    </xsl:template>

    <!-- RegistryObject - Rights RightsStatement - From CreativeCommons -->
    <xsl:template match="mcp:MD_CreativeCommons" mode="registryObject_rights_rightsStatement_creative">
        <xsl:for-each select="mcp:attributionConstraints">
            <!-- If there is text in other contraints, use this; otherwise, do nothing -->
            <xsl:if test="string-length(normalize-space(.))">
                <rights>
                    <rightsStatement>
                        <xsl:value-of select="normalize-space(.)"/>
                    </rightsStatement>
                </rights>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- RegistryObject - RightsStatement -->
    <xsl:template match="gmd:MD_LegalConstraints" mode="registryObject_rights_rightsStatement">
        <xsl:for-each select="gmd:useLimitation">
            <!-- If there is text in other contraints, use this; otherwise, do nothing -->
            <xsl:if test="string-length(normalize-space(.))">
                <rights>
                    <rightsStatement>
                        <xsl:value-of select="normalize-space(.)"/>
                    </rightsStatement>
                </rights>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- RegistryObject - Rights AccessRights Element -->
    <xsl:template match="gmd:MD_LegalConstraints" mode="registryObject_rights_accessRights">
        <xsl:for-each select="gmd:accessConstraints">
            <xsl:variable name="accessConstraints" select="normalize-space(.)"/>
            <xsl:choose>
                <xsl:when test="contains($accessConstraints, 'otherRestrictions')">
                    <xsl:for-each select="following-sibling::gmd:otherConstraints">
                        <xsl:if test="string-length(normalize-space(.))">
                            <rights>
                                <accessRights>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </accessRights>
                            </rights>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <rights>
                        <accessRights>
                            <xsl:value-of select="$accessConstraints"/>
                        </accessRights>
                    </rights>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <!-- RegistryObject - Rights Licence Element -->
    <xsl:template match="gmd:MD_LegalConstraints" mode="registryObject_rights_licence">
        <xsl:for-each select="gmd:useConstraints">
            <xsl:variable name="useConstraints" select="normalize-space(.)"/>
            <xsl:choose>
                <xsl:when test="contains($useConstraints, 'otherRestrictions')">
                    <xsl:for-each select="following-sibling::gmd:otherConstraints">
                        <xsl:if test="string-length(normalize-space(.))">
                            <rights>
                                <licence>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </licence>
                            </rights>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <rights>
                        <licence>
                            <xsl:value-of select="$useConstraints"/>
                        </licence>
                    </rights>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <!-- RegistryObject - CitationInfo Element -->
    <xsl:template name="registryObject_citationMetadata_citationInfo">
        <xsl:param name="metadataURL"/>
        <xsl:param name="citation"/>
        <xsl:param name="pointOfContactNode_sequence" as="node()*"/>
        <xsl:param name="distributorContactNode_sequence" as="node()*"/>
        <xsl:param name="metadataCreationDate"/>
        
        
        <xsl:variable name="identifierType"
            select="normalize-space(gmd:identifier/gmd:MD_Identifier/gmd:code)"/>
        <xsl:variable name="lowerIdentifierType">
            <xsl:call-template name="getLowered">
                <xsl:with-param name="inputString" select="$identifierType"/>
            </xsl:call-template>
        </xsl:variable>
        
       <xsl:message>Metadata Creation Date: <xsl:value-of select="$metadataCreationDate"/></xsl:message>
        
        <xsl:variable name="CI_Citation" select="." as="node()"></xsl:variable>
        
        <!-- Attempt to obtain contributor names; only construct citation if we have contributor names -->
        
        <xsl:variable name="principalInvestigatorName_sequence" as="xs:string*">
            <xsl:call-template name="getIndividualNameSequence">
                <xsl:with-param name="parent" select="$CI_Citation" as="node()"/>  
                <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
            </xsl:call-template>
            
            <xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact" as="node()"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
                </xsl:call-template>
            </xsl:for-each>
        
            <xsl:call-template name="getOrganisationNameSequence">
                <xsl:with-param name="parent" select="$CI_Citation" as="node()"/> 
                <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
            </xsl:call-template>
            
            <xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getOrganisationNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
                </xsl:call-template>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="coInvestigatorName_sequence" as="xs:string*">
            <xsl:call-template name="getIndividualNameSequence">
                <xsl:with-param name="parent" select="$CI_Citation"/>  
                <xsl:with-param name="role_sequence" as="xs:string*" select="'coInvestigator'"/>  
            </xsl:call-template>
            
            <xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'coInvestigator'"/>  
                </xsl:call-template>
            </xsl:for-each>
            
            <xsl:call-template name="getOrganisationNameSequence">
                <xsl:with-param name="parent" select="$CI_Citation"/>  
                <xsl:with-param name="role_sequence" as="xs:string*" select="'coInvestigator'"/>  
            </xsl:call-template>
            
            <xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getOrganisationNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'coInvestigator'"/>  
                </xsl:call-template>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="pointOfContactName_sequence" as="xs:string*">
            <xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'pointOfContact'"/>  
                </xsl:call-template>
            </xsl:for-each>
            
           <xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getOrganisationNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'pointOfContact'"/>  
                </xsl:call-template>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:if test="  (count($principalInvestigatorName_sequence) > 0) or 
                        (count($coInvestigatorName_sequence) > 0) or
                        (string-length($pointOfContactName_sequence) > 0)">
        
        
            <citationInfo>
                <citationMetadata>
                    <xsl:choose>
                        <xsl:when
                            test="string-length($lowerIdentifierType) and contains($lowerIdentifierType, 'doi')">
                            <identifier>
                                <xsl:attribute name="type">
                                    <xsl:text>doi</xsl:text>
                                </xsl:attribute>
                                <xsl:value-of select="$identifierType"/>
                            </identifier>
                        </xsl:when>
                        <xsl:otherwise>
                            <identifier>
                                <xsl:attribute name="type">
                                    <xsl:text>uri</xsl:text>
                                </xsl:attribute>
                                <xsl:value-of select="$metadataURL"/>
                            </identifier>
                        </xsl:otherwise>
                    </xsl:choose>
    
                    <title>
                        <xsl:value-of select="gmd:title"/>
                    </title>
                    
                    <xsl:variable name="current_CI_Citation" select="."/>
                    <xsl:variable name="CI_Date_sequence" as="node()*">
                        <xsl:variable name="type_sequence" as="xs:string*" select="'publication,revision,creation'"/>
                        <xsl:for-each select="tokenize($type_sequence, ',')">
                            <xsl:variable name="type" select="."/>
                            <xsl:for-each select="$current_CI_Citation/gmd:date/gmd:CI_Date">
                                <xsl:variable name="lowerCode">
                                    <xsl:call-template name="getLowered">
                                        <xsl:with-param name="inputString"
                                            select="gmd:dateType/gmd:CI_DateTypeCode/@codeListValue"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                
                                <xsl:if test="contains($lowerCode, $type)">
                                    <xsl:copy-of select="."/>
                                </xsl:if>
                            </xsl:for-each>
                            
                        </xsl:for-each>
                    </xsl:variable>
                    
                    <xsl:variable name="codelist" select="$gmdCodelists/codelists/codelist[@name = 'gmd:CI_DateTypeCode']"/>
                    
                    <xsl:variable name="dateType">
                        <xsl:if test="count($CI_Date_sequence) > 0">
                            <xsl:variable name="codevalue" select="$CI_Date_sequence[1]/gmd:dateType/gmd:CI_DateTypeCode/@codeListValue"/>
                            <xsl:value-of select="$codelist/entry[code = $codevalue]/description"/>
                        </xsl:if>
                    </xsl:variable>
                    
                    <xsl:variable name="dateValue">
                        <xsl:if test="(count($CI_Date_sequence) > 0) and
                                      (string-length($CI_Date_sequence[1]/gmd:date/gco:DateTime) > 3)">
                           <xsl:value-of select="substring($CI_Date_sequence[1]/gmd:date/gco:DateTime, 1, 4)"/>
                        </xsl:if>
                    </xsl:variable>
                    
                    <xsl:choose>
                        <xsl:when test="(string-length($dateType) > 0) and (string-length($dateValue) > 0)">
                            <date>
                                <xsl:attribute name="type">
                                    <xsl:value-of select="$dateType"/>
                                </xsl:attribute>
                                <xsl:value-of select="$dateValue"/>
                            </date>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if test="string-length($metadataCreationDate) > 3">
                                <date>
                                    <xsl:attribute name="type">
                                        <xsl:text>publicationDate</xsl:text>
                                    </xsl:attribute>
                                    <xsl:value-of select="substring($metadataCreationDate, 1, 4)"/>
                                </date>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <xsl:for-each select="distinct-values($principalInvestigatorName_sequence)">
                        <contributor>
                            <namePart>
                                <xsl:value-of select="."/>
                            </namePart>
                        </contributor>
                    </xsl:for-each>
                    
                    <xsl:for-each select="distinct-values($coInvestigatorName_sequence)">
                        <contributor>
                            <namePart>
                                <xsl:value-of select="."/>
                            </namePart>
                        </contributor>
                    </xsl:for-each>
                    
                    <xsl:if test="(count($principalInvestigatorName_sequence) = 0) and (count($coInvestigatorName_sequence) = 0)">
                        <xsl:if test="count($pointOfContactName_sequence) > 0">
                            <contributor>
                                <namePart>
                                    <xsl:value-of select="$pointOfContactName_sequence"/>
                                </namePart>
                            </contributor>
                        </xsl:if>
                    </xsl:if>
    
                    <xsl:variable name="publisherName_sequence" as="xs:string*">
                        <xsl:call-template name="getAllOrganisationNameSequence">
                            <xsl:with-param name="parent" select="$CI_Citation"/>  
                            <xsl:with-param name="role_sequence" as="xs:string*" select="'distributor'"/>  
                        </xsl:call-template>
                        
                        <xsl:for-each select="$distributorContactNode_sequence">
                            <xsl:variable name="distributorContact" select="." as="node()"/>
                            <xsl:call-template name="getAllOrganisationNameSequence">
                                <xsl:with-param name="parent" select="$distributorContact"/>  
                                <xsl:with-param name="role_sequence" as="xs:string*" select="'distributor'"/>  
                            </xsl:call-template>
                        </xsl:for-each>
                        
                        <xsl:for-each select="$pointOfContactNode_sequence">
                            <xsl:variable name="pointOfContact" select="." as="node()"/>
                            <xsl:call-template name="getAllOrganisationNameSequence">
                                <xsl:with-param name="parent" select="$pointOfContact"/>  
                                <xsl:with-param name="role_sequence" as="xs:string*" select="'distributor'"/>  
                            </xsl:call-template>
                        </xsl:for-each>
                        
                       <xsl:for-each select="$pointOfContactNode_sequence">
                            <xsl:variable name="pointOfContact" select="." as="node()"/>
                            <xsl:call-template name="getAllOrganisationNameSequence">
                                <xsl:with-param name="parent" select="$pointOfContact"/>  
                                <xsl:with-param name="role_sequence" as="xs:string*" select="'pointOfContact'"/>  
                            </xsl:call-template>
                       </xsl:for-each>
                        
                        <!-- Default if no other -->
                        <xsl:value-of select="$global_publisherName"/>
                    </xsl:variable>
                    
                    <xsl:if test="count($publisherName_sequence) > 0">
                        <publisher>
                            <xsl:value-of select="$publisherName_sequence[1]"/>
                        </publisher>
                    </xsl:if>
    
               </citationMetadata>
            </citationInfo>
        </xsl:if>
    </xsl:template>



    <!-- ====================================== -->
    <!-- Party RegistryObject - Child Templates -->
    <!-- ====================================== -->

    <!-- Party Registry Object (Individuals (person) and Organisations (group)) -->
    <xsl:template name="party">
        <xsl:param name="type"/>
        <registryObject group="{$global_group}">

            <xsl:variable name="transformedName">
                <xsl:call-template name="getTransformed">
                    <xsl:with-param name="inputString" select="current-grouping-key()"/>
                </xsl:call-template>
            </xsl:variable>


            <key>
                <xsl:value-of
                    select="concat($global_group, '/', translate(normalize-space($transformedName),' ',''))"
                />
            </key>

            <originatingSource>
                <xsl:value-of select="$global_originatingSource"/>
            </originatingSource>

            <!-- Use the party type provided, except for exception:
                    Because sometimes e-Atlas is used for an author, appearing in individualName,
                    we want to make sure that we use 'group', not 'person', if this anomoly occurs -->

            <xsl:variable name="typeToUse">
                <xsl:choose>
                    <xsl:when test="contains($transformedName, 'e-Atlas')">
                        <xsl:text>group</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$type"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <party type="{$typeToUse}">
                <name type="primary">
                    <namePart>
                        <xsl:value-of select="$transformedName"/>
                    </namePart>
                </name>

                <!-- If we have are dealing with individual who has an organisation name:
                    - leave out the address (so that it is on the organisation only); and 
                    - relate the individual to the organisation -->

                <!-- If we are dealing with an individual...-->
                <xsl:choose>
                    <xsl:when test="contains($type, 'person')">
                        <xsl:variable name="transformedOrganisationName">
                            <xsl:call-template name="getTransformed">
                                <xsl:with-param name="inputString" select="gmd:organisationName"/>
                            </xsl:call-template>
                        </xsl:variable>


                        <xsl:choose>
                            <xsl:when
                                test="string-length(normalize-space($transformedOrganisationName))">
                                <!--  Individual has an organisation name, so related the individual to the organisation, and omit the address 
                                        (the address will be included within the organisation to which this individual is related) -->
                                <relatedObject>
                                    <key>
                                        <xsl:value-of
                                            select="concat($global_group,'/', $transformedOrganisationName)"
                                        />
                                    </key>
                                    <relation type="isMemberOf"/>
                                </relatedObject>
                            </xsl:when>

                            <xsl:otherwise>
                                <!-- Individual does not have an organisation name, so include the address here -->
                                <xsl:call-template name="physicalAddress"/>
                                <xsl:call-template name="phone"/>
                                <xsl:call-template name="electronic"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- We are dealing with an organisation, so always include the address -->
                        <xsl:call-template name="physicalAddress"/>
                        <xsl:call-template name="phone"/>
                        <xsl:call-template name="electronic"/>
                    </xsl:otherwise>
                </xsl:choose>
            </party>
        </registryObject>
    </xsl:template>

    <xsl:template name="physicalAddress">
        <xsl:for-each select="current-group()">
            <xsl:sort
                select="count(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/child::*)"
                data-type="number" order="descending"/>

            <xsl:if test="position() = 1">
                <xsl:if
                    test="count(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/child::*) > 0">

                    <location>
                        <address>
                            <physical type="streetAddress">
                                <addressPart type="addressLine">
                                         <xsl:value-of select="normalize-space(current-grouping-key())"/>
                                </addressPart>
                                
                                <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:deliveryPoint/gco:CharacterString[string-length(text()) > 0]">
                                     <addressPart type="addressLine">
                                         <xsl:value-of select="normalize-space(.)"/>
                                     </addressPart>
                                </xsl:for-each>
                                
                                 <xsl:if test="string-length(normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:city))">
                                      <addressPart type="suburbOrPlaceLocality">
                                          <xsl:value-of select="normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:city)"/>
                                      </addressPart>
                                 </xsl:if>
                                
                                 <xsl:if test="string-length(normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:administrativeArea))">
                                     <addressPart type="stateOrTerritory">
                                         <xsl:value-of select="normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:administrativeArea)"/>
                                     </addressPart>
                                 </xsl:if>
                                     
                                 <xsl:if test="string-length(normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:postalCode))">
                                     <addressPart type="postCode">
                                         <xsl:value-of select="normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:postalCode)"/>
                                     </addressPart>
                                 </xsl:if>
                                 
                                 <xsl:if test="string-length(normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:country))">
                                     <addressPart type="country">
                                         <xsl:value-of select="normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:country)"/>
                                     </addressPart>
                                 </xsl:if>
                            </physical>
                        </address>
                    </location>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="phone">
        <xsl:for-each select="current-group()">
            <xsl:sort
                select="count(gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/child::*)"
                data-type="number" order="descending"/>

            <xsl:if test="position() = 1">
                <xsl:if
                    test="count(gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/child::*) > 0">
                    <xsl:for-each
                        select="gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/gmd:voice/gco:CharacterString[string-length(text()) > 0]">
                        <location>
                            <address>
                                <physical type="streetAddress">
                                    <addressPart type="telephoneNumber">
                                        <xsl:value-of select="normalize-space(.)"/>
                                    </addressPart>
                                </physical>
                            </address>
                        </location>
                    </xsl:for-each>

                    <xsl:for-each
                        select="gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/gmd:facsimile/gco:CharacterString[string-length(text()) > 0]">
                        <location>
                            <address>
                                <physical type="streetAddress"> 
                                    <addressPart type="faxNumber">
                                        <xsl:value-of select="normalize-space(.)"/>
                                    </addressPart>
                                </physical>
                            </address>
                        </location>
                    </xsl:for-each>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="electronic">
        <xsl:for-each select="current-group()">
            <xsl:sort
                select="count(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:electronicMailAddress/gco:CharacterString[string-length(text()) > 0])"
                data-type="number" order="descending"/>

            <xsl:if test="position() = 1">
                <xsl:if
                    test="count(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:electronicMailAddress/gco:CharacterString[string-length(text()) > 0])">
                    <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:electronicMailAddress/gco:CharacterString[string-length(text()) > 0]">
                        <location>
                            <address>
                                <electronic type="email">
                                    <value>
                                        <xsl:value-of select="normalize-space(.)"/>
                                    </value>
                                </electronic>
                            </address>
                        </location>
                    </xsl:for-each>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="getRegistryObjectType">
        <xsl:param name="scopeCode"/>
        <xsl:choose>
            <xsl:when test="string-length($scopeCode) = 0">
                <xsl:message>Error: empty scope code</xsl:message>
                <xsl:text>unknown</xsl:text>
            </xsl:when>
            <xsl:when
                test="
                contains($scopeCode, 'collectionSession') or
                contains($scopeCode, 'project') or
                contains($scopeCode, 'fieldSession')">
                <xsl:text>activity</xsl:text>
            </xsl:when>
            <xsl:when
                test="
                contains($scopeCode, 'dataset') or
                contains($scopeCode, 'series') or
                contains($scopeCode, 'nonGeographicDataset')">
                <xsl:text>collection</xsl:text>
            </xsl:when>
            <xsl:when
                test="
                contains($scopeCode, 'software') or
                contains($scopeCode, 'sensor') or
                contains($scopeCode, 'service')">
                <xsl:text>service</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>collection</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="getRegistryObjectSubType">
        <xsl:param name="scopeCode"/>
        <xsl:choose>
            <xsl:when
                test="
                contains($scopeCode, 'collectionSession') or
                contains($scopeCode, 'program')">
                <xsl:text>program</xsl:text>
            </xsl:when>
            <xsl:when
                test="
                contains($scopeCode, 'project') or
                contains($scopeCode, 'fieldSession')">
                <xsl:text>project</xsl:text>
            </xsl:when>
            <xsl:when test="
                contains($scopeCode, 'series')">
                <xsl:text>collection</xsl:text>
            </xsl:when>
            <xsl:when
                test="
                contains($scopeCode, 'dataset') or
                contains($scopeCode, 'series') or
                contains($scopeCode, 'nonGeographicDataset')">
                <xsl:text>dataset</xsl:text>
            </xsl:when>
            <xsl:when
                test="
                contains($scopeCode, 'sensor')">
                <xsl:text>create</xsl:text>
            </xsl:when>
            <xsl:when
                test="
                contains($scopeCode, 'software')">
                <xsl:text>generate</xsl:text>
            </xsl:when>
            <xsl:when
                test="
                contains($scopeCode, 'service')">
                <xsl:text>report</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>dataset</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getLowered">
        <xsl:param name="inputString"/>
        <xsl:variable name="smallCase" select="'abcdefghijklmnopqrstuvwxyz'"/>
        <xsl:variable name="upperCase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
        <xsl:value-of select="translate($inputString,$upperCase,$smallCase)"/>
    </xsl:template>

   <xsl:template name="isRole" as="xs:boolean*">
        <xsl:param name="role"/>
        <xsl:for-each-group select="current-group()/gmd:role"
            group-by="gmd:CI_RoleCode/@codeListValue">
            <xsl:if test="(string-length($role) > 0) and contains(current-grouping-key(), $role)">
                <xsl:value-of select="true()"/>
            </xsl:if>
        </xsl:for-each-group>
    </xsl:template>

    <!-- Finds name of organisation with particular role - ignores organisations that don't have an individual name -->
    <xsl:template name="getOrganisationNameSequence">
        <xsl:param name="parent"/>
        <xsl:param name="role_sequence"/>
        <xsl:message>getOrganisationNameSequence - Parent: <xsl:value-of select="local-name($parent)"/>, Role: <xsl:value-of select="$role_sequence"/></xsl:message>
     
        <!-- Contributing organisations - included only when there is no individual name (in which case the individual has been included above) 
        Note again that we are ignoring organisations where a role has not been specified -->
        <xsl:for-each select="tokenize($role_sequence, ',')">
            <xsl:variable name="role" select="."/>
            
            <xsl:for-each-group
                 select="$parent/descendant::gmd:CI_ResponsibleParty[
                 (string-length(normalize-space(gmd:organisationName))) and
                 not(string-length(normalize-space(gmd:individualName))) and
                 (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                 group-by="gmd:organisationName">
     
                 <xsl:variable name="transformedOrganisationName">
                     <xsl:call-template name="getTransformed">
                         <xsl:with-param name="inputString"
                             select="normalize-space(current-grouping-key())"/>
                     </xsl:call-template>
                 </xsl:variable>
     
                 <xsl:variable name="userIsRole" as="xs:boolean*">
                     <xsl:call-template name="isRole">
                         <xsl:with-param name="role" select="$role"/>
                     </xsl:call-template>
                 </xsl:variable>
                 <xsl:if test="(count($userIsRole) > 0)">
                     <xsl:message>getOrganisationNameSequence returning 
                         <xsl:value-of select="$transformedOrganisationName"/> 
                         for role
                         <xsl:value-of select="$role"/>
                     </xsl:message>
                     <xsl:value-of select="$transformedOrganisationName"/>
                 </xsl:if>
            </xsl:for-each-group>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Finds name of organisation for an individual of a particular role - whether or not there in an individual name -->
    <xsl:template name="getAllOrganisationNameSequence">
        <xsl:param name="parent"/>
        <xsl:param name="role_sequence"/>
        <xsl:message>getAllOrganisationNameSequence - Parent: <xsl:value-of select="name($parent)"/>, Role: <xsl:value-of select="$role_sequence"/></xsl:message>
            
        <!-- Contributing organisations - included only when there is no individual name (in which case the individual has been included above) 
            Note again that we are ignoring organisations where a role has not been specified -->
        <xsl:for-each select="tokenize($role_sequence, ',')">
            <xsl:variable name="role" select="."/>
            
            <xsl:for-each-group
                select="$parent/descendant::gmd:CI_ResponsibleParty[
                (string-length(normalize-space(gmd:organisationName))) and
                (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                group-by="gmd:organisationName">
                
               <xsl:variable name="transformedOrganisationName">
                    <xsl:call-template name="getTransformed">
                        <xsl:with-param name="inputString"
                            select="normalize-space(current-grouping-key())"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <xsl:variable name="userIsRole" as="xs:boolean*">
                    <xsl:call-template name="isRole">
                        <xsl:with-param name="role" select="$role"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:if test="(count($userIsRole) > 0)">
                    <xsl:message>getAllOrganisationNameSequence returning 
                        <xsl:value-of select="$transformedOrganisationName"/> 
                        for role
                        <xsl:value-of select="$role"/>
                    </xsl:message>
                    <xsl:value-of select="$transformedOrganisationName"/>
                </xsl:if>
                
            </xsl:for-each-group>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="getIndividualNameSequence">
        <xsl:param name="parent" as="node()"/>
        <xsl:param name="role_sequence"/>
        <xsl:message>getIndividualNameSequence - Parent: <xsl:value-of select="name($parent)"/>, Role: <xsl:value-of select="$role_sequence"/></xsl:message>
        
        <!-- Contributing individuals - note that we are ignoring those individuals where a role has not been specified -->
        
        <xsl:for-each select="tokenize($role_sequence, ',')">
           <xsl:variable name="role" select="."/>
                
           <xsl:for-each-group
                 select="$parent/descendant::gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
                 (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                 group-by="gmd:individualName">
                 
                <xsl:variable name="userIsRole" as="xs:boolean*">
                    <xsl:call-template name="isRole">
                        <xsl:with-param name="role" select="$role"/>
                    </xsl:call-template>
                 </xsl:variable>
                <xsl:if test="count($userIsRole) > 0">
                    <xsl:message>getIndividualNameSequence - Returning 
                        <xsl:value-of select="normalize-space(current-grouping-key())"/> 
                        for role
                        <xsl:value-of select="$role"/>
                    </xsl:message>
                    <xsl:value-of select="normalize-space(current-grouping-key())"/>
                </xsl:if>
            </xsl:for-each-group>
        </xsl:for-each>          
    </xsl:template>
   
    <xsl:template name="getPublisherNameToUse">
        <xsl:variable name="organisationPublisherName">
            <xsl:call-template name="getChildValueForRole">
                <xsl:with-param name="roleSubstring">
                    <xsl:text>publish</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="childElementName">
                    <xsl:text>organisationName</xsl:text>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <xsl:message>Organisation publisher name: <xsl:value-of select="$organisationPublisherName"
            /></xsl:message>

        <xsl:variable name="transformedOrganisationPublisherName">
            <xsl:call-template name="getTransformed">
                <xsl:with-param name="inputString" select="$organisationPublisherName"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="individualPublisherName">
            <xsl:call-template name="getChildValueForRole">
                <xsl:with-param name="roleSubstring">
                    <xsl:text>publish</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="childElementName">
                    <xsl:text>individualName</xsl:text>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <xsl:message>Individual publisher name: <xsl:value-of select="$individualPublisherName"
            /></xsl:message>

        <xsl:variable name="transformedIndividualPublisherName">
            <xsl:call-template name="getTransformed">
                <xsl:with-param name="inputString" select="$individualPublisherName"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string-length(normalize-space($transformedOrganisationPublisherName))">
                <xsl:value-of select="$transformedOrganisationPublisherName"/>
            </xsl:when>
            <xsl:when test="string-length(normalize-space($transformedIndividualPublisherName))">
                <xsl:value-of select="$transformedIndividualPublisherName"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$global_publisherName"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="getPublishPlaceToUse">
        <xsl:param name="publishNameToUse"/>
        <xsl:variable name="publishCity">
            <xsl:call-template name="getChildValueForRole">
                <xsl:with-param name="roleSubstring">
                    <xsl:text>publish</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="childElementName">
                    <xsl:text>city</xsl:text>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="publishCountry">
            <xsl:call-template name="getChildValueForRole">
                <xsl:with-param name="roleSubstring">
                    <xsl:text>publish</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="childElementName">
                    <xsl:text>country</xsl:text>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <xsl:message>Country: <xsl:value-of select="$publishCountry"/></xsl:message>

        <xsl:choose>
            <xsl:when test="string-length($publishCity)">
                <xsl:value-of select="$publishCity"/>
            </xsl:when>
            <xsl:when test="string-length($publishCountry)">
                <xsl:value-of select="$publishCity"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Only default publisher place if publisher name is equal to the global value (whether it was set or retrieved) -->
                <xsl:if test="$publishNameToUse = $global_publisherName">
                    <xsl:value-of select="$global_publisherPlace"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="getTransformed">
        <xsl:param name="inputString"/>
        <xsl:choose>
            <xsl:when test="contains($inputString, 'AIMS')">
                <xsl:text>Australian Institute of Marine Science</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$inputString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="getMetadataURL">
        <xsl:param name="transferOptions"/>
        <xsl:for-each select="$transferOptions/gmd:onLine/gmd:CI_OnlineResource">
            <xsl:if test="contains(gmd:protocol, 'http--metadata-URL')">
                <xsl:value-of select="normalize-space(gmd:linkage/gmd:URL)"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- Get the values of the child element of the point of contact responsible parties whose role contains this substring provided 
         For example, if you provide roleSubsting as 'publish' and childElementName as 'organisationName',
            you will receive all organisation names within point of contact.  They will be separated by 'commas', with an 'and' between
            the last and second last, where applicable -->
    <xsl:template name="getChildValueForRole">
        <xsl:param name="roleSubstring"/>
        <xsl:param name="childElementName"/>
        <xsl:variable name="lowerRoleSubstring">
            <xsl:call-template name="getLowered">
                <xsl:with-param name="inputString" select="$roleSubstring"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="name_sequence" as="xs:string*">
            <xsl:for-each-group
                select="descendant::gmd:CI_ResponsibleParty[
                (string-length(normalize-space(descendant::node()[local-name()=$childElementName]))) and 
                (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                group-by="descendant::node()[local-name()=$childElementName]">
                <xsl:choose>
                    <!-- obtain for two locations so far - we don't want for example we don't want
                        responsible parties under citation of thesauruses used -->
                    <xsl:when
                        test="contains(local-name(..), 'pointOfContact') or 
                                    contains(local-name(../../..), 'citation')">
                        <xsl:variable name="lowerCode">
                            <xsl:call-template name="getLowered">
                                <xsl:with-param name="inputString"
                                    select="gmd:role/gmd:CI_RoleCode/@codeListValue"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:if test="contains($lowerCode, $lowerRoleSubstring)">
                            <xsl:sequence
                                select="descendant::node()[local-name()=$childElementName]"/>
                            <xsl:message>Child value: <xsl:value-of
                                    select="descendant::node()[local-name()=$childElementName]"
                                /></xsl:message>
                        </xsl:if>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="formattedValues">
            <xsl:for-each select="$name_sequence">
                <xsl:if test="position() > 1">
                    <xsl:choose>
                        <xsl:when test="position() = count($name_sequence)">
                            <xsl:text> and </xsl:text>
                        </xsl:when>
                        <xsl:when test="position() &lt; count($name_sequence)">
                            <xsl:text>, </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:if>
                <xsl:value-of select="."/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:message>Formatted values: <xsl:value-of select="$formattedValues"/></xsl:message>
    </xsl:template>

    <xsl:template name="getSplitText">
        <xsl:param name="string"/>
        <xsl:param name="separator" select="', '"/>
        <xsl:variable name="altSeparator" select="' '"/>
        <xsl:choose>
            <xsl:when test="contains($string, $separator)">
                <xsl:if test="not(starts-with($string, $separator))">
                    <subject>
                        <xsl:attribute name="type">
                            <xsl:text>local</xsl:text>
                        </xsl:attribute>
                        <xsl:value-of select="substring-before($string, $separator)"/>
                    </subject>
                </xsl:if>
                <xsl:call-template name="getSplitText">
                    <xsl:with-param name="string" select="substring-after($string,$separator)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains($string, $altSeparator)">
                <xsl:if test="not(starts-with($string, $altSeparator))">
                    <subject>
                        <xsl:attribute name="type">
                            <xsl:text>local</xsl:text>
                        </xsl:attribute>
                        <xsl:value-of select="substring-before($string, $altSeparator)"/>
                    </subject>
                </xsl:if>
                <xsl:call-template name="getSplitText">
                    <xsl:with-param name="string" select="substring-after($string, $altSeparator)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="string-length(normalize-space($string))">
                    <subject>
                        <xsl:attribute name="type">
                            <xsl:text>local</xsl:text>
                        </xsl:attribute>
                        <xsl:value-of select="$string"/>
                    </subject>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>