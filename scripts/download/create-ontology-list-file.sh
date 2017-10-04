#!/bin/bash -e

# jq is used to extract each OWL file 'product' for each ontology.
# Obsolete ontologies are excluded, however there are several development
# OWL files that are included b/c they cannot be reliably excluded programmatically.
#
# Output is a comma-delimited file with 2 columns:
# 1) A unique identifier for the OWL file
# 2) The URL for the OWL file

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-l <ontology list file>]: MUST BE ABSOLUTE PATH. The file into which to place the list of id,ontology pairs."
    echo "  [-j <jq command path>]: MUST BE ABSOLUTE PATH. The path to the jq command."
}

while getopts "l:j:h" OPTION; do
    case $OPTION in
        # The output file (will contain input ontology + content of all imports)
        l) OUTPUT_FILE=$OPTARG
           ;;
        # The jq command path
        j) JQ_BIN=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${OUTPUT_FILE} || -z ${JQ_BIN} ]]; then
	echo "missing input arguments!!!!!"
	echo "Ontology list file: ${OUTPUT_FILE}"
	echo "jq command: ${JQ_BIN}"
	print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

# make the directory for the ontology list file if it doesn't exist
dir=$(dirname ${OUTPUT_FILE})
if ! [[ -d ${dir} ]]; then
    mkdir -p ${dir}
fi

curl http://obofoundry.org/registry/ontologies.jsonld | ${JQ_BIN} -r '. | .ontologies[] | select(.is_obsolete != true) | select(.products != null) | .products[] | select (.ontology_purl | endswith("owl")) | [.id, .ontology_purl] | @csv' | sed 's/"//g' | awk -F, 'BEGIN {OFS=","} {gsub(/\//,"_",$1); print}' |  awk -F, 'BEGIN {OFS=","} {gsub(/\.owl/,"",$1); print}' > ${OUTPUT_FILE}
