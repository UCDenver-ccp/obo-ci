#!/bin/bash -e

# Given an ontology file, extract all relations used.
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-i <ontology file>]: MUST BE ABSOLUTE PATH. The ontology file to process."
    echo "  [-o <output file>]: MUST BE ABSOLUTE PATH. The output file to store the extracted relations."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-g <log file>]: MUST BE ABSOLUTE PATH. Path to the log file."
}

while getopts "i:o:m:g:h" OPTION; do
    case ${OPTION} in
        # The input ontology file
        i) ONT_FILE=$OPTARG
           ;;
        # The output file where extracted relations are stored
        o) OUTPUT_FILE=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # Log file
        g) LOG_FILE=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${ONT_FILE} || -z ${MAVEN} || -z ${OUTPUT_FILE} || -z ${LOG_FILE} ]]; then
	echo "missing input arguments!!!!!"
	echo "ontology file: ${ONT_FILE}"
	echo "output file: ${OUTPUT_FILE}"
	echo "maven: ${MAVEN}"
	echo "log file: ${LOG_FILE}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

PATH_TO_ME=`pwd`

date | tee -a ${LOG_FILE}
echo "Extracting relations from: ${ONT_FILE}" | tee -a ${LOG_FILE}
${MAVEN} -e -f scripts/relation-analysis/pom-relation-extraction.xml exec:exec \
        -DontologyFile=${ONT_FILE} \
        -DoutputFile=${OUTPUT_FILE} \
        -DlaunchDir=${PATH_TO_ME} 2>&1 | tee -a ${LOG_FILE}
e=${PIPESTATUS[0]}
date | tee -a ${LOG_FILE}
exit ${e}