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

if [[ -z ${WORK_DIRECTORY} || -z ${MAVEN} || -z ${CHECKSUM_BIN} || -z ${CODE_BASE_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "work directory: ${WORK_DIRECTORY}"
	echo "path to the Apache Maven binary: ${MAVEN}"
	echo "path to the md5sum command: ${CHECKSUM_BIN}"
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

# This script first downloads all of the OBOs and creates a flattened (all imports included) version of each
# owl file. It then creates a md5 hash of that flattened owl file and uses the hash to determine if

# for each line in the ontology list file, create a download script

IDs=( $(awk -F, '{print $1}' ${ONTOLOGY_LIST_FILE}) )
URLs=( $(awk -F, '{print $2}' ${ONTOLOGY_LIST_FILE}) )
for index in ${!IDs[*]}; do
    id=${IDs[$index]}
    url=${URLs[$index]}
    SCRIPT_FILE="${SCRIPT_DIRECTORY_DOWNLOAD}/${id}.download.sh"

    ### create the download script
    if [[ -z ${HEADER_FILE} ]]; then
        ${CODE_BASE_DIRECTORY}/scripts/download/download-ontology-script-gen.sh -d ${WORK_DIRECTORY} -m ${MAVEN} -i ${id} -u ${url} -c ${CHECKSUM_BIN} -t ${SCRIPT_FILE} -z ${CODE_BASE_DIRECTORY}
    else
        ${CODE_BASE_DIRECTORY}/scripts/download/download-ontology-script-gen.sh -d ${WORK_DIRECTORY} -m ${MAVEN} -i ${id} -u ${url} -c ${CHECKSUM_BIN} -t ${SCRIPT_FILE} -a ${HEADER_FILE} -n ${HEADER_JOB_NAME} -e ${HEADER_EMAIL} -y ${HEADER_JOB_LOG_DIRECTORY} -z ${CODE_BASE_DIRECTORY}
    fi
    chmod 755 ${SCRIPT_FILE}
done

# submit each generated script
for index in ${!IDs[*]}; do
      id=${IDs[$index]}
      SCRIPT_FILE="${SCRIPT_DIRECTORY_DOWNLOAD}/${id}.download.sh"
      ${RUN_CMD} ${SCRIPT_FILE}
done