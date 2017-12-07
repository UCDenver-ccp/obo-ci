#!/bin/bash -e

# Given an ontology file, download all imported ontologies and create
# a new file containing the source ontology and content of all imported
# ontologies. This script uses the OWLTools library (https://github.com/owlcollab/owltools)
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-i <ontology file>]: MUST BE ABSOLUTE PATH. The ontology file to process. All imports for this ontology will be recursively downloaded and merged."
    echo "  [-r <reasoner name>]: MUST BE ABSOLUTE PATH. 'elk' or 'hermit'"
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-g <log file>]: MUST BE ABSOLUTE PATH. Path to the log file."
    echo "  [-x <xtra ontology>]: MUST BE ABSOLUTE PATH. [OPTIONAL] Merge extra ontology before processing."
}

while getopts "i:r:m:g:x:h" OPTION; do
    case ${OPTION} in
        # The input ontology file
        i) ONT_FILE=$OPTARG
           ;;
        # The name of the reasoner to use
        r) REASONER_NAME=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # Log file
        g) LOG_FILE=$OPTARG
           ;;
        # Extra ontology file to be merged prior to processing (OPTIONAL)
        x) XTRA_ONT_FILE=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${ONT_FILE} || -z ${MAVEN} || -z ${REASONER_NAME} || -z ${LOG_FILE} ]]; then
	echo "missing input arguments!!!!!"
	echo "ontology file: ${ONT_FILE}"
	echo "reasoner name: ${REASONER_NAME}"
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
if [[ -z ${XTRA_ONT_FILE} ]]; then
echo "Classifying ontology file: ${ONT_FILE}" | tee -a ${LOG_FILE}
${MAVEN} -e -f scripts/classify/pom-classify-ontology-with-explanation.xml exec:exec \
        -DontologyFile=${ONT_FILE} \
        -DreasonerName=${REASONER_NAME} \
        -DlaunchDir=${PATH_TO_ME} 2>&1 | tee -a ${LOG_FILE}
else
echo "Classifying ontology pair: ${ONT_FILE} ${XTRA_ONT_FILE}" | tee -a ${LOG_FILE}
${MAVEN} -e -f scripts/classify/pom-classify-ontology-pair-with-explanation.xml exec:exec \
        -DontologyFile=${ONT_FILE} \
        -DxtraOntologyFile=${XTRA_ONT_FILE} \
        -DreasonerName=${REASONER_NAME} \
        -DlaunchDir=${PATH_TO_ME} 2>&1 | tee -a ${LOG_FILE}
fi
e=${PIPESTATUS[0]}
date | tee -a ${LOG_FILE}
exit ${e}