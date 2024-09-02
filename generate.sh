#!/bin/sh

COUNTRIES="countries"
COUNTRIES_ZIP="${COUNTRIES}.zip"
OUTPUT_DIRECTORY="subnets"
MAXMIND_ACCOUNT_ID_AND_LICENSE_KEY=""
SEPARATE_ANONYMOUS_PROXIES=false

optspec=":hv-:"
while getopts "$optspec" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                liecense)
                    val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    # echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
                    MAXMIND_ACCOUNT_ID_AND_LICENSE_KEY=${val}
                    ;;
                liecense=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$val}
                    MAXMIND_ACCOUNT_ID_AND_LICENSE_KEY=${val}
                    ;;
                output-directory)
                    val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    OUTPUT_DIRECTORY=${val}
                    ;;
                output-directory=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$val}
                    OUTPUT_DIRECTORY=${val}
                    ;;
                separate-anonymous-proxies)
                    SEPARATE_ANONYMOUS_PROXIES=true
                    ;;
                separate-anonymous-proxies=*)
                    SEPARATE_ANONYMOUS_PROXIES=true
                    ;;
                help)
                    echo "Usage: $0 --license[=]<value> [--output-directory[=]<value>] [--separate-anonymous-proxies]" >&2
                    echo "Options:" >&2
                    echo "--license                      A MaxMind.com account ID and license key separated by colon: 'accountID:licenceKey'. Get data from maxmind.com -> My Account -> My License Key" >&2
                    echo "--output-directory             Output directory for subnets. Default 'subnets'" >&2
                    echo "--separate-anonymous-proxies   If set, anonymous proxies will be stored into different file: CountryCode_anonymous_proxies.txt" >&2
                    exit 2
                    ;;
                *)
                    if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                        echo "Unknown option --${OPTARG}" >&2
                    fi
                    ;;
            esac;;
        h)
            echo "Usage: $0 --license[=]<value> [--output-directory[=]<value>] [--separate-anonymous-proxies]" >&2
            echo "Options:" >&2
            echo "--license                      A MaxMind.com account ID and license key separated by colon: 'accountID:licenceKey'. Get data from maxmind.com -> My Account -> My License Key" >&2
            echo "--output-directory             Output directory for subnets. Default 'subnets'" >&2
            echo "--separate-anonymous-proxies   If set, anonymous proxies will be stored into different file: CountryCode_anonymous_proxies.txt" >&2
            exit 2
            ;;
        # v)
        #     echo "Parsing option: '-${optchar}'" >&2
        #     ;;
        *)
            if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                echo "Non-option argument: '-${OPTARG}'" >&2
            fi
            ;;
    esac
done

if [ -z $MAXMIND_ACCOUNT_ID_AND_LICENSE_KEY ]; then
    echo "MaxMind license key must be set via --liecense parameter. See --help for more.";
    exit 1;
fi

curl --output "$COUNTRIES_ZIP" -J -L -u $MAXMIND_ACCOUNT_ID_AND_LICENSE_KEY 'https://download.maxmind.com/geoip/databases/GeoLite2-Country-CSV/download?suffix=zip'

if [ ! -f "$COUNTRIES_ZIP" ]; then
    echo "Error downloading file"
    exit 1
fi

unzip -qq -o $COUNTRIES_ZIP

cp -r GeoLite2-Country-CSV_* $COUNTRIES
rm -rf GeoLite2-Country-CSV_*

mkdir -p $OUTPUT_DIRECTORY
rm $OUTPUT_DIRECTORY/*.txt # delete old entries

# generate subnets/COUNTRYCODE.txt files and fill it with subnets
IFS=","
while read geoname_id locale_code continent_code continent_name country_iso_code country_name is_in_european_union
do
    if [ ! "$country_iso_code" ]; then
        continue
    fi

    if [ "$country_iso_code" = 'country_iso_code' ]; then
        continue
    fi

    echo "Processing $country_iso_code records"

    GLOBAL_GEONAME_ID=$geoname_id

    # IPv4
    grep $GLOBAL_GEONAME_ID $COUNTRIES/GeoLite2-Country-Blocks-IPv4.csv > $COUNTRIES/country_geoname_id.csv
    while read network geoname_id registered_country_geoname_id represented_country_geoname_id is_anonymous_proxy is_satellite_provider is_anycast
    do
        if [ "$SEPARATE_ANONYMOUS_PROXIES" = true ] && [ $is_anonymous_proxy = "1" ]; then
            echo "$network" >> "${OUTPUT_DIRECTORY}/${country_iso_code}_anonymous_proxies.txt"
        else
            echo "$network" >> "${OUTPUT_DIRECTORY}/${country_iso_code}.txt"
        fi
    done < $COUNTRIES/country_geoname_id.csv


    # IPv6
    grep $GLOBAL_GEONAME_ID $COUNTRIES/GeoLite2-Country-Blocks-IPv6.csv > $COUNTRIES/country_geoname_id.csv
    while read network geoname_id registered_country_geoname_id represented_country_geoname_id is_anonymous_proxy is_satellite_provider is_anycast
    do
        if [ "$SEPARATE_ANONYMOUS_PROXIES" = true ] && [ $is_anonymous_proxy = "1" ]; then
            echo "$network" >> "${OUTPUT_DIRECTORY}/${country_iso_code}_anonymous_proxies.txt"
        else
            echo "$network" >> "${OUTPUT_DIRECTORY}/${country_iso_code}.txt"
        fi
    done < $COUNTRIES/country_geoname_id.csv

done < $COUNTRIES/GeoLite2-Country-Locations-en.csv

# clean up
rm $COUNTRIES_ZIP 2> /dev/null
rm -rf $COUNTRIES 2> /dev/null

exit 0
