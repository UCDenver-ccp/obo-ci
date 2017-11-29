#!/bin/bash -e

# Creates a file containing the message digest for each flattened ontology file.
# Any algorithm can be used, e.g. md5sum
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <download directory>]: MUST BE ABSOLUTE PATH. The base directory where all intermediate files will be stored."
    echo "  [-i <ontology id>]: Identifier of the ontology to download."
    echo "  [-c <md5sum>]: MUST BE ABSOLUTE PATH. The path to the md5sum command."
    echo "  [-s <ontology status directory>]: MUST BE ABSOLUTE PATH. The path to a directory where json files indicating ontology status are to be written."
}

while getopts "d:i:c:s:h" OPTION; do
    case ${OPTION} in
        # The work directory
        d) DOWNLOAD_DIRECTORY=$OPTARG
           ;;
        # The ontology id to download
        i) ONT_ID=$OPTARG
           ;;
        # The path to the Apache Maven command
        c) CHECKSUM_BIN=$OPTARG
           ;;
        # A directory where ontology status json will be written
        s) STATUS_DIR=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${DOWNLOAD_DIRECTORY} || -z ${ONT_ID} || -z ${CHECKSUM_BIN} || -z ${STATUS_DIR} ]]; then
	echo "missing input arguments!!!!!"
	echo "download directory: ${DOWNLOAD_DIRECTORY}"
	echo "ontology id: ${ONTOLOGY_ID}"
	echo "path to checksum binary: ${CHECKSUM_BIN}"
	echo "ontology status directory: ${STATUS_DIR}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

### only compute the checksum if the flattening step succeeded
FLATTEN_STATUS_FILE="${STATUS_DIR}/${ONT_ID}_flat.json"
if grep -q "\"flat\": true," "${FLATTEN_STATUS_FILE}"; then
    # remove any duplicate forward slashes from the directory path
    dir=$(echo "${DOWNLOAD_DIRECTORY}/ontologies/${ONT_ID}" | sed 's/\/\//\//g')
    ont_file="${dir}/${ONT_ID}_flat.owl"

    echo "generating checksum for ${ont_file} using ${CHECKSUM_BIN}"
    ${CHECKSUM_BIN} ${ont_file} > ${ont_file}.md5
    e=$?
    if [ ${e} -ne 0 ]; then
        exit_code=${e}
    fi
fi
