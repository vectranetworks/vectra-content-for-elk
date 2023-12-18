# Vectra content library for ELK

Table of content:
- [Vectra content library for ELK](#vectra-content-library-for-elk)
  - [Supported version](#supported-version)
  - [Overview](#overview)
  - [Logstash](#logstash)
  - [Elasticsearch](#elasticsearch)
  - [Kibana](#kibana)
- [Credit](#credit)
- [Support](#support)

## Supported version

The content for version 7 and 8 of ELK is available in this repository.

## Overview

This repository contains content for ELK and Vectra Stream. This includes:

- [Logstash](https://www.elastic.co/logstash) configuration examples.
- [Elasticsearch](https://www.elastic.co/elasticsearch) Index templates/components.
- [Kibana](https://www.elastic.co/kibana) Index patterns/Data Views, Searches and dashboards.

Using this repo, most of the content available within Vectra Recall can be added to your own ELK instance. Regarding Vectra Detect, everything is available through an [integration that you can install directly from your ELK stack](https://docs.elastic.co/integrations/vectra_detect).

## Logstash

In the Logstash directory, there are 2 configuration examples:

- A minimalist configuration file: *vectra-stream-minimal.conf*

  - TCP Input on port 9009
  - A filter that parses the JSON
  - An Elasticearch output with username/password authentication (no SSL) and dynamic index names based on metadata_type JSON attribute.

- A more advanced version: *vectra-stream-pipeline-full.conf*

  - Include the index lifecycle management configuration (ILM).
  - SSL is enabled
  - CA certificate for Elasticsearch certificate validation

You have to make changes in the configuration file according to your own environment.

> In Vectra Stream configuratio, **the RAW JSON output needs to be used.**

## Elasticsearch

There is a significant difference in creating Index Template between version 7 and 8 of Elasticsearch. Actually, *Component templates* have been added in version 7.8, so you can use the content for version 8 in that case. The script we have created to deploy this content to your stack is using the following logic:

- **Flag *-v 7* as parameter**: Legacy Index templates would be pushed.
- **Flag *-v 8* as parameter**: Component templates with Index templates would be pushed.

> Legacy Index templates are compatible with Elasticsearch 7.8+ and 8.x but it is recommended to transition to composable index templates.

> An Index Lifecycle Policy is added as a component on each Index template. It is recommended to change the default policy to meet your requirements.

Use the bash script `create_content_elastic.sh` to automate the deployment to your Elasticsearch instances. The script uses environment variables as well as parameters.

Set environment variables:

``` 
export IP_ELASTIC="<ELASTCI_IP>"
export USERNAME="<ELASTIC_USERNAME>"
export PASSWORD="<ELASTIC_PASSWORD>"
```

To see the help info:

``` 
./create_content_elastic.sh -h
Usage: ./create_content_elastic.sh [-c] [-v <7|8>] [-a] [-s]
	c: check connectivity
	v: Elasticsearch version 7 or 8
	a: Elasticsearch requires credentials to authenticate (USERMAME and PASSWORD environment varibale needs to be set)
	s: Elastiseach uses SSL
```

By default, the script has some flags enable for curl:

- *-k* to ignore certificate validation. 
- *-s* to run in quiet mode. 

Edit the **CURL_OPTIONS** variable within the script to enable/disable those flags.

Before pushing the content to your Elasticsearch instance, you can validate the connectivity with the *-c* flag. It will make sure that the connectivity (authentication, scheme, etc) is correct. Add the flag *-a* if authentication is required and add the flag *-s* if SSL is enabled:

```bash
./create_content_elastic.sh -c -a
Check mode enabled
Authentication enabled
Elasticsearch username: <REDACTED>
Elasticsearch password: <REDACTED>
Elasticsearch IP address: <REDACTED>
Checking connectivity with Kibana
{
  "name": "elk",
  "cluster_name": "elasticsearch",
  "cluster_uuid": "IUwx9BaETdWeqsbpcY-8Yg",
  "version": {
    "number": "8.11.1",
    "build_flavor": "default",
    "build_type": "deb",
    "build_hash": "6f9ff581fbcde658e6f69d6ce03050f060d1fd0c",
    "build_date": "2023-11-11T10:05:59.421038163Z",
    "build_snapshot": false,
    "lucene_version": "9.8.0",
    "minimum_wire_compatibility_version": "7.17.0",
    "minimum_index_compatibility_version": "7.0.0"
  },
  "tagline": "You Know, for Search"
}
```

To push the content (composable index templates):

```bash
./create_content_elastic.sh -a -v 8
Authentication enabled
Elasticsearch username: <REDACTED>
Elasticsearch password: <REDACTED>
Elastichsearch version 8
Elasticsearch IP address: <REDACTED>
Create Index Lifecyle Policies
vectra-metadata-policy (elastic-index-templates/tpl_8x/ilm/vectra-metadata-policy.jsonc): 
{
  "acknowledged": true
}
Creating Template components
metadata_default_lifecyle_policy (elastic-index-templates/tpl_8x/component_templates/metadata_default_lifecyle_policy.jsonc): 
{
  "acknowledged": true
}
[...]
```

To validate, login to the UI and navigate to *Management > Stack Management > Data > Index Management*.

> In case, you use non-default space, edit the script to modify the API endpoint to include the target space. 

## Kibana

The content available for Kibana is:

- Index patterns (v7.x) or Data View (v8.x): Set the timestamp & representation of each index.
- Saved searches: hundreds of searches crafted by Vectra for its network metadata.
- Visualizations & Dashboards: Dozens of dashboards covering multiple use cases and helping you navigate the metadata.

Similar to Elasticsearch, we provide a script that you can use to deploy Index Patterns or Data Views to Kibana. However, we recommend to import the content from **Kibana Saved Objects** directly in the UI.

Under [kibana-searches-dashboards](/kibana-searches-dashboards/), there is one folder for Kibana version [7](/kibana-searches-dashboards/7.x/) and one for version [8](/kibana-searches-dashboards/8.x/).

In Kibana, navigate to **Management > Stack Management > Kibana > Saved Objects**. Then use the import tool.

_Version 7.x_:

- *kibana_index_patterns_only.ndjson*: Contains only Index Patterns.
- *kibana_AIO_index_patterns_searches_dashboards.ndjson*: Contains everything. Index patterns, Searches, visualization and Dashboards.

_Version 8.x_:

- *Kibana_data_view_and_default_table_view_searches.ndjson*: Contains Data Views and a set of saved Searches that provides a default "table" views personnalized per metadata type.
- *Kibana_AIO_data_view_dashboards_searches.ndjson*: Contains Data Views, Searches, visualization and Dashboards.

> The "Table Views" are not included in the second file. Import both files to get everything.

# Credit

Special thanks to Aurelien Hess who contributed to this repo.

# Support

If you believe you found a bug or have an idea you'd like to suggest you may [report an issue](https://github.com/vectranetworks/vectra-content-for-elk/issues) or [start a discussion](https://github.com/vectranetworks/vectra-content-for-elk/discussions).


