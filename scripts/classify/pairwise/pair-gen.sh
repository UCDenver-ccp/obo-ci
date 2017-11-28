#!/bin/bash -e

#
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-l <ontology files to update list>]: MUST BE ABSOLUTE PATH. The list of ontology files to process."
    echo "  [-a <available ontology files list>]: MUST BE ABSOLUTE PATH. The list of all available ontology files."
    echo "  [-o <output file>]: MUST BE ABSOLUTE PATH. Path to the output file that will contain the list of ontology pairs to process."
}

while getopts "l:a:o:h" OPTION; do
    case $OPTION in
        # The list of ontology files to process
        l) ONT_FILE_LIST=$OPTARG
           ;;
        # The list of all available ontology files
        a) ALL_ONT_LIST=$OPTARG
           ;;
        # The path to the output file
        o) OUTPUT_FILE=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${ONT_FILE_LIST} || -z ${ALL_ONT_LIST} || -z ${OUTPUT_FILE} ]]; then
	echo "missing input arguments!!!!!"
	echo "ontology file list: ${ONT_FILE_LIST}"
	echo "all available ontologies list: ${ALL_ONT_LIST}"
	echo "output file: ${OUTPUT_FILE}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi


IDs=( $(awk -F, '{print $1}' ${ONT_FILE_LIST}) )
ALL_IDs=( $(awk -F, '{print $1}' ${ALL_ONT_LIST}) )

> ${OUTPUT_FILE}.tmp

for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  for ind in ${!ALL_IDs[*]}; do
    id2=${IDs[$ind]}
    # exclude cases where an ontology is paired with itself
    if [ "${id}" != "${id2}" ]; then
        # sort the line b/c order does not matter and we can exclude redundant pairs more easily if the lines are sorted
        echo "${id} ${id2}" | tr ' ' '\n' | sort | tr '\n' ',' >> ${OUTPUT_FILE}.tmp
        echo '' >> ${OUTPUT_FILE}.tmp
    fi
  done
done

# remove redundant pairings
cat ${OUTPUT_FILE}.tmp | sort | uniq > ${OUTPUT_FILE}
rm ${OUTPUT_FILE}.tmp
