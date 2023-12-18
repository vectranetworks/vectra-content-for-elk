#!/bin/bash

# Check if environment variable exists
if [ -z "$IP_KIBANA" ]; then
    echo "Variable IP_KIBANA not exist or is empty. Please set the environment variable"
    exit
else
    echo "Kibana IP address: $IP_KIBANA"
fi

usage() { 
    echo "Usage: $0 [-c] [-v <7|8>] [-a] [-s]" 
    echo -e "\tc: check connectivity"
    echo -e "\tv: Kibana version 7 or 8" 
    echo -e "\ta: Kibana requires credentials to authenticate (USERMAME and PASSWORD environment varibale needs to be set)" 
    echo -e "\ts: Kibana uses SSL"
    exit 1; 
}

#kibana port
KIBANA_PORT=5601
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
            echo "Kibana version ${OPTARG}"
            version=${OPTARG}
            ;;
        a) 
            echo "Authentication enabled"
            if ! [ -z "USERNAME" ]; then

                echo "Kibana username: $USERNAME"
            else

                echo "USERNAME environment varibale is not set"
                exit

            fi

            if ! [ -z "PASSWORD" ]; then
                echo "Kibana password: $PASSWORD"
                
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

#check connectivity with Kibana
if [ "$check_mode" = "TRUE" ]; then
    echo -e "Checking connectivity with Kibana"
    cmd=$(curl $CURL_OPTIONS $CURL_CREDS "$CURL_SCHEME://$IP_KIBANA:$KIBANA_PORT/api/status")
    echo $cmd | jq
    exit
fi

generate_post_data_v7()
{
  cat <<EOF
    {
    "index_pattern": {
        "timeFieldName": "ts",
        "title": "$TEMPLATE_NAME*"
    }
    }
EOF
}


generate_post_data_v8()
{
  cat <<EOF
  {
	"data_view": {
        "timeFieldName": "ts",
        "title": "$TEMPLATE_NAME-*",
        "name": "$TEMPLATE_NAME"
    }
  }
EOF
}

#use default space

if [ "$version" == "7" ]; then

    for TEMPLATE_PATH in $(ls elastic-index-templates/tpl_7x/*.jsonc); do
        TEMPLATE_NAME=$(basename "$TEMPLATE_PATH" .jsonc)
        echo -e "$TEMPLATE_NAME:"
        test=$(generate_post_data_v7)
        echo $test
        cmd=$(curl -X POST $CURL_OPTIONS $CURL_CREDS "$CURL_SCHEME://$IP_KIBANA:$KIBANA_PORT/api/index_patterns/index_pattern" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' --data "$(generate_post_data_v7)")
        echo $cmd | jq
    done

elif [ "$version" == "8" ]; then

    for TEMPLATE_PATH in $(ls elastic-index-templates/tpl_8x/*.jsonc); do
        TEMPLATE_NAME=$(basename "$TEMPLATE_PATH" .jsonc)
        echo -e "$TEMPLATE_NAME:"
        cmd=$(curl -X POST $CURL_OPTIONS $CURL_CREDS "$CURL_SCHEME://$IP_KIBANA:$KIBANA_PORT/api/data_views/data_view" -H 'kbn-xsrf: true' -H "Content-Type: application/json" --data "$(generate_post_data_v8)")
        echo $cmd | jq
    done

else

    echo "Unknown version"

fi