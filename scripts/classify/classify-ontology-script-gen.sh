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
    echo "  [-a <script header file>]: MUST BE ABSOLUTE PATH. [OPTIONAL] File containing header for the script."
    echo "  [-t <script file>]: MUST BE ABSOLUTE PATH. The path to the script file created by this script."
    echo "  [-z <code base directory>]: MUST BE ABSOLUTE PATH. Path to the base directory where this project has been downloaded."

        ### header arguments
    echo "  [-n <job name>]: OPTIONALLY USED IN HEADER. Job name; will replace JOB_NAME in header file."
    echo "  [-e <email>]: OPTIONALLY USED IN HEADER. Your email address; will replace YOUR_EMAIL in header file."
    echo "  [-y <job log directory>]: OPTIONALLY USED IN HEADER. Job log directory; will replace JOB_LOG_DIRECTORY in header file."

}

while getopts "b:i:x:m:r:s:a:n:e:y:t:z:h" OPTION; do
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
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${BASE_DIRECTORY} || -z ${ONT_ID} || -z ${REASONER_NAME} || -z ${MAVEN} \
     || -z ${STATUS_DIR}  || -z ${SCRIPT_FILE} || -z ${CODE_BASE_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "base directory: ${BASE_DIRECTORY}"
	echo "ontology id: ${ONT_ID}"
	echo "reasoner: ${REASONER_NAME}"
	echo "maven: ${MAVEN}"
	echo "script file: ${SCRIPT_FILE}"
	echo "ontology status directory: ${STATUS_DIR}"
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

if [[ -z ${HEADER_FILE} ]]; then
    HEADER="#!/bin/bash -e"
    echo ${HEADER} >> ${SCRIPT_FILE}
    echo "" >> ${SCRIPT_FILE}
else
    cat ${HEADER_FILE} > ${SCRIPT_FILE}
fi

### modify header file with replacement strings for job name, email, and job log directory (if they have been specified)
if [[ ! -z ${HEADER_JOB_NAME} ]]; then
    sed -i 's/JOB_NAME/'${HEADER_JOB_NAME}'/' ${SCRIPT_FILE}
fi
if [[ ! -z ${HEADER_EMAIL} ]]; then
    sed -i 's/YOUR_EMAIL/'${HEADER_EMAIL}'/' ${SCRIPT_FILE}
fi
if [[ ! -z ${HEADER_JOB_LOG_DIRECTORY} ]]; then
    ### remove any trailing slash from the directory, then escape any remaining slashes
    case "${HEADER_JOB_LOG_DIRECTORY}" in
        */)
        HEADER_JOB_LOG_DIRECTORY=${HEADER_JOB_LOG_DIRECTORY%?}
        ;;
    esac
    pattern="[/]"
    escaped_job_log_directory="${HEADER_JOB_LOG_DIRECTORY//$pattern/\/}"
    sed -i 's/JOB_LOG_DIRECTORY/'${escaped_job_log_directory}'/' ${SCRIPT_FILE}
fi

# remove any duplicate forward slashes from the directory path
dir=$(echo "${BASE_DIRECTORY}/ontologies/${ONT_ID}" | sed 's/\/\//\//g')
owl_file="${dir}/${ONT_ID}_flat.owl"
output_file="${dir}/${ONT_ID}_flat.inferred_${REASONER_NAME}.owl"
LOG_DIRECTORY=${STATUS_DIR}/log

if [[ -z ${XTRA_ONT_ID} ]]; then
    LOG_FILE=${LOG_DIRECTORY}/${ONT_ID}_${REASONER_NAME}.log
    STATUS_FILE="${ONT_ID}_${REASONER_NAME}.json"
    printf "###\n### This script will run the ${REASONER_NAME} reasoner over the ontology in ${owl_file}, using the OWLTools library.\n###\n" >> ${SCRIPT_FILE}
    printf "\n### create the status file by copying from the template status file" >> ${SCRIPT_FILE}
    printf "\ncp ${BASE_DIRECTORY}/template.json ${STATUS_DIR}/${STATUS_FILE}" >> ${SCRIPT_FILE}
    printf "\n### update the id field in the status file" >> ${SCRIPT_FILE}
    printf "\nsed -i 's/\\\"id\\\": null,/\\\"id\\\": \\\"'\"${ONT_ID}\"'\\\",/' \"${STATUS_DIR}/${STATUS_FILE}\"" >> ${SCRIPT_FILE}
    printf "\n\n### start the reasoner and log its output" >> ${SCRIPT_FILE}
    printf "\nprintf \"classifying ${owl_file}...\"" >> ${SCRIPT_FILE}
    printf "\n> ${LOG_FILE}" >> ${SCRIPT_FILE}
    printf "\n${CODE_BASE_DIRECTORY}/scripts/classify/classify.sh -i ${owl_file} -o ${output_file} -r ${REASONER_NAME} -m ${MAVEN} -g ${LOG_FILE}" >> ${SCRIPT_FILE}
else
    LOG_FILE=${LOG_DIRECTORY}/${ONT_ID}_${XTRA_ONT_ID}_${REASONER_NAME}.log
    STATUS_FILE="${ONT_ID}_${XTRA_ONT_ID}_${REASONER_NAME}.json"
    xtra_dir=$(echo "${BASE_DIRECTORY}/ontologies/${XTRA_ONT_ID}" | sed 's/\/\//\//g')
    xtra_owl_file="${xtra_dir}/${XTRA_ONT_ID}_flat.owl"
    output_dir=$(echo "${BASE_DIRECTORY}/pairs/${ONT_ID}_${XTRA_ONT_ID}" | sed 's/\/\//\//g')
    output_file="${output_dir}/${ONT_ID}_${XTRA_ONT_ID}.inferred_${REASONER_NAME}.owl"
    printf "###\n### This script will run the ${REASONER_NAME} reasoner over the merged ontologies in ${owl_file} and ${xtra_owl_file}, using the OWLTools library.\n###\n" >> ${SCRIPT_FILE}
    printf "\n### create the status file by copying from the template status file" >> ${SCRIPT_FILE}
    printf "\ncp ${BASE_DIRECTORY}/template.json ${STATUS_DIR}/${STATUS_FILE}" >> ${SCRIPT_FILE}
    printf "\n### update the id field in the status file" >> ${SCRIPT_FILE}
    printf "\nsed -i 's/\\\"id\\\": null,/\\\"id\\\": \\\"'\"${ONT_ID}_${XTRA_ONT_ID}\"'\\\",/' \"${STATUS_DIR}/${STATUS_FILE}\"" >> ${SCRIPT_FILE}
    printf "\nmkdir -p ${output_dir}" >> ${SCRIPT_FILE}
    printf "\n\n### start the reasoner and log its output" >> ${SCRIPT_FILE}
    printf "\nprintf \"classifying ${owl_file} + ${xtra_owl_file}...\"" >> ${SCRIPT_FILE}
    printf "\n> ${LOG_FILE}" >> ${SCRIPT_FILE}
    printf "\n${CODE_BASE_DIRECTORY}/scripts/classify/classify.sh -i ${owl_file} -x ${xtra_owl_file} -o ${output_file} -r ${REASONER_NAME} -m ${MAVEN} -g ${LOG_FILE}" >> ${SCRIPT_FILE}
fi
printf "\ne=\$?" >> ${SCRIPT_FILE}

# populate the template json with the path to the download log file
pattern="[/]"
escaped_log_file="${LOG_FILE//$pattern/\/}"
printf "\n\n### log the location of the reasoner log file" >> ${SCRIPT_FILE}
printf "\nsed -i 's/\\\"'\"${REASONER_NAME}\"'_log\\\": null/\\\"'\"${REASONER_NAME}\"'_log\\\": \\\"'\"${escaped_log_file}\"'\\\"/' \"${STATUS_DIR}/${STATUS_FILE}\"" >> ${SCRIPT_FILE}
printf "\n### if the reasoner succeeded then log the status as 'true', otherwise log the status as 'false" >> ${SCRIPT_FILE}
printf "\nif [ \${e} == 0 ]; then" >> ${SCRIPT_FILE}
printf "\n\tsed -i 's/\\\"'${REASONER_NAME}'\\\": null/\\\"'${REASONER_NAME}'\\\": true/' \"${STATUS_DIR}/${STATUS_FILE}\"" >> ${SCRIPT_FILE}
printf "\nelse" >> ${SCRIPT_FILE}
printf "\n\tsed -i 's/\\\"'${REASONER_NAME}'\\\": null/\\\"'${REASONER_NAME}'\\\": false/' \"${STATUS_DIR}/${STATUS_FILE}\"" >> ${SCRIPT_FILE}
printf "\nfi" >> ${SCRIPT_FILE}

