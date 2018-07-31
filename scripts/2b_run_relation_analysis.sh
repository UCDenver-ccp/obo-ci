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

### remove trailing slash from CODE_BASE_DIRECTORY if it exists
case "${CODE_BASE_DIRECTORY}" in
    */)
    CODE_BASE_DIRECTORY=${CODE_BASE_DIRECTORY%?}
    ;;
esac

### define directories that will be used in the scripts
. ${CODE_BASE_DIRECTORY}/scripts/util/define_directories.bash

# ensure the slurm log directory exists
if [[ -n ${HEADER_JOB_LOG_DIRECTORY} ]]; then
    mkdir -p ${HEADER_JOB_LOG_DIRECTORY}
fi


IDs=( $(awk -F, '{print $1}' ${MODIFIED_ONTOLOGY_LIST_FILE}) )
for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  SCRIPT_FILE="${SCRIPT_DIRECTORY_RELATION_ANALYSIS}/${id}.relation_extraction.sh"
  if [[ -z ${HEADER_FILE} ]]; then
    ${CODE_BASE_DIRECTORY}/scripts/relation_analyses/relation-extraction-script-gen.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -i ${id} -t ${SCRIPT_FILE} -z ${CODE_BASE_DIRECTORY} -l ${LOG_DIRECTORY_CLASSIFY}
  else
    ${CODE_BASE_DIRECTORY}/scripts/relation_analyses/relation-extraction-script-gen.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -i ${id} -t ${SCRIPT_FILE} -a ${HEADER_FILE} -n ${HEADER_JOB_NAME} -e ${HEADER_EMAIL} -y ${HEADER_JOB_LOG_DIRECTORY} -z ${CODE_BASE_DIRECTORY} -l ${LOG_DIRECTORY_CLASSIFY}
  fi
  chmod 755 ${SCRIPT_FILE}
done

# submit each generated script
for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  SCRIPT_FILE="${SCRIPT_DIRECTORY_RELATION_ANALYSIS}/${id}.relation_extraction.sh"
  echo "Submitting ${SCRIPT_FILE}..."
  #${RUN_CMD} ${SCRIPT_FILE}
  #sleep 1
done
