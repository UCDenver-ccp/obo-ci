#!/bin/bash

# Given an ontology file, attempt to classify all ontologies using the specified reasoner.
# This script uses the OWLTools library (https://github.com/owlcollab/owltools)
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-b <base directory>]: MUST BE ABSOLUTE PATH. The base directory where the ontologies have previously been downloaded."
    echo "  [-l <ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs to be downloaded."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-r <reasoner name>]: 'elk' or 'hermit'"
    echo "  [-o <classified ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs that were successfully classified."
    echo "  [-e <classify error file>]: MUST BE ABSOLUTE PATH. A file used to record classification errors."
    echo "  [-s <ontology status directory>]: MUST BE ABSOLUTE PATH. The path to a directory where json files indicating ontology status are to be written."
}

while getopts "b:l:m:r:o:e:s:h" OPTION; do
    case ${OPTION} in
        # The work directory
        b) BASE_DIRECTORY=$OPTARG
           ;;
        # The ontology list file (id,url pairs)
        l) ONTOLOGY_LIST_FILE=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
           # The name of the reasoner to use
        r) REASONER_NAME=$OPTARG
           ;;
        # The ontology list file (id,url pairs)
        o) CLASSIFIED_ONTOLOGY_LIST_FILE=$OPTARG
           ;;
        # A file to record download errors
        e) CLASSIFY_ERROR_FILE=$OPTARG
           ;;
        # A directory where ontology status json will be written
        s) STATUS_DIR=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${BASE_DIRECTORY} || -z ${ONTOLOGY_LIST_FILE} || -z ${REASONER_NAME} || -z ${MAVEN} \
     || -z ${CLASSIFIED_ONTOLOGY_LIST_FILE} || -z ${CLASSIFY_ERROR_FILE} || -z ${STATUS_DIR} ]]; then
	echo "missing input arguments!!!!!"
	echo "base directory: ${BASE_DIRECTORY}"
	echo "ontology list file: ${ONTOLOGY_LIST_FILE}"
	echo "reasoner: ${REASONER_NAME}"
	echo "maven: ${MAVEN}"
	echo "classified ontology list file: ${CLASSIFIED_ONTOLOGY_LIST_FILE}"
	echo "classify error file: ${CLASSIFY_ERROR_FILE}"
	echo "ontology status directory: ${STATUS_DIR}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

IDs=( $(awk -F, '{print $1}' ${ONTOLOGY_LIST_FILE}) )
URLs=( $(awk -F, '{print $2}' ${ONTOLOGY_LIST_FILE}) )
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
> ${CLASSIFIED_ONTOLOGY_LIST_FILE}
> ${CLASSIFY_ERROR_FILE}


exit_code=0
for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  url=${URLs[$index]}
  # remove any duplicate forward slashes from the directory path
  dir=$(echo "${BASE_DIRECTORY}/ontologies/${id}" | sed 's/\/\//\//g')
  owl_file="${dir}/${id}_flat.owl"
  output_file="${dir}/${id}_flat.inferred_${REASONER_NAME}.owl"
  echo "classifying ${owl_file}..."

  LOG_DIRECTORY=${STATUS_DIR}/log
  LOG_FILE=${LOG_DIRECTORY}/${id}_${REASONER_NAME}.log
  ${CURRENT_DIR}/classify.sh -i ${owl_file} -o ${output_file}  -r ${REASONER_NAME} -m ${MAVEN} -g ${LOG_FILE}
  e=$?
  cp scripts/template.json ${STATUS_DIR}/${id}_${REASONER_NAME}.json
  sed -i '' 's/\"id\": null,/\"id\": \"'"${id}"'\",/' "${STATUS_DIR}/${id}_${REASONER_NAME}.json"
   # populate the template json with the path to the download log file
  pattern="[/]"
  escaped_log_file="${LOG_FILE//$pattern/\/}"
  sed -i '' 's/\"'"${REASONER_NAME}"'_log\": null,/\"'"${REASONER_NAME}"'_log\": \"'"${escaped_log_file}"'\",/' "${STATUS_DIR}/${id}_${REASONER_NAME}.json"
  if [ ${e} == 0 ]; then
    echo "${id},${url}" >> ${CLASSIFIED_ONTOLOGY_LIST_FILE}
    sed -i '' 's/\"'${REASONER_NAME}'\": null/\"'${REASONER_NAME}'\": true/' "${STATUS_DIR}/${id}_${REASONER_NAME}.json"
  else
    echo "${id},${url}" >> ${CLASSIFY_ERROR_FILE}
    sed -i '' 's/\"'${REASONER_NAME}'\": null/\"'${REASONER_NAME}'\": false/' "${STATUS_DIR}/${id}_${REASONER_NAME}.json"
  fi
done
