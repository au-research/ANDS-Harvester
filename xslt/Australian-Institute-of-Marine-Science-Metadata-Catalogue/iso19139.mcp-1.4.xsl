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
    <xsl:param name="global_defaultOriginatingSource" select="'external'"/>
    <xsl:param name="global_baseURI" select="'data.aims.gov.au'"/>
    <xsl:param name="global_group" select="'Australian Institute of Marine Science'"/>
    <xsl:param name="global_groupAcronym" select="'AIMS'"/>
    <xsl:param name="global_path" select="'/metadataviewer/faces/view.xhtml?uuid='"/>
    <xsl:variable name="anzsrcCodelist" select="document('anzsrc-codelist.xml')"/>
    <xsl:variable name="licenseCodelist" select="document('license-codelist.xml')"/>
    <xsl:variable name="gmdCodelists" select="document('codelists.xml')"/>
    
    <xsl:template match="oai:responseDate"/>
    <xsl:template match="oai:resumptionToken"/>
    <xsl:template match="oai:request"/>
    <xsl:template match="oai:error"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:identifier"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:datestamp"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:setSpec"/>
    
    <!--xsl:template match="node()"/-->

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

        <xsl:variable name="metadataTruthURL">
            <xsl:call-template name="getMetadataTruthURL">
                <xsl:with-param name="transferOptions" select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="fileIdentifier"><xsl:value-of select="gmd:fileIdentifier"/></xsl:variable>
        
        <xsl:variable name="aimsDataCatalogueURL">
              <xsl:value-of select="concat('http://', $global_baseURI, $global_path, $fileIdentifier)"/>
        </xsl:variable>
        
        <xsl:variable name="dataSetURI"><xsl:value-of select="gmd:dataSetURI"/></xsl:variable>
        
        <xsl:variable name="scopeCode">
            <xsl:choose>
                <xsl:when test="string-length(normalize-space(gmd:hierarchyLevel/gmx:MX_ScopeCode/@codeListValue))">
                    <xsl:value-of select="normalize-space(gmd:hierarchyLevel/gmx:MX_ScopeCode/@codeListValue)"/>
                </xsl:when>
                <xsl:when test="string-length(normalize-space(gmd:hierarchyLevel/gmd:MD_ScopeCode/@codeListValue))">
                    <xsl:value-of select="normalize-space(gmd:hierarchyLevel/gmd:MD_ScopeCode/@codeListValue)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>dataset</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
            
        <!--xsl:message>scopeCode: <xsl:value-of select="$scopeCode"/-->
        <!--xsl:message>metadataTruthURL: <xsl:value-of select="$metadataTruthURL"/-->
        <!--xsl:message>dataSetURI: <xsl:value-of select="$dataSetURI"/-->
        <!--xsl:message>splashPage: <xsl:value-of select="$splashPage"/-->
        <xsl:variable name="originatingSource">
            <xsl:variable name="originatingSourcemetadataTruthURL">
                <xsl:call-template name="getOriginatingSource">
                    <xsl:with-param name="inputString" select="$metadataTruthURL"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:choose>
                <xsl:when test="string-length($originatingSourcemetadataTruthURL)">
                    <xsl:value-of select="$originatingSourcemetadataTruthURL"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="originatingSourceDataSetURI">
                        <xsl:call-template name="getOriginatingSource">
                            <xsl:with-param name="inputString" select="$dataSetURI"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="string-length($originatingSourceDataSetURI)">
                            <xsl:value-of select="$originatingSourceDataSetURI"/>
                        </xsl:when>   
                        <xsl:otherwise>
                            <xsl:value-of select="$global_defaultOriginatingSource"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        
            <registryObject>
                <xsl:attribute name="group">
                    <xsl:value-of select="$global_group"/>
                </xsl:attribute>
                
                <xsl:apply-templates select="gmd:fileIdentifier" mode="registryObject_key"/>
                
                <originatingSource>
                    <xsl:value-of select="$originatingSource"/>    
                </originatingSource>
                
                <xsl:variable name="metadataCreationDate">
                    <xsl:if test="string-length(normalize-space(gmd:dateStamp/gco:Date))">
                        <xsl:value-of select="normalize-space(gmd:dateStamp/gco:Date)"/>
                    </xsl:if>
                    <xsl:if test="string-length(normalize-space(gmd:dateStamp/gco:DateTime))">
                        <xsl:value-of select="normalize-space(gmd:dateStamp/gco:DateTime)"/>
                    </xsl:if>
                </xsl:variable>
                
                <xsl:variable name="registryObjectTypeSubType_sequence" as="xs:string*">
                    <xsl:call-template name="getRegistryObjectTypeSubType">
                        <xsl:with-param name="scopeCode" select="$scopeCode"/>
                        <xsl:with-param name="originatingSource" select="$originatingSource"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:if test="(count($registryObjectTypeSubType_sequence) = 2)">
                    <xsl:element name="{$registryObjectTypeSubType_sequence[1]}">
    
                        <xsl:attribute name="type">
                            <xsl:value-of select="$registryObjectTypeSubType_sequence[2]"/>
                        </xsl:attribute>
                       
                        <!--xsl:apply-templates select="gmd:fileIdentifier" mode="registryObject_identifier"/-->
                        
                        <xsl:apply-templates select="gmd:fileIdentifier" mode="registryObject_identifier_url"/>
                        
                        
    
                        <!--xsl:apply-templates
                            select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions"
                            mode="registryObject_identifier"/-->
    
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:title"
                            mode="registryObject_name"/>
    
                        <xsl:apply-templates select="gmd:parentIdentifier"
                            mode="registryObject_related_object"/>
    
                        <xsl:call-template name="set_registryObject_location_metadata">
                            <xsl:with-param name="metadataTruthURL" select="$metadataTruthURL"/>
                            <xsl:with-param name="aimsDataCatalogueURL" select="$aimsDataCatalogueURL"/>
                        </xsl:call-template>
                        
                        <xsl:for-each-group
                            select="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
                         (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
                         gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
                         (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
                         gmd:identificationInfo/*/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
                         (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                            group-by="gmd:individualName">
                            <xsl:apply-templates select="." mode="registryObject_related_object"/>
                        </xsl:for-each-group>
    
                        <xsl:for-each-group
                            select="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
                         (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
                         gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
                         (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
                         gmd:identificationInfo/*/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
                         (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                            group-by="gmd:organisationName">
                            <xsl:apply-templates select="." mode="registryObject_related_object"/>
                        </xsl:for-each-group>
    
                        <xsl:apply-templates select="mcp:children/mcp:childIdentifier"
                            mode="registryObject_related_object"/>
    
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:topicCategory/gmd:MD_TopicCategoryCode"
                            mode="registryObject_subject"/>
    
                        <xsl:apply-templates
                            select="gmd:identificationInfo/mcp:MD_DataIdentification"
                            mode="registryObject_subject"/>
                        
                        <xsl:apply-templates
                            select="gmd:identificationInfo/srv:ServiceIdentification"
                            mode="registryObject_subject"/>
                        
                        <xsl:apply-templates
                            select="gmd:identificationInfo/mcp:MD_ServiceIdentification"
                            mode="registryObject_subject"/>
    
                       <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:abstract"
                            mode="registryObject_description"/>
    
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox"
                            mode="registryObject_coverage_spatial"/>
    
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_BoundingPolygon"
                            mode="registryObject_coverage_spatial"/>
    
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:extent/gmd:EX_Extent/gmd:temporalElement/mcp:EX_TemporalExtent"
                            mode="registryObject_coverage_temporal"/>
    
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent"
                            mode="registryObject_coverage_temporal"/>
    
                        <xsl:apply-templates
                            select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions"
                            mode="registryObject_relatedInfo"/>
    
                        <xsl:apply-templates select="mcp:children/mcp:childIdentifier"
                            mode="registryObject_relatedInfo"/>
                        
                        <xsl:apply-templates select="gmd:identificationInfo/srv:SV_ServiceIdentification/srv:operatesOn"
                            mode="registryObject_relatedInfo"/>
                           
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:resourceConstraints/mcp:MD_CreativeCommons[
                            exists(mcp:licenseLink)]"
                            mode="registryObject_rights_licence_creative"/>
    
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:resourceConstraints/mcp:MD_CreativeCommons"
                            mode="registryObject_rights_rightsStatement_creative"/>
    
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:resourceConstraints/mcp:MD_Commons[
                            exists(mcp:licenseLink)]"
                            mode="registryObject_rights_licence_creative"/>
                        
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:resourceConstraints/mcp:MD_Commons"
                            mode="registryObject_rights_rightsStatement_creative"/>
                        
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:resourceConstraints/gmd:MD_LegalConstraints"
                            mode="registryObject_rights_rightsStatement"/>
    
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:resourceConstraints/gmd:MD_LegalConstraints[
                            exists(gmd:accessConstraints)]"
                            mode="registryObject_rights_accessRights"/>
    
                       <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:resourceConstraints/gmd:MD_Constraints"
                            mode="registryObject_rights_rightsStatement"/>
                        
                        
                        <xsl:apply-templates
                            select="gmd:identificationInfo/*/gmd:resourceConstraints/gmd:MD_Constraints"
                            mode="registryObject_rights_accessRights"/>
                        
                        <xsl:if test="$registryObjectTypeSubType_sequence[1] = 'collection'">
                          
                            <xsl:variable name="pointOfContactNode_sequence" as="node()*">
                                <xsl:call-template name="getPointOfContactSequence">
                                    <xsl:with-param name="parent" select="gmd:identificationInfo/mcp:MD_DataIdentification"/>
                                </xsl:call-template>
                            </xsl:variable>
                            
                            <xsl:variable name="pointOfContactNode_sequence" as="node()*">
                                <xsl:call-template name="getPointOfContactSequence">
                                    <xsl:with-param name="parent" select="gmd:identificationInfo/mcp:MD_ServiceIdentification"/>
                                </xsl:call-template>
                            </xsl:variable>
                            
                            <xsl:variable name="distributorContactNode_sequence" as="node()*">
                                <xsl:call-template name="getDistributorContactSequence">
                                    <xsl:with-param name="parent" select="gmd:distributionInfo/gmd:MD_Distribution"/>
                                </xsl:call-template>
                            </xsl:variable>
                            
                            <xsl:apply-templates
                                 select="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:date"
                                 mode="registryObject_dates"/>
                             
                             <xsl:for-each
                                 select="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation">
                                 <xsl:call-template name="registryObject_citationMetadata_citationInfo">
                                     <xsl:with-param name="aimsDataCatalogueURL" select="$aimsDataCatalogueURL"/>
                                     <xsl:with-param name="originatingSource" select="$originatingSource"/>
                                     <xsl:with-param name="citation" select="."/>
                                     <!--xsl:with-param name="pointOfContactNode_sequence" select="$pointOfContactNode_sequence" as="node()*"/-->
                                     <!--xsl:with-param name="distributorContactNode_sequence" select="$distributorContactNode_sequence" as="node()*"/-->
                                     <xsl:with-param name="metadataCreationDate" select="$metadataCreationDate"/>
                                 </xsl:call-template>
                             </xsl:for-each>
                        </xsl:if>
                    </xsl:element>
                </xsl:if>
            </registryObject>

            <!-- =========================================== -->
            <!-- Party RegistryObject Template          -->
            <!-- =========================================== -->

            <xsl:for-each-group
                select="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
             gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
             gmd:identificationInfo/*/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                group-by="gmd:individualName">
                <xsl:call-template name="party">
                    <xsl:with-param name="type">person</xsl:with-param>
                    <xsl:with-param name="originatingSource" select="$originatingSource"/>
                </xsl:call-template>
            </xsl:for-each-group>

            <xsl:for-each-group
                select="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
             gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
             gmd:identificationInfo/*/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
             (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                group-by="gmd:organisationName">
                <xsl:call-template name="party">
                    <xsl:with-param name="type">group</xsl:with-param>
                    <xsl:with-param name="originatingSource" select="$originatingSource"/>
                </xsl:call-template>
            </xsl:for-each-group>

        <!--/xsl:if-->

    </xsl:template>

    <!-- =========================================== -->
    <!-- RegistryObject RegistryObject - Child Templates -->
    <!-- =========================================== -->

    <!-- RegistryObject - Key Element  -->
    <xsl:template match="gmd:fileIdentifier" mode="registryObject_key">
        <key>
            <xsl:value-of select="concat($global_groupAcronym,'/', normalize-space(.))"/>
        </key>
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
                <xsl:value-of select="concat($global_groupAcronym,'/', $identifier)"/>
            </identifier>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="gmd:fileIdentifier" mode="registryObject_identifier_url">
        <xsl:variable name="identifier" select="normalize-space(.)"/>
        <xsl:if test="string-length($identifier)">
            <identifier>
                <xsl:attribute name="type">
                    <xsl:text>uri</xsl:text>
                </xsl:attribute>
                <xsl:value-of
                    select="concat('http://', $global_baseURI, $global_path, $identifier)"
                />
            </identifier>
           </xsl:if>
    </xsl:template>

    <!-- RegistryObject - Identifier Element  -->
    <xsl:template match="gmd:MD_DigitalTransferOptions" mode="registryObject_identifier">
        <xsl:for-each select="gmd:onLine/gmd:CI_OnlineResource">
            <xsl:if test="contains(gmd:protocol, 'WWW:LINK-1.0-http--metadata-URL')">
                <xsl:if test="string-length(normalize-space(gmd:linkage/gmd:URL))">
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
        match="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:title"
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
        match="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:date"
        mode="registryObject_dates">
        <xsl:variable name="dateValue">
            <xsl:if test="string-length(normalize-space(gmd:CI_Date/gmd:date/gco:Date))">
                <xsl:value-of select="normalize-space(gmd:CI_Date/gmd:date/gco:Date)"/>
            </xsl:if>
            <xsl:if test="string-length(normalize-space(gmd:CI_Date/gmd:date/gco:DateTime))">
                <xsl:value-of select="normalize-space(gmd:CI_Date/gmd:date/gco:DateTime)"/>
            </xsl:if>
        </xsl:variable> 
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
            (string-length($dateValue)) and
            (string-length($transformedDateCode))">
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
                    <xsl:value-of select="$dateValue"/>
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
                    <xsl:value-of select="concat($global_groupAcronym,'/', $identifier)"/>
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
    <xsl:template name="set_registryObject_location_metadata">
        <xsl:param name="metadataTruthURL"/>
        <xsl:param name="aimsDataCatalogueURL"/>
        <xsl:choose>
            <xsl:when test="string-length($metadataTruthURL)">
                <location>
                    <address>
                        <electronic>
                            <xsl:attribute name="type">
                                <xsl:text>url</xsl:text>
                            </xsl:attribute>
                            <value>
                                <xsl:value-of select="$metadataTruthURL"/>
                            </value>
                        </electronic>
                    </address>
                </location>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="string-length($aimsDataCatalogueURL)">
                    <location>
                        <address>
                        <electronic>
                            <xsl:attribute name="type">
                                <xsl:text>url</xsl:text>
                            </xsl:attribute>
                            <value>
                                <xsl:value-of select="$aimsDataCatalogueURL"/>
                            </value>
                        </electronic>
                    </address>
                    </location>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
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
                    select="concat($global_groupAcronym,'/', translate(normalize-space($transformedName),' ',''))"
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
        <!--xsl:message>mcp:children</xsl:message-->
        <xsl:variable name="identifier" select="normalize-space(.)"/>
        <xsl:if test="string-length($identifier)">
            <relatedObject>
                <key>
                    <xsl:value-of select="concat($global_groupAcronym,'/', $identifier)"/>
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
    <xsl:template match="mcp:MD_DataIdentification" mode="registryObject_subject">
        <xsl:call-template name="populateSubjects">
            <xsl:with-param name="parent" select="."/>
        </xsl:call-template>  
    </xsl:template>
    
    <xsl:template match="srv:ServiceIdentification" mode="registryObject_subject">
        <xsl:call-template name="populateSubjects">
            <xsl:with-param name="parent" select="."/>
        </xsl:call-template>  
    </xsl:template>
    
    <xsl:template match="mcp:MD_ServiceIdentification" mode="registryObject_subject">
        <xsl:call-template name="populateSubjects">
            <xsl:with-param name="parent" select="."/>
        </xsl:call-template>  
    </xsl:template>
        
    <xsl:template name="populateSubjects">
         <xsl:param name="parent"/>
         <xsl:for-each select="$parent/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:keyword">
             <subject type="local">
                 <xsl:value-of select="normalize-space(.)"/>
             </subject>
         </xsl:for-each>
         
         <xsl:variable name="subject_sequence" as="xs:string*">
             <xsl:for-each select="gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:keyword">
                 <xsl:if test="string-length(normalize-space(.))">
                     <xsl:call-template name="getSplitText_sequence">
                         <xsl:with-param name="string" select="."/>
                         <xsl:with-param name="separator_sequence" select="'|,-'" as="xs:string*"/>
                     </xsl:call-template>
                 </xsl:if>
             </xsl:for-each>
         </xsl:variable>
         <xsl:for-each select="distinct-values($subject_sequence)">
             <xsl:variable name="keyword" select="normalize-space(.)"/>
             <xsl:variable name="code"
                 select="(normalize-space($anzsrcCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='ANZSRCCode']/gmx:codeEntry/gmx:CodeDefinition/gml:identifier[lower-case(following-sibling::gml:name) = lower-case($keyword)]))[1]"/>
             <xsl:if test="string-length($code)">
                 <subject>
                     <xsl:attribute name="type">
                         <xsl:value-of select="'anzsrc-for'"/>
                     </xsl:attribute>
                     <xsl:value-of select="$code"/>
                 </subject>
             </xsl:if>
         </xsl:for-each>
     </xsl:template>

    <xsl:template match="gmd:MD_TopicCategoryCode" mode="registryObject_subject">
        <xsl:if test="string-length(normalize-space(.))">
            <subject type="local">
                <xsl:value-of select="."></xsl:value-of>
            </subject>
        </xsl:if>
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
        <description type="full">
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
            <xsl:variable name="spatialString">
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
            </xsl:variable>
            <coverage>
                <spatial>
                    <xsl:attribute name="type">
                        <xsl:text>iso19139dcmiBox</xsl:text>
                    </xsl:attribute>
                    <xsl:value-of select="$spatialString"/>
                </spatial>
                <spatial>
                    <xsl:attribute name="type">
                        <xsl:text>text</xsl:text>
                    </xsl:attribute>
                    <xsl:value-of select="$spatialString"/>
                </spatial>
            </coverage>
        </xsl:if>
    </xsl:template>


    <!-- RegistryObject - Coverage Spatial Element -->
    <xsl:template match="gmd:EX_BoundingPolygon" mode="registryObject_coverage_spatial">
        <xsl:if
            test="string-length(normalize-space(gmd:polygon/gml:Polygon/gml:exterior/gml:LinearRing/gml:coordinates))">
            <coverage>
                <spatial>
                    <xsl:attribute name="type">
                        <xsl:text>gmlKmlPolyCoords</xsl:text>
                    </xsl:attribute>
                    <xsl:value-of
                        select="replace(normalize-space(gmd:polygon/gml:Polygon/gml:exterior/gml:LinearRing/gml:coordinates), ',0', '')"
                    />
                </spatial>
            </coverage>
        </xsl:if>
    </xsl:template>

    <!-- RegistryObject - Coverage Temporal Element -->
    <xsl:template match="mcp:EX_TemporalExtent" mode="registryObject_coverage_temporal">
        <xsl:if
            test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:begin/gml:TimeInstant/gml:timePosition)) or
                      string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:end/gml:TimeInstant/gml:timePosition))">
            <coverage>
                <temporal>
                    <xsl:if
                        test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:begin/gml:TimeInstant/gml:timePosition))">
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
                        test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:end/gml:TimeInstant/gml:timePosition))">
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
                        test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:beginPosition))">
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
                        test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:endPosition))">
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
                <xsl:if test="string-length($identifierValue)">
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
                        select="concat('http://', $global_baseURI, $global_path, $identifier)"
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
    
    <xsl:template match="srv:operatesOn" mode="registryObject_relatedInfo">
        
        <xsl:variable name="abstract" select="normalize-space(gmd:MD_DataIdentification/gmd:abstract)"/>
        
        <xsl:variable name="uri">
            <xsl:if test="string-length($abstract) > 0">
                <xsl:copy-of select='substring-before(substring-after($abstract, "href="""), "&amp;")'/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:variable name="uuid">
            <xsl:choose>
                <xsl:when test="string-length(normalize-space(@uuidref)) > 0">
                    <xsl:value-of select="normalize-space(@uuidref)"/>
                 </xsl:when>
                <xsl:when test="(string-length($abstract) > 0) and contains($abstract, 'uuid')">
                    <xsl:value-of select='substring-before(substring-after($abstract, "uuid="), "&amp;")'/>
                 </xsl:when>
            </xsl:choose>
        </xsl:variable> 
        
        <xsl:if test="((string-length($uri) > 0) and contains($uri, 'http')) or (string-length($uuid) > 0)">
            <relatedInfo type="activity">
                <xsl:if test="((string-length($uri) > 0) and contains($uri, 'http'))">
                    <identifier type="uri">
                        <xsl:value-of select="$uri"/>
                    </identifier>
                </xsl:if>
                
                <xsl:if test="(string-length($uuid) > 0)">
                    <!--identifier type="global">
                        <xsl:value-of select="concat($global_groupAcronym,'/', $uuid)"/>
                    </identifier-->
                    
                    <xsl:variable name="constructedUri" select="concat('http://', $global_baseURI, $global_path, $uuid)"/>
            
                    <xsl:if test="$constructedUri != $uri">
                        <identifier type="uri">
                            <xsl:value-of select="$constructedUri"/>
                        </identifier>
                    </xsl:if>
                    
                </xsl:if>
                
                <relation>
                    <xsl:attribute name="type">
                        <xsl:text>supports</xsl:text>
                    </xsl:attribute>
                </relation>
                
                <xsl:variable name="title" select="normalize-space(gmd:MD_DataIdentification/gmd:citation/gmd:title)"/>
                <xsl:if test="string-length($title)"/>
                <title>
                    <xsl:value-of select="$title"/>
                </title>
            </relatedInfo>
        </xsl:if>
    </xsl:template>
    
    <!-- RegistryObject - Rights Licence - From CreativeCommons -->
    <xsl:template match="mcp:MD_CreativeCommons" mode="registryObject_rights_licence_creative">
        <xsl:variable name="licenseLink" select="normalize-space(mcp:licenseLink/gmd:URL)"/>
        <xsl:for-each
            select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
            <xsl:if test="string-length(normalize-space(gml:remarks))">
                <xsl:if test="contains($licenseLink, gml:remarks)">
                    <rights>
                        <licence>
                            <xsl:attribute name="type" select="gml:identifier"/>
                            <xsl:attribute name="rightsUri" select="$licenseLink"/>
                            <xsl:if test="string-length(normalize-space(gml:name))">
                                <xsl:value-of select="normalize-space(gml:name)"/>
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
    
    <!-- RegistryObject - Rights Licence - From CreativeCommons -->
    <xsl:template match="mcp:MD_Commons" mode="registryObject_rights_licence_creative">
        <xsl:variable name="licenseLink" select="normalize-space(mcp:licenseLink/gmd:URL)"/>
        <xsl:for-each
            select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
            <xsl:if test="string-length(normalize-space(gml:remarks))">
                <xsl:if test="contains($licenseLink, gml:remarks)">
                    <rights>
                        <licence>
                            <xsl:attribute name="type" select="gml:identifier"/>
                            <xsl:attribute name="rightsUri" select="$licenseLink"/>
                            <xsl:if test="string-length(normalize-space(gml:name))">
                                <xsl:value-of select="normalize-space(gml:name)"/>
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
    <xsl:template match="mcp:MD_Commons" mode="registryObject_rights_rightsStatement_creative">
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
    <xsl:template match="gmd:MD_Constraints" mode="registryObject_rights_rightsStatement">
        <xsl:variable name="useLimitation_sequence" as="xs:string*">
            <xsl:for-each select="gmd:useLimitation">
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="distinct-values($useLimitation_sequence)">
            <xsl:variable name="useLimitation" select="normalize-space(.)"/>
            <!-- If there is text in other contraints, use this; otherwise, do nothing -->
            <xsl:if test="string-length($useLimitation)">
                <rights>
                    <rightsStatement>
                        <xsl:value-of select="$useLimitation"/>
                    </rightsStatement>
                </rights>
            </xsl:if>
        </xsl:for-each>
        <xsl:if test="not(exists(gmd:accessConstraints))">
            <xsl:for-each select="gmd:otherConstraints">
                <xsl:variable name="otherConstraints" select="normalize-space(.)"/>
                <!-- If there is text in other contraints, use this; otherwise, do nothing -->
                <xsl:if test="string-length($otherConstraints)">
                    <rights>
                        <rightsStatement>
                            <xsl:value-of select="$otherConstraints"/>
                        </rightsStatement>
                    </rights>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
        
    </xsl:template>
    
   <!-- RegistryObject - Rights AccessRights Element -->
    <xsl:template match="gmd:MD_Constraints" mode="registryObject_rights_accessRights">
        <xsl:for-each select="gmd:otherConstraints">
            <xsl:if test="string-length(normalize-space(.))">
                <rights>
                    <accessRights>
                        <xsl:value-of select="normalize-space(.)"/>
                    </accessRights>
                </rights>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- Collection - Rights Licence Element -->
    <xsl:template match="gmd:MD_Constraints" mode="collection_rights_licence">
        <xsl:variable name="otherConstraints" select="normalize-space(gmd:otherConstraints)"/>
        <xsl:if test="string-length($otherConstraints)">
            <xsl:if test="contains(lower-case($otherConstraints), 'picccby')">
                <rights>
                    <licence><xsl:text disable-output-escaping="yes">&lt;![CDATA[&lt;a href="http://polarcommons.org/ethics-and-norms-of-data-sharing.php"&gt; &lt;img src="http://polarcommons.org/images/PIC_print_small.png" style="border-width:0; width:40px; height:40px;" alt="Polar Information Commons's PICCCBY license."/&gt;&lt;/a&gt;&lt;a rel="license" href="http://creativecommons.org/licenses/by/3.0/" rel="license"&gt; &lt;img alt="Creative Commons License" style="border-width:0; width: 88px; height: 31px;" src="http://i.creativecommons.org/l/by/3.0/88x31.png" /&gt;&lt;/a&gt;]]&gt;</xsl:text>
                        <!--xsl:for-each select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
                            <xsl:if test="string-length(normalize-space(gml:remarks))">
                            <xsl:if test="contains($otherConstraints, gml:remarks)">
                            <xsl:message>Identifier <xsl:value-of select='gml:identifier'/></xsl:message>
                            <xsl:message>Remarks <xsl:value-of select='gml:remarks'/></xsl:message>
                            <xsl:attribute name="type" select="gml:identifier"/>
                            <xsl:attribute name="rightsUri" select="gml:remarks"/>
                            </xsl:if>
                            </xsl:if>
                            </xsl:for-each>
                            <xsl:value-of select="$otherConstraints"/-->
                    </licence>
                </rights>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- RegistryObject - RightsStatement -->
    <xsl:template match="gmd:MD_LegalConstraints" mode="registryObject_rights_rightsStatement">
        <xsl:for-each select="gmd:useLimitation">
            <xsl:variable name="useLimitation" select="normalize-space(.)"/>
            <!-- If there is text in other contraints, use this; otherwise, do nothing -->
            <xsl:if test="string-length($useLimitation)">
                <rights>
                    <rightsStatement>
                        <xsl:value-of select="$useLimitation"/>
                    </rightsStatement>
                </rights>
            </xsl:if>
        </xsl:for-each>
        <xsl:if test="not(exists(gmd:accessConstraints))">
            <xsl:for-each select="gmd:otherConstraints">
                <xsl:variable name="otherConstraints" select="normalize-space(.)"/>
                <!-- If there is text in other contraints, use this; otherwise, do nothing -->
                <xsl:if test="string-length($otherConstraints)">
                    <rights>
                        <rightsStatement>
                            <xsl:value-of select="$otherConstraints"/>
                        </rightsStatement>
                    </rights>
                </xsl:if>
                <xsl:if test="contains(lower-case($otherConstraints), 'picccby')">
                    <rights>
                        <licence><xsl:text disable-output-escaping="yes">&lt;![CDATA[&lt;a href="http://polarcommons.org/ethics-and-norms-of-data-sharing.php"&gt; &lt;img src="http://polarcommons.org/images/PIC_print_small.png" style="border-width:0; width:40px; height:40px;" alt="Polar Information Commons's PICCCBY license."/&gt;&lt;/a&gt;&lt;a rel="license" href="http://creativecommons.org/licenses/by/3.0/" rel="license"&gt; &lt;img alt="Creative Commons License" style="border-width:0; width: 88px; height: 31px;" src="http://i.creativecommons.org/l/by/3.0/88x31.png" /&gt;&lt;/a&gt;]]&gt;</xsl:text>
                            <!--xsl:for-each select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
                                <xsl:if test="string-length(normalize-space(gml:remarks))">
                                <xsl:if test="contains($otherConstraints, gml:remarks)">
                                <xsl:message>Identifier <xsl:value-of select='gml:identifier'/></xsl:message>
                                <xsl:message>Remarks <xsl:value-of select='gml:remarks'/></xsl:message>
                                <xsl:attribute name="type" select="gml:identifier"/>
                                <xsl:attribute name="rightsUri" select="gml:remarks"/>
                                </xsl:if>
                                </xsl:if>
                                </xsl:for-each>
                                <xsl:value-of select="$otherConstraints"/-->
                        </licence>
                    </rights>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <!-- RegistryObject - Rights AccessRights Element -->
    <xsl:template match="gmd:MD_LegalConstraints" mode="registryObject_rights_accessRights">
         <xsl:for-each select="gmd:otherConstraints">
            <xsl:if test="string-length(normalize-space(.))">
                <rights>
                    <accessRights>
                        <xsl:value-of select="normalize-space(.)"/>
                    </accessRights>
                </rights>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
   <!-- Collection - Rights Licence Element -->
    <xsl:template match="gmd:MD_LegalConstraints" mode="collection_rights_licence">
        <xsl:variable name="otherConstraints" select="normalize-space(gmd:otherConstraints)"/>
        <xsl:if test="string-length($otherConstraints)">
            <xsl:if test="contains(lower-case($otherConstraints), 'picccby')">
                <rights>
                    <licence><xsl:text disable-output-escaping="yes">&lt;![CDATA[&lt;a href="http://polarcommons.org/ethics-and-norms-of-data-sharing.php"&gt; &lt;img src="http://polarcommons.org/images/PIC_print_small.png" style="border-width:0; width:40px; height:40px;" alt="Polar Information Commons's PICCCBY license."/&gt;&lt;/a&gt;&lt;a rel="license" href="http://creativecommons.org/licenses/by/3.0/" rel="license"&gt; &lt;img alt="Creative Commons License" style="border-width:0; width: 88px; height: 31px;" src="http://i.creativecommons.org/l/by/3.0/88x31.png" /&gt;&lt;/a&gt;]]&gt;</xsl:text>
                        <!--xsl:for-each select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
                            <xsl:if test="string-length(normalize-space(gml:remarks))">
                            <xsl:if test="contains($otherConstraints, gml:remarks)">
                            <xsl:message>Identifier <xsl:value-of select='gml:identifier'/></xsl:message>
                            <xsl:message>Remarks <xsl:value-of select='gml:remarks'/></xsl:message>
                            <xsl:attribute name="type" select="gml:identifier"/>
                            <xsl:attribute name="rightsUri" select="gml:remarks"/>
                            </xsl:if>
                            </xsl:if>
                            </xsl:for-each>
                            <xsl:value-of select="$otherConstraints"/-->
                    </licence>
                </rights>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- RegistryObject - CitationInfo Element -->
    <xsl:template name="registryObject_citationMetadata_citationInfo">
        <xsl:param name="metadataTruthURL"/>
        <xsl:param name="aimsDataCatalogueURL"/>
        <xsl:param name="dataSetURI"/>
        <xsl:param name="originatingSource"/>
        <xsl:param name="citation"/>
        <!--xsl:param name="pointOfContactNode_sequence" as="node()*"/-->
        <!--xsl:param name="distributorContactNode_sequence" as="node()*"/-->
        <xsl:param name="metadataCreationDate"/>
        
        
       <xsl:variable name="CI_Citation" select="." as="node()"></xsl:variable>
        
        <!-- Attempt to obtain contributor names; only construct citation if we have contributor names -->
        
        <xsl:variable name="principalInvestigatorName_sequence" as="xs:string*">
            <xsl:call-template name="getIndividualNameSequence">
                <xsl:with-param name="parent" select="$CI_Citation" as="node()"/>  
                <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
            </xsl:call-template>
            
            <!--xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact" as="node()"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
                </xsl:call-template>
            </xsl:for-each-->
        
            <xsl:call-template name="getAllOrganisationNameSequence">
                <xsl:with-param name="parent" select="$CI_Citation" as="node()"/> 
                <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
            </xsl:call-template>
            
            <!--xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getOrganisationNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
                </xsl:call-template>
            </xsl:for-each-->
            
        </xsl:variable>
        
        <xsl:variable name="coInvestigatorName_sequence" as="xs:string*">
            <xsl:call-template name="getIndividualNameSequence">
                <xsl:with-param name="parent" select="$CI_Citation"/>  
                <xsl:with-param name="role_sequence" as="xs:string*" select="'coInvestigator'"/>  
            </xsl:call-template>
            
            <!--xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'coInvestigator'"/>  
                </xsl:call-template>
            </xsl:for-each-->
            
            <xsl:call-template name="getAllOrganisationNameSequence">
                <xsl:with-param name="parent" select="$CI_Citation"/>  
                <xsl:with-param name="role_sequence" as="xs:string*" select="'coInvestigator'"/>  
            </xsl:call-template>
            
           <!--xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getOrganisationNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'coInvestigator'"/>  
                </xsl:call-template>
                </xsl:for-each-->
            
        </xsl:variable>
        
        <xsl:variable name="pointOfContactName_sequence" as="xs:string*">
            <!--xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'pointOfContact'"/>  
                </xsl:call-template>
            </xsl:for-each-->
            
           <!--xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getOrganisationNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'pointOfContact'"/>  
                </xsl:call-template>
            </xsl:for-each-->
        </xsl:variable>
        
        <xsl:variable name="anyRoleName_sequence" as="xs:string*">
            <!-- Get individual names, regardless of role -->
            <xsl:call-template name="getIndividualNameSequence">
                <xsl:with-param name="parent" select="$CI_Citation" as="node()"/>  
            </xsl:call-template>
            
            <!-- Get organisation names, regardless of role -->
            <xsl:call-template name="getAllOrganisationNameSequence">
                <xsl:with-param name="parent" select="$CI_Citation" as="node()"/> 
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="allContributorName_sequence" as="xs:string*">
            <xsl:for-each select="distinct-values($principalInvestigatorName_sequence)">
                <xsl:if test="string-length(normalize-space(.))">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
            
            <xsl:for-each select="distinct-values($coInvestigatorName_sequence)">
                <xsl:if test="string-length(normalize-space(.))">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
           
            <xsl:if test="
                not(boolean(count($principalInvestigatorName_sequence))) and
                not(boolean(count($coInvestigatorName_sequence)))">
                <xsl:for-each select="distinct-values($pointOfContactName_sequence)">
                    <xsl:if test="string-length(normalize-space(.))">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
            
            <xsl:for-each select="distinct-values($anyRoleName_sequence)">
                <xsl:if test="string-length(normalize-space(.))">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="defaultContributorName">
            <xsl:call-template name="getDefaultContributorName">
                <xsl:with-param name="originatingSource" select="$originatingSource"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="identifierType"
            select="normalize-space(gmd:identifier/gmd:MD_Identifier/gmd:code)"/>
        <!--xsl:message>Metadata Creation Date: <xsl:value-of select="$metadataCreationDate"/></xsl:message-->
        
        <xsl:if test="count($allContributorName_sequence) or string-length($defaultContributorName)">
           <citationInfo>
                <citationMetadata>
                    <xsl:choose>
                        <xsl:when
                            test="string-length($identifierType) and contains(lower-case($identifierType), 'doi')">
                            <identifier>
                                <xsl:attribute name="type">
                                    <xsl:text>doi</xsl:text>
                                </xsl:attribute>
                                <xsl:value-of select="$identifierType"/>
                            </identifier>
                        </xsl:when>
                        <xsl:when
                            test="string-length($metadataTruthURL)">
                            <identifier>
                                <xsl:attribute name="type">
                                    <xsl:text>uri</xsl:text>
                                </xsl:attribute>
                                <xsl:value-of select="$metadataTruthURL"/>
                            </identifier>
                        </xsl:when>
                        <xsl:when
                            test="string-length($aimsDataCatalogueURL)">
                            <identifier>
                                <xsl:attribute name="type">
                                    <xsl:text>uri</xsl:text>
                                </xsl:attribute>
                                <xsl:value-of select="$aimsDataCatalogueURL"/>
                            </identifier>
                        </xsl:when>
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
                                <xsl:variable name="code" select="normalize-space(gmd:dateType/gmd:CI_DateTypeCode/@codeListValue)"/>
                                <xsl:if test="contains(lower-case($code), $type)">
                                    <xsl:copy-of select="."/>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:variable>
                    
                    
                    <xsl:variable name="codelist" select="$gmdCodelists/codelists/codelist[@name = 'gmd:CI_DateTypeCode']"/>
                    
                    <xsl:variable name="dateType">
                        <xsl:if test="count($CI_Date_sequence)">
                            <xsl:variable name="codevalue" select="$CI_Date_sequence[1]/gmd:dateType/gmd:CI_DateTypeCode/@codeListValue"/>
                            <xsl:value-of select="$codelist/entry[code = $codevalue]/description"/>
                        </xsl:if>
                    </xsl:variable>
                    
                    <xsl:variable name="dateValue">
                        <xsl:if test="count($CI_Date_sequence)">
                            <xsl:if test="string-length($CI_Date_sequence[1]/gmd:date/gco:Date) > 3">
                                <xsl:value-of select="substring($CI_Date_sequence[1]/gmd:date/gco:Date, 1, 4)"/>
                            </xsl:if>
                            <xsl:if test="string-length($CI_Date_sequence[1]/gmd:date/gco:DateTime) > 3">
                                <xsl:value-of select="substring($CI_Date_sequence[1]/gmd:date/gco:DateTime, 1, 4)"/>
                            </xsl:if>
                        </xsl:if>
                    </xsl:variable>
                    
                   <xsl:choose>
                        <xsl:when test="(string-length($dateType)) and (string-length($dateValue))">
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
                    
                    <xsl:choose>
                        <xsl:when test="count($allContributorName_sequence)">
                            <xsl:for-each select="distinct-values($allContributorName_sequence)">
                                <contributor>
                                    <namePart>
                                        <xsl:value-of select="."/>
                                    </namePart>
                                </contributor>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if test="string-length($defaultContributorName)">
                                <contributor>
                                    <namePart>
                                        <xsl:value-of select="$defaultContributorName"/>
                                    </namePart>
                                </contributor>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                   <xsl:variable name="defaultPublisherName">
                        <xsl:call-template name="getDefaultPublisherName">
                            <xsl:with-param name="originatingSource" select="$originatingSource"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:if test="string-length($defaultPublisherName)">
                        <publisher>
                            <xsl:value-of select="$defaultPublisherName"/>
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
        <xsl:param name="originatingSource"/>
        <registryObject group="{$global_group}">

            <xsl:variable name="transformedName">
                <xsl:call-template name="getTransformed">
                    <xsl:with-param name="inputString" select="current-grouping-key()"/>
                </xsl:call-template>
            </xsl:variable>


            <key>
                <xsl:value-of
                    select="concat($global_groupAcronym, '/', translate(normalize-space($transformedName),' ',''))"
                />
            </key>

            <originatingSource>
                <xsl:value-of select="$originatingSource"/>
            </originatingSource>

            <!-- Use the party type provided, except for exception:
                    Because sometimes AIMS is used for an author, appearing in individualName,
                    we want to make sure that we use 'group', not 'person', if this anomoly occurs -->

            <xsl:variable name="typeToUse">
                <xsl:variable name="isKnownOrganisation" as="xs:boolean">
                    <xsl:call-template name="get_isKnownOrganisation">
                        <xsl:with-param name="name" select="$transformedName"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="boolean($isKnownOrganisation)">
                        <!--xsl:message select="concat('Is known organisation ', $transformedName)"/-->
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
                                <!--  Individual has an organisation name, so relate the individual to the organisation, and omit the address 
                                        (the address will be included within the organisation to which this individual is related) -->
                                <relatedObject>
                                    <key>
                                        <xsl:value-of
                                            select="concat($global_groupAcronym,'/', translate(normalize-space($transformedOrganisationName),' ',''))"
                                        />
                                    </key>
                                    <relation type="isMemberOf"/>
                                </relatedObject>
                            </xsl:when>

                            <xsl:otherwise>
                                <!-- Individual does not have an organisation name, so onlineResource and physicalAddress must pertain this individual -->
                                <xsl:call-template name="onlineResource"/>
                                <xsl:call-template name="physicalAddress"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                        <!-- Individual - Phone and email on the individual, regardless of whether there's an organisation name -->
                        <xsl:call-template name="telephone"/>
                        <xsl:call-template name="facsimile"/>
                        <xsl:call-template name="email"/>
                        
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- If we are dealing with an Organisation with no individual name, phone and email must pertain to this organisation -->
                        <xsl:variable name="individualName" select="normalize-space(gmd:individualName)"/>
                        <xsl:if test="string-length($individualName) = 0">
                            <xsl:call-template name="telephone"/>
                            <xsl:call-template name="facsimile"/>
                            <xsl:call-template name="email"/>
                        </xsl:if>
                        
                        <!-- We are dealing with an organisation, so always include the address -->
                        <xsl:call-template name="onlineResource"/>
                        <xsl:call-template name="physicalAddress"/>
                        
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
                    test="count(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/child::*)">

                    <location>
                        <address>
                            <physical type="streetAddress">
                                <addressPart type="addressLine">
                                         <xsl:value-of select="normalize-space(current-grouping-key())"/>
                                </addressPart>
                                
                                <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:deliveryPoint/gco:CharacterString[string-length(text())]">
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


    <xsl:template name="telephone">
        <xsl:variable name="phone_sequence" as="xs:string*">
            <xsl:for-each select="current-group()">
                <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/gmd:voice">
                    <xsl:if test="string-length(normalize-space(.))">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="distinct-values($phone_sequence)">
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
    </xsl:template>
    
    <xsl:template name="facsimile">
        <xsl:variable name="facsimile_sequence" as="xs:string*">
            <xsl:for-each select="current-group()">
                <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/gmd:facsimile">
                    <xsl:if test="string-length(normalize-space(.))">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="distinct-values($facsimile_sequence)">
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
    </xsl:template>
    
    <xsl:template name="email">
        <xsl:variable name="email_sequence" as="xs:string*">
            <xsl:for-each select="current-group()">
                <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:electronicMailAddress">
                    <xsl:if test="string-length(normalize-space(.))">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="distinct-values($email_sequence)">
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
    </xsl:template>
    
    <xsl:template name="onlineResource">
        <xsl:variable name="url_sequence" as="xs:string*">
            <xsl:for-each select="current-group()">
                <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:onlineResource/gmd:CI_OnlineResource/gmd:linkage/gmd:URL">
                    <xsl:if test="string-length(normalize-space(.))">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="distinct-values($url_sequence)">
            <location>
                <address>
                    <electronic type="url">
                        <value>
                            <xsl:value-of select="."/>
                        </value>
                    </electronic>
                </address>
            </location>
        </xsl:for-each>
    </xsl:template>
    
    
    
   
    <!-- Modules -->
    
    <xsl:template name="get_isKnownOrganisation">
        <xsl:param name="name"/>
        <xsl:choose>
            <xsl:when test="
            contains($name, 'Integrated Marine Observing System') or
            contains($name, 'Australian Institute of Marine Science') or
            contains($name, 'Australian Antarctic Data Centre') or
            contains($name, 'Australian Antarctic Division') or
            contains($name, 'CSIRO Marine and Atmospheric Research') or
            contains($name, 'Commonwealth Scientific and Industrial Research Organisation')">
            <xsl:value-of select="true()"/>
        </xsl:when>
        <xsl:otherwise>
                <xsl:value-of select="false()"/>
    </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
   <xsl:template name="getDefaultContributorName">
        <xsl:param name="originatingSource"/>
        <xsl:if test="contains(lower-case($originatingSource), 'cmar')">
            <xsl:text>CSIRO Division of Marine and Atmospheric Research</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="getDefaultPublisherName">
        <xsl:param name="originatingSource"/>
        <xsl:choose>
            <xsl:when test="contains(lower-case($originatingSource), 'cmar')">
                <xsl:text>Commonwealth Scientific and Industrial Research Organisation</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($originatingSource), 'aims')">
                <xsl:text>Australian Institute of Marine Science</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($originatingSource), 'imos')">
                <xsl:text>Integrated Marine Observing System</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($originatingSource), 'aad')">
                <xsl:text>Australian Antarctic Data Centre</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($originatingSource), 'aoml')">
                <xsl:text>Atlantic Oceanographic and Meteorological Laboratory</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getOriginatingSource">
        <xsl:param name="inputString"/>
        <!-- Match will match the uri up to the third forward slash, e.g. it will match "http(s)://data.aims.gov.au/"
            from examples like the following:  http(s)://http://data.aims.gov.au// http(s)://http://data.aims.gov.au//morethings http(s)://http://data.aims.gov.au/more/stuff/-->
        <xsl:variable name="match">
            <xsl:analyze-string select="normalize-space($inputString)"
                regex="(http:|https:)//(\S+?)(/)">
                <xsl:matching-substring>
                    <xsl:value-of select="regex-group(0)"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:choose>
            <xsl:when
                test="(string-length($match)) and (substring($match, string-length($match), 1) = '/')">
                <xsl:value-of select="substring($match, 1, string-length($match)-1)"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- If we didn't match that pattern, just include the entire thing - rare but possible -->
                <xsl:value-of select="normalize-space($inputString)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getRegistryObjectTypeSubType" as="xs:string*">
        <xsl:param name="scopeCode"/>
        <xsl:param name="originatingSource"/>
        <xsl:choose>
            <xsl:when test="string-length($scopeCode) = 0">
                <!--xsl:message>Error: empty scope code</xsl:message-->
            </xsl:when>
            <xsl:when test="contains(lower-case($originatingSource), 'aims')">
                <xsl:call-template name="getRegistryObjectTypeSubType_AIMS">
                    <xsl:with-param name="scopeCode" select="$scopeCode"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains(lower-case($originatingSource), 'imos')">
                <xsl:call-template name="getRegistryObjectTypeSubType_IMOS">
                    <xsl:with-param name="scopeCode" select="$scopeCode"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!--xsl:message>Defaulting to 'collection' due to no specific processing being required for originatingSource<xsl:value-of select="$originatingSource"></xsl:value-of></xsl:message-->
                <xsl:text>collection</xsl:text>
                <xsl:text>dataset</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getRegistryObjectTypeSubType_AIMS" as="xs:string*">
        <xsl:param name="scopeCode"/>
        <xsl:choose>
            <xsl:when test="string-length($scopeCode) = 0">
                <!--xsl:message>Error: empty scope code</xsl:message-->
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'dataset')">
                <xsl:text>activity</xsl:text>
                <xsl:text>project</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'nonGeographicDataset')">
                <xsl:text>activity</xsl:text>
                <xsl:text>project</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'collectionHardware')">
                <xsl:text>activity</xsl:text>
                <xsl:text>project</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'sensor')">
                <xsl:text>collection</xsl:text>
                <xsl:text>dataset</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'sensorSeries')">
                <xsl:text>collection</xsl:text>
                <xsl:text>collection</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'software')">
                <xsl:text>service</xsl:text>
                <xsl:text>create</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'model')">
                <xsl:text>service</xsl:text>
                <xsl:text>generate</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'service')">
                <xsl:text>service</xsl:text>
                <xsl:text>report</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!--xsl:message>Defaulting due to unknown scope code <xsl:value-of select="$scopeCode"></xsl:value-of></xsl:message-->
                <xsl:text>collection</xsl:text>
                <xsl:text>dataset</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getRegistryObjectTypeSubType_IMOS" as="xs:string*">
        <xsl:param name="scopeCode"/>
        <xsl:choose>
            <xsl:when test="string-length($scopeCode) = 0">
                <!--xsl:message>Error: empty scope code<xsl:message-->
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'dataset')">
                <xsl:text>collection</xsl:text>
                <xsl:text>dataset</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'collectionSession')">
                <xsl:text>activity</xsl:text>
                <xsl:text>project</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'series')">
                <xsl:text>activity</xsl:text>
                <xsl:text>program</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'software')">
                <xsl:text>service</xsl:text>
                <xsl:text>create</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'service')">
                <xsl:text>service</xsl:text>
                <xsl:text>report</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!--xsl:message>Defaulting due to unknown scope code<xsl:value-of select="$scopeCode"></xsl:value-of><xsl:message-->
                <xsl:text>collection</xsl:text>
                <xsl:text>dataset</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
   <xsl:template name="isRole" as="xs:boolean*">
        <xsl:param name="role"/>
        <xsl:for-each-group select="current-group()/gmd:role"
            group-by="gmd:CI_RoleCode/@codeListValue">
            <xsl:if test="(string-length($role)) and contains(current-grouping-key(), $role)">
                <xsl:value-of select="true()"/>
            </xsl:if>
        </xsl:for-each-group>
    </xsl:template>

    <!-- Finds name of organisation with particular role - ignores organisations that don't have an individual name -->
    <xsl:template name="getOrganisationNameSequence">
        <xsl:param name="parent" as="node()"/>
        <xsl:param name="role_sequence" as="xs:string*"/>  <!-- if role_sequence is empty: return every, regardless of role -->
        <!--xsl:message>getOrganisationNameSequence - Parent: <xsl:value-of select="name($parent)"/>, Num roles: <xsl:value-of select="count($role_sequence)"/></xsl:message-->
        
        <!-- Contributing organisations - note that we are ignoring those organisations where a role has not been specified -->
        <xsl:choose>
            <xsl:when test="count($role_sequence)">
               <xsl:for-each select="tokenize($role_sequence, ',')">
                    <xsl:variable name="role" select="normalize-space(.)"/>
                   
                    <xsl:for-each-group
                        select="$parent/descendant::gmd:CI_ResponsibleParty[
                        (string-length(normalize-space(gmd:organisationName))) and 
                        (string-length(normalize-space(gmd:individualName)) = 0) and
                        (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                        group-by="gmd:organisationName">
                        
                        <xsl:variable name="transformedOrganisationName">
                            <xsl:call-template name="getTransformed">
                                <xsl:with-param name="inputString"
                                    select="normalize-space(current-grouping-key())"/>
                            </xsl:call-template>
                        </xsl:variable>
                        
                        <xsl:choose>
                            <xsl:when test="string-length($role)">
                                <xsl:variable name="userIsRole" as="xs:boolean*">
                                    <xsl:call-template name="isRole">
                                        <xsl:with-param name="role" select="$role"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:if test="count($userIsRole)">
                                    <!--xsl:message>getOrganisationNameSequence - Returning
                                        <xsl:value-of select="$transformedOrganisationName"/> 
                                        for role
                                        <xsl:value-of select="$role"/>
                                    </xsl:message-->                                         
                                    <xsl:value-of select="$transformedOrganisationName"/>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- No role specified, so return the name -->
                                <!--xsl:message>Role is empty</xsl:message-->
                                <!--xsl:message>getOrganisationNameSequence - Returning
                                    <xsl:value-of select="$transformedOrganisationName"/> 
                                    for no role
                                </xsl:message-->                                     
                                <xsl:if test="string-length($transformedOrganisationName)">
                                    <xsl:value-of select="$transformedOrganisationName"/>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each-group>
                </xsl:for-each>     
            </xsl:when>
            <xsl:otherwise>
                <!--xsl:message>Sequence is empty</xsl:message-->
                <xsl:for-each-group
                    select="$parent/descendant::gmd:CI_ResponsibleParty[
                    (string-length(normalize-space(gmd:organisationName))) and 
                    (string-length(normalize-space(gmd:individualName)) = 0) and
                    (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                    group-by="gmd:organisationName">
                    
                    <xsl:variable name="transformedOrganisationName">
                        <xsl:call-template name="getTransformed">
                            <xsl:with-param name="inputString"
                                select="normalize-space(current-grouping-key())"/>
                        </xsl:call-template>
                    </xsl:variable>
                    
                    <xsl:if test="string-length($transformedOrganisationName)">
                        <!--xsl:message>getOrganisationNameSequence - Returning
                            <xsl:value-of select="$transformedOrganisationName"/> 
                            for no role
                        </xsl:message-->                             
                        <xsl:value-of select="$transformedOrganisationName"/>
                    </xsl:if>
                </xsl:for-each-group>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Finds name of organisation for an individual of a particular role - whether or not there in an individual name -->
    <xsl:template name="getAllOrganisationNameSequence">
        <xsl:param name="parent" as="node()"/>
        <xsl:param name="role_sequence" as="xs:string*"/>  <!-- if role_sequence is empty: return every, regardless of role -->
        <!--xsl:message>getAllOrganisationNameSequence - Parent: <xsl:value-of select="name($parent)"/>, Num roles: <xsl:value-of select="count($role_sequence)"/></xsl:message-->
        
        
        <!-- Contributing organisations - note that we are ignoring those organisations where a role has not been specified -->
        <xsl:choose>
            <xsl:when test="count($role_sequence)">
                <xsl:for-each select="tokenize($role_sequence, ',')">
                    <xsl:variable name="role" select="normalize-space(.)"/>
                    
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
                        
                        <xsl:choose>
                            <xsl:when test="string-length($role)">
                                <xsl:variable name="userIsRole" as="xs:boolean*">
                                    <xsl:call-template name="isRole">
                                        <xsl:with-param name="role" select="$role"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:if test="count($userIsRole)">
                                    <!--xsl:message>getOrganisationNameSequence - Returning
                                        <xsl:value-of select="$transformedOrganisationName"/> 
                                        for role
                                        <xsl:value-of select="$role"/>
                                    </xsl:message-->                                         
                                    <xsl:value-of select="$transformedOrganisationName"/>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- No role specified, so return the name -->
                                <!--xsl:message>getOrganisationNameSequence - Returning
                                    <xsl:value-of select="$transformedOrganisationName"/> 
                                    for no role
                                </xsl:message-->                                     
                                <xsl:if test="string-length($transformedOrganisationName)">
                                    <xsl:value-of select="$transformedOrganisationName"/>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each-group>
                </xsl:for-each>     
            </xsl:when>
            <xsl:otherwise>
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
                    
                    <xsl:if test="string-length($transformedOrganisationName)">
                        <!--xsl:message>getOrganisationNameSequence - Returning
                            <xsl:value-of select="$transformedOrganisationName"/> 
                            for no role
                        </xsl:message-->                             
                        <xsl:value-of select="$transformedOrganisationName"/>
                    </xsl:if>
                </xsl:for-each-group>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getIndividualNameSequence">
        <xsl:param name="parent" as="node()"/>
        <xsl:param name="role_sequence" as="xs:string*" select="''"/>  <!-- if role_sequence is empty: return every, regardless of role -->
        <!--xsl:message>getIndividualNameSequence - Parent: <xsl:value-of select="name($parent)"/>, Num roles: <xsl:value-of select="count($role_sequence)"/></xsl:message-->
        
        
        <!-- Contributing individuals - note that we are ignoring those individuals where a role has not been specified -->
        <xsl:choose>
            <xsl:when test="count($role_sequence)">
                <xsl:for-each select="tokenize($role_sequence, ',')">
                    <xsl:variable name="role" select="normalize-space(.)"/>
                    
                    <xsl:for-each-group
                        select="$parent/descendant::gmd:CI_ResponsibleParty[
                        (string-length(normalize-space(gmd:individualName))) and 
                        (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                        group-by="gmd:individualName">
                        
                        <xsl:choose>
                            <xsl:when test="string-length($role)">
                                <xsl:variable name="userIsRole" as="xs:boolean*">
                                    <xsl:call-template name="isRole">
                                        <xsl:with-param name="role" select="$role"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:if test="count($userIsRole)">
                                    <!--xsl:message>getIndividualNameSequence - Returning
                                        <xsl:value-of select="normalize-space(current-grouping-key())"/> 
                                        for role
                                        <xsl:value-of select="$role"/>
                                    </xsl:message-->                                         
                                    <xsl:value-of select="normalize-space(current-grouping-key())"/>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- No role specified, so return the name -->
                                <xsl:if test="string-length(normalize-space(current-grouping-key()))">
                                    <!--xsl:message>getIndividualNameSequence - Returning
                                        <xsl:value-of select="normalize-space(current-grouping-key())"/> 
                                        for no role
                                    </xsl:message-->                                         
                                    <xsl:value-of select="normalize-space(current-grouping-key())"/>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each-group>
                </xsl:for-each>     
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each-group
                    select="$parent/descendant::gmd:CI_ResponsibleParty[
                    (string-length(normalize-space(gmd:individualName))) and 
                    (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                    group-by="gmd:individualName">
                    
                    <xsl:if test="string-length(normalize-space(current-grouping-key()))">
                        <!--xsl:message>getIndividualNameSequence - Returning
                            <xsl:value-of select="normalize-space(current-grouping-key())"/> 
                            for no role
                       </xsl:message-->                             
                        <xsl:value-of select="normalize-space(current-grouping-key())"/>
                    </xsl:if>
                </xsl:for-each-group>
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

        <!--xsl:message>Country: <xsl:value-of select="$publishCountry"/></xsl:message-->

        <xsl:choose>
            <xsl:when test="string-length($publishCity)">
                <xsl:value-of select="$publishCity"/>
            </xsl:when>
            <xsl:when test="string-length($publishCountry)">
                <xsl:value-of select="$publishCity"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="getTransformed">
        <xsl:param name="inputString"/>
        <xsl:choose>
            <xsl:when test="contains(lower-case($inputString), 'imos')">
                <xsl:text>Integrated Marine Observing System</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($inputString), 'aims')">
                <xsl:text>Australian Institute of Marine Science</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($inputString), 'aadc')">
                <xsl:text>Australian Antarctic Data Centre</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($inputString), 'aad')">
                <xsl:text>Australian Antarctic Division</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($inputString), 'cmar')">
                <xsl:text>CSIRO Marine and Atmospheric Research</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($inputString), 'csiro') and 
                            not(contains(lower-case($inputString), 'marine')) and
                            not(contains(lower-case($inputString), 'cmar'))">
                <xsl:text>Commonwealth Scientific and Industrial Research Organisation</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$inputString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="getMetadataTruthURL">
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
                        <xsl:variable name="code" select="normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)"/>
                        <xsl:if test="contains(lower-case($code), lower-case($roleSubstring))">
                            <xsl:sequence
                                select="descendant::node()[local-name()=$childElementName]"/>
                            <!--xsl:message>Child value: <xsl:value-of
                                    select="descendant::node()[local-name()=$childElementName]"
                                /></xsl:message-->
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

    <xsl:template name="getSplitText_sequence" as="xs:string*">
        <xsl:param name="string"/>
        <xsl:param name="separator_sequence" select="', '" as="xs:string*"/>
        <xsl:for-each select="tokenize($separator_sequence, ',')">
            <xsl:call-template name="getSplitTextFunc_sequence">
                <xsl:with-param name="string" select="$string"/>
                <xsl:with-param name="separator" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="getSplitTextFunc_sequence" as="xs:string*">
        <xsl:param name="string"/>
        <xsl:param name="separator" select="', '" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="contains($string, $separator)">
                <xsl:if test="not(starts-with($string, $separator))">
                    <xsl:value-of select="normalize-space(substring-before($string, $separator))"/>
                </xsl:if>
                <xsl:call-template name="getSplitTextFunc_sequence">
                    <xsl:with-param name="string" select="normalize-space(substring-after($string,$separator))"/>
                    <xsl:with-param name="separator" select="$separator"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="string-length(normalize-space($string))">
                    <xsl:value-of select="normalize-space($string)"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>