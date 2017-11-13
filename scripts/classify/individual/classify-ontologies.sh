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
}

while getopts "b:l:m:r:o:e:h" OPTION; do
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
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${BASE_DIRECTORY} || -z ${ONTOLOGY_LIST_FILE} || -z ${REASONER_NAME} || -z ${MAVEN} || -z ${CLASSIFIED_ONTOLOGY_LIST_FILE} || -z ${CLASSIFY_ERROR_FILE} ]]; then
	echo "missing input arguments!!!!!"
	echo "base directory: ${BASE_DIRECTORY}"
	echo "ontology list file: ${ONTOLOGY_LIST_FILE}"
	echo "reasoner: ${REASONER_NAME}"
	echo "maven: ${MAVEN}"
	echo "classified ontology list file: ${CLASSIFIED_ONTOLOGY_LIST_FILE}"
	echo "classify error file: ${CLASSIFY_ERROR_FILE}"
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
  echo "downloading ${url} into directory ${dir}"

  ${CURRENT_DIR}/classify.sh -i ${owl_file} -o ${output_file}  -r ${REASONER_NAME} -m ${MAVEN}
  e=$?
  if [ ${e} == 0 ]; then
    echo "${id},${url}" >> ${CLASSIFIED_ONTOLOGY_LIST_FILE}
  else
    echo "${id},${url}" >> ${CLASSIFY_ERROR_FILE}
    mv ${dir} "${dir}_FLAT_ERROR"
  fi
done
