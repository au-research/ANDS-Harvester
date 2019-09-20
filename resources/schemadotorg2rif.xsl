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
            <xsl:apply-templates
                select="//dataset[type = 'DataSet'] | //dataset[type = 'Dataset'] | //dataset[type = 'dataset']"
            />
        </registryObjects>
    </xsl:template>

    <xsl:template match="dataset">
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
                <xsl:apply-templates select="identifier"/>
                <xsl:apply-templates select="title" mode="primary"/>
                <xsl:apply-templates select="datePublished | dateCreated | spatialCoverage"/>
                <xsl:apply-templates select="description | citation | license | publishingPrinciples"/>
                <xsl:element name="location">
                    <xsl:element name="address">
                        <xsl:apply-templates select="url"/>
                        <xsl:apply-templates select="distribution"/>
                    </xsl:element>
                </xsl:element>
                <xsl:apply-templates select="isPartOf"/>
            </xsl:element>
        </xsl:element>
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

    <xsl:template match="publisher" mode="originatingSource">
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

    <xsl:template match="type">
        <xsl:attribute name="type">
            <xsl:apply-templates select="text()"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="keywords">
        <xsl:element name="subject" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">local</xsl:attribute>
            <xsl:value-of select="normalize-space(.)"/>
        </xsl:element>
    </xsl:template>


    <xsl:template match="description">
        <xsl:element name="description" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
            <xsl:attribute name="type">brief</xsl:attribute>
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

    <xsl:template match="url">
        <xsl:if test="text() != ''">
            <xsl:element name="electronic" xmlns="http://ands.org.au/standards/rif-cs/registryObjects">
                <xsl:attribute name="type">
                    <xsl:text>url</xsl:text>
                </xsl:attribute>
                <xsl:element name="value">
                    <xsl:apply-templates select="text()"/>
                </xsl:element> 
            </xsl:element>
        </xsl:if>
    </xsl:template>


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
                <xsl:apply-templates select="mediaType | encodingFormat"/>
                <xsl:apply-templates select="type" mode="distribution"/>   
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

    <xsl:template match="name | title" mode="primary">
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
    
    <!-- 
            <spatialCoverage>
            <type>Place</type>
            <geo>
                <type>GeoCoordinates</type>
                <longitude>144.414</longitude>
                <latitude>-9.131</latitude>
            </geo>
        </spatialCoverage>
    
    
    <spatialCoverage>
            <type>Place</type>
            <geo>
                <type>GeoShape</type>
                <box>-94.225000, 23.460000 -93.237000, 24.112000</box>
            </geo>
        </spatialCoverage>
        
          <coverage>
        <spatial type="kmlPolyCoords" xml:lang="en">-130.42419433596,35.82263863353 -172.61169433596,35.82263863353 -175.42419433596,-42.224110606678 -76.283569335959,-25.398209194418 76.283,-25.398 176.84143066404,-37.36542752964 178.24768066404,-16.882965286964 170.51330566404,17.062473840212 28.482055664041,54.422392482688 -52.377319335959,50.573062509559 -115.65856933596,38.621520109062 -130.42419433596,35.82263863353</spatial>
      </coverage>
    
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
