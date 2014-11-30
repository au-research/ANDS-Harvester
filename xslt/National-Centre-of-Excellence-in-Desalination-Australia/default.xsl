<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gmd="http://www.isotc211.org/2005/gmd" 
    xmlns:srv="http://www.isotc211.org/2005/srv"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:gco="http://www.isotc211.org/2005/gco" 
    xmlns:gts="http://www.isotc211.org/2005/gts"
    xmlns:geonet="http://www.fao.org/geonetwork" 
    xmlns:gmx="http://www.isotc211.org/2005/gmx"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://ands.org.au/standards/rif-cs/registryObjects"
    exclude-result-prefixes="geonet gmx oai xsi gmd srv gml gco gts">
    <!-- stylesheet to convert iso19139 in OAI-PMH ListRecords response to RIF-CS -->
    <xsl:output method="xml" version="1.0" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:param name="global_acronym" select="'AuScope'"/>
    <xsl:param name="global_originatingSource" select="'AuScope'"/> <!-- Only used as originating source if organisation name cannot be determined from Point Of Contact -->
    <xsl:param name="global_group" select="'AuScope'"/> 
    <xsl:param name="global_baseURI" select="'portal.auscope.org.au'"/>
    <xsl:variable name="anzsrcCodelist" select="document('anzsrc-codelist.xml')"/>
    <xsl:variable name="licenseCodelist" select="document('license-codelist.xml')"/>
    <xsl:variable name="gmdCodelists" select="document('codelists.xml')"/>
    <xsl:template match="oai:responseDate"/>
    <xsl:template match="oai:request"/>
    <xsl:template match="oai:error"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:identifier"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:datestamp"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:setSpec"/>
    <xsl:template match="oai:ListRecords/oai:record/oai:header/oai:identifier"/>
    <xsl:template match="oai:ListRecords/oai:record/oai:header/oai:datestamp"/>
    <xsl:template match="oai:ListRecords/oai:record/oai:header/oai:setSpec"/>
    
    <!-- =========================================== -->
    <!-- RegistryObjects (root) Template             -->
    <!-- =========================================== -->
    
    <xsl:template match="/">
        <registryObjects>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="//gmd:MD_Metadata"/>
        </registryObjects>
    </xsl:template>
    
    <xsl:template match="node()"/>

    <!-- =========================================== -->
    <!-- RegistryObject RegistryObject Template          -->
    <!-- =========================================== -->

    <xsl:template match="gmd:MD_Metadata">

        <xsl:variable name="metadataURL">
            <xsl:call-template name="getMetadataURL">
                <xsl:with-param name="transferOptions" select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="fileIdentifier"><xsl:value-of select="gmd:fileIdentifier"/></xsl:variable>
        
        <xsl:variable name="crsCode">
            <xsl:variable name="referenceCodeSpace" select="gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:codeSpace"/>
            <xsl:if test="contains(lower-case($referenceCodeSpace), 'crs')">
                <xsl:value-of select="gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:code"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:variable name="dateStamp"><xsl:value-of select="gmd:dateStamp/gco:Date"/></xsl:variable>
        
        <xsl:variable name="locationURL">
            <xsl:choose>
                <xsl:when test="string-length($metadataURL) > 0">
                    <xsl:value-of select="$metadataURL"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('http://', $global_baseURI, '/geonetwork/srv/en/metadata.show?uuid=', $fileIdentifier)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="dataSetURI"><xsl:value-of select="gmd:dataSetURI"/></xsl:variable>
        
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
        
        <xsl:variable name="pointOfContactNode_sequence" as="node()*">
            
            <xsl:if test="count(gmd:identificationInfo/gmd:MD_DataIdentification)">
                <xsl:call-template name="getPointOfContactSequence">
                    <xsl:with-param name="parent" select="gmd:identificationInfo/gmd:MD_DataIdentification"/>
                </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="count(gmd:identificationInfo/gmd:MD_ServiceIdentification)">
                <xsl:call-template name="getPointOfContactSequence">
                    <xsl:with-param name="parent" select="gmd:identificationInfo/gmd:MD_ServiceIdentification"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        
        
        <xsl:variable name="contributor_sequence" as="node()*">
            
            <xsl:if test="count(gmd:identificationInfo/gmd:MD_DataIdentification)">
                <xsl:call-template name="getPointOfContactSequence">
                    <xsl:with-param name="parent" select="gmd:identificationInfo/gmd:MD_DataIdentification"/>
                </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="count(gmd:identificationInfo/gmd:MD_ServiceIdentification)">
                <xsl:call-template name="getPointOfContactSequence">
                    <xsl:with-param name="parent" select="gmd:identificationInfo/gmd:MD_ServiceIdentification"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        
        
        <xsl:variable name="contactNode_sequence" select="gmd:contact" as="node()*"/>
        
        <xsl:variable name="distributorContactNode_sequence" as="node()*">
            <xsl:if test="gmd:distributionInfo/gmd:MD_Distribution">
                <xsl:call-template name="getDistributorContactSequence">
                    <xsl:with-param name="parent" select="gmd:distributionInfo/gmd:MD_Distribution"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        
        
        <xsl:variable name="originatingSource">
            <xsl:variable name="originatingSource_sequence" as="xs:string*">
                
                <xsl:for-each select="$contactNode_sequence">
                    <xsl:variable name="contact" select="." as="node()"/>
                    <xsl:call-template name="getOrganisationNameSequence">
                        <xsl:with-param name="parent" select="$contact" as="node()"/>  
                    </xsl:call-template>
                </xsl:for-each>
                
                <xsl:for-each select="$pointOfContactNode_sequence">
                    <xsl:variable name="pointOfContact" select="." as="node()"/>
                    <xsl:call-template name="getOrganisationNameSequence">
                        <xsl:with-param name="parent" select="$pointOfContact" as="node()"/>  
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:choose>
                <xsl:when test="count($originatingSource_sequence) > 0">
                    <xsl:value-of select="$originatingSource_sequence[1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$global_originatingSource"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        
        <xsl:variable name="group">
            <xsl:variable name="group_sequence" as="xs:string*">
                
                <xsl:for-each select="$distributorContactNode_sequence">
                    <xsl:variable name="distributorContact" select="." as="node()"/>
                    <xsl:call-template name="getOrganisationNameSequence">
                        <xsl:with-param name="parent" select="$distributorContact" as="node()"/>  
                    </xsl:call-template>
                </xsl:for-each>
                
                <xsl:for-each select="$pointOfContactNode_sequence">
                    <xsl:variable name="pointOfContact" select="." as="node()"/>
                    <xsl:call-template name="getOrganisationNameSequence">
                        <xsl:with-param name="parent" select="$pointOfContact" as="node()"/>  
                        <xsl:with-param name="role_sequence" as="xs:string*" select="'custodian'"/>  
                    </xsl:call-template>
                </xsl:for-each>
                
                <xsl:for-each select="$pointOfContactNode_sequence">
                    <xsl:variable name="pointOfContact" select="." as="node()"/>
                    <xsl:call-template name="getOrganisationNameSequence">
                        <xsl:with-param name="parent" select="$pointOfContact" as="node()"/>  
                        <xsl:with-param name="role_sequence" as="xs:string*" select="'owner'"/>  
                    </xsl:call-template>
                </xsl:for-each>
                
            </xsl:variable>
            
            <xsl:choose>
                <xsl:when test="count($group_sequence) > 0">
                    <xsl:value-of select="$group_sequence[1]"/>
                 </xsl:when>
                 <xsl:otherwise>
                     <xsl:value-of select="$global_group"/>
                 </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
            <registryObject>
                <xsl:attribute name="group">
                    <xsl:value-of select="$group"/>    
                </xsl:attribute>
                
                <xsl:apply-templates select="gmd:fileIdentifier" mode="registryObject_key"/>

                <originatingSource>
                    <xsl:value-of select="$originatingSource"/>    
                </originatingSource>
                
                <xsl:variable name="metadataCreationDate">
                    <xsl:if test="string-length(normalize-space(gmd:dateStamp/gco:Date)) > 0">
                        <xsl:value-of select="normalize-space(gmd:dateStamp/gco:Date)"/>
                    </xsl:if>
                    <xsl:if test="string-length(normalize-space(gmd:dateStamp/gco:DateTime)) > 0">
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
                        
                        <xsl:if test="$registryObjectTypeSubType_sequence[1] = 'collection'">
                             <xsl:attribute name="dateAccessioned">
                                 <xsl:value-of select="$dateStamp"/>
                             </xsl:attribute>
                        </xsl:if>
                       
                        <xsl:apply-templates select="gmd:fileIdentifier" 
                            mode="registryObject_identifier"/>
                        
                        <xsl:apply-templates select="
                            descendant::gmd:citation/gmd:CI_Citation/gmd:identifier[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]" 
                            mode="registryObject_identifier"/>
    
                        <xsl:apply-templates
                            select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions"
                            mode="registryObject_identifier"/>
    
                        <xsl:apply-templates
                            select="descendant::gmd:citation/gmd:CI_Citation/gmd:title[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_name"/>
    
                        <xsl:apply-templates select="gmd:parentIdentifier"
                            mode="registryObject_related_object"/>
    
                        <xsl:call-template name="set_registryObject_location_metadata">
                            <xsl:with-param name="uri_sequence" select="concat($locationURL, '|', $dataSetURI)"/>
                        </xsl:call-template>
                        
                        <xsl:for-each-group
                            select="descendant::gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification) and (string-length(normalize-space(gmd:individualName))) > 0] |
                            gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) > 0] |
                            descendant::gmd:pointOfContact/gmd:CI_ResponsibleParty[(ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification) and (string-length(normalize-space(gmd:individualName))) > 0]"
                            group-by="gmd:individualName">
                            <xsl:apply-templates select="." mode="registryObject_related_object"/>
                        </xsl:for-each-group>
    
                        <xsl:for-each-group
                            select="descendant::gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification) and (string-length(normalize-space(gmd:organisationName))) > 0] |
                            gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) > 0] |
                            descendant::gmd:pointOfContact/gmd:CI_ResponsibleParty[(ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification) and (string-length(normalize-space(gmd:organisationName))) > 0]"
                            group-by="gmd:organisationName">
                            <xsl:apply-templates select="." mode="registryObject_related_object"/>
                        </xsl:for-each-group>
    
                        <xsl:apply-templates select="gmd:children/gmd:childIdentifier"
                            mode="registryObject_related_object"/>
    
                        <xsl:apply-templates
                            select="descendant::gmd:topicCategory/gmd:MD_TopicCategoryCode[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_subject"/>
                        
                        <xsl:apply-templates
                            select="descendant::gmd:topicCategory/gmd:MD_TopicCategoryCode[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_subject"/>
    
                        <xsl:apply-templates
                            select="gmd:identificationInfo/gmd:MD_DataIdentification"
                            mode="registryObject_subject"/>
                        
                        <xsl:apply-templates
                            select="gmd:identificationInfo/gmd:MD_ServiceIdentification"
                            mode="registryObject_subject"/>
    
                       <xsl:apply-templates
                            select="descendant::gmd:abstract[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_description_brief"/>
    
                        <xsl:apply-templates
                            select="descendant::gmd:purpose[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_description_notes"/>
                        
                        <xsl:apply-templates
                            select="descendant::gmd:credit[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_description_notes"/>
                                                
                        <xsl:call-template name="set_registryObject_coverage_spatial">
                            <xsl:with-param name="boundingBox" select="descendant::gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"/>
                            <xsl:with-param name="crsCode" select="$crsCode"/>
                        </xsl:call-template>
                        
                        <xsl:call-template name="set_registryObject_coverage_spatial">
                            <xsl:with-param name="boundingBox" select="descendant::gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_BoundingPolygon[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"/>
                            <xsl:with-param name="crsCode" select="$crsCode"/>
                        </xsl:call-template>
    
                       <xsl:apply-templates
                           select="descendant::gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_coverage_temporal"/>
                        
                        <xsl:apply-templates
                            select="descendant::gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_coverage_temporal_period"/>
    
                        <xsl:apply-templates
                            select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions"
                            mode="registryObject_relatedInfo"/>
                        
                        <xsl:apply-templates
                            select="gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:lineage/gmd:LI_Lineage/gmd:source/gmd:LI_Source[string-length(gmd:sourceCitation/gmd:CI_Citation/gmd:identifier/gmd:MD_Identifier/gmd:code) > 0]"
                            mode="registryObject_relatedInfo"/>
    
                        <xsl:apply-templates select="gmd:children/gmd:childIdentifier"
                            mode="registryObject_relatedInfo"/>
    
                        <xsl:apply-templates
                            select="descendant::gmd:resourceConstraints/gmd:MD_CreativeCommons[(ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification) and exists(gmd:licenseLink)]"
                            mode="registryObject_rights_licence_creative"/>
    
                        <xsl:apply-templates
                            select="descendant::gmd:resourceConstraints/gmd:MD_CreativeCommons[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_rights_rightsStatement_creative"/>
    
                        <xsl:apply-templates
                            select="descendant::gmd:resourceConstraints/gmd:MD_Commons[(ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification) and exists(gmd:licenseLink)]"
                            mode="registryObject_rights_licence_creative"/>
                        
                        <xsl:apply-templates
                            select="descendant::gmd:resourceConstraints/gmd:MD_Commons[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_rights_rightsStatement_creative"/>
                        
                        <xsl:apply-templates
                            select="descendant::gmd:resourceConstraints/gmd:MD_LegalConstraints[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_rights_rightsStatement"/>
    
                        <xsl:apply-templates
                            select="descendant::gmd:resourceConstraints/gmd:MD_LegalConstraints[(ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification) and exists(gmd:accessConstraints)]"
                            mode="registryObject_rights_accessRights"/>
    
                       <xsl:apply-templates
                           select="descendant::gmd:resourceConstraints/gmd:MD_Constraints[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_rights_rightsStatement"/>
                        
                        
                        <xsl:apply-templates
                            select="descendant::gmd:resourceConstraints/gmd:MD_Constraints[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                            mode="registryObject_rights_accessRights"/>
                        
                        <xsl:if test="$registryObjectTypeSubType_sequence[1] = 'collection'">
                          
                            <xsl:apply-templates
                                select="descendant::gmd:citation/gmd:CI_Citation/gmd:date[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]"
                                 mode="registryObject_dates"/>
                             
                             <xsl:for-each
                                 select="descendant::gmd:citation/gmd:CI_Citation[ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification]">
                                 <xsl:call-template name="registryObject_citationMetadata_citationInfo">
                                     <xsl:with-param name="locationURL" select="$locationURL"/>
                                     <xsl:with-param name="originatingSource" select="$originatingSource"/>
                                     <xsl:with-param name="citation" select="."/>
                                     <xsl:with-param name="pointOfContactNode_sequence" select="$pointOfContactNode_sequence" as="node()*"/>
                                     <xsl:with-param name="distributorContactNode_sequence" select="$distributorContactNode_sequence" as="node()*"/>
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
                select="descendant::gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification) and(string-length(normalize-space(gmd:individualName))) > 0] |
                gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) > 0] |
                descendant::gmd:pointOfContact/gmd:CI_ResponsibleParty[(ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification) and (string-length(normalize-space(gmd:individualName))) > 0]"
                group-by="gmd:individualName">
                <xsl:call-template name="party">
                    <xsl:with-param name="type">person</xsl:with-param>
                    <xsl:with-param name="originatingSource" select="$originatingSource"/>
                    <xsl:with-param name="group" select="$group"/>
                </xsl:call-template>
            </xsl:for-each-group>

            <xsl:for-each-group
                select="descendant::gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification) and (string-length(normalize-space(gmd:organisationName))) > 0] |
                gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor/gmd:MD_Distributor/gmd:distributorContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) > 0] |
                descendant::gmd:pointOfContact/gmd:CI_ResponsibleParty[(ancestor::gmd:MD_DataIdentification | ancestor::gmd:MD_ServiceIdentification) and (string-length(normalize-space(gmd:organisationName))) > 0]"
                group-by="gmd:organisationName">
                <xsl:call-template name="party">
                    <xsl:with-param name="type">group</xsl:with-param>
                    <xsl:with-param name="originatingSource" select="$originatingSource"/>
                    <xsl:with-param name="group" select="$group"/>
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
            <xsl:value-of select="concat($global_acronym,'/', normalize-space(.))"/>
        </key>
    </xsl:template>

   <!-- RegistryObject - Identifier Element  -->
    <xsl:template match="gmd:fileIdentifier" mode="registryObject_identifier">
        <xsl:variable name="identifier" select="normalize-space(.)"/>
        <xsl:if test="string-length($identifier) > 0">
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
                <xsl:value-of select="concat($global_acronym,'/', $identifier)"/>
            </identifier>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="gmd:identifier" mode="registryObject_identifier">
        <xsl:variable name="code" select="normalize-space(gmd:MD_Identifier/gmd:code)"></xsl:variable>
        <xsl:if test="string-length($code) > 0">
            <identifier>
                <xsl:attribute name="type">
                    <xsl:choose>
                        <xsl:when test="contains(lower-case($code), 'doi')">
                            <xsl:text>doi</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains(lower-case($code), 'http')">
                            <xsl:text>uri</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>local</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:value-of select="$code"/>
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
        match="gmd:citation/gmd:CI_Citation/gmd:title"
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
       <xsl:if test="$parent and (count($parent) > 0)">
            <xsl:for-each select="$parent/descendant::gmd:pointOfContact">
                <xsl:copy-of select="."/>
            </xsl:for-each>
       </xsl:if>
    </xsl:template>
    
    <xsl:template name="getDistributorContactSequence" as="node()*">
        <xsl:param name="parent" as="node()"/>
        <xsl:if test="$parent and (count($parent) > 0)">
            <xsl:for-each select="$parent/descendant::gmd:distributorContact">
                <xsl:copy-of select="."/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- RegistryObject - Dates Element  -->
    <xsl:template
        match="gmd:citation/gmd:CI_Citation/gmd:date"
        mode="registryObject_dates">
        <xsl:variable name="dateValue">
            <xsl:if test="string-length(normalize-space(gmd:CI_Date/gmd:date/gco:Date)) > 0">
                <xsl:value-of select="normalize-space(gmd:CI_Date/gmd:date/gco:Date)"/>
            </xsl:if>
            <xsl:if test="string-length(normalize-space(gmd:CI_Date/gmd:date/gco:DateTime)) > 0">
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
            (string-length($dateValue) > 0) and
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
                    <xsl:value-of select="$dateValue"/>
                </date>
            </dates>
        </xsl:if>
    </xsl:template>
    
    <!-- RegistryObject - Related Object Element  -->
    <xsl:template match="gmd:parentIdentifier" mode="registryObject_related_object">
        <xsl:variable name="identifier" select="normalize-space(.)"/>
        <xsl:if test="string-length($identifier) > 0">
            <relatedObject>
                <key>
                    <xsl:value-of select="concat($global_acronym,'/', $identifier)"/>
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
        <xsl:param name="uri_sequence"/>
        <xsl:for-each select="distinct-values(tokenize($uri_sequence, '\|'))">
            <xsl:if test="string-length(normalize-space(.)) > 0">
                <location>
                    <address>
                        <electronic>
                            <xsl:attribute name="type">
                                <xsl:text>url</xsl:text>
                            </xsl:attribute>
                            <value>
                                <xsl:value-of select="normalize-space(.)"/>
                            </value>
                        </electronic>
                    </address>
                </location>
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
                <xsl:value-of select="concat($global_acronym,'/', translate(normalize-space($transformedName),' ',''))"/>
            </key>
            <xsl:for-each-group select="current-group()/gmd:role"
                group-by="gmd:CI_RoleCode/@codeListValue">
                <xsl:variable name="code">
                    <xsl:value-of select="current-grouping-key()"/>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="string-length($code) > 0">
                        <relation>
                            <xsl:attribute name="type">
                                <xsl:value-of select="$code"/>
                            </xsl:attribute>
                        </relation>
                    </xsl:when>
                    <xsl:otherwise>
                        <relation>
                            <xsl:attribute name="type">
                                <xsl:text>unknown</xsl:text>
                            </xsl:attribute>
                        </relation>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:for-each-group>
        </relatedObject>
    </xsl:template>

    <!-- RegistryObject - Related Object Element  -->
    <xsl:template match="gmd:childIdentifier" mode="registryObject_related_object">
        <xsl:variable name="identifier" select="normalize-space(.)"/>
        <xsl:if test="string-length($identifier) > 0">
            <relatedObject>
                <key>
                    <xsl:value-of select="concat($global_acronym,'/', $identifier)"/>
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
    <xsl:template match="gmd:MD_ServiceIdentification" mode="registryObject_subject">
            
        <xsl:variable name="subject_sequence">
            <xsl:for-each select="gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:keyword">
                <xsl:value-of select="normalize-space(.)"/>
                <xsl:text>|</xsl:text>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:for-each select="distinct-values(tokenize($subject_sequence, '\|'))">
            
            <xsl:if test="string-length(normalize-space(.)) > 0">
                <subject type="local">
                    <xsl:value-of select="normalize-space(.)"/>
                </subject>
                
                <!-- seek an anzsrc-code -->
                <xsl:variable name="match" as="xs:string*">
                    <xsl:analyze-string select="normalize-space(.)"
                        regex="[0-9]+">
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(0)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                
                <xsl:if test="count($match) > 0">
                    <xsl:for-each select="distinct-values($match)">
                        <xsl:if test="string-length(normalize-space(.)) > 0">
                            <subject>
                                <xsl:attribute name="type">
                                    <xsl:value-of select="'anzsrc-for'"/>
                                </xsl:attribute>
                                <xsl:value-of select="."/>
                            </subject>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
            
        <xsl:variable name="subjectSplit_sequence" as="xs:string*">
            <xsl:for-each select="gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:keyword">
                <xsl:if test="string-length(normalize-space(.)) > 0">
                    <xsl:call-template name="getSplitText_sequence">
                        <xsl:with-param name="string" select="."/>
                        <xsl:with-param name="separator_sequence" select="'&gt;,-'" as="xs:string*"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="distinct-values($subjectSplit_sequence)">
            <xsl:variable name="keyword" select="normalize-space(.)"/>
                <xsl:variable name="code"
                select="(normalize-space($anzsrcCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='ANZSRCCode']/gmx:codeEntry/gmx:CodeDefinition/gml:identifier[lower-case(following-sibling::gml:name) = lower-case($keyword)]))[1]"/>
            <xsl:if test="string-length($code) > 0">
                <subject>
                    <xsl:attribute name="type">
                        <xsl:value-of select="'anzsrc-for'"/>
                    </xsl:attribute>
                    <xsl:value-of select="$code"/>
                </subject>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <!-- RegistryObject - Subject Element -->
    <xsl:template match="gmd:MD_DataIdentification" mode="registryObject_subject">
        <xsl:variable name="subject_sequence">
            <xsl:for-each select="gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:keyword">
                <xsl:value-of select="normalize-space(.)"/>
                <xsl:text>|</xsl:text>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:for-each select="distinct-values(tokenize($subject_sequence, '\|'))">
            
            <xsl:if test="string-length(normalize-space(.)) > 0">
                <subject type="local">
                    <xsl:value-of select="normalize-space(.)"/>
                </subject>
                
                <!-- seek an anzsrc-code -->
                <xsl:variable name="match" as="xs:string*">
                    <xsl:analyze-string select="normalize-space(.)"
                        regex="[0-9]+">
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(0)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                
                <xsl:if test="count($match) > 0">
                    <xsl:for-each select="distinct-values($match)">
                        <xsl:if test="string-length(normalize-space(.)) > 0">
                            <subject>
                                <xsl:attribute name="type">
                                    <xsl:value-of select="'anzsrc-for'"/>
                                </xsl:attribute>
                                <xsl:value-of select="."/>
                            </subject>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
        
        <xsl:variable name="subjectSplit_sequence" as="xs:string*">
            <xsl:for-each select="gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:keyword">
                <xsl:if test="string-length(normalize-space(.)) > 0">
                    <xsl:call-template name="getSplitText_sequence">
                        <xsl:with-param name="string" select="."/>
                        <xsl:with-param name="separator_sequence" select="'&gt;,-'" as="xs:string*"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="distinct-values($subjectSplit_sequence)">
            <xsl:variable name="keyword" select="normalize-space(.)"/>
            <xsl:variable name="code"
                select="(normalize-space($anzsrcCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='ANZSRCCode']/gmx:codeEntry/gmx:CodeDefinition/gml:identifier[lower-case(following-sibling::gml:name) = lower-case($keyword)]))[1]"/>
            <xsl:if test="string-length($code) > 0">
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
        <xsl:if test="string-length(normalize-space(.)) > 0">
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
        <xsl:if test="string-length($code) > 0">
            <subject>
                <xsl:attribute name="type">
                    <xsl:value-of select="'anzsrc-for'"/>
                </xsl:attribute>
                <xsl:value-of select="$code"/>
            </subject>
        </xsl:if>
    </xsl:template>

    <!-- RegistryObject - Decription Element -->
    <xsl:template match="gmd:abstract" mode="registryObject_description_brief">
        <xsl:if test="string-length(normalize-space(.)) > 0">
            <description type="brief">
                <xsl:value-of select="."/>
            </description>
        </xsl:if>
    </xsl:template>
    
    <!-- RegistryObject - Decription Element -->
    <xsl:template match="gmd:purpose" mode="registryObject_description_notes">
        <xsl:if test="string-length(normalize-space(.)) > 0">
            <description type="notes">
                <xsl:value-of select="."/>
            </description>
        </xsl:if>
    </xsl:template>
    
    <!-- RegistryObject - Decription Element -->
    <xsl:template match="gmd:credit" mode="registryObject_description_notes">
        <xsl:if test="string-length(normalize-space(.)) > 0">
            <description type="notes">
                <xsl:value-of select="."/>
            </description>
        </xsl:if>
    </xsl:template>

    <!-- RegistryObject - Coverage Spatial Element -->
    <xsl:template name="set_registryObject_coverage_spatial">
        <xsl:param name="boundingBox" as="node()*"/>
        <xsl:param name="crsCode"/>
        <xsl:for-each select="$boundingBox">
            <xsl:if test="string-length(normalize-space(gmd:northBoundLatitude/gco:Decimal)) > 0"/>
            <xsl:if
                 test="
                    (string-length(normalize-space(gmd:northBoundLatitude/gco:Decimal)) > 0) and
                    (string-length(normalize-space(gmd:southBoundLatitude/gco:Decimal)) > 0) and
                    (string-length(normalize-space(gmd:westBoundLongitude/gco:Decimal)) > 0) and
                    (string-length(normalize-space(gmd:eastBoundLongitude/gco:Decimal)) > 0)">
                     <xsl:variable name="spatialString">
                         <xsl:value-of
                             select="normalize-space(concat('northlimit=',gmd:northBoundLatitude/gco:Decimal,'; southlimit=',gmd:southBoundLatitude/gco:Decimal,'; westlimit=',gmd:westBoundLongitude/gco:Decimal,'; eastLimit=',gmd:eastBoundLongitude/gco:Decimal))"/>
                         
                         <xsl:if
                             test="
                             (string-length(normalize-space(gmd:EX_VerticalExtent/gmd:maximumValue/gco:Real)) > 0) and
                             (string-length(normalize-space(gmd:EX_VerticalExtent/gmd:minimumValue/gco:Real)) > 0)">
                             <xsl:value-of
                                 select="normalize-space(concat('; uplimit=',gmd:EX_VerticalExtent/gmd:maximumValue/gco:Real,'; downlimit=',gmd:EX_VerticalExtent/gmd:minimumValue/gco:Real))"
                             />
                         </xsl:if>
                         <xsl:choose>
                              <xsl:when test="string-length(normalize-space($crsCode)) > 0">
                                 <xsl:value-of select="concat('; projection=', $crsCode)"/>
                              </xsl:when>
                             <xsl:otherwise>
                                 <xsl:text>; projection=GDA94</xsl:text>
                             </xsl:otherwise>
                         </xsl:choose>
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
           </xsl:for-each>
    </xsl:template>


    <!-- RegistryObject - Coverage Spatial Element -->
    <xsl:template match="gmd:EX_BoundingPolygon" mode="registryObject_coverage_spatial">
        <xsl:if
            test="string-length(normalize-space(gmd:polygon/gml:Polygon/gml:exterior/gml:LinearRing/gml:coordinates)) > 0">
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
    <xsl:template match="gmd:EX_TemporalExtent" mode="registryObject_coverage_temporal">
        <xsl:if
            test="(string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:begin/gml:TimeInstant/gml:timePosition)) > 0) or
                  (string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:end/gml:TimeInstant/gml:timePosition)) > 0)">
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
    <xsl:template match="gmd:EX_TemporalExtent" mode="registryObject_coverage_temporal_period">
        <xsl:if
            test="(string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:beginPosition)) > 0) or
                  (string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:endPosition)) > 0)">
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
            <xsl:if test="(string-length($protocol) > 0) and not(contains($protocol, 'metadata-URL'))">

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
                            <xsl:when test="string-length(normalize-space(gmd:name)) > 0">
                                <title>
                                    <xsl:value-of select="normalize-space(gmd:name)"/>
                                </title>
                                <!-- ...and then description as notes -->
                                <xsl:if
                                    test="string-length(normalize-space(gmd:description)) > 0">
                                    <notes>
                                        <xsl:value-of
                                            select="normalize-space(gmd:description)"/>
                                    </notes>
                                </xsl:if>
                            </xsl:when>
                            <!-- No name, so use description as title if we have it -->
                            <xsl:otherwise>
                                <xsl:if
                                    test="string-length(normalize-space(gmd:description)) > 0">
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
    
    <xsl:template match="gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:lineage/gmd:LI_Lineage/gmd:source/gmd:LI_Source" mode="registryObject_relatedInfo">
        <xsl:variable name="relatedType_sequence" as="xs:string*">
            <xsl:call-template name="getRelatedInfoTypeRelationship">
                <xsl:with-param name="presentationForm" select="gmd:sourceCitation/gmd:CI_Citation/gmd:presentationForm/gmd:CI_PresentationFormCode/@codeListValue"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="identifierValue" select="gmd:sourceCitation/gmd:CI_Citation/gmd:identifier/gmd:MD_Identifier/gmd:code"/>
        <xsl:variable name="title" select="gmd:sourceCitation/gmd:CI_Citation/gmd:title"/>
        <xsl:if test="count($relatedType_sequence) = 2">
            <relatedInfo type="{$relatedType_sequence[1]}">
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
                        <xsl:value-of select="$relatedType_sequence[2]"/>
                    </xsl:attribute>
                </relation>
                <xsl:if test="string-length(normalize-space(@title)) > 0"/>
                <title>
                    <xsl:value-of select="normalize-space(@title)"/>
                </title>
            </relatedInfo>
        </xsl:if>
    </xsl:template>
   
    <!-- RegistryObject - RelatedInfo Element  -->
    <xsl:template match="gmd:childIdentifier" mode="registryObject_relatedInfo">
        <xsl:variable name="identifier" select="normalize-space(.)"/>
        <xsl:if test="string-length($identifier) > 0">
            <relatedInfo type="collection">
                <identifier type="uri">
                    <xsl:value-of
                        select="concat('http://', $global_baseURI, '/geonetwork/srv/en/metadata.show?uuid=', $identifier)"
                    />
                </identifier>
                <relation>
                    <xsl:attribute name="type">
                        <xsl:text>hasPart</xsl:text>
                    </xsl:attribute>
                </relation>
                <xsl:if test="string-length(normalize-space(@title)) > 0"/>
                <title>
                    <xsl:value-of select="normalize-space(@title)"/>
                </title>
            </relatedInfo>
        </xsl:if>
    </xsl:template>

    <!-- Variable - Individual Name -->
    <xsl:template match="gmd:MD_DataIdentification" mode="variable_individual_name">
        <xsl:call-template name="getChildValueForRole">
            <xsl:with-param name="roleSubstring">
                <xsl:text>owner</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="childElementName">
                <xsl:text>individualName</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="gmd:MD_ServiceIdentification" mode="variable_individual_name">
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
    <xsl:template match="gmd:MD_CreativeCommons" mode="registryObject_rights_licence_creative">
        <xsl:variable name="licenseLink" select="normalize-space(gmd:licenseLink/gmd:URL)"/>
        <xsl:for-each
            select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
            <xsl:if test="string-length(normalize-space(gml:remarks)) > 0">
                <xsl:if test="contains($licenseLink, gml:remarks)">
                    <rights>
                        <licence>
                            <xsl:attribute name="type" select="gml:identifier"/>
                            <xsl:attribute name="rightsUri" select="$licenseLink"/>
                            <xsl:if test="string-length(normalize-space(gml:name)) > 0">
                                <xsl:value-of select="normalize-space(gml:name)"/>
                            </xsl:if>
                        </licence>
                    </rights>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>

        <!--xsl:for-each select="gmd:otherConstraints">
            <xsl:if test="string-length(normalize-space(.)) > 0">
                <rights>
                    <licence>
                        <xsl:value-of select='normalize-space(.)'/>
                    </licence>
                </rights>
            </xsl:if>
        </xsl:for-each-->
    </xsl:template>

    <!-- RegistryObject - Rights RightsStatement - From CreativeCommons -->
    <xsl:template match="gmd:MD_CreativeCommons" mode="registryObject_rights_rightsStatement_creative">
        <xsl:for-each select="gmd:attributionConstraints">
            <!-- If there is text in other contraints, use this; otherwise, do nothing -->
            <xsl:if test="string-length(normalize-space(.)) > 0">
                <rights>
                    <rightsStatement>
                        <xsl:value-of select="normalize-space(.)"/>
                    </rightsStatement>
                </rights>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <!-- RegistryObject - Rights Licence - From CreativeCommons -->
    <xsl:template match="gmd:MD_Commons" mode="registryObject_rights_licence_creative">
        <xsl:variable name="licenseLink" select="normalize-space(gmd:licenseLink/gmd:URL)"/>
        <xsl:for-each
            select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
            <xsl:if test="string-length(normalize-space(gml:remarks)) > 0">
                <xsl:if test="contains($licenseLink, gml:remarks)">
                    <rights>
                        <licence>
                            <xsl:attribute name="type" select="gml:identifier"/>
                            <xsl:attribute name="rightsUri" select="$licenseLink"/>
                            <xsl:if test="string-length(normalize-space(gml:name)) > 0">
                                <xsl:value-of select="normalize-space(gml:name)"/>
                            </xsl:if>
                        </licence>
                    </rights>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
        
        <!--xsl:for-each select="gmd:otherConstraints">
            <xsl:if test="string-length(normalize-space(.)) > 0">
            <rights>
            <licence>
            <xsl:value-of select='normalize-space(.)'/>
            </licence>
            </rights>
            </xsl:if>
            </xsl:for-each-->
    </xsl:template>
    
    <!-- RegistryObject - Rights RightsStatement - From CreativeCommons -->
    <xsl:template match="gmd:MD_Commons" mode="registryObject_rights_rightsStatement_creative">
        <xsl:for-each select="gmd:attributionConstraints">
            <!-- If there is text in other contraints, use this; otherwise, do nothing -->
            <xsl:if test="string-length(normalize-space(.)) > 0">
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
            <xsl:if test="string-length($useLimitation) > 0">
                <rights>
                    <rightsStatement>
                        <xsl:value-of select="$useLimitation"/>
                    </rightsStatement>
                </rights>
            </xsl:if>
        </xsl:for-each>
        <xsl:variable name="useConstraints_sequence" as="xs:string*">
            <xsl:for-each select="gmd:useConstraints">
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="distinct-values($useConstraints_sequence)">
            <xsl:variable name="useConstraints" select="normalize-space(.)"/>
            <!-- If there is text in other contraints, use this; otherwise, do nothing -->
            <xsl:if test="string-length($useConstraints) > 0">
                <rights>
                    <rightsStatement>
                        <xsl:value-of select="$useConstraints"/>
                    </rightsStatement>
                </rights>
            </xsl:if>
        </xsl:for-each>
        <xsl:if test="not(exists(gmd:accessConstraints))">
            <xsl:for-each select="gmd:otherConstraints">
                <xsl:variable name="otherConstraints" select="normalize-space(.)"/>
                <!-- If there is text in other contraints, use this; otherwise, do nothing -->
                <xsl:if test="string-length($otherConstraints) > 0">
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
            <xsl:if test="string-length(normalize-space(.)) > 0">
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
        <xsl:if test="string-length($otherConstraints) > 0">
            <xsl:if test="contains(lower-case($otherConstraints), 'picccby')">
                <rights>
                    <licence><xsl:text disable-output-escaping="yes">&lt;![CDATA[&lt;a href="http://polarcommons.org/ethics-and-norms-of-data-sharing.php"&gt; &lt;img src="http://polarcommons.org/images/PIC_print_small.png" style="border-width:0; width:40px; height:40px;" alt="Polar Information Commons's PICCCBY license."/&gt;&lt;/a&gt;&lt;a rel="license" href="http://creativecommons.org/licenses/by/3.0/" rel="license"&gt; &lt;img alt="Creative Commons License" style="border-width:0; width: 88px; height: 31px;" src="http://i.creativecommons.org/l/by/3.0/88x31.png" /&gt;&lt;/a&gt;]]&gt;</xsl:text>
                        <!--xsl:for-each select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
                            <xsl:if test="string-length(normalize-space(gml:remarks)) > 0">
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
            <xsl:if test="string-length($useLimitation) > 0">
                <rights>
                    <rightsStatement>
                        <xsl:value-of select="$useLimitation"/>
                    </rightsStatement>
                </rights>
            </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="gmd:useConstraints">
            <xsl:variable name="useConstraints" select="normalize-space(.)"/>
            <!-- If there is text in other contraints, use this; otherwise, do nothing -->
            <xsl:if test="string-length($useConstraints) > 0">
                <rights>
                    <rightsStatement>
                        <xsl:value-of select="$useConstraints"/>
                    </rightsStatement>
                </rights>
            </xsl:if>
        </xsl:for-each>
        <xsl:if test="not(exists(gmd:accessConstraints))">
            <xsl:for-each select="gmd:otherConstraints">
                <xsl:variable name="otherConstraints" select="normalize-space(.)"/>
                <!-- If there is text in other contraints, use this; otherwise, do nothing -->
                <xsl:if test="string-length($otherConstraints) > 0">
                    <xsl:choose>
                        <xsl:when test="contains(lower-case($otherConstraints), 'copyright')">
                            <rights>
                                <rightsStatement>
                                    <xsl:value-of select="$otherConstraints"/>
                                </rightsStatement>
                            </rights>
                        </xsl:when>
                        <xsl:when test="contains(lower-case($otherConstraints), 'licence') or 
                                        contains(lower-case($otherConstraints), 'license')">
                            <rights>
                                <licence>
                                    <xsl:value-of select="$otherConstraints"/>
                                </licence>
                            </rights>
                        </xsl:when>
                        <xsl:otherwise>
                            <rights>
                                <rightsStatement>
                                    <xsl:value-of select="$otherConstraints"/>
                                </rightsStatement>
                            </rights>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:if test="contains(lower-case($otherConstraints), 'picccby')">
                    <rights>
                        <licence><xsl:text disable-output-escaping="yes">&lt;![CDATA[&lt;a href="http://polarcommons.org/ethics-and-norms-of-data-sharing.php"&gt; &lt;img src="http://polarcommons.org/images/PIC_print_small.png" style="border-width:0; width:40px; height:40px;" alt="Polar Information Commons's PICCCBY license."/&gt;&lt;/a&gt;&lt;a rel="license" href="http://creativecommons.org/licenses/by/3.0/" rel="license"&gt; &lt;img alt="Creative Commons License" style="border-width:0; width: 88px; height: 31px;" src="http://i.creativecommons.org/l/by/3.0/88x31.png" /&gt;&lt;/a&gt;]]&gt;</xsl:text>
                            <!--xsl:for-each select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
                                <xsl:if test="string-length(normalize-space(gml:remarks)) > 0">
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
            <xsl:if test="string-length(normalize-space(.)) > 0">
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
        <xsl:if test="string-length($otherConstraints) > 0">
            <xsl:if test="contains(lower-case($otherConstraints), 'picccby')">
                <rights>
                    <licence><xsl:text disable-output-escaping="yes">&lt;![CDATA[&lt;a href="http://polarcommons.org/ethics-and-norms-of-data-sharing.php"&gt; &lt;img src="http://polarcommons.org/images/PIC_print_small.png" style="border-width:0; width:40px; height:40px;" alt="Polar Information Commons's PICCCBY license."/&gt;&lt;/a&gt;&lt;a rel="license" href="http://creativecommons.org/licenses/by/3.0/" rel="license"&gt; &lt;img alt="Creative Commons License" style="border-width:0; width: 88px; height: 31px;" src="http://i.creativecommons.org/l/by/3.0/88x31.png" /&gt;&lt;/a&gt;]]&gt;</xsl:text>
                        <!--xsl:for-each select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
                            <xsl:if test="string-length(normalize-space(gml:remarks)) > 0">
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
        <xsl:param name="locationURL"/>
        <xsl:param name="originatingSource"/>
        <xsl:param name="citation"/>
        <xsl:param name="pointOfContactNode_sequence" as="node()*"/>
        <xsl:param name="distributorContactNode_sequence" as="node()*"/>
        <xsl:param name="metadataCreationDate"/>
        
        <xsl:variable name="CI_Citation" select="." as="node()"></xsl:variable>
        
        <!-- Attempt to obtain contributor names; only construct citation if we have contributor names -->
        
        <xsl:variable name="principalInvestigatorName_sequence" as="xs:string*">
            <xsl:if test="$CI_Citation and (count($CI_Citation) > 0)">
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$CI_Citation" as="node()"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
                </xsl:call-template>
            </xsl:if>
            
            <xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact" as="node()"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
                </xsl:call-template>
            </xsl:for-each>
        
            <xsl:if test="$CI_Citation and (count($CI_Citation) > 0)">
                <xsl:call-template name="getAllOrganisationNameSequence">
                    <xsl:with-param name="parent" select="$CI_Citation" as="node()"/> 
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
                </xsl:call-template>
            </xsl:if>
            
            <xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getOrganisationNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'principalInvestigator'"/>  
                </xsl:call-template>
            </xsl:for-each>
            
        </xsl:variable>
        
        <xsl:variable name="publisherName_sequence" as="xs:string*">
            <xsl:if test="$CI_Citation and (count($CI_Citation) > 0)">
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$CI_Citation" as="node()"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'publisher'"/>  
                </xsl:call-template>
            </xsl:if>
            
            
            <xsl:if test="$CI_Citation and (count($CI_Citation) > 0)">
                <xsl:call-template name="getAllOrganisationNameSequence">
                    <xsl:with-param name="parent" select="$CI_Citation" as="node()"/> 
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'publisher'"/>  
                </xsl:call-template>
            </xsl:if>
            
            <xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact" as="node()"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'publisher'"/>  
                </xsl:call-template>
            </xsl:for-each>
            
            <xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getOrganisationNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'publisher'"/>  
                </xsl:call-template>
            </xsl:for-each>
            
        </xsl:variable>
        
        <xsl:variable name="coInvestigatorName_sequence" as="xs:string*">
            <xsl:if test="$CI_Citation and (count($CI_Citation) > 0)">
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$CI_Citation"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'coInvestigator'"/>  
                </xsl:call-template>
            </xsl:if>
            
            <xsl:for-each select="$pointOfContactNode_sequence">
                <xsl:variable name="pointOfContact" select="." as="node()"/>
                <xsl:call-template name="getIndividualNameSequence">
                    <xsl:with-param name="parent" select="$pointOfContact"/>  
                    <xsl:with-param name="role_sequence" as="xs:string*" select="'coInvestigator'"/>  
                </xsl:call-template>
            </xsl:for-each>
            
            <xsl:if test="$CI_Citation and (count($CI_Citation) > 0)">
                 <xsl:call-template name="getAllOrganisationNameSequence">
                     <xsl:with-param name="parent" select="$CI_Citation"/>  
                     <xsl:with-param name="role_sequence" as="xs:string*" select="'coInvestigator'"/>  
                 </xsl:call-template>
            </xsl:if>
            
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
        
        <xsl:variable name="anyRoleName_sequence" as="xs:string*">
            <!-- Get individual names, regardless of role -->
            <xsl:if test="$CI_Citation and (count($CI_Citation) > 0)">
                 <xsl:call-template name="getIndividualNameSequence">
                     <xsl:with-param name="parent" select="$CI_Citation" as="node()"/>  
                 </xsl:call-template>
            </xsl:if>
            
            <!-- Get organisation names, regardless of role -->
            <xsl:if test="$CI_Citation and (count($CI_Citation) > 0)">
                 <xsl:call-template name="getAllOrganisationNameSequence">
                     <xsl:with-param name="parent" select="$CI_Citation" as="node()"/> 
                 </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        
        <xsl:variable name="allContributorName_sequence" as="xs:string*">
            <xsl:for-each select="distinct-values($principalInvestigatorName_sequence)">
                <xsl:if test="string-length(normalize-space(.)) > 0">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
            
            <xsl:for-each select="distinct-values($coInvestigatorName_sequence)">
                <xsl:if test="string-length(normalize-space(.)) > 0">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
           
            <xsl:if test="
                not(boolean(count($principalInvestigatorName_sequence))) and
                not(boolean(count($coInvestigatorName_sequence)))">
                <xsl:for-each select="distinct-values($pointOfContactName_sequence)">
                    <xsl:if test="string-length(normalize-space(.)) > 0">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
            
            <xsl:for-each select="distinct-values($anyRoleName_sequence)">
                <xsl:if test="string-length(normalize-space(.)) > 0">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="defaultContributorName">
            <xsl:call-template name="getDefaultContributorName">
                <xsl:with-param name="originatingSource" select="$originatingSource"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- We can only accept one DOI; howerver, first we will find all -->
        <xsl:variable name = "doiIdentifier_sequence" as="xs:string*">
            <xsl:call-template name="doiFromIdentifiers">
                <xsl:with-param name="identifier_sequence" as="xs:string*" select="gmd:identifier/gmd:MD_Identifier/gmd:code"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="identifierToUse">
            <xsl:choose>
                <xsl:when test="count($doiIdentifier_sequence) and (string-length($doiIdentifier_sequence[1]) > 0)">
                    <xsl:value-of select="$doiIdentifier_sequence[1]"/>   
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$locationURL"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="typeToUse">
            <xsl:choose>
                <xsl:when test="count($doiIdentifier_sequence) and (string-length($doiIdentifier_sequence[1]) > 0)">
                    <xsl:text>doi</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>uri</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        
        <xsl:if test="count($allContributorName_sequence) or (string-length($defaultContributorName) > 0)">
           <citationInfo>
                <citationMetadata>
                    <xsl:if test="string-length($identifierToUse) > 0">
                        <identifier>
                            <xsl:if test="string-length($typeToUse) > 0">
                                <xsl:attribute name="type">
                                    <xsl:value-of select='$typeToUse'/>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select='$identifierToUse'/>
                        </identifier>
                    </xsl:if>
    
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
                            <xsl:if test="string-length($defaultContributorName) > 0">
                                <contributor>
                                    <namePart>
                                        <xsl:value-of select="$defaultContributorName"/>
                                    </namePart>
                                </contributor>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <xsl:if test="count($publisherName_sequence)">
                        <publisher>
                            <namePart>
                                <xsl:value-of select="$publisherName_sequence[1]"/>
                            </namePart>
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
        <xsl:param name="group"/>
        <registryObject group="{$group}">

            <xsl:variable name="transformedName">
                <xsl:call-template name="getTransformed">
                    <xsl:with-param name="inputString" select="current-grouping-key()"/>
                </xsl:call-template>
            </xsl:variable>


            <key>
                <xsl:value-of
                    select="concat($global_acronym, '/', translate(normalize-space($transformedName),' ',''))"
                />
            </key>

            <originatingSource>
                <xsl:value-of select="$originatingSource"/>
            </originatingSource>

           <xsl:variable name="typeToUse">
                <xsl:variable name="isKnownOrganisation" as="xs:boolean">
                    <xsl:call-template name="get_isKnownOrganisation">
                        <xsl:with-param name="name" select="$transformedName"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="boolean($isKnownOrganisation)">
                        <xsl:value-of>group</xsl:value-of>
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
                                test="string-length(normalize-space($transformedOrganisationName)) > 0">
                                <!--  Individual has an organisation name, so relate the individual to the organisation, and omit the address 
                                        (the address will be included within the organisation to which this individual is related) -->
                                <relatedObject>
                                    <key>
                                        <xsl:value-of
                                            select="concat($global_acronym,'/', translate(normalize-space($transformedOrganisationName),' ',''))"
                                        />
                                    </key>
                                    <relation type="isMemberOf"/>
                                </relatedObject>
                            </xsl:when>

                            <xsl:otherwise>
                                <!-- Individual does not have an organisation name, so physicalAddress must pertain this individual -->
                                <xsl:call-template name="physicalAddress"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                        <!-- Individual - Phone and email on the individual, regardless of whether there's an organisation name -->
                        <xsl:call-template name="onlineResource"/>
                        <xsl:call-template name="telephone"/>
                        <xsl:call-template name="facsimile"/>
                        <xsl:call-template name="email"/>
                        
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- If we are dealing with an Organisation with no individual name, phone and email must pertain to this organisation -->
                        <xsl:variable name="individualName" select="normalize-space(gmd:individualName)"/>
                        <xsl:if test="string-length($individualName) = 0">
                            <xsl:call-template name="onlineResource"/>
                            <xsl:call-template name="telephone"/>
                            <xsl:call-template name="facsimile"/>
                            <xsl:call-template name="email"/>
                        </xsl:if>
                        
                        <!-- We are dealing with an organisation, so always include the address -->
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
                                
                                <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:deliveryPoint[string-length(gco:CharacterString) > 0]">
                                     <addressPart type="addressLine">
                                         <xsl:value-of select="normalize-space(.)"/>
                                     </addressPart>
                                </xsl:for-each>
                                
                                 <xsl:if test="string-length(normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:city)) > 0">
                                      <addressPart type="suburbOrPlaceLocality">
                                          <xsl:value-of select="normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:city)"/>
                                      </addressPart>
                                 </xsl:if>
                                
                                 <xsl:if test="string-length(normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:administrativeArea)) > 0">
                                     <addressPart type="stateOrTerritory">
                                         <xsl:value-of select="normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:administrativeArea)"/>
                                     </addressPart>
                                 </xsl:if>
                                     
                                 <xsl:if test="string-length(normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:postalCode)) > 0">
                                     <addressPart type="postCode">
                                         <xsl:value-of select="normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:postalCode)"/>
                                     </addressPart>
                                 </xsl:if>
                                 
                                 <xsl:if test="string-length(normalize-space(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:country)) > 0">
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
                    <xsl:if test="string-length(normalize-space(.)) > 0">
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
                    <xsl:if test="string-length(normalize-space(.)) > 0">
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
                    <xsl:if test="string-length(normalize-space(.)) > 0">
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
                    <xsl:if test="string-length(normalize-space(.)) > 0">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="distinct-values($url_sequence)">
            <xsl:choose>
                <xsl:when test="contains(., 'orcid')">
                    <identifier type="orcid">
                        <xsl:value-of select="."/> 
                    </identifier>
                </xsl:when>
                <xsl:otherwise>
                    <location>
                        <address>
                            <electronic type="url">
                                <value>
                                    <xsl:value-of select="."/>
                                </value>
                            </electronic>
                        </address>
                    </location>
                </xsl:otherwise>
            </xsl:choose>
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
    
    <xsl:template name="getRegistryObjectTypeSubType" as="xs:string*">
        <xsl:param name="scopeCode"/>
        <xsl:param name="originatingSource"/>
        <xsl:choose>
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
                <xsl:call-template name="getRegistryObjectTypeSubType_default">
                    <xsl:with-param name="scopeCode" select="$scopeCode"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getRegistryObjectTypeSubType_AIMS" as="xs:string*">
        <xsl:param name="scopeCode"/>
        <xsl:choose>
            <xsl:when test="contains($scopeCode, 'dataset')">
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
            <xsl:when test="contains($scopeCode, 'service')">
                <xsl:text>service</xsl:text>
                <xsl:text>report</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>collection</xsl:text>
                <xsl:text>dataset</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
   
    
    <xsl:template name="getRegistryObjectTypeSubType_IMOS" as="xs:string*">
        <xsl:param name="scopeCode"/>
        <xsl:choose>
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
                <xsl:text>collection</xsl:text>
                <xsl:text>dataset</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getRegistryObjectTypeSubType_default" as="xs:string*">
        <xsl:param name="scopeCode"/>
        <xsl:choose>
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
            <xsl:when test="contains($scopeCode, 'model')">
                <xsl:text>service</xsl:text>
                <xsl:text>create</xsl:text>
            </xsl:when>
            <xsl:when test="contains($scopeCode, 'service')">
                <xsl:text>service</xsl:text>
                <xsl:text>report</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>collection</xsl:text>
                <xsl:text>dataset</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getRelatedInfoTypeRelationship" as="xs:string*">
        <xsl:param name="presentationForm"/>
        <xsl:choose>
           <xsl:when test="contains($presentationForm, 'modelDigital')">
                <xsl:text>service</xsl:text>
                <xsl:text>produces</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>reuseInformation</xsl:text>
                <xsl:text>supplements</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
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

    <!-- Finds name of organisation with particular role - ignores organisations that have an individual name -->
    <xsl:template name="getOrganisationNameSequence">
        <xsl:param name="parent" as="node()"/>
        <xsl:param name="role_sequence" as="xs:string*"/>  <!-- if role_sequence is empty: return every, regardless of role -->
        
        <xsl:choose>
            <xsl:when test="count($role_sequence) > 0">
               <xsl:for-each select="tokenize($role_sequence, ',')">
                    <xsl:variable name="role" select="normalize-space(.)"/>
                   
                    <xsl:for-each-group
                        select="$parent/descendant::gmd:CI_ResponsibleParty[
                        (string-length(normalize-space(gmd:organisationName)) > 0)]"
                        group-by="gmd:organisationName">
                        
                        <xsl:variable name="transformedOrganisationName">
                            <xsl:call-template name="getTransformed">
                                <xsl:with-param name="inputString"
                                    select="normalize-space(current-grouping-key())"/>
                            </xsl:call-template>
                        </xsl:variable>
                        
                        <xsl:choose>
                            <xsl:when test="string-length($role) > 0">
                                <xsl:variable name="userIsRole" as="xs:boolean*">
                                    <xsl:call-template name="isRole">
                                        <xsl:with-param name="role" select="$role"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:if test="count($userIsRole)">
                                    <xsl:value-of select="$transformedOrganisationName"/>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- No role specified, so return the name -->
                                <xsl:if test="string-length($transformedOrganisationName) > 0">
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
                    (string-length(normalize-space(gmd:organisationName)) > 0)]"
                    group-by="gmd:organisationName">
                    
                    <xsl:variable name="transformedOrganisationName">
                        <xsl:call-template name="getTransformed">
                            <xsl:with-param name="inputString"
                                select="normalize-space(current-grouping-key())"/>
                        </xsl:call-template>
                    </xsl:variable>
                    
                    <xsl:if test="string-length($transformedOrganisationName) > 0">
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
        
        <!-- Contributing organisations - note that we are ignoring those organisations where a role has not been specified -->
        <xsl:choose>
            <xsl:when test="count($role_sequence)">
                <xsl:for-each select="tokenize($role_sequence, ',')">
                    <xsl:variable name="role" select="normalize-space(.)"/>
                    
                    <xsl:for-each-group
                        select="$parent/descendant::gmd:CI_ResponsibleParty[
                        (string-length(normalize-space(gmd:organisationName)) > 0)]"
                        group-by="gmd:organisationName">
                        
                        <xsl:variable name="transformedOrganisationName">
                            <xsl:call-template name="getTransformed">
                                <xsl:with-param name="inputString"
                                    select="normalize-space(current-grouping-key())"/>
                            </xsl:call-template>
                        </xsl:variable>
                        
                        <xsl:choose>
                            <xsl:when test="string-length($role) > 0">
                                <xsl:variable name="userIsRole" as="xs:boolean*">
                                    <xsl:call-template name="isRole">
                                        <xsl:with-param name="role" select="$role"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:if test="count($userIsRole)">
                                    <xsl:value-of select="$transformedOrganisationName"/>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- No role specified, so return the name -->
                                <xsl:if test="string-length($transformedOrganisationName) > 0">
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
                    (string-length(normalize-space(gmd:organisationName)) > 0)]"
                    group-by="gmd:organisationName">
                    
                    <xsl:variable name="transformedOrganisationName">
                        <xsl:call-template name="getTransformed">
                            <xsl:with-param name="inputString"
                                select="normalize-space(current-grouping-key())"/>
                        </xsl:call-template>
                    </xsl:variable>
                    
                    <xsl:if test="string-length($transformedOrganisationName) > 0">
                        <xsl:value-of select="$transformedOrganisationName"/>
                    </xsl:if>
                </xsl:for-each-group>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getIndividualNameSequence">
        <xsl:param name="parent" as="node()"/>
        <xsl:param name="role_sequence" as="xs:string*"/>  <!-- if role_sequence is empty: return every, regardless of role -->
        
        <xsl:choose>
            <xsl:when test="count($role_sequence)">
                <xsl:for-each select="tokenize($role_sequence, ',')">
                    <xsl:variable name="role" select="normalize-space(.)"/>
                    
                    <xsl:for-each-group
                        select="$parent/descendant::gmd:CI_ResponsibleParty[
                        (string-length(normalize-space(gmd:individualName)) > 0)]"
                        group-by="gmd:individualName">
                        
                        <xsl:choose>
                            <xsl:when test="string-length($role) > 0">
                                <xsl:variable name="userIsRole" as="xs:boolean*">
                                    <xsl:call-template name="isRole">
                                        <xsl:with-param name="role" select="$role"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:if test="count($userIsRole)">
                                    <xsl:value-of select="normalize-space(current-grouping-key())"/>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- No role specified, so return the name -->
                                <xsl:if test="string-length(normalize-space(current-grouping-key())) > 0">
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
                    (string-length(normalize-space(gmd:individualName)) > 0)]"
                    group-by="gmd:individualName">
                    
                    <xsl:if test="string-length(normalize-space(current-grouping-key())) > 0">
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

        <xsl:choose>
            <xsl:when test="string-length($publishCity) > 0">
                <xsl:value-of select="$publishCity"/>
            </xsl:when>
            <xsl:when test="string-length($publishCountry) > 0">
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
        <xsl:variable name="name_sequence" as="xs:string*">
            <xsl:for-each-group
                select="descendant::gmd:CI_ResponsibleParty[
                (string-length(normalize-space(descendant::node()[local-name()=$childElementName])) > 0)]"
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
        <xsl:value-of select="$formattedValues"/>
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
                <xsl:if test="string-length(normalize-space($string)) > 0">
                    <xsl:value-of select="normalize-space($string)"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="doiFromIdentifiers">
        <xsl:param name="identifier_sequence"/>
        <xsl:for-each select="distinct-values($identifier_sequence)">
            <xsl:if test="contains(lower-case(normalize-space(.)), 'doi')">
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
        
</xsl:stylesheet>