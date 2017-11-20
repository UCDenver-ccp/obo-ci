#!/bin/bash

# Uses the OWLTools library (https://github.com/owlcollab/owltools)
# to consolidate an ontology and all of its imports into a single OWL file.
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <download directory>]: MUST BE ABSOLUTE PATH. The base directory where all intermediate files will be stored."
    echo "  [-l <ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs to be downloaded."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-o <flattened ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs that were successfully flattened."
    echo "  [-e <flatten error file>]: MUST BE ABSOLUTE PATH. A file used to record errors when flattening ontology imports."
    echo "  [-s <ontology status directory>]: MUST BE ABSOLUTE PATH. The path to a directory where json files indicating ontology status are to be written."
}

while getopts "d:l:m:o:e:s:h" OPTION; do
    case ${OPTION} in
        # The work directory
        d) DOWNLOAD_DIRECTORY=$OPTARG
           ;;
        # The ontology list file (id,url pairs)
        l) ONTOLOGY_LIST_FILE=$OPTARG
           ;;
        # The ontology list file (id,url pairs) to record successful ontology flattening of imports
        o) FLATTENED_ONTOLOGY_LIST_FILE=$OPTARG
           ;;
        # A file to record errors
        e) FLATTEN_ERROR_FILE=$OPTARG
           ;;
        # A directory where ontology status json will be written
        s) STATUS_DIR=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${DOWNLOAD_DIRECTORY} || -z ${ONTOLOGY_LIST_FILE} || -z ${MAVEN} \
   || -z ${FLATTENED_ONTOLOGY_LIST_FILE} || -z ${FLATTEN_ERROR_FILE} || -z ${STATUS_DIR} ]]; then
	echo "missing input arguments!!!!!"
	echo "work directory: ${DOWNLOAD_DIRECTORY}"
	echo "ontology list file: ${ONTOLOGY_LIST_FILE}"
	echo "path to Maven binary: ${MAVEN}"
	echo "path to output file listing ontologies that were successfully flattened: ${FLATTENED_ONTOLOGY_LIST_FILE}"
	echo "path to output file listing ontologies that were unable to be flattened: ${FLATTEN_ERROR_FILE}"
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
> ${FLATTENED_ONTOLOGY_LIST_FILE}
> ${FLATTEN_ERROR_FILE}

LOG_DIRECTORY=${STATUS_DIR}/log
exit_code=0
for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  url=${URLs[$index]}
  # remove any duplicate forward slashes from the directory path
  dir=$(echo "${DOWNLOAD_DIRECTORY}/ontologies/${id}" | sed 's/\/\//\//g')
  ont_file="${dir}/${id}.owl"
  flat_ont_file="${dir}/${id}_flat.owl"
  LOG_FILE="${LOG_DIRECTORY}/${id}_flat.log"

  echo "flattening ${ont_file} into ${flat_ont_file}"
  ${CURRENT_DIR}/flatten.sh -i ${ont_file} -o ${flat_ont_file} -m ${MAVEN} -g ${LOG_FILE}
  e=$?
  cp scripts/template.json ${STATUS_DIR}/${id}_flat.json
  sed -i '' 's/\"id\": null,/\"id\": \"'"${id}"'\",/' "${STATUS_DIR}/${id}_flat.json"
  # populate the template json with the path to the download log file
  pattern="[/]"
  escaped_log_file="${LOG_FILE//$pattern/\/}"
  sed -i '' 's/\"flat_log\": null,/\"flat_log\": \"'"${escaped_log_file}"'\",/' "${STATUS_DIR}/${id}_flat.json"

  if [ ${e} == 0 ]; then
    echo "${id},${url}" >> ${FLATTENED_ONTOLOGY_LIST_FILE}
    sed -i '' 's/\"flat\": null,/\"flat\": true,/' "${STATUS_DIR}/${id}_flat.json"
  else
    echo "${id},${url}" >> ${FLATTEN_ERROR_FILE}
    sed -i '' 's/\"flat\": null,/\"flat\": false,/' "${STATUS_DIR}/${id}_flat.json"
  fi
done

exit ${exit_code}