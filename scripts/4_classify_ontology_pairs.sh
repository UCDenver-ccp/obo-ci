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

#${CODE_BASE_DIRECTORY}/scripts/classify/pairwise/pair-gen.sh -l ${MODIFIED_ONTOLOGY_LIST_FILE} -a ${ONTOLOGY_LIST_FILE} -o ${PAIRS_TO_PROCESS_FILE} -d ${BASE_DIRECTORY}

# for each line in the pair file, create a run/submission script
ID1s=( $(awk -F, '{print $1}' ${PAIRS_TO_PROCESS_FILE}) )
ID2s=( $(awk -F, '{print $2}' ${PAIRS_TO_PROCESS_FILE}) )
for index in ${!ID1s[*]}; do
  id1=${ID1s[$index]}
  id2=${ID2s[$index]}
  SCRIPT_FILE="${SCRIPT_DIRECTORY_CLASSIFY_PAIRS}/${id1}_${id2}.elk.sh"
  if [[ -z ${HEADER_FILE} ]]; then
    ${CODE_BASE_DIRECTORY}/scripts/classify/incoherent-query-script-gen.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -i ${id1} -x ${id2} -r elk -s ${STATUS_DIRECTORY_PAIRS} -t ${SCRIPT_FILE} -z ${CODE_BASE_DIRECTORY} -l ${LOG_DIRECTORY_CLASSIFY_PAIRS}
  else
    ${CODE_BASE_DIRECTORY}/scripts/classify/incoherent-query-script-gen.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -i ${id1} -x ${id2} -r elk -s ${STATUS_DIRECTORY_PAIRS} -t ${SCRIPT_FILE} -a ${HEADER_FILE} -n ${HEADER_JOB_NAME} -e ${HEADER_EMAIL} -y ${HEADER_JOB_LOG_DIRECTORY} -z ${CODE_BASE_DIRECTORY} -l ${LOG_DIRECTORY_CLASSIFY_PAIRS}
  fi
  chmod 755 ${SCRIPT_FILE}
  ELK_STATUS_FILE="${STATUS_DIRECTORY_PAIRS}/${id1}+${id2}_elk.json"
  if [ ! -f ${ELK_STATUS_FILE} ]; then
      ${RUN_CMD} ${SCRIPT_FILE}
  fi

  SCRIPT_FILE="${SCRIPT_DIRECTORY_CLASSIFY_PAIRS}/${id1}_${id2}.hermit.sh"
  if [[ -z ${HEADER_FILE} ]]; then
    ${CODE_BASE_DIRECTORY}/scripts/classify/incoherent-query-script-gen.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -i ${id1} -x ${id2} -r hermit -s ${STATUS_DIRECTORY_PAIRS} -t ${SCRIPT_FILE} -z ${CODE_BASE_DIRECTORY} -l ${LOG_DIRECTORY_CLASSIFY_PAIRS}
  else
    ${CODE_BASE_DIRECTORY}/scripts/classify/incoherent-query-script-gen.sh -b ${BASE_DIRECTORY} -m ${MAVEN} -i ${id1} -x ${id2} -r hermit -s ${STATUS_DIRECTORY_PAIRS} -t ${SCRIPT_FILE} -a ${HEADER_FILE} -n ${HEADER_JOB_NAME} -e ${HEADER_EMAIL} -y ${HEADER_JOB_LOG_DIRECTORY} -z ${CODE_BASE_DIRECTORY} -l ${LOG_DIRECTORY_CLASSIFY_PAIRS}
  fi
  chmod 755 ${SCRIPT_FILE}
  HERMIT_STATUS_FILE="${STATUS_DIRECTORY_PAIRS}/${id1}+${id2}_hermit.json"
  if [ ! -f ${HERMIT_STATUS_FILE} ]; then
      ${RUN_CMD} ${SCRIPT_FILE}
      sleep 1
  fi
done

## run/submit each generated script if the corresponding status file does not yet exist
#for index in ${!ID1s[*]}; do
#  id1=${ID1s[$index]}
#  id2=${ID2s[$index]}
#
#  ELK_STATUS_FILE="${STATUS_DIRECTORY_PAIRS}/${id1}+${id2}_elk.json"
#  if [ ! -f ${ELK_STATUS_FILE} ]; then
#      SCRIPT_FILE="${SCRIPT_DIRECTORY_CLASSIFY_PAIRS}/${id1}_${id2}.elk.sh"
#      ${RUN_CMD} ${SCRIPT_FILE}
#      sleep 1
#  fi
#  HERMIT_STATUS_FILE="${STATUS_DIRECTORY_PAIRS}/${id1}+${id2}_hermit.json"
#  if [ ! -f ${HERMIT_STATUS_FILE} ]; then
#      SCRIPT_FILE="${SCRIPT_DIRECTORY_CLASSIFY_PAIRS}/${id1}_${id2}.hermit.sh"
#      ${RUN_CMD} ${SCRIPT_FILE}
#      sleep 1
#  fi
#done







