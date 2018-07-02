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
    echo "  [-x <xtra ontology id>]: [OPTIONAL] Identifier of an ontology to merge prior to processing."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-r <reasoner name>]: 'elk' or 'hermit'"
    echo "  [-s <ontology status directory>]: MUST BE ABSOLUTE PATH. The path to a directory where json files indicating ontology status are to be written."
    echo "  [-p <explanation directory>]: MUST BE ABSOLUTE PATH. The path to a directory where the incoherent class explanations will be written."
    echo "  [-a <script header file>]: MUST BE ABSOLUTE PATH. [OPTIONAL] File containing header for the script."
    echo "  [-t <script file>]: MUST BE ABSOLUTE PATH. The path to the script file created by this script."
    echo "  [-z <code base directory>]: MUST BE ABSOLUTE PATH. Path to the base directory where this project has been downloaded."
    echo "  [-l <log directory>]: MUST BE ABSOLUTE PATH. Log directory."

        ### header arguments
    echo "  [-n <job name>]: OPTIONALLY USED IN HEADER. Job name; will replace JOB_NAME in header file."
    echo "  [-e <email>]: OPTIONALLY USED IN HEADER. Your email address; will replace YOUR_EMAIL in header file."
    echo "  [-y <job log directory>]: OPTIONALLY USED IN HEADER. Job log directory; will replace JOB_LOG_DIRECTORY in header file."

}

while getopts "b:i:x:m:r:s:a:n:e:y:t:z:l:p:h" OPTION; do
    case ${OPTION} in
        # The work directory
        b) BASE_DIRECTORY=$OPTARG
           ;;
        # The ontology id to process
        i) ONT_ID=$OPTARG
           ;;
        # An xtra ontology to merge prior to processing
        x) XTRA_ONT_ID=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # The path to the directory where this project has been downloaded
        z) CODE_BASE_DIRECTORY=$OPTARG
           ;;
        # The name of the reasoner to use
        r) REASONER_NAME=$OPTARG
           ;;
        # A directory where ontology status json will be written
        s) STATUS_DIR=$OPTARG
           ;;
        # A directory where incoherent class explanations will be written
        p) EXPLANATION_DIR=$OPTARG
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

if [[ -z ${BASE_DIRECTORY} || -z ${ONT_ID} || -z ${REASONER_NAME} || -z ${MAVEN} \
     || -z ${STATUS_DIR}  || -z ${SCRIPT_FILE} || -z ${CODE_BASE_DIRECTORY} || -z ${LOG_DIRECTORY} || -z ${EXPLANATION_DIR} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "base directory: ${BASE_DIRECTORY}"
	echo "log directory: ${LOG_DIRECTORY}"
	echo "ontology id: ${ONT_ID}"
	echo "reasoner: ${REASONER_NAME}"
	echo "maven: ${MAVEN}"
	echo "script file: ${SCRIPT_FILE}"
	echo "ontology status directory: ${STATUS_DIR}"
	echo "explanation directory: ${EXPLANATION_DIR}"
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
output_file="${dir}/${ONT_ID}_flat.inferred_${REASONER_NAME}.owl"

if [[ -z ${XTRA_ONT_ID} ]]; then
    LOG_FILE=${LOG_DIRECTORY}/${ONT_ID}_${REASONER_NAME}.log
    EXPLANATIONS_FILE="${ONT_ID}_${REASONER_NAME}.explanation"

    HEADER_JOB_NAME="${HEADER_JOB_NAME}_${ONT_ID}_${REASONER_NAME}"
    ### add the header to the script file if one has been specified
    . ${CODE_BASE_DIRECTORY}/scripts/util/handle_header.bash

    printf "######## EXPLANATIONS ########" >> ${SCRIPT_FILE}
#    printf "###\n### This script will run the ${REASONER_NAME} reasoner over the ontology in ${owl_file}, using the OWLTools library.\n###\n" >> ${SCRIPT_FILE}
#    printf "\n\n### start the reasoner and log its output" >> ${SCRIPT_FILE}
#    printf "\nprintf \"classifying ${owl_file}...\"" >> ${SCRIPT_FILE}
    # don't reset the log file b/c we are re-classifying the owl file and want to add to the existing log
    #printf "\n> ${LOG_FILE}" >> ${SCRIPT_FILE}
#    printf "\n${CODE_BASE_DIRECTORY}/scripts/classify/classify-with-explanation.sh -i ${owl_file} -r ${REASONER_NAME} -m ${MAVEN} -g ${LOG_FILE}" >> ${SCRIPT_FILE}
else
    LOG_FILE="${LOG_DIRECTORY}/${ONT_ID}+${XTRA_ONT_ID}_${REASONER_NAME}.log"
    EXPLANATIONS_FILE="${ONT_ID}+${XTRA_ONT_ID}_${REASONER_NAME}.explanation"
    xtra_dir=$(echo "${BASE_DIRECTORY}/ontologies/${XTRA_ONT_ID}" | sed 's/\/\//\//g')
    xtra_owl_file="${xtra_dir}/${XTRA_ONT_ID}_flat.owl"

    HEADER_JOB_NAME="${HEADER_JOB_NAME}_${ONT_ID}+${XTRA_ONT_ID}_${REASONER_NAME}"
    ### add the header to the script file if one has been specified
    . ${CODE_BASE_DIRECTORY}/scripts/util/handle_header.bash

    printf "######## EXPLANATIONS ########" >> ${SCRIPT_FILE}
#    printf "###\n### This script will run the ${REASONER_NAME} reasoner over the merged ontologies in ${owl_file} and ${xtra_owl_file}, using the OWLTools library.\n###\n" >> ${SCRIPT_FILE}
#    printf "\n\n### start the reasoner and log its output" >> ${SCRIPT_FILE}
#    printf "\nprintf \"classifying ${owl_file} + ${xtra_owl_file}...\"" >> ${SCRIPT_FILE}
    # don't reset the log file b/c we are re-classifying the owl file and want to add to the existing log
    #printf "\n> ${LOG_FILE}" >> ${SCRIPT_FILE}
#    printf "\n${CODE_BASE_DIRECTORY}/scripts/classify/classify-with-explanation.sh -i ${owl_file} -x ${xtra_owl_file} -r ${REASONER_NAME} -m ${MAVEN} -g ${LOG_FILE}" >> ${SCRIPT_FILE}
fi

# b/c of the incoherent classes, the reasoner will exit abnormally (i.e. exit code != 0) so we don't check for reasoner success here
#printf "\ne=\$?" >> ${SCRIPT_FILE}
#printf "\n### if the reasoner succeeded then extract the explanations." >> ${SCRIPT_FILE}
#printf "\nif [ \${e} == 0 ]; then" >> ${SCRIPT_FILE}
printf "\n\t### compute the number of incoherent classes observed by counting lines in the log file that start with 'E: '" >> ${SCRIPT_FILE}
# if the log file exists and if the explanations file does not exist
printf "\n\tif [ -f '${LOG_FILE}' ] \n\tthen\n" >> ${SCRIPT_FILE}
printf "\t\t\tif [ ! -f '${EXPLANATION_DIR}/${EXPLANATIONS_FILE}' ] \n\t\tthen" >> ${SCRIPT_FILE}
printf "\n\t\tgrep -e '^\\[INFO\\] UNSAT: ' ${LOG_FILE} > ${EXPLANATION_DIR}/${EXPLANATIONS_FILE}" >> ${SCRIPT_FILE}
printf "\nfi\nfi" >> ${SCRIPT_FILE}
#printf "\nfi" >> ${SCRIPT_FILE}

