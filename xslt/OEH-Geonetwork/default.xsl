<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gmd="http://www.isotc211.org/2005/gmd" xmlns:srv="http://www.isotc211.org/2005/srv"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:gml="http://www.opengis.net/gml"
    xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:gts='http://www.isotc211.org/2005/gts'
    xmlns:geonet="http://www.fao.org/geonetwork" xmlns:gmx="http://www.isotc211.org/2005/gmx"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://ands.org.au/standards/rif-cs/registryObjects"
    exclude-result-prefixes="geonet gmx oai xsi gmd srv gml gco gts">
    <!-- stylesheet to convert iso19139 in OAI-PMH ListRecords response to RIF-CS -->
    <xsl:output method="xml" version="1.0" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
    <xsl:strip-space elements='*'/>
    <xsl:param name="global_originatingSource" select="'http://mapdata.environment.nsw.gov.au/geonetwork/srv/en'"/>
    <xsl:param name="global_baseURI" select="'http://mapdata.environment.nsw.gov.au'"/>
    <xsl:param name="global_group" select="'Office of Environment and Heritage NSW'"/>
    <xsl:param name="global_publisherName" select="'Office of Environment and Heritage NSW'"/>
    <xsl:param name="global_publisherPlace" select="'Canberra'"/>
    <xsl:variable name="anzsrcCodelist" select="document('anzsrc-codelist.xml')"/>
    <xsl:variable name="licenseCodelist" select="document('license-codelist.xml')"/>
    <xsl:variable name="gmdCodelists" select="document('codelists.xml')"/>

    <xsl:template match="oai:responseDate"/>
    <xsl:template match="oai:request"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:identifier"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:datestamp"/>
    <xsl:template match="oai:GetRecord/oai:record/oai:header/oai:setSpec"/>

    <xsl:template match="/">
        <registryObjects>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="//gmd:MD_Metadata"/>
        </registryObjects>
    </xsl:template>
    <!-- =========================================== -->
    <!-- RegistryObjects (root) Template             -->
    <!-- =========================================== -->

    <xsl:template match="gmd:MD_Metadata">
        <xsl:apply-templates select="." mode="collection"/>
        <xsl:apply-templates select="." mode="party"/>
    </xsl:template>

    <xsl:template match="node()"/>

    <!-- =========================================== -->
    <!-- Collection RegistryObject Template          -->
    <!-- =========================================== -->

    <xsl:template match="gmd:MD_Metadata" mode="collection">
       
        <!-- construct parameters for values that are required in more than one place in the output xml-->
        <!--xsl:param name="dataSetURI" select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine[1]/gmd:CI_OnlineResource/gmd:linkage/gmd:URL"/-->
        <xsl:param name="fileIdentifier" select="gmd:fileIdentifier"/>
        
        <registryObject>
            <xsl:attribute name="group">
                <xsl:value-of select="$global_group"/>
            </xsl:attribute>
            <xsl:apply-templates select="gmd:fileIdentifier" mode="collection_key"/>
           
            <originatingSource>
                <xsl:value-of select="$global_originatingSource"/>
            </originatingSource>
            
            <collection>
                
                <xsl:apply-templates select="gmd:dataQualityInfo[1]/gmd:DQ_DataQuality[1]/gmd:scope/gmd:DQ_Scope/gmd:level/gmd:MD_ScopeCode/@codeListValue" 
                    mode="collection_type_attribute"/>
                
                <xsl:apply-templates select="gmd:fileIdentifier" 
                    mode="collection_identifier"/>
                
                <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:identifier" 
                    mode="collection_identifier"/>
                
                <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title" 
                    mode="collection_name"/>
                
                <!--xsl:apply-templates select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine[1]/gmd:CI_OnlineResource/gmd:linkage/gmd:URL" 
                mode="collection_location"/-->
                
                <xsl:apply-templates select="gmd:fileIdentifier" 
                    mode="collection_location"/>
                
               <xsl:for-each-group select="gmd:contact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
                    (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] | 
                    gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
                    (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
                    gmd:identificationInfo/gmd:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
                    (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                    group-by="gmd:individualName">
                     <xsl:apply-templates select="." 
                        mode="collection_related_object"/>
                </xsl:for-each-group>
                
                <xsl:for-each-group select="gmd:contact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName)) and not(string-length(normalize-space(gmd:individualName)))) and  
                    (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] | 
                    gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName)) and not(string-length(normalize-space(gmd:individualName)))) and 
                    (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
                    gmd:identificationInfo/gmd:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName)) and not(string-length(normalize-space(gmd:individualName)))) and 
                    (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                    group-by="gmd:organisationName">
                    <xsl:apply-templates select="." 
                        mode="collection_related_object"/>
                </xsl:for-each-group>
                
                <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode" 
                    mode="collection_subject"/>
                
                <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:keyword" 
                    mode="collection_subject"/>
                
                <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:keyword" 
                    mode="collection_subject_anzsrc"/>
                
                <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract" 
                    mode="collection_description"/>
                
                <xsl:apply-templates select="gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:lineage/gmd:LI_Lineage/gmd:statement" 
                    mode="collection_description_lineage"/>
                
                <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox" 
                    mode="collection_coverage_spatial"/>
                
                 <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent"
                    mode="collection_coverage_temporal"/>
                
                <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints[
                    exists(gmd:useLimitation) and string-length(gmd:useLimitation)]"
                    mode="collection_rights_rightsStatement"/> 
                
                <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_SecurityConstraints[
                    exists(gmd:useLimitation) and string-length(gmd:useLimitation)]"
                    mode="collection_rights_rightsStatement"/> 
                
                <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints[
                    exists(gmd:accessConstraints) and string-length(gmd:accessConstraints)]"
                    mode="collection_rights_accessRights"/> 
                
                <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints[
                    exists(gmd:useConstraints) and string-length(gmd:useConstraints)]"
                    mode="collection_rights_licence"/> 
                
                <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation">
                   <xsl:call-template name="collection_citationMetadata_citationInfo">
                       <xsl:with-param name="fileIdentifier" select="$fileIdentifier"/>
                       <xsl:with-param name="citation" select="."/>
                   </xsl:call-template>
                </xsl:for-each> 
               
            </collection>
        </registryObject>
    </xsl:template>   
    
    <!-- =========================================== -->
    <!-- Party RegistryObject Template          -->
    <!-- =========================================== -->
    
    <xsl:template match="gmd:MD_Metadata" mode="party">
        
        <xsl:for-each-group select="gmd:contact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
            (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] | 
            gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
            (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
            gmd:identificationInfo/gmd:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
            (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
            group-by="gmd:individualName">
             <xsl:call-template name="party">
                <xsl:with-param name="type">person</xsl:with-param>
            </xsl:call-template>
        </xsl:for-each-group>
        
        <xsl:for-each-group select="gmd:contact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
            (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] | 
            gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
            (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))] |
            gmd:identificationInfo/gmd:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:organisationName))) and 
            (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
            group-by="gmd:organisationName">
            <xsl:call-template name="party">
                <xsl:with-param name="type">group</xsl:with-param>
            </xsl:call-template>
        </xsl:for-each-group>
    </xsl:template>
    
    
    <!-- =========================================== -->
    <!-- Collection RegistryObject - Child Templates -->
    <!-- =========================================== -->
    
    <!-- Collection - Key Element  -->
    <xsl:template match="gmd:fileIdentifier" mode="collection_key">
        <key>
            <xsl:value-of select="concat($global_baseURI, '/', normalize-space(.))"/>
        </key>
    </xsl:template>
    
    <!-- Collection - Type Attribute -->
    <xsl:template match="gmd:dataQualityInfo[1]/gmd:DQ_DataQuality[1]/gmd:scope/gmd:DQ_Scope/gmd:level/gmd:MD_ScopeCode/@codeListValue" mode="collection_type_attribute">
        <xsl:attribute name="type">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- Collection - Identifier Element  -->
    <xsl:template match="gmd:fileIdentifier" mode="collection_identifier">
        <identifier>
            <xsl:attribute name="type">
                 <xsl:text>local</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="normalize-space(.)"/>
        </identifier>
    </xsl:template>
    
    <xsl:template match="gmd:identifier" mode="collection_identifier">
        <xsl:variable name="code" select="normalize-space(gmd:MD_Identifier/gmd:code)"></xsl:variable>
        <xsl:if test="string-length($code)">
            <identifier>
                <xsl:attribute name="type">
                    <xsl:variable name="lowerCode">
                        <xsl:call-template name="toLower">
                            <xsl:with-param name="inputString" select="$code"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="contains($lowerCode, 'doi')">
                            <xsl:text>doi</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains($lowerCode, 'http')">
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
    
        <!-- Collection - Name Element  -->
    <xsl:template match="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title" mode="collection_name">
        <name>
            <xsl:attribute name="type">
                 <xsl:text>primary</xsl:text>
            </xsl:attribute>
            <namePart>
                 <xsl:value-of select="."/>
            </namePart>
        </name>
    </xsl:template>
    
    <!-- Collection - Address Electronic Element  -->
    <!--xsl:template match="gmd:URL" mode="collection_location">
       <location>
            <address>
                <electronic>
                    <xsl:attribute name="type">
                        <xsl:text>url</xsl:text>
                    </xsl:attribute>
                    <value>
                        <xsl:value-of select="."/>
                    </value>
                </electronic>
            </address>
       </location>
       </xsl:template-->
    
    <xsl:template match="gmd:fileIdentifier" mode="collection_location">
        <xsl:variable name="identifier" select='normalize-space(.)'/>
        <xsl:if test="string-length($identifier)">
            <location>
                <address>
                    <electronic>
                        <xsl:attribute name="type">
                            <xsl:text>url</xsl:text>
                        </xsl:attribute>
                        <value>
                            <xsl:value-of select="concat($global_originatingSource, '/metadata.show?uuid=', $identifier)"/>
                        </value>
                    </electronic>
                </address>
            </location>
        </xsl:if>
    </xsl:template>
    
    <!-- Collection - Related Object (Organisation or Individual) Element -->
    <xsl:template match="gmd:CI_ResponsibleParty" mode="collection_related_object">
        
        <xsl:variable name="transformedName">
            <xsl:call-template name="transform">
                <xsl:with-param name="inputString" select="normalize-space(current-grouping-key())"/>
            </xsl:call-template>
        </xsl:variable>
        <relatedObject>
            <key>
                <xsl:value-of select="concat($global_baseURI,'/', translate(normalize-space(current-grouping-key()),' ',''))"/>
            </key>
            <xsl:for-each-group select="current-group()/gmd:role" group-by="gmd:CI_RoleCode/@codeListValue">
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
    
   
    <!-- Collection - Subject Element -->
    <xsl:template match="gmd:keyword" mode="collection_subject">
        <xsl:call-template name="splitText">
            <xsl:with-param name="string" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="gmd:MD_TopicCategoryCode" mode="collection_subject">
        <xsl:call-template name="splitText">
            <xsl:with-param name="string" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- Collection - Subject (anzsrc) Element -->
    <xsl:template match="gmd:keyword" mode="collection_subject_anzsrc">
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
    
    <!-- Collection - Decription Element - brief -->
    <xsl:template match="gmd:abstract" mode="collection_description">
        <description type="brief">
           <xsl:value-of select="."/>
        </description>
    </xsl:template>
    
    <xsl:template match="gmd:statement" mode="collection_description_lineage">
        <xsl:if test="string-length(normalize-space(.))">
            <description type="lineage">
                <xsl:value-of select="normalize-space(.)"/>
            </description>
        </xsl:if>
    </xsl:template>
    
   <!-- Collection - Coverage Spatial Element -->
    <xsl:template match="gmd:EX_TemporalExtent" mode="collection_coverage_temporal">
        <xsl:if test="string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:beginPosition)) or
                        string-length(normalize-space(gmd:extent/gml:TimePeriod/gml:endPosition))">
            <xsl:message>collection_coverage_temporal</xsl:message>
            
            <coverage>
                <temporal>
                    <!-- We can only deal currently with format 08/09/2008 - will need to add lines for other formats -->
                    <xsl:variable name="beginTime">
                        <xsl:variable name="beginTimeFull" select="normalize-space(gmd:extent/gml:TimePeriod/gml:beginPosition)"/>
                        <xsl:choose>
                            <xsl:when test="contains($beginTimeFull,'/')">
                                <xsl:choose>
                                    <xsl:when test="string-length($beginTimeFull) = 10">
                                        <xsl:value-of select="concat(substring($beginTimeFull,7,4), '-', substring($beginTimeFull,4,2), '-', substring($beginTimeFull,1,2))"/>
                                    </xsl:when>
                                    <xsl:when test="string-length($beginTimeFull) = 7">
                                        <xsl:value-of select="concat(substring($beginTimeFull,4,4), '-', substring($beginTimeFull,1,2))"/>
                                    </xsl:when>
                                    <xsl:otherwise> <!-- slashes but unexpected length, so don't know what to do - just return what it is -->
                                        <xsl:value-of select="$beginTimeFull"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise> <!-- no slashes - presume valid format -->
                                <xsl:value-of select="$beginTimeFull"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                  
                    <xsl:if test="string-length($beginTime)">
                        <date>
                            <xsl:attribute name="dateFormat">
                                <xsl:text>W3CDTF</xsl:text>
                            </xsl:attribute>
                            <xsl:attribute name="type">
                                <xsl:text>dateFrom</xsl:text>
                            </xsl:attribute>
                            <xsl:value-of select="$beginTime"/>
                        </date>
                    </xsl:if>
                    <xsl:variable name="endTime" select="normalize-space(gmd:extent/gml:TimePeriod/gml:endPosition)"/>
                    <xsl:if test="string-length($endTime) = 10">
                        <date>
                            <xsl:attribute name="dateFormat">
                                <xsl:text>W3CDTF</xsl:text>
                            </xsl:attribute>
                            <xsl:attribute name="type">
                                <xsl:text>dateTo</xsl:text>
                            </xsl:attribute>
                            <xsl:value-of select="concat(substring($endTime,7,4), '-', substring($endTime,4,2), '-', substring($endTime,1,2))"/>
                        </date>
                    </xsl:if>
                </temporal>
            </coverage>
        </xsl:if>
    </xsl:template>
    
    <!-- Collection - Coverage Spatial Element -->
    <xsl:template match="gmd:EX_GeographicBoundingBox" mode="collection_coverage_spatial">
        <xsl:variable name="spatialString">
               <xsl:variable name="horizontal">
                    <xsl:if test="(string-length(normalize-space(gmd:northBoundLatitude/gco:Decimal))) and
                                  (string-length(normalize-space(gmd:southBoundLatitude/gco:Decimal))) and
                                  (string-length(normalize-space(gmd:westBoundLongitude/gco:Decimal))) and
                                  (string-length(normalize-space(gmd:eastBoundLongitude/gco:Decimal)))">
                        <xsl:value-of select="normalize-space(concat('northlimit=',gmd:northBoundLatitude/gco:Decimal,'; southlimit=',gmd:southBoundLatitude/gco:Decimal,'; westlimit=',gmd:westBoundLongitude/gco:Decimal,'; eastLimit=',gmd:eastBoundLongitude/gco:Decimal))"/>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="vertical">
                    <xsl:if test="
                        (string-length(normalize-space(gmd:EX_VerticalExtent/gmd:maximumValue/gco:Real))) and
                        (string-length(normalize-space(gmd:EX_VerticalExtent/gmd:minimumValue/gco:Real)))">
                        <xsl:value-of select="normalize-space(concat('; uplimit=',gmd:EX_VerticalExtent/gmd:maximumValue/gco:Real,'; downlimit=',gmd:EX_VerticalExtent/gmd:minimumValue/gco:Real))"/>
                    </xsl:if>
                </xsl:variable>
                <xsl:value-of select="concat($horizontal, $vertical, '; projection=WGS84')"/>
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
    </xsl:template>
    
    <!-- Variable - Owner Name -->
    <xsl:template match="gmd:MD_DataIdentification" mode="variable_owner_name">
        <xsl:call-template name="childValueForRole">
            <xsl:with-param name="roleSubstring">
                <xsl:text>owner</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="childElementName">
                <xsl:text>organisationName</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <!-- Variable - Individual Name -->
    <xsl:template match="gmd:MD_DataIdentification" mode="variable_individual_name">
        <xsl:call-template name="childValueForRole">
            <xsl:with-param name="roleSubstring">
                <xsl:text>owner</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="childElementName">
                <xsl:text>individualName</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
     <!-- Collection - RightsStatement -->
    <xsl:template match="gmd:MD_LegalConstraints" mode="collection_rights_rightsStatement">
        <xsl:for-each select="gmd:useLimitation">
            <!-- If there is text in other contraints, use this; otherwise, do nothing -->
            <xsl:variable name="useLimitation" select="normalize-space(.)"/>
            <xsl:if test="string-length($useLimitation)">
                <rights>
                    <rightsStatement>
                        <xsl:value-of select='$useLimitation'/>
                    </rightsStatement>
                </rights>
                <xsl:for-each select="$licenseCodelist/gmx:CT_CodelistCatalogue/gmx:codelistItem/gmx:CodeListDictionary[@gml:id='LicenseCode']/gmx:codeEntry/gmx:CodeDefinition">
                    <xsl:if test="string-length(normalize-space(gml:remarks))">
                        <xsl:if test="contains($useLimitation, gml:remarks)">
                            <rights>
                                <licence>
                                    <xsl:attribute name="type" select="gml:identifier"/>
                                    <xsl:attribute name="rightsUri" select="gml:remarks"/>
                                </licence>
                            </rights>
                        </xsl:if>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Collection - RightsStatement -->
    <xsl:template match="gmd:MD_SecurityConstraints" mode="collection_rights_rightsStatement">
        <xsl:for-each select="gmd:useLimitation">
            <!-- If there is text in other contraints, use this; otherwise, do nothing -->
            <xsl:if test="string-length(normalize-space(.))">
                <rights>
                    <rightsStatement>
                        <xsl:value-of select='normalize-space(.)'/>
                    </rightsStatement>
                </rights>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Collection - Rights AccessRights Element -->
    <xsl:template match="gmd:MD_LegalConstraints" mode="collection_rights_accessRights">
        <xsl:for-each select="gmd:accessConstraints">
            <xsl:variable name="accessConstraints" select="normalize-space(.)"/>
            <xsl:choose>
                <xsl:when test="contains($accessConstraints, 'otherRestrictions')">
                    <xsl:for-each select="following-sibling::gmd:otherConstraints">
                        <xsl:if test="string-length(normalize-space(.))">
                            <rights>
                                <accessRights>
                                    <xsl:value-of select="normalize-space(.)"></xsl:value-of>
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
    
    <!-- Collection - Rights Licence Element -->
    <xsl:template match="gmd:MD_LegalConstraints" mode="collection_rights_licence">
        <xsl:for-each select="gmd:useConstraints">
            <xsl:variable name="useConstraints" select="normalize-space(.)"/>
            <xsl:choose>
                <xsl:when test="contains($useConstraints, 'otherRestrictions')">
                    <xsl:for-each select="following-sibling::gmd:otherConstraints">
                        <xsl:if test="string-length(normalize-space(.))">
                            <rights>
                                <licence>
                                    <xsl:value-of select="normalize-space(.)"></xsl:value-of>
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
  
    <!-- Collection - CitationInfo Element -->
    <xsl:template name="collection_citationMetadata_citationInfo">
        <xsl:param name="fileIdentifier"/>
        <xsl:param name="citation"/>
        <!-- We can only accept one DOI; howerver, first we will find all -->
        <xsl:variable name = "doiIdentifier_sequence" as="xs:string*">
            <xsl:call-template name="doiFromIdentifiers">
                <xsl:with-param name="identifier_sequence" as="xs:string*" select="gmd:identifier/gmd:MD_Identifier/gmd:code"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="identifierToUse">
            <xsl:choose>
                <xsl:when test="count($doiIdentifier_sequence) and string-length($doiIdentifier_sequence[1])">
                    <xsl:value-of select="$doiIdentifier_sequence[1]"/>   
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($global_originatingSource, '/metadata.show?uuid=', $fileIdentifier)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="typeToUse">
            <xsl:choose>
                <xsl:when test="count($doiIdentifier_sequence) and string-length($doiIdentifier_sequence[1])">
                    <xsl:text>doi</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>uri</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <citationInfo>
            <citationMetadata>
                <xsl:if test="string-length($identifierToUse)">
                    <identifier>
                        <xsl:if test="string-length($typeToUse)">
                            <xsl:attribute name="type">
                                <xsl:value-of select='$typeToUse'/>
                            </xsl:attribute>
                        </xsl:if>
                        <xsl:value-of select='$identifierToUse'/>
                    </identifier>
                </xsl:if>
                
                <title>
                    <xsl:value-of select="gmd:CI_Citation/gmd:title"/>
                </title>
                <xsl:for-each select="gmd:CI_Citation/gmd:date/gmd:CI_Date">
                    <xsl:variable name="lowerCode">
                        <xsl:call-template name="toLower">
                            <xsl:with-param name="inputString" select="gmd:dateType/gmd:CI_DateTypeCode/@codeListValue"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:if test="contains($lowerCode, 'publication')">
                        <xsl:variable name="publicationDate" select="normalize-space(gmd:date/gco:DateTime)"/>
                        <xsl:if test="string-length($publicationDate) >= 4">
                            <date>
                                <xsl:attribute name="type">
                                    <xsl:variable name="codelist" select="$gmdCodelists/codelists/codelist[@name = 'gmd:CI_DateTypeCode']"/>
                                    <xsl:variable name="codevalue" select="gmd:dateType/gmd:CI_DateTypeCode/@codeListValue"/>
                                    <xsl:value-of select="$codelist/entry[code = $codevalue]/description"/>
                                </xsl:attribute>
                                <xsl:value-of select="substring($publicationDate, 1, 4)"></xsl:value-of>
                            </date>
                        </xsl:if>
                    </xsl:if>
                </xsl:for-each>
                
                 <!-- Contributing individuals - note that we are ignoring those individuals where a role has not been specified -->
                <xsl:for-each-group
                    select="following-sibling::gmd:pointOfContact/gmd:CI_ResponsibleParty[(string-length(normalize-space(gmd:individualName))) and 
                    (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                    group-by="gmd:individualName">
                    
                    <xsl:variable name="individualName" select="normalize-space(current-grouping-key())"/>
                    <xsl:variable name="userIsRole" as="xs:boolean*">
                        <xsl:call-template name="isRole">
                            <xsl:with-param name="roles" select="'author,principalInvestigator,originator,owner'"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:if test="(count($userIsRole) > 0)">
                        <contributor>
                            <namePart>
                                <xsl:value-of select="$individualName"/>
                            </namePart>
                        </contributor>
                    </xsl:if>
                </xsl:for-each-group>
                
                <!-- Contributing organisations - included only when there is no individual name (in which case the individual has been included above) 
                        Note again that we are ignoring organisations where a role has not been specified -->
                <xsl:for-each-group
                    select="following-sibling::gmd:pointOfContact//gmd:CI_ResponsibleParty[
                            (string-length(normalize-space(gmd:organisationName))) and
                            not(string-length(normalize-space(gmd:individualName))) and
                            (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                    group-by="gmd:organisationName">
                    
                    <xsl:message>Contributing Organisations</xsl:message>
                    
                    <xsl:variable name="transformedOrganisationName">
                        <xsl:call-template name="transform">
                            <xsl:with-param name="inputString" select="normalize-space(current-grouping-key())"/>
                        </xsl:call-template>
                    </xsl:variable>
                    
                    <xsl:variable name="userIsRole" as="xs:boolean*">
                        <xsl:call-template name="isRole">
                            <xsl:with-param name="roles" select="'author,principalInvestigator,originator,owner'"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:if test="(count($userIsRole) > 0)">
                        <contributor>
                            <namePart>
                                <xsl:value-of select="$transformedOrganisationName"/>
                            </namePart>
                        </contributor>
                    </xsl:if>
                </xsl:for-each-group>
                
                <xsl:variable name="publishName">
                    <xsl:call-template name="publishNameToUse"/>
                </xsl:variable>
                
                <xsl:if test="string-length($publishName)">
                    <publisher>
                        <xsl:value-of select="$publishName"/>
                    </publisher>
                </xsl:if>
                
                <xsl:variable name="publishPlace">
                    <xsl:call-template name="publishPlaceToUse">
                        <xsl:with-param name="publishNameToUse" select="$publishName"/>
                    </xsl:call-template>
                </xsl:variable>
               
                <xsl:if test="string-length($publishPlace)">
                    <placePublished>
                        <xsl:value-of select="$publishPlace"/>
                    </placePublished>
                </xsl:if>
    
            </citationMetadata>
        </citationInfo>
    </xsl:template>
    
    
  
    <!-- ====================================== -->
    <!-- Party RegistryObject - Child Templates -->
    <!-- ====================================== -->
    
    <!-- Party Registry Object (Individuals (person) and Organisations (group)) -->
    <xsl:template name="party">
        <xsl:param name="type"/>
        <registryObject group="{$global_group}">
            
            <xsl:variable name="transformedName">
                <xsl:call-template name="transform">
                    <xsl:with-param name="inputString" select="current-grouping-key()"/>
                </xsl:call-template>
            </xsl:variable>
            
            <key>
                <xsl:value-of select="concat($global_baseURI, '/', translate(normalize-space($transformedName),' ',''))"/>
            </key>
            
            <originatingSource>
                <xsl:value-of select="$global_originatingSource"/>
            </originatingSource>
            
            <!-- Use the party type provided, except for exception:
                Because sometimes "OEH" or "OE&H" is used for an author, appearing in individualName,
                we want to make sure that we use 'group', not 'person', if this anomoly occurs -->
            
            <xsl:variable name="typeToUse">
                <xsl:choose>
                    <xsl:when test="contains($transformedName, 'OEH') or
                                    contains($transformedName, 'OE&amp;H')">
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
                            <xsl:call-template name="transform">
                                <xsl:with-param name="inputString" select="gmd:organisationName"/>
                            </xsl:call-template>
                        </xsl:variable>
                        
                        
                        <xsl:choose>
                            <xsl:when test="string-length(normalize-space($transformedOrganisationName))">
                                <!--  Individual has an organisation name, so related the individual to the organisation, and omit the address 
                                    (the address will be included within the organisation to which this individual is related) -->
                                <relatedObject>
                                    <key>
                                        <xsl:value-of select="concat($global_baseURI,'/', $transformedOrganisationName)"/>
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
                <xsl:if test="count(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/child::*) > 0">
                
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
                <xsl:if test="count(gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/child::*) > 0">
                    <location>
                        <address>
                            <physical type="streetAddress">
                                 <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/gmd:voice/gco:CharacterString[string-length(text()) > 0]">
                                     <addressPart type="telephoneNumber">
                                         <xsl:value-of select="normalize-space(.)"/>
                                     </addressPart>
                                 </xsl:for-each>
                                    
                                 <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/gmd:facsimile/gco:CharacterString[string-length(text()) > 0]">
                                     <addressPart type="faxNumber">
                                         <xsl:value-of select="normalize-space(.)"/>
                                     </addressPart>
                                 </xsl:for-each>
                            </physical>
                        </address>
                    </location>
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
                <xsl:if test="count(gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:electronicMailAddress/gco:CharacterString[string-length(text()) > 0])">
                    <location>
                        <address>
                            <electronic type="email">
                                <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:electronicMailAddress/gco:CharacterString[string-length(text()) > 0]">
                                    <value>
                                        <xsl:value-of select="normalize-space(.)"/>
                                    </value>
                                </xsl:for-each>
                            </electronic>
                        </address>
                    </location>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    
    <!-- Modules -->
    
    <xsl:template name="toLower">
        <xsl:param name="inputString"/>
        <xsl:variable name="smallCase" select="'abcdefghijklmnopqrstuvwxyz'"/>
        <xsl:variable name="upperCase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
        <xsl:value-of select="translate($inputString,$upperCase,$smallCase)"/>
    </xsl:template>
    
    <xsl:template name="isRole" as="xs:boolean*">
        <xsl:param name="roles"/>
        <xsl:for-each-group select="current-group()/gmd:role" group-by="gmd:CI_RoleCode/@codeListValue">
           <xsl:for-each select="tokenize($roles, ',')">
                <xsl:if test="contains(current-grouping-key(), .)">
                    <xsl:value-of select="true()"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each-group>
    </xsl:template>
    
    <xsl:template name="publishNameToUse">
        <xsl:variable name="organisationPublisherName">
            <xsl:call-template name="childValueForRole">
                <xsl:with-param name="roleSubstring">
                    <xsl:text>publish</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="childElementName">
                    <xsl:text>organisationName</xsl:text>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="transformedOrganisationPublisherName">
            <xsl:call-template name="transform">
                <xsl:with-param name="inputString" select="$organisationPublisherName"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="individualPublisherName">
            <xsl:call-template name="childValueForRole">
                <xsl:with-param name="roleSubstring">
                    <xsl:text>publish</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="childElementName">
                    <xsl:text>individualName</xsl:text>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="transformedIndividualPublisherName">
            <xsl:call-template name="transform">
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
    
    <xsl:template name="publishPlaceToUse">
        <xsl:param name="publishNameToUse"/>
        <xsl:variable name="publishCity">
            <xsl:call-template name="childValueForRole">
                <xsl:with-param name="roleSubstring">
                    <xsl:text>publish</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="childElementName">
                    <xsl:text>city</xsl:text>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="publishCountry">
            <xsl:call-template name="childValueForRole">
                <xsl:with-param name="roleSubstring">
                    <xsl:text>publish</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="childElementName">
                    <xsl:text>country</xsl:text>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="string-length($publishCity)">
                <xsl:value-of select="$publishCity"/>
            </xsl:when>
            <xsl:when test="string-length($publishCountry)">
                <xsl:value-of select="$publishCity"/>
            </xsl:when>
            <!-- Only default publisher place if publisher name is equal to the global value (whether it was set or retrieved) -->
            <!--xsl:otherwise>
                <xsl:if test="$publishNameToUse = $global_publisherName">
                        <xsl:value-of select="$global_publisherPlace"></xsl:value-of>
                </xsl:if>
            </xsl:otherwise-->
        </xsl:choose>
    </xsl:template>
    
   
    <xsl:template name="transform">
        <xsl:param name="inputString"/>
        <xsl:choose>
            <xsl:when test="normalize-space($inputString) = 'OEH'">
                <xsl:text>Office of Environment and Heritage NSW</xsl:text>
            </xsl:when>
            <xsl:when test="normalize-space($inputString) = 'OE&amp;H'">
                <xsl:text>Office of Environment and Heritage NSW</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="normalize-space($inputString)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Get the values of the child element of the point of contact responsible parties whose role contains this substring provided 
         For example, if you provide roleSubsting as 'publish' and childElementName as 'organisationName',
            you will receive all organisation names within point of contact.  They will be separated by 'commas', with an 'and' between
            the last and second last, where applicable -->
    <xsl:template name="childValueForRole">
        <xsl:param name="roleSubstring"/>
        <xsl:param name="childElementName"/>
        <xsl:variable name="lowerRoleSubstring">
            <xsl:call-template name="toLower">
                <xsl:with-param name="inputString" select="$roleSubstring"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="nameSequence" as="xs:string*">
            <xsl:for-each-group
                select="descendant::gmd:CI_ResponsibleParty[
                (string-length(normalize-space(descendant::node()[local-name()=$childElementName]))) and 
                (string-length(normalize-space(gmd:role/gmd:CI_RoleCode/@codeListValue)))]"
                group-by="descendant::node()[local-name()=$childElementName]">
                 <xsl:choose>
                    <!-- obtain for two locations so far - we don't want for example we don't want
                        responsible parties under citation of thesauruses used -->
                    <xsl:when test="contains(local-name(..), 'pointOfContact') or 
                                    contains(local-name(../../..), 'citation')">
                        <!--xsl:message>Parent: <xsl:value-of select="ancestor::node()"></xsl:value-of></xsl:message-->
                        <xsl:variable name="lowerCode">
                            <xsl:call-template name="toLower">
                                <xsl:with-param name="inputString" select="gmd:role/gmd:CI_RoleCode/@codeListValue"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:if test="contains($lowerCode, $lowerRoleSubstring)">
                            <xsl:sequence select="descendant::node()[local-name()=$childElementName]"/> 
                            <xsl:message>Child value: <xsl:value-of select="descendant::node()[local-name()=$childElementName]"></xsl:value-of></xsl:message>
                        </xsl:if>
                    </xsl:when>
                </xsl:choose>
             </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="formattedValues">
            <xsl:for-each select="$nameSequence">
                <xsl:if test="position() > 1">
                    <xsl:choose>
                        <xsl:when test="position() = count($nameSequence)">
                            <xsl:text> and </xsl:text>
                        </xsl:when>
                        <xsl:when test="position() &lt; count($nameSequence)">
                            <xsl:text>, </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:if>
                <xsl:value-of select="."/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:if test="string-length($formattedValues)">
            <xsl:message>Formatted values: <xsl:value-of select="$formattedValues"></xsl:value-of></xsl:message>
        </xsl:if>
        <xsl:value-of select="$formattedValues"/>
    </xsl:template>
    
    <xsl:template name="doiFromIdentifiers">
        <xsl:param name="identifier_sequence"/>
        <xsl:for-each select="distinct-values($identifier_sequence)">
            <xsl:if test="contains(lower-case(normalize-space(.)), 'doi')">
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    
    <xsl:template name="splitText">
        <xsl:param name="string"/>
        <xsl:param name="separator" select="', '"/>
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
                <xsl:call-template name="splitText">
                    <xsl:with-param name="string" select="substring-after($string,$separator)"/>
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