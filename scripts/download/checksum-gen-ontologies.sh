#!/bin/bash -e

# Creates a file containing the message digest for each flattened ontology file.
# Any algorithm can be used, e.g. md5sum
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <work directory>]: MUST BE ABSOLUTE PATH. The base directory where all intermediate files will be stored."
    echo "  [-l <ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs to be downloaded."
    echo "  [-m <md5sum>]: MUST BE ABSOLUTE PATH. The path to the md5sum command."
}

while getopts "d:l:c:h" OPTION; do
    case ${OPTION} in
        # The work directory
        d) WORK_DIRECTORY=$OPTARG
           ;;
        # The ontology list file (id,url pairs)
        l) ONTOLOGY_LIST_FILE=$OPTARG
           ;;
        # The path to the Apache Maven command
        c) CHECKSUM_BIN=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${WORK_DIRECTORY} || -z ${ONTOLOGY_LIST_FILE} || -z ${CHECKSUM_BIN} ]]; then
	echo "missing input arguments!!!!!"
	echo "work directory: ${WORK_DIRECTORY}"
	echo "ontology list file: ${ONTOLOGY_LIST_FILE}"
	echo "path to checksum binary: ${CHECKSUM_BIN}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

IDs=( $(awk -F, '{print $1}' ${ONTOLOGY_LIST_FILE}) )
exit_code=0
for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  # remove any duplicate forward slashes from the directory path
  dir=$(echo "${WORK_DIRECTORY}/ontologies/${id}" | sed 's/\/\//\//g')
  ont_file="${dir}/${id}_flat.owl"

  echo "generating checksum for ${ont_file} using ${CHECKSUM_BIN}"

  ${CHECKSUM_BIN} ${ont_file} > ${ont_file}.md5
  e=$?
  if [ ${e} -ne 0 ]; then
    exit_code=${e}
  fi
done

exit ${exit_code}