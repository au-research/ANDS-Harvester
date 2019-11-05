# ARDC Harvester

The harvester daemon is a monitoring and processing class for the Harvester, it checks for scheduled harvests, monitors running harvests, stops harvests that are marked 'STOPPED'  by the registry.

The Harvester is a class that defines all basic transactions and methods that are preformed by a generic harvest

harvest handlers are specific classes that extends the  Harvester class and overrides the protocol and content handler 

The harvester daemon instantiates a specific harvest handler that was selected by the datasource admin

The following harvest methods are currently supported:

* GET (aka http get) - allows the harvest of individual files from any web resource, in any format (e.g. json or xml)
    * The GET harvester can be given any url with complete parameter list
* CKAN - json metadata over HTTP
    * The CKAN harvester attempts to get a list of Identifiers and retrieve the json data for each record.
    * Conversts the entire set as one XML document (json serialised as XML)
* CKAN QUERY - json metadata over HTTP
    * The CKAN QUERY sends a query string to the CKAN server and retrieves all content using the start and rows params 
Converts the json response to serialised XML
* OAI-PMH - xml
    * Retrieves all records in the metadataFormat requested by the datasource owner using the ListRecords endpoint
* CSW (Catalogue Services for the Web) - xml
    * Retrieves datasets using the CSW protocol (using the outputSchema, in batches of 100)
* PURE (a simple dataset harvester using the PURE API)
    * Requesting pages of 100 datasets until completed.
* JSONLD ( a sitemap crawler and jsonld content extractor )
    * The sitemap crawler requires a sitemap file, \
    it could be text or xml (either \<sitemapindex> or \<urlset>)
    * Using asynchronous request (max 5)
    * Attempts to extract json-ld from all pages
    * Combines the result into batches of 400

Whilst the Harvester can retrieve metadata in any format, it must be transformed into RIF-CS XML to be compatible with the ARDC Registry's ingest process

If a Crosswalk is added in the harvest setting by the Registry, the Harvester will save the response(s) as .tmp file(s) and after all data is retrieved it will attempt to run a crosswalk on each .tmp file to generate the rifcs (.xml)

The Harvester can perform simultaneous harvests; the maximum number of concurrent harvests can be set within its configuration. the default is 3

## Installation
Requirements:
* python 3.5 - 3.7
* pip3 for respective versions
* virtualenv (optional)
```
pip3 install -r requirements.txt
```

## Running the Harvester as a Linux service

The file `ands-harvester` is a System V init script to be copied into
`/etc/init.d`. Once copied into place, run:

```
chmod 755 /etc/init.d/ands-harvester
chkconfig --add ands-harvester
chkconfig ands-harvester on
service ands-harvester start
```

The Harvester will start up, and it will be started at each boot time.
The script supports `start`, `stop`, and `status` commands.

