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

        ### header arguments
    echo "  [-n <job name>]: OPTIONALLY USED IN HEADER. Job name; will replace JOB_NAME in header file."
    echo "  [-e <email>]: OPTIONALLY USED IN HEADER. Your email address; will replace YOUR_EMAIL in header file."
    echo "  [-y <job log directory>]: OPTIONALLY USED IN HEADER. Job log directory; will replace JOB_LOG_DIRECTORY in header file."

}

while getopts "d:m:k:c:j:a:n:e:y:z:h" OPTION; do
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

if [[ -z ${WORK_DIRECTORY} || -z ${MAVEN} || -z ${JQ} || -z ${CHECKSUM_BIN} || -z ${CODE_BASE_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "work directory: ${WORK_DIRECTORY}"
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
LOG_DIRECTORY="${WORK_DIRECTORY}/status/log"
STATUS_DIRECTORY="${WORK_DIRECTORY}/status"
mkdir -p ${DOWNLOAD_DIRECTORY}
rm -Rf ${DOWNLOAD_DIRECTORY}
mkdir -p ${DOWNLOAD_DIRECTORY}
mkdir -p ${BASE_DIRECTORY}
mkdir -p ${STATUS_DIRECTORY}
mkdir -p ${LOG_DIRECTORY}

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


### remove any trailing slash from the code base directory
case "${CODE_BASE_DIRECTORY}" in
    */)
    CODE_BASE_DIRECTORY=${CODE_BASE_DIRECTORY%?}
    ;;
esac

# This script first downloads all of the OBOs and creates a flattened (all imports included) version of each
# owl file. It then creates a md5 hash of that flattened owl file and uses the hash to determine if
SCRIPT_DIRECTORY="${BASE_DIRECTORY}/scripts"
mkdir -p ${SCRIPT_DIRECTORY}
SCRIPT_FILE="${SCRIPT_DIRECTORY}/download.sh"

### create the download script
if [[ -z ${HEADER_FILE} ]]; then
    ${CODE_BASE_DIRECTORY}/scripts/download/download-ontology-script-gen.sh -d ${WORK_DIRECTORY} -m ${MAVEN} -j ${JQ} -c ${CHECKSUM_BIN} -t ${SCRIPT_FILE} -z ${CODE_BASE_DIRECTORY}
else
    ${CODE_BASE_DIRECTORY}/scripts/download/download-ontology-script-gen.sh -d ${WORK_DIRECTORY} -m ${MAVEN} -j ${JQ} -c ${CHECKSUM_BIN} -t ${SCRIPT_FILE} -a ${HEADER_FILE} -n ${HEADER_JOB_NAME} -e ${HEADER_EMAIL} -y ${HEADER_JOB_LOG_DIRECTORY} -z ${CODE_BASE_DIRECTORY}
fi
chmod 755 ${SCRIPT_FILE}

### run the download script using the optionally-specified run command
${RUN_CMD} ${SCRIPT_FILE}