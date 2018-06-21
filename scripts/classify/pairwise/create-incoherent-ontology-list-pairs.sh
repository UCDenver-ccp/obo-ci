#!/bin/bash -e

# Creates a list of the ontology files that were observed to be incoherent by the reasoners
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-l <ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id1,id2 pairs. This should be the ontology pairs file."
    echo "  [-o <incoherent ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs where the ontology has been determined to be incoherent."
    echo "  [-s <ontology status directory>]: MUST BE ABSOLUTE PATH. The path to a directory where json files indicating ontology status are to be written."

}

while getopts "d:b:l:o:s:h" OPTION; do
    case ${OPTION} in
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

if [[ -z ${ONTOLOGY_LIST_FILE} || -z ${INCOHERENT_ONTOLOGY_LIST_FILE_PREFIX} || -z ${STATUS_DIR} ]]; then
	echo "missing input arguments!!!!!"
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

# reset the ontology_list_to_process file in case it already exists
> ${INCOHERENT_ONTOLOGY_LIST_FILE_ELK}
> ${INCOHERENT_ONTOLOGY_LIST_FILE_HERMIT}

ID1s=( $(awk -F, '{print $1}' ${PAIRS_TO_PROCESS_FILE}) )
ID2s=( $(awk -F, '{print $2}' ${PAIRS_TO_PROCESS_FILE}) )
for index in ${!ID1s[*]}; do
    id1=${ID1s[$index]}
    id2=${ID2s[$index]}
    elk_status_file=$(echo "${STATUS_DIR}/${id1}+${id2}_elk.json" | sed 's/\/\//\//g')
    hermit_status_file=$(echo "${STATUS_DIR}/${id1}+${id2}_hermit.json" | sed 's/\/\//\//g')

    echo "checking file: ${elk_status_file}"

    if grep -q '"elk": true,' ${elk_status_file}; then
        if grep -q '"elk_incoherent_count": 0,' ${elk_status_file}; then
        :
        else
           echo "${id1},${id2}," >> ${INCOHERENT_ONTOLOGY_LIST_FILE_ELK}
        fi
    fi

    echo "checking file: ${hermit_status_file}"

    if grep -q '"hermit": true,' ${hermit_status_file}; then
        if grep -q '"hermit_incoherent_count": 0,' ${hermit_status_file}; then
        :
        else
           echo "${id1},${id2}," >> ${INCOHERENT_ONTOLOGY_LIST_FILE_HERMIT}
        fi
    fi
done
