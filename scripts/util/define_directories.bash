
### remove trailing slash from WORK_DIRECTORY if it exists
case "${WORK_DIRECTORY}" in
    */)
    WORK_DIRECTORY=${WORK_DIRECTORY%?}
    ;;
esac

DOWNLOAD_DIRECTORY="${WORK_DIRECTORY}/download"
BASE_DIRECTORY="${WORK_DIRECTORY}/base"

STATUS_DIRECTORY="${WORK_DIRECTORY}/status"
STATUS_DIRECTORY_INDIVIDUAL="${WORK_DIRECTORY}/status/individual"
STATUS_DIRECTORY_PAIRS="${WORK_DIRECTORY}/status/pairs"

LOG_DIRECTORY="${WORK_DIRECTORY}/log"
LOG_DIRECTORY_DOWNLOAD="${WORK_DIRECTORY}/log/download"
LOG_DIRECTORY_CLASSIFY="${WORK_DIRECTORY}/log/classify"
LOG_DIRECTORY_CLASSIFY_PAIRS="${WORK_DIRECTORY}/log/classify-pairs"
LOG_DIRECTORY_CHECKS="${WORK_DIRECTORY}/log/checks"
LOG_DIRECTORY_CHECKS_PAIRS="${WORK_DIRECTORY}/log/checks-pairs"

SCRIPT_DIRECTORY="${WORK_DIRECTORY}/scripts"
SCRIPT_DIRECTORY_DOWNLOAD="${WORK_DIRECTORY}/scripts/download"
SCRIPT_DIRECTORY_CLASSIFY="${WORK_DIRECTORY}/scripts/classify"
SCRIPT_DIRECTORY_CLASSIFY_PAIRS="${WORK_DIRECTORY}/scripts/classify-pairs"
SCRIPT_DIRECTORY_CHECKS="${WORK_DIRECTORY}/scripts/checks"
SCRIPT_DIRECTORY_CHECKS_PAIRS="${WORK_DIRECTORY}/scripts/checks-pairs"

ONTOLOGY_LIST_FILE="${WORK_DIRECTORY}/ontologies.available.list"
MODIFIED_ONTOLOGY_LIST_FILE="${WORK_DIRECTORY}/ontologies.modified.list"
PAIRS_TO_PROCESS_FILE="${WORK_DIRECTORY}/ontologies.pairs.list"

# remove any duplicate slashes in file paths
DOWNLOAD_DIRECTORY=$(echo "${DOWNLOAD_DIRECTORY}" | sed 's/\/\//\//g')
BASE_DIRECTORY=$(echo "${BASE_DIRECTORY}" | sed 's/\/\//\//g')
STATUS_DIRECTORY=$(echo "${STATUS_DIRECTORY}" | sed 's/\/\//\//g')
LOG_DIRECTORY=$(echo "${LOG_DIRECTORY}" | sed 's/\/\//\//g')
ONTOLOGY_LIST_FILE=$(echo "${ONTOLOGY_LIST_FILE}" | sed 's/\/\//\//g')

### remove any trailing slash from the code base directory
case "${CODE_BASE_DIRECTORY}" in
    */)
    CODE_BASE_DIRECTORY=${CODE_BASE_DIRECTORY%?}
    ;;
esac