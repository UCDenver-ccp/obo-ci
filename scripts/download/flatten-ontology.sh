#!/bin/bash

# Uses the OWLTools library (https://github.com/owlcollab/owltools)
# to consolidate an ontology and all of its imports into a single OWL file.
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <download directory>]: MUST BE ABSOLUTE PATH. The base directory where all intermediate files will be stored."
    echo "  [-i <ontology id>]: Identifier of the ontology to download."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-o <flattened ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs that were successfully flattened."
    echo "  [-e <flatten error file>]: MUST BE ABSOLUTE PATH. A file used to record errors when flattening ontology imports."
    echo "  [-s <ontology status directory>]: MUST BE ABSOLUTE PATH. The path to a directory where json files indicating ontology status are to be written."
    echo "  [-z <code base directory>]: MUST BE ABSOLUTE PATH. Path to the base directory where this project has been downloaded."
    echo "  [-l <log directory>]: MUST BE ABSOLUTE PATH. log directory."
}

while getopts "d:l:i:m:s:z:h" OPTION; do
    case ${OPTION} in
        # The work directory
        d) DOWNLOAD_DIRECTORY=$OPTARG
           ;;
        # The ontology id to download
        i) ONT_ID=$OPTARG
           ;;
        # A directory where ontology status json will be written
        s) STATUS_DIR=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # The path to the directory where this project has been downloaded
        z) CODE_BASE_DIRECTORY=$OPTARG
           ;;
        # The path to the directory where this project has been downloaded
        l) LOG_DIRECTORY=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${DOWNLOAD_DIRECTORY} || -z ${LOG_DIRECTORY} || -z ${ONT_ID} || -z ${MAVEN} \
   || -z ${STATUS_DIR} || -z ${CODE_BASE_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "work directory: ${DOWNLOAD_DIRECTORY}"
	echo "ontology id: ${ONT_ID}"
	echo "path to Maven binary: ${MAVEN}"
	echo "ontology status directory: ${STATUS_DIR}"
	echo "log directory: ${LOG_DIRECTORY}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

### remove any trailing slash from the code base directory
case "${CODE_BASE_DIRECTORY}" in
    */)
    CODE_BASE_DIRECTORY=${CODE_BASE_DIRECTORY%?}
    ;;
esac

# remove any duplicate forward slashes from the directory path
dir=$(echo "${DOWNLOAD_DIRECTORY}/ontologies/${ONT_ID}" | sed 's/\/\//\//g')
ont_file="${dir}/${ONT_ID}.owl"
flat_ont_file="${dir}/${ONT_ID}_flat.owl"
LOG_FILE="${LOG_DIRECTORY}/${ONT_ID}_flat.log"

cp ${CODE_BASE_DIRECTORY}/scripts/template.json ${STATUS_DIR}/${ONT_ID}_flat.json
sed -i 's/\"id\": null,/\"id\": \"'"${ONT_ID}"'\",/' "${STATUS_DIR}/${ONT_ID}_flat.json"

### check the download log to see if the download was successful. If successful then proceed with the flattening
DOWNLOAD_STATUS_FILE="${STATUS_DIR}/${ONT_ID}_dload.json"
if grep -q '"dload": true,' ${DOWNLOAD_STATUS_FILE}; then
    echo "flattening ${ont_file} into ${flat_ont_file}"
    ${CODE_BASE_DIRECTORY}/scripts/download/flatten.sh -i ${ont_file} -o ${flat_ont_file} -m ${MAVEN} -g ${LOG_FILE}
    e=$?

    # populate the template json with the path to the flatten log file
    pattern="[/]"
    escaped_log_file="${LOG_FILE//$pattern/\/}"
    sed -i 's/\"flat_log\": null,/\"flat_log\": \"'"${escaped_log_file}"'\",/' "${STATUS_DIR}/${ONT_ID}_flat.json"

    if [ ${e} == 0 ]; then
        sed -i 's/\"flat\": null,/\"flat\": true,/' "${STATUS_DIR}/${ONT_ID}_flat.json"
    else
        sed -i 's/\"flat\": null,/\"flat\": false,/' "${STATUS_DIR}/${ONT_ID}_flat.json"
    fi
fi
