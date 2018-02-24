#!/bin/bash -e

# Download and preprocess all ontologies in the OBOFoundry.org catalog
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <work directory>]: MUST BE ABSOLUTE PATH. The directory where all generated/downloaded files will be stored."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-i <ontology id>]: Identifier of the ontology to download."
    echo "  [-u <ontology url>]: URL of the ontology to download."
    echo "  [-c <md5sum>]: MUST BE ABSOLUTE PATH. The path to the md5sum command."
    echo "  [-z <code base directory>]: MUST BE ABSOLUTE PATH. Path to the base directory where this project has been downloaded."
    echo "  [-k <run command>]: [OPTIONAL] The command used to run the generated scripts. Default = '', but could be something like 'qsub'"
    echo "  [-a <script header file>]: MUST BE ABSOLUTE PATH. [OPTIONAL] File containing header for the script."
    echo "  [-t <script file>]: MUST BE ABSOLUTE PATH. The path to the script file created by this script."

    ### header arguments
    echo "  [-n <job name>]: OPTIONALLY USED IN HEADER. Job name; will replace JOB_NAME in header file."
    echo "  [-e <email>]: OPTIONALLY USED IN HEADER. Your email address; will replace YOUR_EMAIL in header file."
    echo "  [-y <job log directory>]: OPTIONALLY USED IN HEADER. Job log directory; will replace JOB_LOG_DIRECTORY in header file."

}

while getopts "d:m:i:u:c:a:k:t:n:e:y:z:h" OPTION; do
    case ${OPTION} in
        # The work directory where all intermediate files are stored
        d) WORK_DIRECTORY=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # The ontology id to download
        i) ONT_ID=$OPTARG
           ;;
        # The ontology URL to download
        u) ONT_URL=$OPTARG
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

if [[ -z ${WORK_DIRECTORY} || -z ${MAVEN} || -z ${ONT_ID} || -z ${ONT_URL} \
|| -z ${SCRIPT_FILE} || -z ${CODE_BASE_DIRECTORY} || -z ${CHECKSUM_BIN} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "work directory: ${WORK_DIRECTORY}"
	echo "path to the Apache Maven binary: ${MAVEN}"
	echo "ontology id: ${ONT_ID}"
	echo "ontology url: ${ONT_URL}"
	echo "script file: ${SCRIPT_FILE}"
	echo "checksum binary: ${CHECKSUM_BIN}"
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

### make the ontology id part of the job name
HEADER_JOB_NAME="${HEADER_JOB_NAME}_${ONT_ID}"
### add the header to the script file if one has been specified
. ${CODE_BASE_DIRECTORY}/scripts/util/handle_header.bash

printf "\n###\n### This script will download the Open Biomedical Ontologies, validate the downloads as RDF, and process all imports for each ontology.\n###\n" >> ${SCRIPT_FILE}
printf "\n### clean the download directory and create other directories as needed" >> ${SCRIPT_FILE}
printf "\n\n# Reset BASH time counter" >> ${SCRIPT_FILE}
printf "\nSECONDS=0" >> ${SCRIPT_FILE}
printf "\n\n### download each ontology" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/download/download-ontology.sh -i ${ONT_ID} -u ${ONT_URL} -d ${DOWNLOAD_DIRECTORY} -s ${STATUS_DIRECTORY_INDIVIDUAL} -m ${MAVEN} -z ${CODE_BASE_DIRECTORY} -l ${LOG_DIRECTORY_DOWNLOAD}" >> ${SCRIPT_FILE}
printf "\n\n### for each ontology, download all owl:imports and consolidate (flatten) into a single OWL file per ontology" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/download/flatten-ontology.sh  -i ${ONT_ID} -d ${DOWNLOAD_DIRECTORY} -m ${MAVEN} -s ${STATUS_DIRECTORY_INDIVIDUAL} -z ${CODE_BASE_DIRECTORY} -l ${LOG_DIRECTORY_DOWNLOAD}" >> ${SCRIPT_FILE}
printf "\n\n### for each flattened ontology file, generate the md5 message digest" >> ${SCRIPT_FILE}
printf "\n${CODE_BASE_DIRECTORY}/scripts/download/checksum-gen-ontology.sh -i ${ONT_ID} -s ${STATUS_DIRECTORY_INDIVIDUAL} -d ${DOWNLOAD_DIRECTORY} -c ${CHECKSUM_BIN}" >> ${SCRIPT_FILE}
printf "\n\n### output run time in seconds" >> ${SCRIPT_FILE}
printf "\n\nprintf \"Script runtime in seconds: \${SECONDS}\"" >> ${SCRIPT_FILE}
