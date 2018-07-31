#!/bin/bash

#
# This script uses the OWLTools library (https://github.com/owlcollab/owltools)
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-b <base directory>]: MUST BE ABSOLUTE PATH. The base directory where the ontologies have previously been downloaded."
    echo "  [-i <ontology id>]: Identifier of the ontology to process."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-a <script header file>]: MUST BE ABSOLUTE PATH. [OPTIONAL] File containing header for the script."
    echo "  [-t <script file>]: MUST BE ABSOLUTE PATH. The path to the script file created by this script."
    echo "  [-z <code base directory>]: MUST BE ABSOLUTE PATH. Path to the base directory where this project has been downloaded."
    echo "  [-l <log directory>]: MUST BE ABSOLUTE PATH. Log directory."

        ### header arguments
    echo "  [-n <job name>]: OPTIONALLY USED IN HEADER. Job name; will replace JOB_NAME in header file."
    echo "  [-e <email>]: OPTIONALLY USED IN HEADER. Your email address; will replace YOUR_EMAIL in header file."
    echo "  [-y <job log directory>]: OPTIONALLY USED IN HEADER. Job log directory; will replace JOB_LOG_DIRECTORY in header file."

}

while getopts "b:i:m:a:n:e:y:t:z:l:h" OPTION; do
    case ${OPTION} in
        # The work directory
        b) BASE_DIRECTORY=$OPTARG
           ;;
        # The ontology id to process
        i) ONT_ID=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # The path to the directory where this project has been downloaded
        z) CODE_BASE_DIRECTORY=$OPTARG
           ;;
        # File containing header file for the script (OPTIONAL)
        a) HEADER_FILE=$OPTARG
           ;;
        # Job name; will replace JOB_NAME in header file. (OPTIONAL)
        n) HEADER_JOB_NAME=$OPTARG
           ;;
        # Your email address; will replace YOUR_EMAIL in header file. (OPTIONAL)
        e) HEADER_EMAIL=$OPTARG
           ;;
        # Job log directory; will replace JOB_LOG_DIRECTORY in header file. (OPTIONAL)
        y) HEADER_JOB_LOG_DIRECTORY=$OPTARG
           ;;
        # Path to the script file created by this script
        t) SCRIPT_FILE=$OPTARG
           ;;
        # Log directory
        l) LOG_DIRECTORY=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${BASE_DIRECTORY} || -z ${ONT_ID} || -z ${MAVEN} || -z ${RELATION_DIRECTORY_BY_ONTOLOGY} \
     || -z ${SCRIPT_FILE} || -z ${CODE_BASE_DIRECTORY} || -z ${LOG_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "base directory: ${BASE_DIRECTORY}"
	echo "log directory: ${LOG_DIRECTORY}"
	echo "ontology id: ${ONT_ID}"
	echo "maven: ${MAVEN}"
	echo "script file: ${SCRIPT_FILE}"
	echo "output directory: ${RELATION_DIRECTORY_BY_ONTOLOGY}"
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

> ${SCRIPT_FILE}

# remove any duplicate forward slashes from the directory path
dir=$(echo "${BASE_DIRECTORY}/ontologies/${ONT_ID}" | sed 's/\/\//\//g')
owl_file="${dir}/${ONT_ID}_flat.owl"
output_file="${RELATION_DIRECTORY_BY_ONTOLOGY}/${ONT_ID}_flat.owl.relations"
LOG_FILE="${LOG_DIRECTORY}/${ONT_ID}_relation-extraction.log"
HEADER_JOB_NAME="${HEADER_JOB_NAME}_${ONT_ID}_relation_extraction"
### add the header to the script file if one has been specified
. ${CODE_BASE_DIRECTORY}/scripts/util/handle_header.bash

printf "###\n### This script will extract relations from ${owl_file}.\n###\n" >> ${SCRIPT_FILE}
printf "\n> ${LOG_FILE}" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/relation_analyses/extract-relations.sh -i ${owl_file} -o ${output_file} -m ${MAVEN} -g ${LOG_FILE}" >> ${SCRIPT_FILE}

printf "\ne=\$?" >> ${SCRIPT_FILE}

