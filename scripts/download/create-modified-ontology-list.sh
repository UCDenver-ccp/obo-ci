#!/bin/bash -e

# Creates a list of the ontology files that have just been downloaded and flattened that are different
# from the version of the files that were downloaded previously.
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <download directory>]: MUST BE ABSOLUTE PATH. The directory where all intermediate files will be stored."
    echo "  [-b <base directory>]: MUST BE ABSOLUTE PATH. The directory where all previously downloaded versions of the ontologies are stored."
    echo "  [-l <ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs to be downloaded."

}

while getopts "d:b:l:h" OPTION; do
    case ${OPTION} in
        # The work directory
        d) DOWNLOAD_DIRECTORY=$OPTARG
           ;;
        # The base directory (where previous versions of the ontologies are stored)
        b) BASE_DIRECTORY=$OPTARG
           ;;
        # The ontology list file (id,url pairs)
        l) ONTOLOGY_LIST_FILE=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${DOWNLOAD_DIRECTORY} || -z ${ONTOLOGY_LIST_FILE} || -z ${BASE_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "work directory: ${DOWNLOAD_DIRECTORY}"
	echo "ontology list file: ${ONTOLOGY_LIST_FILE}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

IDs=( $(awk -F, '{print $1}' ${ONTOLOGY_LIST_FILE}) )
URLs=( $(awk -F, '{print $2}' ${ONTOLOGY_LIST_FILE}) )
ONTOLOGY_LIST_TO_PROCESS_FILE="${ONTOLOGY_LIST_FILE}.to_process"
# reset the ontology_list_to_process file in case it already exists
> ${ONTOLOGY_LIST_TO_PROCESS_FILE}
mkdir -p ${BASE_DIRECTORY}

exit_code=0
for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  url=${URLs[$index]}
  # remove any duplicate forward slashes from the directory path
  dload_dir=$(echo "${DOWNLOAD_DIRECTORY}/ontologies/${id}" | sed 's/\/\//\//g')
  dload_ont_file="${dload_dir}/${id}_flat.owl"
  dload_ont_file_md5="${dload_ont_file}.md5"

  base_dir=$(echo "${BASE_DIRECTORY}/ontologies/${id}" | sed 's/\/\//\//g')
  base_ont_file="${base_dir}/${id}_flat.owl"
  base_ont_file_md5="${base_ont_file}.md5"

  # if the base md5 file does not exist, then this is a new ontology (downloaded for the first time)
  if [ ! -f ${base_ont_file_md5} ]; then
    echo "new ontology detected: ${id}"
    # create the directory
    mkdir -p ${base_dir}
    # copy the new file and new md5 to replace the old version and add a line in the new ontology-file-to-process list file
    cp ${dload_ont_file} ${base_dir}
    cp ${dload_ont_file_md5} ${base_dir}
    echo "${id},${url}" >> ${ONTOLOGY_LIST_TO_PROCESS_FILE}
  fi

  # if the base md5 file does exist, then compare the two md5 files. If there is a difference, then
  # the newly downloaded ontology is a newer version
  if ! diff ${base_ont_file_md5} ${dload_ont_file_md5}; then
    echo "new ontology version detected: ${id}"
    # copy the new file and new md5 to replace the old version and add a line in the new ontology-file-to-process list file
    cp ${dload_ont_file} ${base_dir}
    cp ${dload_ont_file_md5} ${base_dir}
    echo "${id},${url}" >> ${ONTOLOGY_LIST_TO_PROCESS_FILE}
  fi

  e=$?
  if [ ${e} -ne 0 ]; then
    exit_code=${e}
  fi
done

exit ${exit_code}