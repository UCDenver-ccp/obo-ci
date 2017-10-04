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
ONTOLOGY_LIST_FILE="${DOWNLOAD_DIRECTORY}/ontologies.list"
mkdir -p ${DOWNLOAD_DIRECTORY}

# This script first downloads all of the OBOs and creates a flattened (all imports included) version of each
# owl file. It then creates a md5 hash of that flattened owl file and uses the hash to determine if

# generate a list of all available ontologies in the OBOFoundry.org catalog
./scripts/download/create-ontology-list-file.sh -l ${ONTOLOGY_LIST_FILE} -j ${JQ}
# download each ontology
./scripts/download/download-ontologies.sh -l ${ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY}
# download and install the most recent SNAPSHOT of the OWLTools-Runtime library
./scripts/download/install-latest-owltools-runner-jar.sh -d ${WORK_DIRECTORY} -m ${MAVEN}
# for each ontology, download all owl:imports and consolidate (flatten) into a single OWL file per ontology
./scripts/download/flatten-ontologies.sh  -l ${ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY} -m ${MAVEN}
# for each flattened ontology file, generate the md5 message digest
./scripts/download/checksum-gen-ontologies.sh -l ${ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY} -c ${CHECKSUM_BIN}
# create a list of ontologies that are new or have changed from the previously downloaded version
./scripts/download/create-modified-ontology-list.sh -l ${ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY} -b ${BASE_DIRECTORY}