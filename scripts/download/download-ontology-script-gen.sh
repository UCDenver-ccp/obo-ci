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
    echo "  [-z <code base directory>]: MUST BE ABSOLUTE PATH. Path to the base directory where this project has been downloaded."
    echo "  [-k <run command>]: [OPTIONAL] The command used to run the generated scripts. Default = '', but could be something like 'qsub'"
    echo "  [-a <script header file>]: MUST BE ABSOLUTE PATH. [OPTIONAL] File containing header for the script."
    echo "  [-t <script file>]: MUST BE ABSOLUTE PATH. The path to the script file created by this script."

    ### header arguments
    echo "  [-n <job name>]: OPTIONALLY USED IN HEADER. Job name; will replace JOB_NAME in header file."
    echo "  [-e <email>]: OPTIONALLY USED IN HEADER. Your email address; will replace YOUR_EMAIL in header file."
    echo "  [-y <job log directory>]: OPTIONALLY USED IN HEADER. Job log directory; will replace JOB_LOG_DIRECTORY in header file."

}

while getopts "d:m:c:j:a:k:t:n:e:y:z:h" OPTION; do
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

if [[ -z ${WORK_DIRECTORY} || -z ${MAVEN} || -z ${JQ} || -z ${SCRIPT_FILE} || -z ${CHECKSUM_BIN} || -z ${CODE_BASE_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "work directory: ${WORK_DIRECTORY}"
	echo "path to the Apache Maven binary: ${MAVEN}"
	echo "path to the md5sum command: ${CHECKSUM_BIN}"
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
    sed -i '' 's/JOB_NAME/'${HEADER_JOB_NAME}'/' ${SCRIPT_FILE}
fi
if [[ ! -z ${HEADER_EMAIL} ]]; then
    sed -i '' 's/YOUR_EMAIL/'${HEADER_EMAIL}'/' ${SCRIPT_FILE}
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
    sed -i '' 's/JOB_LOG_DIRECTORY/'${escaped_job_log_directory}'/' ${SCRIPT_FILE}
fi

DOWNLOAD_DIRECTORY="${WORK_DIRECTORY}/download"
BASE_DIRECTORY="${WORK_DIRECTORY}/base"
LOG_DIRECTORY="${WORK_DIRECTORY}/status/log"
STATUS_DIRECTORY="${WORK_DIRECTORY}/status"

printf "\n###\n### This script will download the Open Biomedical Ontologies, validate the downloads as RDF, and process all imports for each ontology.\n###\n" >> ${SCRIPT_FILE}
printf "\n### clean the download directory and create other directories as needed" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${DOWNLOAD_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nrm -Rf ${DOWNLOAD_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${DOWNLOAD_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${BASE_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${STATUS_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\nmkdir -p ${LOG_DIRECTORY}" >> ${SCRIPT_FILE}

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

### copy template status file to base directory
cp ./scripts/template.json ${BASE_DIRECTORY}

printf "\n\n### This script first downloads all of the OBOs and creates a flattened (all imports included)" >> ${SCRIPT_FILE}
printf "\n### version of each owl file. It then creates a md5 hash of that flattened owl file and uses the" >> ${SCRIPT_FILE}
printf "\n### hash to determine if the file is new and thus needs further processing.\n" >> ${SCRIPT_FILE}
printf "\n### generate a list of all available ontologies in the OBOFoundry.org catalog" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/download/create-ontology-list-file.sh -l ${ONTOLOGY_LIST_FILE} -j ${JQ}" >> ${SCRIPT_FILE}
printf "\n\n### download and install the most recent SNAPSHOT of the OWLTools-Runtime library" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/download/install-latest-owltools-runner-jar.sh -d ${WORK_DIRECTORY} -m ${MAVEN}" >> ${SCRIPT_FILE}
printf "\n\n### download each ontology" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/download/download-ontologies.sh -l ${ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY} -o ${DOWNLOADED_ONTOLOGY_LIST_FILE} -e ${DOWNLOAD_ERROR_FILE} -s ${STATUS_DIRECTORY} -m ${MAVEN} -z ${CODE_BASE_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\n\n### for each ontology, download all owl:imports and consolidate (flatten) into a single OWL file per ontology" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/download/flatten-ontologies.sh  -l ${DOWNLOADED_ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY} -m ${MAVEN} -o ${FLATTENED_ONTOLOGY_LIST_FILE} -e ${FLATTEN_ERROR_FILE} -s ${STATUS_DIRECTORY} -z ${CODE_BASE_DIRECTORY}" >> ${SCRIPT_FILE}
printf "\n\n### for each flattened ontology file, generate the md5 message digest" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/download/checksum-gen-ontologies.sh -l ${FLATTENED_ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY} -c ${CHECKSUM_BIN}" >> ${SCRIPT_FILE}
printf "\n\n### create a list of ontologies that are new or have changed from the previously downloaded version" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/download/create-modified-ontology-list.sh -l ${FLATTENED_ONTOLOGY_LIST_FILE} -d ${DOWNLOAD_DIRECTORY} -b ${BASE_DIRECTORY}" >> ${SCRIPT_FILE}
