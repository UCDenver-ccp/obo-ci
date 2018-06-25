#!/bin/bash -e

#
# This script creates a script that will download the list of available Open Biomedical Ontologies
# and install the OWLTools library. The generated script also cleans the download directory and creates
# other directories as needed.
#

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <work directory>]: MUST BE ABSOLUTE PATH. The directory where all generated/downloaded files will be stored."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-j <jq>]: MUST BE ABSOLUTE PATH. The path to the jq command (https://stedolan.github.io/jq/)."
    echo "  [-z <code base directory>]: MUST BE ABSOLUTE PATH. Path to the base directory where this project has been downloaded."
    echo "  [-k <run command>]: [OPTIONAL] The command used to run the generated scripts. Default = '', but could be something like 'qsub'"
    echo "  [-a <script header file>]: MUST BE ABSOLUTE PATH. [OPTIONAL] File containing header for the script."
    echo "  [-t <script file>]: MUST BE ABSOLUTE PATH. The path to the script file created by this script."

    ### header arguments
    echo "  [-n <job name>]: OPTIONALLY USED IN HEADER. Job name; will replace JOB_NAME in header file."
    echo "  [-e <email>]: OPTIONALLY USED IN HEADER. Your email address; will replace YOUR_EMAIL in header file."
    echo "  [-y <job log directory>]: OPTIONALLY USED IN HEADER. Job log directory; will replace JOB_LOG_DIRECTORY in header file."

}

while getopts "d:m:j:a:k:t:n:e:y:z:h" OPTION; do
    case ${OPTION} in
        # The work directory where all intermediate files are stored
        d) WORK_DIRECTORY=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # The path to the jq command
        j) JQ=$OPTARG
           ;;
        # The path to the directory where this project has been downloaded
        z) CODE_BASE_DIRECTORY=$OPTARG
           ;;
        # The command used to execute the generated scripts (OPTIONAL)
        k) RUN_CMD=$OPTARG
           ;;
        # File containing header file for the script (OPTIONAL)
        a) HEADER_FILE=$OPTARG
           ;;
        # Path to the script file created by this script
        t) SCRIPT_FILE=$OPTARG
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
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${WORK_DIRECTORY} || -z ${MAVEN} || -z ${JQ} || -z ${SCRIPT_FILE} || -z ${CODE_BASE_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "work directory: ${WORK_DIRECTORY}"
	echo "path to the Apache Maven binary: ${MAVEN}"
	echo "path to the jq binary: ${JQ}"
	echo "script file: ${SCRIPT_FILE}"
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
### define directories that will be used in the scripts
. ${CODE_BASE_DIRECTORY}/scripts/util/define_directories.bash

> ${SCRIPT_FILE}

### add the header to the script file if one has been specified
. ${CODE_BASE_DIRECTORY}/scripts/util/handle_header.bash

printf "\n###\n### This script will download the list of available Open Biomedical Ontologies and install the OWLTools library.\n###\n" >> ${SCRIPT_FILE}
printf "\n### It also cleans the download directory and creates other directories as needed." >> ${SCRIPT_FILE}
printf "\nmkdir -p ${DOWNLOAD_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nrm -Rf ${DOWNLOAD_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${DOWNLOAD_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${BASE_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${STATUS_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nrm -Rf ${STATUS_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${STATUS_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${STATUS_DIRECTORY_INDIVIDUAL}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${STATUS_DIRECTORY_PAIRS}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${LOG_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${LOG_DIRECTORY_DOWNLOAD}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${LOG_DIRECTORY_CLASSIFY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${LOG_DIRECTORY_CLASSIFY_PAIRS}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${LOG_DIRECTORY_CLASSIFY_EXPLANATION}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${LOG_DIRECTORY_CLASSIFY_PAIRS_EXPLANATION}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${LOG_DIRECTORY_CHECKS}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${LOG_DIRECTORY_CHECKS_PAIRS}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${SCRIPT_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${SCRIPT_DIRECTORY_DOWNLOAD}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${SCRIPT_DIRECTORY_CLASSIFY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${SCRIPT_DIRECTORY_CLASSIFY_PAIRS}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${SCRIPT_DIRECTORY_CLASSIFY_EXPLANATION}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${SCRIPT_DIRECTORY_CLASSIFY_PAIRS_EXPLANATION}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${SCRIPT_DIRECTORY_CHECKS}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${SCRIPT_DIRECTORY_CHECKS_PAIRS}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${EXPLANATION_DIRECTORY_INDIVIDUAL}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${EXPLANATION_DIRECTORY_PAIRS}" >> ${SCRIPT_FILE}
printf "\n### generate a list of all available ontologies in the OBOFoundry.org catalog" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/download/create-ontology-list-file.sh -l ${ONTOLOGY_LIST_FILE} -j ${JQ}" >> ${SCRIPT_FILE}
printf "\n\n### download and install the most recent SNAPSHOT of the OWLTools-Runtime library" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/download/install-latest-owltools-runner-jar.sh -d ${WORK_DIRECTORY} -m ${MAVEN}" >> ${SCRIPT_FILE}
