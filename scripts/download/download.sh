#!/bin/bash

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-l <log file>]: MUST BE ABSOLUTE PATH. The log file that will document the downloading of the specified URL."
    echo "  [-o <output directory>]: MUST BE ABSOLUTE PATH. The directory where the downloaded file will be stored."
    echo "  [-i <ontology id>]: Ontology identifier (this will be used as the downloaded file name (appended with .owl)"
    echo "  [-u <url>]: The URL to download."
}

while getopts "l:o:i:u:h" OPTION; do
    case ${OPTION} in
        # The input ontology file
        l) LOG_FILE=$OPTARG
           ;;
        # The output file (will contain input ontology + content of all imports)
        o) OUTPUT_DIRECTORY=$OPTARG
           ;;
        # The ontology identifier (will be used to name the downloaded file)
        i) ID=$OPTARG
           ;;
        # The path to the Apache Maven command
        u) URL=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${LOG_FILE} || -z ${OUTPUT_DIRECTORY} || -z ${ID} || -z ${URL} ]]; then
	echo "missing input arguments!!!!!"
	echo "log file: ${LOG_FILE}"
	echo "output directory: ${OUTPUT_DIRECTORY}"
	echo "ontology identifier: ${ID}"
	echo "url: ${URL}"
    print_usage
    exit 1
fi

#verify target dir and switch there
mkdir -p ${OUTPUT_DIRECTORY}
cd ${OUTPUT_DIRECTORY}

#append forwardslash to target directory if it doesn't end in a slash already
case ${OUTPUT_DIRECTORY} in
*/)
;;
*)
OUTPUT_DIRECTORY=$(echo "${OUTPUT_DIRECTORY}/")
;;
esac

#verify the log file
touch ${LOG_FILE}

date | tee -a ${LOG_FILE}
wget -c -t 0 --timeout 60 --waitretry 10 -O ${ID}.owl -P ${OUTPUT_DIRECTORY} ${URL} | tee -a ${LOG_FILE}
e=${PIPESTATUS[0]}
date | tee -a ${LOG_FILE}
exit ${e}


