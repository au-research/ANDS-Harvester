<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns="http://ands.org.au/standards/rif-cs/registryObjects" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:custom="http://custom.nowhere.yet"
    xpath-default-namespace="http://datacite.org/schema/kernel-4"
    exclude-result-prefixes="xsl fn xs xsi custom">
	
    <xsl:import href="DataCite_Kernel4_To_Rifcs.xsl"/>
    
    <xsl:param name="global_originatingSource" select="'DataCite'"/>
    <xsl:param name="global_group" select="'DataCite'"/>
    <xsl:param name="global_acronym" select="'DataCite'"/>
    <xsl:param name="global_publisherName" select="''"/>
    <xsl:param name="global_rightsStatement" select="''"/>
    <xsl:param name="global_hesanda_identifier_strings" select="'anzctr|actrn'" as="xs:string*"/>
    <xsl:param name="global_project_identifier_strings" select="'raid'" as="xs:string*"/>
    <!--xsl:param name="global_baseURI" select="''"/-->
    <!--xsl:param name="global_path" select="''"/-->
      
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:template match="/">
        <xsl:message select="'HeSANDA_DataCite_To_Rifcs'"/>
        
        <xsl:for-each select="resource">
            <xsl:apply-templates select="." mode="datacite_4_to_rifcs_collection">
                <xsl:with-param name="dateAccessioned"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="relatedIdentifier | relatedItemIdentifier" mode="relation">
        <xsl:variable name="currentNode" select="." as="node()"/>
        <relation>
            <xsl:attribute name="type">
                <xsl:variable name="inferredRelation" as="xs:string*">
                    <xsl:for-each select="tokenize($global_hesanda_identifier_strings, '\|')">
                        <xsl:variable name="testString" select="." as="xs:string"/>
                        <xsl:if test="string-length($testString)">
                            <xsl:if test="count($currentNode/[contains(lower-case(.), $testString)])">
                                <xsl:text>isOutputOf</xsl:text>
                            </xsl:if>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:apply-templates select="." mode="relation_core"/>
                </xsl:variable>
                
                <xsl:choose>
                     <xsl:when test="string-length($inferredRelation[1])">
                         <xsl:value-of select="$inferredRelation[1]"/>
                     </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@relationType"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </relation>
        
    </xsl:template>
    
    <xsl:template match="relatedIdentifier | relatedItemIdentifier" mode="related_item_type">
        <xsl:variable name="currentNode" select="." as="node()"/>
        
        <xsl:variable name="inferredType" as="xs:string*">
            <xsl:for-each select="tokenize($global_hesanda_identifier_strings, '\|')">
                <xsl:variable name="testString" select="." as="xs:string"/>
                <xsl:if test="count($currentNode[contains(lower-case(.), $testString)])">
                    <xsl:text>activity</xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:apply-templates select="." mode="related_item_type_core"/>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="string-length($inferredType[1])">
                <xsl:value-of select="$inferredType[1]"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="resource" mode="resourceSubType">
        
        <xsl:variable name="resourceNode" select="." as="node()"/>
        
        <xsl:variable name="inferredPrefix" as="xs:string*">
            <xsl:for-each select="tokenize($global_hesanda_identifier_strings, '\|')">
                <xsl:variable name="testString" select="." as="xs:string"/>
                <xsl:if test="count($resourceNode/relatedIdentifiers/relatedIdentifier[contains(lower-case(.), $testString)])">
                    <xsl:text>health</xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="subTypeDefault">
            <xsl:choose>
                <xsl:when test="boolean(custom:sequenceContains(resourceType/@resourceTypeGeneral, 'dataset')) = true()">
                    <xsl:value-of select="'dataset'"/>
                </xsl:when>
                <xsl:when test="boolean(custom:sequenceContains(resourceType/@resourceTypeGeneral, 'text')) = true()">
                    <xsl:value-of select="'publication'"/>
                </xsl:when>
                <xsl:when test="boolean(custom:sequenceContains(resourceType/@resourceTypeGeneral, 'software')) = true()">
                    <xsl:value-of select="'software'"/>
                </xsl:when>
                <xsl:when test="boolean(custom:sequenceContains(resourceType/@resourceTypeGeneral, 'service')) = true()">
                    <xsl:value-of select="'report'"/>
                </xsl:when>
                <xsl:when test="boolean(custom:sequenceContains(resourceType/@resourceTypeGeneral, 'website')) = true()">
                    <xsl:value-of select="'report'"/>
                </xsl:when>
                <xsl:when test="boolean(custom:sequenceContains(resourceType/@resourceTypeGeneral, 'model')) = true()">
                    <xsl:value-of select="'generate'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'collection'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="string-length($inferredPrefix[1])">
                <xsl:value-of select="concat($inferredPrefix[1], '.', $subTypeDefault)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$subTypeDefault"/>
            </xsl:otherwise>
        </xsl:choose>
        
        
    </xsl:template>
   
</xsl:stylesheet>