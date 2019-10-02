<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0">
    <xsl:output indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:param name="originatingSource">'NO ORIGINATING SOURCE FOUND'</xsl:param>

    <xsl:template match="/">
        <registryObjects xmlns="http://ands.org.au/standards/rif-cs/registryObjects"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://ands.org.au/standards/rif-cs/registryObjects http://services.ands.org.au/documentation/rifcs/schema/registryObjects.xsd">
            <xsl:apply-templates select="//dataset"/>
            <xsl:apply-templates select="//includedInDataCatalog" mode="catalog"/>
            <xsl:apply-templates select="//publisher | //funder | //contributor" mode="party"/>
        </registryObjects>
    </xsl:template>

    <!--publisher>
        <logo>https://daac.ornl.gov/daac_logo.png</logo>
        <contactPoint>
            <email>uso@daac.ornl.gov</email>
            <telephone>+18652413952</telephone>
            <contactType>customer support</contactType>
            <name>ORNL DAAC User Support Office</name>
            <type>ContactPoint</type>
        </contactPoint>
        <name>ORNL DAAC</name>
        <url>https://daac.ornl.gov</url>
        <type>Organization</type>
    </publisher-->

    <xsl:template match="publisher| funder | contributor" mode="party">
        <xsl:if test="type = 'Organization' and name(parent::node()) = 'dataset'">
            <xsl:element name="registryObject"
                xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:attribute name="group">
                    <xsl:apply-templates select="." mode="originatingSource"/>
                </xsl:attribute>
                <xsl:call-template name="getKey"/>
                <xsl:element name="originatingSource">
                    <xsl:apply-templates select="." mode="originatingSource"/>
                </xsl:element>
                <xsl:element name="party">
                    <xsl:attribute name="type">
                        <xsl:text>group</xsl:text>
                    </xsl:attribute>
                    <xsl:apply-templates select="name | legalName | title" mode="primary"/>
                    <xsl:element name="location">
                        <xsl:element name="address">
                            <xsl:apply-templates select="url"/>
                        </xsl:element>
                    </xsl:element>
                    <xsl:apply-templates select="contactPoint"/>
                    <xsl:apply-templates select="url" mode="identifier"/>
                    <xsl:apply-templates select="description | logo"/>
                    
                </xsl:element>
            </xsl:element>
        </xsl:if>
    </xsl:template>


    <xsl:template match="includedInDataCatalog" mode="catalog">
        <xsl:element name="registryObject"
            xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="group">
                <xsl:call-template name="getGroup"/>
            </xsl:attribute>
            <xsl:call-template name="getKey"/>
            <xsl:call-template name="getOriginatingSource"/>
            <xsl:element name="collection">
                <xsl:attribute name="type">
                    <xsl:text>catalog</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="name" mode="primary"/>
                <xsl:call-template name="getKeyAsIdentifier"/>
                <xsl:apply-templates select="identifier"/>
                <xsl:apply-templates select="name" mode="description"/>
                <xsl:element name="location">
                    <xsl:element name="address">
                        <xsl:apply-templates select="url"/>
                        <xsl:apply-templates select="distribution"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="dataset">
        <xsl:if test="type = 'DataSet'or type = 'Dataset' or type = 'dataset'">
        <xsl:element name="registryObject"
                xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:attribute name="group">
                    <xsl:call-template name="getGroup"/>
                </xsl:attribute>
                <xsl:call-template name="getKey"/>
                <xsl:call-template name="getOriginatingSource"/>
                <xsl:element name="collection">
                    <xsl:attribute name="type">
                        <xsl:text>dataset</xsl:text>
                    </xsl:attribute>
                    <xsl:apply-templates select="name" mode="primary"/>
                    <xsl:call-template name="getKeyAsIdentifier"/>
                    <xsl:apply-templates select="identifier"/>
                    <xsl:apply-templates select="title" mode="primary"/>
                    <xsl:apply-templates select="datePublished | dateCreated | spatialCoverage"/>
                    <xsl:apply-templates select="keywords| description | citation | license | publishingPrinciples"/>
                    <xsl:element name="location">
                        <xsl:element name="address">
                            <xsl:apply-templates select="url"/>
                            <xsl:apply-templates select="distribution"/>
                        </xsl:element>
                    </xsl:element>
                    <xsl:apply-templates select="isPartOf"/>
                    <xsl:apply-templates select="publisher | funder | contributor" mode="relatedInfo"/>
                    <xsl:apply-templates select="includedInDataCatalog" mode="relatedInfo"/>
                    
                </xsl:element>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template name="getOriginatingSource">
        <xsl:element name="originatingSource"
            xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:choose>
                <xsl:when test="sourceOrganization">
                    <xsl:value-of select="sourceOrganization/name/text()"/>
                </xsl:when>
                <xsl:when test="publisher">
                    <xsl:apply-templates select="publisher" mode="originatingSource"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$originatingSource"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="getGroup">
        <xsl:element name="originatingSource"
            xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:choose>
                <xsl:when test="sourceOrganization">
                    <xsl:value-of select="sourceOrganization/name/text()"/>
                </xsl:when>
                <xsl:when test="publisher">
                    <xsl:apply-templates select="publisher" mode="originatingSource"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$originatingSource"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="publisher| funder | contributor" mode="originatingSource">
        <xsl:choose>
            <xsl:when test="name">
                <xsl:value-of select="normalize-space(name)"/>
            </xsl:when>
            <xsl:when test="legalName">
                <xsl:value-of select="normalize-space(legalName)"/>
            </xsl:when>
            <xsl:when test="url">
                <xsl:value-of select="normalize-space(url)"/>
            </xsl:when> 
        </xsl:choose>
    </xsl:template>

    <xsl:template match="datePublished">
        <xsl:element name="dates" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>dc.available</xsl:text>
            </xsl:attribute>
            <xsl:element name="date">
                <xsl:attribute name="type">
                    <xsl:text>dateFrom</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="dateFormat">
                    <xsl:text>W3CDTF</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="text()"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="dateCreated">
        <xsl:element name="dates" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>dc.created</xsl:text>
            </xsl:attribute>
            <xsl:element name="date">
                <xsl:attribute name="type">
                    <xsl:text>dateFrom</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="dateFormat">
                    <xsl:text>W3CDTF</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="text()"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <!-- 
        getKey template from a jsonld (xml)
    if this logic changes the native metadata loader must be updated accordingly
    in the import pipeline
    -->
    <xsl:template name="getKey">
        <xsl:element name="key" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:choose>
                <xsl:when test="identifier/value">
                    <xsl:value-of select="identifier[1]/value/text()"/>
                </xsl:when>
                <xsl:when test="identifier">
                    <xsl:value-of select="identifier[1]/text()"/>
                </xsl:when>
                <xsl:when test="id">
                    <xsl:value-of select="id[1]/text()"/>
                </xsl:when>
                <xsl:when test="url">
                    <xsl:value-of select="url/text()"/>
                </xsl:when>
                <xsl:when test="landingPage">
                    <xsl:value-of select="landingPage/text()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="generate-id(.)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template name="getKeyValue">
        <xsl:choose>
            <xsl:when test="identifier/value">
                <xsl:value-of select="identifier[1]/value/text()"/>
            </xsl:when>
            <xsl:when test="identifier">
                <xsl:value-of select="identifier[1]/text()"/>
            </xsl:when>
            <xsl:when test="id">
                <xsl:value-of select="id[1]/text()"/>
            </xsl:when>
            <xsl:when test="url">
                <xsl:value-of select="url/text()"/>
            </xsl:when>
            <xsl:when test="landingPage">
                <xsl:value-of select="landingPage/text()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="generate-id(.)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template name="getKeyAsIdentifier">
        <xsl:choose>
            <!-- these will be Identifiers - so ignore them here -->
            <xsl:when test="identifier/value"/>
            <xsl:when test="identifier"/>
            <xsl:when test="id"/>
            <!-- if the key is generated from url or landinPage add an Identifier as well -->
            <xsl:when test="url">
                <xsl:element name="identifier" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                    <xsl:attribute name="type">
                        <xsl:text>url</xsl:text>
                    </xsl:attribute>
                    <xsl:apply-templates select="url/text()"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="landingPage">
                <xsl:element name="identifier" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                    <xsl:attribute name="type">
                        <xsl:text>url</xsl:text>
                    </xsl:attribute>
                    <xsl:apply-templates select="landingPage/text()"/>
                </xsl:element>
            </xsl:when>
        </xsl:choose>
    </xsl:template>




    <xsl:template match="type">
        <xsl:attribute name="type">
            <xsl:apply-templates select="text()"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="keywords">
        <xsl:element name="subject" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">local</xsl:attribute>
            <xsl:apply-templates select="text()"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="contentSize">
        <xsl:element name="byteSize" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:apply-templates select="text()"/>
        </xsl:element>
    </xsl:template>
    

    <xsl:template match="distribution/description">
        <xsl:element name="notes" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="description">
        <xsl:element name="description" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">brief</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="name" mode="description">
        <xsl:element name="description" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">brief</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="logo">
        <xsl:element name="description" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">logo</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="citation">
        <xsl:element name="citationInfo" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:element name="fullCitation">
                    <xsl:apply-templates select="text()"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>


    <xsl:template match="license | publishingPrinciples">
        <xsl:element name="rights" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:choose>
                <xsl:when test="starts-with(text(), 'http')">
                    <xsl:element name="rightsStatement">
                        <xsl:attribute name="rightsUri"><xsl:value-of select="normalize-space(text())"/></xsl:attribute>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="rightsStatement">
                        <xsl:value-of select="normalize-space(text())"/>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="landinPage">
        <xsl:element name="electronic" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>url</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="target">
                <xsl:text>landingPage</xsl:text>
            </xsl:attribute>
            <xsl:element name="value">
                <xsl:apply-templates select="text()"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="identifier">
        <xsl:element name="identifier" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:choose>
                <xsl:when test="propertyID">
                    <xsl:attribute name="type">
                        <xsl:value-of select="propertyID/text()"/>
                    </xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="value">
                            <xsl:value-of select="value/text()"/>
                        </xsl:when>
                        <xsl:when test="id">
                            <xsl:value-of select="id/text()"/>
                        </xsl:when>
                        <xsl:when test="url">
                            <xsl:value-of select="url/text()"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="id">
                    <xsl:attribute name="type">
                        <xsl:choose>
                            <xsl:when test="propertyID">
                                <xsl:value-of select="propertyID/text()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>url</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:value-of select="id/text()"/>
                </xsl:when>
                <xsl:when test="url">
                    <xsl:attribute name="type">
                        <xsl:text>url</xsl:text>
                    </xsl:attribute>
                    <xsl:apply-templates select="text()"/>
                </xsl:when>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

<!-- 
    
    <distribution>
            <provider>
                <logo>https://daac.ornl.gov/daac_logo.png</logo>
                <name>ORNL DAAC</name>
                <url>https://daac.ornl.gov</url>
                <type>Organization</type>
            </provider>
            <url>https://daac.ornl.gov/daacdata/airmoss/campaign/AirMOSS_L1_Sigma0_DukeFr/</url>
            <name>Direct Access: AirMOSS: L1 S-0 Polarimetric Data from AirMOSS P-band SAR, Duke
                Forest, 2012-2015</name>
            <publisher>
                <logo>https://daac.ornl.gov/daac_logo.png</logo>
                <name>ORNL DAAC</name>
                <url>https://daac.ornl.gov</url>
                <type>Organization</type>
            </publisher>
            <encodingFormat>binary, ascii, HDF5, KML, png, jpeg</encodingFormat>
            <description>This link allows direct data access via Earthdata Login to: AirMOSS: L1 S-0
                Polarimetric Data from AirMOSS P-band SAR, Duke Forest, 2012-2015</description>
            <type>DataDownload</type>
        </distribution>
    
    -->

    <xsl:template match="url | email">
        <xsl:if test="text() != ''">
            <xsl:element name="electronic" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:attribute name="type">
                    <xsl:value-of select="name()"/>
                </xsl:attribute>
                <xsl:element name="value">
                    <xsl:apply-templates select="text()"/>
                </xsl:element> 
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
    <!--
        <contactPoint>
            <email>uso@daac.ornl.gov</email>
            <telephone>+18652413952</telephone>
            <contactType>customer support</contactType>
            <name>ORNL DAAC User Support Office</name>
            <type>ContactPoint</type>
        </contactPoint>
        
        -->
    
    <xsl:template match="contactPoint">
        <xsl:if test="email/text() != '' or url/text() != ''">
            <xsl:element name="location" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:element name="address">
                    <xsl:apply-templates select="url"/>
                    <xsl:apply-templates select="email"/>
                </xsl:element>
            </xsl:element>
        </xsl:if>
        <xsl:if test="telephone/text() != '' or name/text() != ''">
            <xsl:element name="location" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:element name="address">
                    <xsl:element name="physical" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                        <xsl:apply-templates select="type"/>
                        <xsl:apply-templates select="name" mode="addressPart"/>
                        <xsl:apply-templates select="contactType" mode="addressPart"/>
                        <xsl:apply-templates select="telephone" mode="addressPart"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="name | contactType | telephone" mode="addressPart">
        <xsl:element name="addressPart" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:choose>
                    <xsl:when test="name() = 'telephone'">
                        <xsl:text>telephoneNumber</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>addressLine</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates select="text()"/>
        </xsl:element>
    </xsl:template>
    
    
<!-- 
    <distribution>
            <provider>
                <logo>https://daac.ornl.gov/daac_logo.png</logo>
                <name>ORNL DAAC</name>
                <url>https://daac.ornl.gov</url>
                <type>Organization</type>
            </provider>
            <contentSize>2.3 GB</contentSize>
            <name>Download Dataset: AirMOSS: L2/3 Volumetric Soil Moisture Profiles Derived From
                Radar, 2012-2015</name>
            <description>Download entire dataset bundle: AirMOSS: L2/3 Volumetric Soil Moisture
                Profiles Derived From Radar, 2012-2015</description>
            <url>https://daac.ornl.gov/cgi-bin/download.pl?ds_id=1418&amp;source=schema_org_metadata</url>
            <encodingFormat/>
            <publisher>
                <logo>https://daac.ornl.gov/daac_logo.png</logo>
                <name>ORNL DAAC</name>
                <url>https://daac.ornl.gov</url>
                <type>Organization</type>
            </publisher>
            <type>DataDownload</type>
        </distribution>
    
    
    
    -->

    <xsl:template match="distribution">
        <xsl:if test="node()">
            <xsl:element name="electronic" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:attribute name="type">
                    <xsl:text>url</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="target">
                    <xsl:text>directDownload</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="downloadURL | accessURL | contentUrl"/>
                <xsl:apply-templates select="url" mode="distribution"/>
                <xsl:apply-templates select="name"/>
                <xsl:apply-templates select="description"/>
                <xsl:apply-templates select="mediaType | encodingFormat"/>
                <xsl:apply-templates select="type" mode="distribution"/> 
                <xsl:apply-templates select="contentSize"/>
  
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="accessURL | downloadURL | contentUrl">
        <xsl:element name="value" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:apply-templates select="text()"/>
        </xsl:element>
    </xsl:template>


    <xsl:template match="url" mode="distribution">
        <xsl:element name="value" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:apply-templates select="text()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="encodingFormat | mediaType">
        <xsl:if test="text() != ''">
            <xsl:element name="mediaType" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:apply-templates select="text()"/>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="type" mode="distribution">
        <xsl:if test="text() != ''">
            <xsl:element name="mediaType" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:apply-templates select="text()"/>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="name | title | legalName" mode="primary">
        <xsl:element name="name" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>primary</xsl:text>
            </xsl:attribute>
            <xsl:element name="namePart" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:apply-templates select="text()"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    
    <xsl:template match="isPartOf">
        <xsl:element name="relatedInfo" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:apply-templates select="type"/>
            <xsl:element name="relation">
                <xsl:attribute name="type">
                    <xsl:text>isPartOf</xsl:text>
                </xsl:attribute>
            </xsl:element>
            <xsl:apply-templates select="name"/>
            <xsl:apply-templates select="id"/>
            <xsl:apply-templates select="url" mode="identifier"/>
        </xsl:element>
    </xsl:template>
    
    
    <xsl:template match="publisher | funder | contributor | includedInDataCatalog" mode="relatedInfo">
        <xsl:element name="relatedInfo" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
            <xsl:choose>
                <xsl:when test="name() = 'includedInDataCatalog'">
                    <xsl:text>collection</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>party</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            </xsl:attribute>
            <xsl:element name="relation">
                <xsl:attribute name="type">
                    <xsl:choose>
                        <xsl:when test="name() = 'publisher'">
                            <xsl:text>publishedBy</xsl:text>
                        </xsl:when>
                        <xsl:when test="name() = 'funder'">
                            <xsl:text>fundedBy</xsl:text>
                        </xsl:when>
                        <xsl:when test="name() = 'contributor'">
                            <xsl:text>hasAssociationWith</xsl:text>
                        </xsl:when>
                        <xsl:when test="name() = 'includedInDataCatalog'">
                            <xsl:text>isPartOf</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:element>
            <xsl:apply-templates select="name"/>
            <xsl:apply-templates select="id"/>
            <xsl:apply-templates select="url" mode="identifier"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="name">
        <xsl:element name="title" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:apply-templates select="text()"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="id">
        <xsl:element name="identifier" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>url</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="text()"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="url" mode="identifier">
        <xsl:element name="identifier" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">
                <xsl:text>url</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="text()"/>
        </xsl:element>
    </xsl:template>
    
    <!-- 
        <publisher>
            <logo>https://daac.ornl.gov/daac_logo.png</logo>
            <contactPoint>
                <email>uso@daac.ornl.gov</email>
                <telephone>+18652413952</telephone>
                <contactType>customer support</contactType>
                <name>ORNL DAAC User Support Office</name>
                <type>ContactPoint</type>
            </contactPoint>
            <name>ORNL DAAC</name>
            <url>https://daac.ornl.gov</url>
            <type>Organization</type>
        </publisher>
    
    -->

    <xsl:template match="spatialCoverage">
        <xsl:element name="coverage" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:element name="spatial">
                <xsl:apply-templates select="geo"/>
                <xsl:apply-templates select="name" mode="spatial"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="geo">
        <xsl:choose>
            <xsl:when test="type = 'GeoCoordinates'">
                <xsl:attribute name="type">
                    <xsl:text>kmlPolyCoords</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="concat(longitude/text(), ',' , latitude/text())"/>
            </xsl:when>
            <xsl:when test="type = 'GeoShape'">
                <xsl:apply-templates select="box"/>
            </xsl:when> 
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="name" mode="spatial">
        <xsl:attribute name="type">
            <xsl:text>text</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="text()"/>
    </xsl:template>
    
    <xsl:template match="box">
        <xsl:attribute name="type">
            <xsl:text>iso19139dcmiBox</xsl:text>
        </xsl:attribute>
        <xsl:variable name="coords" select="tokenize(text(),'\s?[, ]\s?')" as="xs:string*"/>
        <xsl:value-of select="concat('westlimit=',$coords[1], '; southlimit=', $coords[2], '; eastlimit=', $coords[3], '; northlimit=', $coords[4],'; projection=WGS84')"/>
    </xsl:template>
      
    <xsl:template match="text()">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>  
      
</xsl:stylesheet>
