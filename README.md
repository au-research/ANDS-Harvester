ANDS-Harvester
==============

The Harvester is an extensible Python module that enables harvesting capabilities within the ANDS Registry.

The plugin-architecture enables the development of further modules that support additional harvest methods and metadata schemas and/or profiles.  Further modules can be ‘plugged-in’ to this architecture, enabling the creation of ANDS Registry records from any web resource.

The following harvest methods are currently supported:

    HTTP-FETCH - allows the harvest of individual files from any web resource, in any format (e.g. json or xml)

    CKAN - json metadata over HTTP

    OAI-PMH - xml

    CSW (Catalogue Services for the Web) - xml


Whilst the Harvester can retrieve metadata in any format, it must be transformed into RIF-CS XML to be compatible with the ANDS Registry ingest process; where a transform is required, an XSL transformation can be incorporated within the ‘plug-in’ module.

The Harvester can perform simultaneous harvests; the maximum number of concurrent harvests can be set within its configuration.
