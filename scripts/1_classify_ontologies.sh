#!/bin/bash -e

# Attempt to classify the downloaded ontologies
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <work directory>]: MUST BE ABSOLUTE PATH. The directory where all generated/downloaded files will be stored."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-z <code base directory>]: MUST BE ABSOLUTE PATH. Path to the base directory where this project has been downloaded."
    echo "  [-k <run command>]: [OPTIONAL] The command used to run the generated scripts. Default = '', but could be something like 'qsub'"
    echo "  [-a <script header file>]: MUST BE ABSOLUTE PATH. [OPTIONAL] File containing header for the script."

            ### header arguments
    echo "  [-n <job name>]: OPTIONALLY USED IN HEADER. Job name; will replace JOB_NAME in header file."
    echo "  [-e <email>]: OPTIONALLY USED IN HEADER. Your email address; will replace YOUR_EMAIL in header file."
    echo "  [-y <job log directory>]: OPTIONALLY USED IN HEADER. Job log directory; will replace JOB_LOG_DIRECTORY in header file."

}

while getopts "d:m:k:a:n:e:y:z:h" OPTION; do
    case ${OPTION} in
        # The work directory where all intermediate files are stored
        d) WORK_DIRECTORY=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
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

if [[ -z ${WORK_DIRECTORY} || -z ${MAVEN} || -z ${CODE_BASE_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "work directory: ${WORK_DIRECTORY}"
	echo "path to the Apache Maven binary: ${MAVEN}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

BASE_DIRECTORY="${WORK_DIRECTORY}/base"
STATUS_DIRECTORY="${WORK_DIRECTORY}/status"
LOG_DIRECTORY="${WORK_DIRECTORY}/status/log"
ONTOLOGY_LIST_FILE="${WORK_DIRECTORY}/ontologies.flat.list.to_process"

# remove any duplicate slashes in file paths
BASE_DIRECTORY=$(echo "${BASE_DIRECTORY}" | sed 's/\/\//\//g')
STATUS_DIRECTORY=$(echo "${STATUS_DIRECTORY}" | sed 's/\/\//\//g')
ONTOLOGY_LIST_FILE=$(echo "${ONTOLOGY_LIST_FILE}" | sed 's/\/\//\//g')
SCRIPT_DIRECTORY="${BASE_DIRECTORY}/scripts"
mkdir -p ${SCRIPT_DIRECTORY}

### remove any trailing slash from the code base directory
case "${CODE_BASE_DIRECTORY}" in
    */)
    CODE_BASE_DIRECTORY=${CODE_BASE_DIRECTORY%?}
    ;;
esac

# This script attempts to classify any downloaded ontology that has been determined to have changed since the previous download.

# for each line in the ontology list file, create a submission script for both elk and hermit

IDs=( $(awk -F, '{print $1}' ${ONTOLOGY_LIST_FILE}) )
for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  SCRIPT_FILE="${SCRIPT_DIRECTORY}/${id}.elk.sh"
  if [[ -z ${HEADER_FILE} ]]; then
    ${CODE_BASE_DIRECTORY}/scripts/classify/classify-ontology-script-gen.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -i ${id} -r elk -s ${STATUS_DIRECTORY} -t ${SCRIPT_FILE} -z ${CODE_BASE_DIRECTORY}
  else
    ${CODE_BASE_DIRECTORY}/scripts/classify/classify-ontology-script-gen.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -i ${id} -r elk -s ${STATUS_DIRECTORY} -t ${SCRIPT_FILE} -a ${HEADER_FILE} -n ${HEADER_JOB_NAME} -e ${HEADER_EMAIL} -y ${HEADER_JOB_LOG_DIRECTORY} -z ${CODE_BASE_DIRECTORY}
  fi
  chmod 755 ${SCRIPT_FILE}
  SCRIPT_FILE="${SCRIPT_DIRECTORY}/${id}.hermit.sh"
  if [[ -z ${HEADER_FILE} ]]; then
    ${CODE_BASE_DIRECTORY}/scripts/classify/classify-ontology-script-gen.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -i ${id} -r hermit -s ${STATUS_DIRECTORY} -t ${SCRIPT_FILE} -z ${CODE_BASE_DIRECTORY}
  else
    ${CODE_BASE_DIRECTORY}/scripts/classify/classify-ontology-script-gen.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -i ${id} -r hermit -s ${STATUS_DIRECTORY} -t ${SCRIPT_FILE} -a ${HEADER_FILE} -n ${HEADER_JOB_NAME} -e ${HEADER_EMAIL} -y ${HEADER_JOB_LOG_DIRECTORY} -z ${CODE_BASE_DIRECTORY}
  fi
  chmod 755 ${SCRIPT_FILE}
done

# submit each generated script
for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  SCRIPT_FILE="${SCRIPT_DIRECTORY}/${id}.elk.sh"
  ${RUN_CMD} ${SCRIPT_FILE}
  SCRIPT_FILE="${SCRIPT_DIRECTORY}/${id}.hermit.sh"
  ${RUN_CMD} ${SCRIPT_FILE}
done
