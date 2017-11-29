#!/bin/bash

# Given an ontology file, download all imported ontologies and create
# a new file containing the source ontology and content of all imported
# ontologies. This script uses the OWLTools library (https://github.com/owlcollab/owltools)
#
# NOTE: input arguments must be absolute paths

function print_usage {
    echo "Usage:"
    echo "$(basename $0) [OPTIONS]"
    echo "  [-d <download directory>]: MUST BE ABSOLUTE PATH. The base directory where all intermediate files will be stored."
    echo "  [-i <ontology id>]: Identifier of the ontology to download."
    echo "  [-u <ontology url>]: URL of the ontology to download."
    echo "  [-s <ontology status directory>]: MUST BE ABSOLUTE PATH. The path to a directory where json files indicating ontology status are to be written."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-z <code base directory>]: MUST BE ABSOLUTE PATH. Path to the base directory where this project has been downloaded."
    echo "  [-l <log directory>]: MUST BE ABSOLUTE PATH. log directory."
}

while getopts "d:i:u:s:m:g:z:l:h" OPTION; do
    case ${OPTION} in
        # The work directory
        d) DOWNLOAD_DIRECTORY=$OPTARG
           ;;
        # The ontology id to download
        i) ONT_ID=$OPTARG
           ;;
        # The ontology URL to download
        u) ONT_URL=$OPTARG
           ;;
        # A directory where ontology status json will be written
        s) STATUS_DIR=$OPTARG
           ;;
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # The path to the directory where this project has been downloaded
        z) CODE_BASE_DIRECTORY=$OPTARG
           ;;
        # The path to the directory where this project has been downloaded
        l) LOG_DIRECTORY=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${DOWNLOAD_DIRECTORY} || -z ${ONT_ID} || -z ${ONT_URL} || -z ${LOG_DIRECTORY} \
      || -z ${STATUS_DIR} || -z ${MAVEN} || -z ${CODE_BASE_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "work directory: ${DOWNLOAD_DIRECTORY}"
	echo "ontology id: ${ONT_ID}"
	echo "ontology url: ${ONT_URL}"
	echo "ontology status directory: ${STATUS_DIR}"
	echo "log directory: ${LOG_DIRECTORY}"
	echo "path to maven bin: ${MAVEN}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

### remove any trailing slash from the code base directory
case "${CODE_BASE_DIRECTORY}" in
    */)
    CODE_BASE_DIRECTORY=${CODE_BASE_DIRECTORY%?}
    ;;
esac

# remove any duplicate forward slashes from the directory path
dir=$(echo "${DOWNLOAD_DIRECTORY}/ontologies/${ONT_ID}" | sed 's/\/\//\//g')
echo "downloading ${ONT_URL} into directory ${dir}"
DOWNLOAD_LOG_FILE=${LOG_DIRECTORY}/${ONT_ID}_dload.log
> ${DOWNLOAD_LOG_FILE}
${CODE_BASE_DIRECTORY}/scripts/download/download.sh -g ${DOWNLOAD_LOG_FILE} -o ${dir} -i ${ONT_ID} -u ${ONT_URL}
e=$?

### create the download status json file and populate it accordingly
cp ${CODE_BASE_DIRECTORY}/scripts/template.json ${STATUS_DIR}/${ONT_ID}_dload.json
# populate the template json with the ontology id
sed -i 's/\"id\": null,/\"id\": \"'"${ONT_ID}"'\",/' "${STATUS_DIR}/${ONT_ID}_dload.json"
# populate the template json with the ontology url
pattern="[/]"
escaped_url="${ONT_URL//$pattern/\/}"
sed -i 's/\"url\": null,/\"url\": \"'"${escaped_url}"'\",/' "${STATUS_DIR}/${ONT_ID}_dload.json"
# populate the template json with the path to the download log file
escaped_log_file="${DOWNLOAD_LOG_FILE//$pattern/\/}"
sed -i 's/\"dload_log\": null,/\"dload_log\": \"'"${escaped_log_file}"'\",/' "${STATUS_DIR}/${ONT_ID}_dload.json"
if [ ${e} == 0 ]; then
    # we've downloaded something. check to see that it's not an error message
    ont_file="${dir}/${ONT_ID}.owl"
    error_msg_count=$(grep Error ${ont_file} | grep 'The specified key does not exist.' | wc -l)
    error_msg_count=$(($error_msg_count + 0))
    if [ ${error_msg_count} == 0 ]; then
        # we've confirmed that we have downloaded more than an error message. Now check
        # to see if the file we've downloaded contains any triples. If it contains triples
        # then we will call it validated.
        output_file="${ont_file}.nt"
        echo "" >> ${DOWNLOAD_LOG_FILE}
        ${CODE_BASE_DIRECTORY}/scripts/download/validate.sh -i ${ont_file} -o ${output_file} -m ${MAVEN} -g ${DOWNLOAD_LOG_FILE}
        if [ $? == 0 ]; then
            # the validation process didn't fail due to error, so we count the number of triples in the generated output_file
            triple_count=$(cat ${output_file} | wc -l)
            triple_count=$(($triple_count + 0))

            if [ ${triple_count} != 0 ]; then
                sed -i 's/\"dload\": null,/\"dload\": true,/' "${STATUS_DIR}/${ONT_ID}_dload.json"
                # log a successful download
                echo "" >> ${DOWNLOAD_LOG_FILE}
                echo "Download validation successful. Triple count = ${triple_count}" >> ${DOWNLOAD_LOG_FILE}
            else
                # download succeeded but the file contains no triples, so what was downloaded most likely wasn't an ontology
                sed -i 's/\"dload\": null,/\"dload\": false,/' "${STATUS_DIR}/${ONT_ID}_dload.json"
                # add an error message to the download log file
                echo "" >> ${DOWNLOAD_LOG_FILE}
                echo "WARNING: Download completed successfully but no triples are observed. A portion of the downloaded file is shown below:" >> ${DOWNLOAD_LOG_FILE}
                echo "" >> ${DOWNLOAD_LOG_FILE}
                head -n 20 ${ont_file} >> ${DOWNLOAD_LOG_FILE}
            fi
        else
            # validation failed due to error
            sed -i 's/\"dload\": null,/\"dload\": false,/' "${STATUS_DIR}/${ONT_ID}_dload.json"
            echo "" >> ${DOWNLOAD_LOG_FILE}
            echo "WARNING: Download validation failed due to error. See above." >> ${DOWNLOAD_LOG_FILE}
            echo "" >> ${DOWNLOAD_LOG_FILE}
        fi
        # delete the n-triples output file if it was created
        if [ -e ${output_file} ]; then
            rm ${output_file}
        fi
    else
        # an error message was detected
        sed -i 's/\"dload\": null,/\"dload\": false,/' "${STATUS_DIR}/${ONT_ID}_dload.json"
        # add an error message to the download log file
        echo "" >> ${DOWNLOAD_LOG_FILE}
        echo "WARNING: Error message detected in the downloaded file. Stale URL is likely cause." >> ${DOWNLOAD_LOG_FILE}
        echo "" >> ${DOWNLOAD_LOG_FILE}
        head -n 20 ${ont_file} >> ${DOWNLOAD_LOG_FILE}
    fi
else
    # an error occurred during the download process
    sed -i 's/\"dload\": null,/\"dload\": false,/' "${STATUS_DIR}/${ONT_ID}_dload.json"
    # log the error
    echo "" >> ${DOWNLOAD_LOG_FILE}
    echo "WARNING: Download failed due to error. See above." >> ${DOWNLOAD_LOG_FILE}
    echo "" >> ${DOWNLOAD_LOG_FILE}
fi