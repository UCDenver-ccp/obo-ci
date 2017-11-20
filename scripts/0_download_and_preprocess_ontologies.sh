#!/bin/bash -e

# Download and preprocess all ontologies in the OBOFoundry.org catalog
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <work directory>]: MUST BE ABSOLUTE PATH. The directory where all generated/downloaded files will be stored."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-c <md5sum>]: MUST BE ABSOLUTE PATH. The path to the md5sum command."
    echo "  [-j <jq>]: MUST BE ABSOLUTE PATH. The path to the jq command (https://stedolan.github.io/jq/)."
}

while getopts "d:m:c:j:h" OPTION; do
    case ${OPTION} in
        # The work directory where all intermediate files are stored
        d) WORK_DIRECTORY=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # The path to the md5sum command
        c) CHECKSUM_BIN=$OPTARG
           ;;
        # The path to the jq command
        j) JQ=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${WORK_DIRECTORY} || -z ${MAVEN} || -z ${JQ} ]]; then
	echo "missing input arguments!!!!!"
	echo "work directory: ${ONT_FILE}"
	echo "path to the Apache Maven binary: ${MAVEN}"
	echo "path to the md5sum command: ${CHECKSUM_BIN}"
	echo "path to the jq binary: ${JQ}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi




DOWNLOAD_DIRECTORY="${WORK_DIRECTORY}/download"
BASE_DIRECTORY="${WORK_DIRECTORY}/base"
LOG_DIRECTORY="${WORK_DIRECTORY}/status/log"
STATUS_DIRECTORY="${WORK_DIRECTORY}/status"
mkdir -p ${DOWNLOAD_DIRECTORY}
rm -Rf ${DOWNLOAD_DIRECTORY}
mkdir -p ${DOWNLOAD_DIRECTORY}
mkdir -p ${BASE_DIRECTORY}
mkdir -p ${STATUS_DIRECTORY}
mkdir -p ${LOG_DIRECTORY}

ONTOLOGY_LIST_FILE="${WORK_DIRECTORY}/ontologies.available.list"

DOWNLOADED_ONTOLOGY_LIST_FILE="${WORK_DIRECTORY}/ontologies.downloaded.list"
DOWNLOAD_ERROR_FILE="${WORK_DIRECTORY}/ontologies.download.error"

FLATTENED_ONTOLOGY_LIST_FILE="${WORK_DIRECTORY}/ontologies.flat.list"
FLATTEN_ERROR_FILE="${WORK_DIRECTORY}/ontologies.flatten.error"


# remove any duplicate slashes in file paths
DOWNLOAD_DIRECTORY=$(echo "${DOWNLOAD_DIRECTORY}" | sed 's/\/\//\//g')
BASE_DIRECTORY=$(echo "${BASE_DIRECTORY}" | sed 's/\/\//\//g')
STATUS_DIRECTORY=$(echo "${STATUS_DIRECTORY}" | sed 's/\/\//\//g')
LOG_DIRECTORY=$(echo "${LOG_DIRECTORY}" | sed 's/\/\//\//g')
ONTOLOGY_LIST_FILE=$(echo "${ONTOLOGY_LIST_FILE}" | sed 's/\/\//\//g')
DOWNLOADED_ONTOLOGY_LIST_FILE=$(echo "${DOWNLOADED_ONTOLOGY_LIST_FILE}" | sed 's/\/\//\//g')
DOWNLOAD_ERROR_FILE=$(echo "${DOWNLOAD_ERROR_FILE}" | sed 's/\/\//\//g')
FLATTENED_ONTOLOGY_LIST_FILE=$(echo "${FLATTENED_ONTOLOGY_LIST_FILE}" | sed 's/\/\//\//g')
FLATTEN_ERROR_FILE=$(echo "${FLATTEN_ERROR_FILE}" | sed 's/\/\//\//g')

# This script first downloads all of the OBOs and creates a flattened (all imports included) version of each
# owl file. It then creates a md5 hash of that flattened owl file and uses the hash to determine if

### generate a list of all available ontologies in the OBOFoundry.org catalog
#./scripts/download/create-ontology-list-file.sh -l ${ONTOLOGY_LIST_FILE} -j ${JQ}
### download each ontology
./scripts/download/download-ontologies.sh -l ${ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY} -o ${DOWNLOADED_ONTOLOGY_LIST_FILE} -e ${DOWNLOAD_ERROR_FILE} -s ${STATUS_DIRECTORY} -m ${MAVEN}
### download and install the most recent SNAPSHOT of the OWLTools-Runtime library
./scripts/download/install-latest-owltools-runner-jar.sh -d ${WORK_DIRECTORY} -m ${MAVEN}
### for each ontology, download all owl:imports and consolidate (flatten) into a single OWL file per ontology
./scripts/download/flatten-ontologies.sh  -l ${DOWNLOADED_ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY} -m ${MAVEN} -o ${FLATTENED_ONTOLOGY_LIST_FILE} -e ${FLATTEN_ERROR_FILE} -s ${STATUS_DIRECTORY}
### for each flattened ontology file, generate the md5 message digest
./scripts/download/checksum-gen-ontologies.sh -l ${FLATTENED_ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY} -c ${CHECKSUM_BIN}
### create a list of ontologies that are new or have changed from the previously downloaded version
./scripts/download/create-modified-ontology-list.sh -l ${FLATTENED_ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY} -b ${BASE_DIRECTORY}