<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:srv="http://www.isotc211.org/2005/srv"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:custom="http://custom.nowhere.yet"
    exclude-result-prefixes="custom">
    
    <xsl:param name="global_debug" select="false()"/>
    
    <xsl:function name="custom:sequenceContains" as="xs:boolean">
        <xsl:param name="sequence" as="xs:string*"/>
        <xsl:param name="str" as="xs:string"/>
        
        <xsl:variable name="true_sequence" as="xs:boolean*">
            <xsl:for-each select="distinct-values($sequence)">
                <xsl:if test="contains(lower-case(.), lower-case($str))">
                    <xsl:copy-of select="true()"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="count($true_sequence) > 0">
                <xsl:copy-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="custom:strContainsSequenceSubset" as="xs:boolean">
        <xsl:param name="str" as="xs:string"/>
        <xsl:param name="sequence" as="xs:string*"/>
        
        <xsl:variable name="true_sequence" as="xs:boolean*">
            <xsl:for-each select="distinct-values($sequence)">
                <xsl:if test="contains(lower-case($str), lower-case(.))">
                    <xsl:copy-of select="true()"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="count($true_sequence) > 0">
                <xsl:copy-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="custom:sequenceContainsExact" as="xs:boolean">
        <xsl:param name="sequence" as="xs:string*"/>
        <xsl:param name="str" as="xs:string"/>
        
        <xsl:variable name="true_sequence" as="xs:boolean*">
            <xsl:for-each select="distinct-values($sequence)">
                <xsl:if test="(lower-case(.) = lower-case($str))">
                    <xsl:copy-of select="true()"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="count($true_sequence) > 0">
                <xsl:copy-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="custom:convertLongitude">
        <xsl:param name="input" as="xs:decimal"/>
        <!--Convert Longitude 0-360 to -180 to 180 or 180W-180E -->
        <xsl:value-of select="(($input+180) mod 360)-180"/>
    </xsl:function>
    
    <xsl:function name="custom:getIdentifierType" as="xs:string">
        <xsl:param name="identifier" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="contains(lower-case($identifier), 'orcid')">
                <xsl:text>orcid</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($identifier), 'raid')">
                <xsl:text>raid</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($identifier), 'purl.org')">
                <xsl:text>purl</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($identifier), 'doi')">
                <xsl:text>doi</xsl:text>
            </xsl:when>
            <xsl:when test="starts-with($identifier, '10.')"> <!-- in case it doesn't contain doi.org -->
                <xsl:text>doi</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($identifier), 'scopus')">
                <xsl:text>scopus</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($identifier), 'handle.net')">
                <xsl:text>handle</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($identifier), 'nla.gov.au')">
                <xsl:text>AU-ANL:PEAU</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($identifier), 'fundref')">
                <xsl:text>fundref</xsl:text>
            </xsl:when>
            <xsl:when test="starts-with(lower-case($identifier), 'arc')">
                <xsl:text>arc</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($identifier), 'http')">
                <xsl:text>uri</xsl:text>
            </xsl:when>
            <xsl:when test="contains(lower-case($identifier), 'uuid')">
                <xsl:text>global</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>local</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="custom:getDOIFromString" as="xs:string">
        <xsl:param name="fullString" as="xs:string"/>
        <xsl:variable name="result">
            <xsl:choose>
                <xsl:when test="contains(lower-case($fullString), 'doi:')">
                    <xsl:analyze-string select="$fullString" regex="((DOI:)|(doi:))+(\d.[^\s&lt;]*)">
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(0)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:analyze-string select="$fullString" regex="(http(s?):)(//[^#\s&lt;]*)">
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(0)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string-length(normalize-space($result)) > 0">
                <xsl:value-of select="normalize-space($result)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text></xsl:text> <!-- return emtpy string because function won't allow empty sequence returned -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
   
    
    <xsl:function name="custom:getDomainFromURL" as="xs:string">
        <xsl:param name="url"/>
        <!--xsl:value-of select="substring-before(':', (substring-before('/', (substring-after('://', $url)))))"/-->
        <xsl:choose>
            <xsl:when test="contains($url, '://')">
                <xsl:variable name="prefix" select="substring-before($url, '://')"/>
                <xsl:variable name="remaining" select="substring-after($url, '://')"/>
                <xsl:variable name="domainAndPerhapsPort">
                    <xsl:choose>
                        <xsl:when test="contains($remaining, '/')">
                            <xsl:value-of select="substring-before($remaining, '/')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$remaining"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="contains($domainAndPerhapsPort, ':')">
                        <xsl:value-of select="concat($prefix, '://', substring-before($domainAndPerhapsPort, ':'))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($prefix, '://', $domainAndPerhapsPort)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('http://', $url)"/>
            </xsl:otherwise>
        </xsl:choose>
        <!--xsl:value-of select="substring-before(substring-before((substring-after($url, '://')), '/'), ':')"/-->
    </xsl:function>
    
    <xsl:function name="custom:convertCoordinatesLatLongToLongLat" as="xs:string">
        <xsl:param name="coordinates" as="xs:string"/>
        <xsl:param name="flipParam" as="xs:boolean"/>
        
        <xsl:variable name="flip" as="xs:boolean">
            <xsl:choose>
                <xsl:when test="$flipParam = true()">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- to handle:
            "long,lat,elevation long,lat,elevation ..." 
            "lat,long,elevation lat,long,elevation ..." (cannot work out to flip yet, so needs to be told with param 'flip')
            "long,lat long,lat" 
            "lat,long lat,long" (cannot work out to flip yet, so needs to be told with param 'flip'
            
            First, separate into sequence each item between a space (and the last item)
        -->
        <xsl:variable name="coordinatePairOrTrioSequence" as="xs:string*" select="tokenize($coordinates, ' ')"/>
        
        <xsl:variable name="coordinateSequence" as="xs:string*">
            <xsl:for-each select="$coordinatePairOrTrioSequence">
                <!-- per each item in this sequence here we have either just one of the following patterns
                    [long,lat,elevation]
                    [lat,long,elevation]
                    [long,lat]
                    [lat,long]
                    We are just going to use the first to (and flip lat long to long lat - if the param told us too)
                    -->
                <xsl:for-each select="tokenize(., ',')">
                    <xsl:if test="position() &lt; 3">
                        <xsl:value-of select="."/>    
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        
        
        <xsl:variable name="latCoords" as="xs:string*">
            <xsl:for-each select="$coordinateSequence">
                <xsl:if test="(position() mod 2) > 0">
                    <xsl:value-of select="."/>    
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="longCoords" as="xs:string*">
            <xsl:for-each select="$coordinateSequence">
                <xsl:if test="(position() mod 2) = 0">
                    <xsl:value-of select="."/>    
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:if test="$global_debug">
            <xsl:message select="concat('longCoords ', string-join(for $i in $longCoords return $i, ' '))"/>
            <xsl:message select="concat('latCoords ', string-join(for $i in $latCoords return $i, ' '))"/>
        </xsl:if>
        
        
        <xsl:variable name="coordinatePair_sequence" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$flip = true()">
                    <xsl:for-each select="$longCoords">
                        <xsl:if test="count($latCoords) > position()">
                            <xsl:variable name="index" select="position()" as="xs:integer"/>
                            <xsl:value-of select="concat(., ',', normalize-space($latCoords[$index]))"/>
                        </xsl:if>
                    </xsl:for-each> 
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$latCoords">
                        <xsl:if test="count($longCoords) > position()">
                            <xsl:variable name="index" select="position()" as="xs:integer"/>
                            <xsl:value-of select="concat(., ',', normalize-space($longCoords[$index]))"/>
                        </xsl:if>
                    </xsl:for-each> 
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>    
            <xsl:when test="count($coordinatePair_sequence) > 0"> 
                <xsl:if test="$global_debug"><xsl:message select="concat('finalstring ', string-join(for $i in $coordinatePair_sequence return $i, ' '))"/></xsl:if>
                <xsl:value-of select="string-join(for $i in $coordinatePair_sequence return $i, ' ')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="''"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="custom:formatName">
        <xsl:param name="name"/>
        <xsl:choose>
            <xsl:when test="contains($name, ', ')">
                <xsl:value-of select="concat(normalize-space(substring-after(substring-before($name, '.'), ',')), ' ', normalize-space(substring-before($name, ',')))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$name"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="custom:registryObjectKeyFromString" as="xs:string">
        <xsl:param name="input" as="xs:string"/>
        <xsl:variable name="buffer" select="string-join(for $n in fn:string-to-codepoints($input) return string($n), '')"/>
        <xsl:choose>
            <xsl:when test="string-length($buffer) &gt; 50">
                <xsl:value-of select="substring($buffer, string-length($buffer)-50, 50)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$buffer"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="custom:getDOI_FromString" as="xs:string*">
        <xsl:param name="fullString"/>
        <!-- set fullURL true if you want https://dx.doi.org/10.4225/72/5705AB92DB429 or as false
            if 10.4225/72/5705AB92DB429 is required -->
        <xsl:param name="fullURL" as="xs:boolean"/> 
        <xsl:if test="$global_debug"><xsl:message select="concat('Attempting to extract doi from : ', $fullString)"/></xsl:if>
        
        <xsl:choose>
            <xsl:when test="contains(lower-case($fullString), 'doi:')">
                <xsl:analyze-string select="$fullString" regex="((DOI:)|(doi:))(\s?)+(\d.[^\s&lt;]*)">
                    <xsl:matching-substring>
                        <xsl:variable name="extractedDOI" select="normalize-space(substring-after(regex-group(0), ':'))"/>
                        <xsl:choose>
                            <xsl:when test="$fullURL">
                                <xsl:if test="$global_debug"><xsl:message select="concat('Returning doi: [', 'https://doi.org/', $extractedDOI, ']')"/></xsl:if>
                                <xsl:value-of select="concat('http://doi.org/', $extractedDOI)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:if test="$global_debug"><xsl:message select="concat('Returning doi: [', $extractedDOI, ']')"/></xsl:if>
                                <xsl:value-of select="$extractedDOI"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:when test="contains(lower-case($fullString), 'doi.org/')">
                <xsl:analyze-string select="$fullString" regex="(http(s?):)(//)([^\s]*)(doi.org/)([^\s&lt;]*)">
                    <xsl:matching-substring>
                        <xsl:variable name="extractedDOI" select="normalize-space(regex-group(0))"/>
                        <xsl:choose>
                            <xsl:when test="$fullURL">
                                <xsl:if test="$global_debug"><xsl:message select="concat('Returning doi: [', $extractedDOI, ']')"/></xsl:if>
                                <xsl:value-of select="$extractedDOI"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:if test="$global_debug"><xsl:message select="concat('Returning doi: [', substring-after($extractedDOI, 'doi.org/'), ']')"/></xsl:if>
                                <xsl:value-of select="substring-after($extractedDOI, 'doi.org/')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="custom:getHandle_FromString" as="xs:string*">
        <xsl:param name="fullString"/>
        <xsl:if test="$global_debug"><xsl:message select="concat('Attempting to extract handle from : ', $fullString)"/></xsl:if>
        
        <xsl:if test="contains(lower-case($fullString), 'handle')">
            <xsl:analyze-string select="$fullString" regex="(http(s?):)(//)([^\s]*)(handle)([^\s&lt;]*)">
                <xsl:matching-substring>
                    <xsl:choose>
                        <xsl:when test="ends-with(regex-group(0), '.')">
                            <xsl:if test="$global_debug"><xsl:message select="concat('Extracted handle: [', substring(regex-group(0), 0, string-length(regex-group(0))), ']')"/></xsl:if>
                            <xsl:value-of select="regex-group(0)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if test="$global_debug"><xsl:message select="concat('Extracted handle: [', regex-group(0), ']')"/></xsl:if>
                            <xsl:value-of select="regex-group(0)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="custom:characterReplace">
        <xsl:param name="input"/>
        <!--xsl:variable name="name" select='replace(.,"&#x00E2;&#x80;&#x99;", "&#8217;")'/-->
        <xsl:variable name="replaceSingleQuote" select='replace($input,"&#x00E2;&#x80;&#x99;", "&#x2019;")'/>
        <xsl:variable name="replaceLeftDoubleQuote" select='replace($replaceSingleQuote, "&#x00E2;&#x80;&#x9c;", "&#x201C;")'/>
        <xsl:variable name="replaceRightDoubleQuote" select='replace($replaceLeftDoubleQuote, "&#x00E2;&#x80;&#x9d;", "&#x201D;")'/>
        <xsl:variable name="replaceNarrowNoBreakSpace" select='replace($replaceRightDoubleQuote, "&#xE2;&#x80;&#xAF;", "&#x202F;")'/>
        <xsl:value-of select="$replaceNarrowNoBreakSpace"/>
    </xsl:function>
    
</xsl:stylesheet>
