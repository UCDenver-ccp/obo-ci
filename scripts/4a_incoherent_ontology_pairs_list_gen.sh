#!/bin/bash -e

#
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-z <code base directory>]: MUST BE ABSOLUTE PATH. Path to the base directory where this project has been downloaded."
}

while getopts "d:z:h" OPTION; do
    case ${OPTION} in
        # The path to the directory where this project has been downloaded
        z) CODE_BASE_DIRECTORY=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${CODE_BASE_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

### remove trailing slash from CODE_BASE_DIRECTORY if it exists
case "${CODE_BASE_DIRECTORY}" in
    */)
    CODE_BASE_DIRECTORY=${CODE_BASE_DIRECTORY%?}
    ;;
esac

### define directories that will be used in the scripts
. ${CODE_BASE_DIRECTORY}/scripts/util/define_directories.bash

# TODO: modify this to work with the pairs
### create a list of ontologies that are new or have changed from the previously downloaded version
${CODE_BASE_DIRECTORY}/scripts/classify/pairwise/create-incoherent-ontology-list-pairs.sh -l ${PAIRS_TO_PROCESS_FILE} -o ${INCOHERENT_ONTOLOGY_PAIRS_LIST_FILE_PREFIX} -s ${STATUS_DIRECTORY_PAIRS}