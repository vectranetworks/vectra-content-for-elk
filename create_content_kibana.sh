#!/bin/bash

# Check if environment variable exists
if [ -z "$IP_ELASTIC" ]; then
    echo "Variable IP_ELASTIC not exist or is empty. Please set the environment variable"
    exit
else
    echo "Elasticsearch IP address: $IP_ELASTIC"
fi

usage() { 
    echo "Usage: $0 [-c] [-v <7|8>] [-a] [-s]" 
    echo -e "\tc: check connectivity"
    echo -e "\tv: Elasticsearch version 7 or 8" 
    echo -e "\ta: Elasticsearch requires credentials to authenticate (USERMAME and PASSWORD environment varibale needs to be set)" 
    echo -e "\ts: Elastiseach uses SSL"
    exit 1; 
}

#curl scheme. Default is http/
CURL_SCHEME="http"
#curl credentials (-u option)
CURL_CREDS=""
#curl options 
#-s for silent. Remove it for full output.
#-k: ignore SSL certification validation
CURL_OPTIONS="-k -s"

while getopts "chv:as" arg; do
    case "${arg}" in
        c) 
            echo "Check mode enabled"
            check_mode="TRUE"
            ;;
        v) 
            echo "Elastichsearch version ${OPTARG}"
            version=${OPTARG}
            ;;
        a) 
            echo "Authentication enabled"
            if ! [ -z "USERNAME" ]; then

                echo "Elasticsearch username: $USERNAME"
            else

                echo "USERNAME environment varibale is not set"
                exit

            fi

            if ! [ -z "PASSWORD" ]; then
                echo "Elasticsearch password: $PASSWORD"
                
            else

                echo "PASSWORD environment varibale is not set"
                exit

            fi

            auth="TRUE"
            CURL_CREDS="-u $USERNAME:$PASSWORD"
            ;;
        s) 
            echo "SSL is enabled"
            ssl="TRUE"
            CURL_SCHEME="https"
            ;;
        h) usage;;
    esac
done

curl_args=""

#check connectivity with Elastic
if [ "$check_mode" = "TRUE" ]; then
    echo -e "Checking connectivity with ElasticSearch"
    cmd=$(curl $CURL_OPTIONS $CURL_CREDS "$CURL_SCHEME://$IP_ELASTIC:9200/?pretty")
    echo $cmd | jq
    exit
fi

if [ "$version" == "7" ]; then

    for TEMPLATE_PATH in $(ls elastic-index-templates/tpl_7x); do
        TEMPLATE_NAME=$(basename "$TEMPLATE_PATH" .jsonc)
        echo -e "$TEMPLATE_NAME: "
        curl $CURL_OPTIONS $CURL_CREDS -XPUT "$CURL_SCHEME://localhost:9200/_template/$TEMPLATE_NAME?include_type_name=true" -H "Content-Type: application/json" --data-binary @tpl_7x/$TEMPLATE_PATH
        echo -e ""
    done

elif [ "$version" == "8" ]; then

    echo -e "Create Index Lifecyle Policies"

    for ILM_PATH in $(ls elastic-index-templates/tpl_8x/ilm/*.jsonc); do
        ILM_NAME=$(basename "$ILM_PATH" .jsonc)
        echo -e "$ILM_NAME ($ILM_PATH): "
        cmd=$(curl $CURL_OPTIONS $CURL_CREDS -XPUT "$CURL_SCHEME://$IP_ELASTIC:9200/_ilm/policy/$ILM_NAME" -H "Content-Type: application/json" --data-binary @$ILM_PATH)
        echo -e $cmd | jq
    done

    echo -e "Creating Template components"

    for COMPONENT_PATH in $(ls elastic-index-templates/tpl_8x/component_templates/*.jsonc); do
        COMPONENT_NAME=$(basename "$COMPONENT_PATH" .jsonc)
        echo -e "$COMPONENT_NAME ($COMPONENT_PATH): "
        cmd=$(curl $CURL_OPTIONS $CURL_CREDS -XPUT "$CURL_SCHEME://$IP_ELASTIC:9200/_component_template/$COMPONENT_NAME" -H "Content-Type: application/json" --data-binary @$COMPONENT_PATH)
        echo -e $cmd | jq
    done

    echo -e "Creating Index templates"

    for TEMPLATE_PATH in $(ls elastic-index-templates/tpl_8x/*.jsonc); do
        TEMPLATE_NAME=$(basename "$TEMPLATE_PATH" .jsonc)
        echo -e "$TEMPLATE_NAME ($TEMPLATE_PATH):"
        cmd=$(curl $CURL_OPTIONS $CURL_CREDS -XPUT "$CURL_SCHEME://$IP_ELASTIC:9200/_index_template/$TEMPLATE_NAME" -H "Content-Type: application/json" --data-binary @$TEMPLATE_PATH)
        echo -e $cmd | jq
    done
else

    echo "Unknown version"

fi