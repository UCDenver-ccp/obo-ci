#!/bin/bash -e

# Attempt to classify the downloaded ontologies
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <work directory>]: MUST BE ABSOLUTE PATH. The directory where all generated/downloaded files will be stored."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
}

while getopts "d:m:h" OPTION; do
    case ${OPTION} in
        # The work directory where all intermediate files are stored
        d) WORK_DIRECTORY=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${WORK_DIRECTORY} || -z ${MAVEN} ]]; then
	echo "missing input arguments!!!!!"
	echo "work directory: ${WORK_DIRECTORY}"
	echo "path to the Apache Maven binary: ${MAVEN}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

BASE_DIRECTORY="${WORK_DIRECTORY}/base"
STATUS_DIRECTORY="${WORK_DIRECTORY}/status"
LOG_DIRECTORY="${WORK_DIRECTORY}/status/log"
ONTOLOGY_LIST_FILE="${WORK_DIRECTORY}/ontologies.flat.list.to_process"

CLASSIFIED_LIST_FILE="${WORK_DIRECTORY}/ontologies.classified.list"
CLASSIFY_ERROR_FILE="${WORK_DIRECTORY}/ontologies.classify.error"

# remove any duplicate slashes in file paths
BASE_DIRECTORY=$(echo "${BASE_DIRECTORY}" | sed 's/\/\//\//g')
STATUS_DIRECTORY=$(echo "${STATUS_DIRECTORY}" | sed 's/\/\//\//g')
ONTOLOGY_LIST_FILE=$(echo "${ONTOLOGY_LIST_FILE}" | sed 's/\/\//\//g')
CLASSIFIED_LIST_FILE=$(echo "${CLASSIFIED_LIST_FILE}" | sed 's/\/\//\//g')
CLASSIFY_ERROR_FILE=$(echo "${CLASSIFY_ERROR_FILE}" | sed 's/\/\//\//g')

# This script attempts to classify any downloaded ontology that has been determined to have changed since the previous download.
# TODO: rewrite this to start up individual jobs to classify each ontology (per reasoner)

# attempt to classify the ontologies using elk
./scripts/classify/individual/classify-ontologies.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -l ${ONTOLOGY_LIST_FILE} -r elk -o ${CLASSIFIED_LIST_FILE}.elk -e ${CLASSIFY_ERROR_FILE}.elk -s ${STATUS_DIRECTORY}

# attempt to classify the ontologies using hermit
#./scripts/classify/individual/classify-ontologies.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -l ${ONTOLOGY_LIST_FILE} -r hermit -o ${CLASSIFIED_LIST_FILE}.hermit -e ${CLASSIFY_ERROR_FILE}.hermit -s ${STATUS_DIRECTORY}
