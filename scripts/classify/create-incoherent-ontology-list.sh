#!/bin/bash -e

# Creates a list of the ontology files that were observed to be incoherent by the reasoners
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <download directory>]: MUST BE ABSOLUTE PATH. The directory where all intermediate files will be stored."
    echo "  [-b <base directory>]: MUST BE ABSOLUTE PATH. The directory where all previously downloaded versions of the ontologies are stored."
    echo "  [-l <ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs. Typically the 'modified' ontology list file."
    echo "  [-o <incoherent ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs where the ontology has been determined to be incoherent."
    echo "  [-s <ontology status directory>]: MUST BE ABSOLUTE PATH. The path to a directory where json files indicating ontology status are to be written."

}

while getopts "d:b:l:o:s:h" OPTION; do
    case ${OPTION} in
        # The download directory
        d) DOWNLOAD_DIRECTORY=$OPTARG
           ;;
        # The base directory (where previous versions of the ontologies are stored)
        b) BASE_DIRECTORY=$OPTARG
           ;;
        # The ontology list file (id,url pairs)
        l) ONTOLOGY_LIST_FILE=$OPTARG
           ;;
        # The ontology list file (id,url pairs)
        o) INCOHERENT_ONTOLOGY_LIST_FILE_PREFIX=$OPTARG
           ;;
        # A directory where ontology status json will be written
        s) STATUS_DIR=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${DOWNLOAD_DIRECTORY} || -z ${ONTOLOGY_LIST_FILE} || -z ${INCOHERENT_ONTOLOGY_LIST_FILE_PREFIX} || -z ${BASE_DIRECTORY} || -z ${STATUS_DIR} ]]; then
	echo "missing input arguments!!!!!"
	echo "work directory: ${DOWNLOAD_DIRECTORY}"
	echo "ontology list file: ${ONTOLOGY_LIST_FILE}"
	echo "incoherent ontology list file prefix: ${INCOHERENT_ONTOLOGY_LIST_FILE_PREFIX}"
	echo "status dir: ${STATUS_DIR}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

INCOHERENT_ONTOLOGY_LIST_FILE_ELK=$(echo "${INCOHERENT_ONTOLOGY_LIST_FILE_PREFIX}.elk")
INCOHERENT_ONTOLOGY_LIST_FILE_HERMIT=$(echo "${INCOHERENT_ONTOLOGY_LIST_FILE_PREFIX}.hermit")

IDs=( $(awk -F, '{print $1}' ${ONTOLOGY_LIST_FILE}) )
URLs=( $(awk -F, '{print $2}' ${ONTOLOGY_LIST_FILE}) )
# reset the ontology_list_to_process file in case it already exists
> ${INCOHERENT_ONTOLOGY_LIST_FILE_ELK}
> ${INCOHERENT_ONTOLOGY_LIST_FILE_HERMIT}

for index in ${!IDs[*]}; do
    id=${IDs[$index]}
    url=${URLs[$index]}

    elk_status_file=$(echo "${STATUS_DIR}/${id}_elk.json" | sed 's/\/\//\//g')
    hermit_status_file=$(echo "${STATUS_DIR}/${id}_hermit.json" | sed 's/\/\//\//g')

    echo "ELK STATUS FILE: ${elk_status_file}"

    if grep -q '"elk_incoherent_count": 0,' ${elk_status_file}; then
    :
    else
       echo "${id},${url}" >> ${INCOHERENT_ONTOLOGY_LIST_FILE_ELK}
    fi

    if grep -q '"hermit_incoherent_count": 0,' ${hermit_status_file}; then
    :
    else
       echo "${id},${url}" >> ${INCOHERENT_ONTOLOGY_LIST_FILE_HERMIT}
    fi

done
