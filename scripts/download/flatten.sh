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
    echo "  [-o <output file>]: MUST BE ABSOLUTE PATH. The file into which to place merged/flattened version of the ontology."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-g <log file>]: MUST BE ABSOLUTE PATH. Path to the log file."
}

while getopts "i:o:m:g:h" OPTION; do
    case $OPTION in
        # The input ontology file
        i) ONT_FILE=$OPTARG
           ;;
        # The output file (will contain input ontology + content of all imports)
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

if [[ -z ${ONT_FILE} || -z ${OUTPUT_FILE} || -z ${MAVEN} || -z ${LOG_FILE}  ]]; then
	echo "missing input arguments!!!!!"
	echo "log file: ${LOG_FILE}"
	echo "output file: ${OUTPUT_FILE}"
	echo "ontology file: ${ONT_FILE}"
	echo "maven: ${MAVEN}"
    print_usage
    exit 1
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

PATH_TO_ME=`pwd`

date | tee -a ${LOG_FILE}
echo "Consolidating all ontology imports for: ${ONT_FILE}" | tee -a ${LOG_FILE}
${MAVEN} -e -f scripts/download/pom-flatten-ontology.xml exec:exec \
        -DontologyFile=${ONT_FILE} \
        -DoutputFile=${OUTPUT_FILE} \
        -DlaunchDir=${PATH_TO_ME} 2>&1 | tee -a ${LOG_FILE}
e=${PIPESTATUS[0]}
date | tee -a ${LOG_FILE}
exit ${e}

