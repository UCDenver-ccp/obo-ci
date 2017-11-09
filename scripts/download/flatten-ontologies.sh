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
}

while getopts "d:l:m:o:e:h" OPTION; do
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
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${DOWNLOAD_DIRECTORY} || -z ${ONTOLOGY_LIST_FILE} || -z ${MAVEN} || -z ${FLATTENED_ONTOLOGY_LIST_FILE} || -z ${FLATTEN_ERROR_FILE} ]]; then
	echo "missing input arguments!!!!!"
	echo "work directory: ${DOWNLOAD_DIRECTORY}"
	echo "ontology list file: ${ONTOLOGY_LIST_FILE}"
	echo "path to Maven binary: ${MAVEN}"
	echo "path to output file listing ontologies that were successfully flattened: ${FLATTENED_ONTOLOGY_LIST_FILE}"
	echo "path to output file listing ontologies that were unable to be flattened: ${FLATTEN_ERROR_FILE}"
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

exit_code=0
for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  url=${URLs[$index]}
  # remove any duplicate forward slashes from the directory path
  dir=$(echo "${DOWNLOAD_DIRECTORY}/ontologies/${id}" | sed 's/\/\//\//g')
  ont_file="${dir}/${id}.owl"
  flat_ont_file="${dir}/${id}_flat.owl"

  echo "flattening ${ont_file} into ${flat_ont_file}"

  ${CURRENT_DIR}/flatten.sh -i ${ont_file} -o ${flat_ont_file} -m ${MAVEN}
  e=$?
  if [ ${e} == 0 ]; then
    echo "${id},${url}" >> ${FLATTENED_ONTOLOGY_LIST_FILE}
  else
    echo "${id},${url}" >> ${FLATTEN_ERROR_FILE}
    mv ${dir} "${dir}_FLAT_ERROR"
  fi
done

exit ${exit_code}