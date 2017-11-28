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
    echo "  [-l <ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs to be downloaded."
    echo "  [-o <downloaded ontology list file>]: MUST BE ABSOLUTE PATH. A file containing ontology id,url pairs that were downloaded."
    echo "  [-e <download error file>]: MUST BE ABSOLUTE PATH. A file used to record download errors."
    echo "  [-s <ontology status directory>]: MUST BE ABSOLUTE PATH. The path to a directory where json files indicating ontology status are to be written."
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
    echo "  [-z <code base directory>]: MUST BE ABSOLUTE PATH. Path to the base directory where this project has been downloaded."
}

while getopts "d:l:o:e:s:m:g:z:h" OPTION; do
    case ${OPTION} in
        # The work directory
        d) DOWNLOAD_DIRECTORY=$OPTARG
           ;;
        # The ontology list file (id,url pairs)
        l) ONTOLOGY_LIST_FILE=$OPTARG
           ;;
        # The ontology list file (id,url pairs)
        o) DOWNLOADED_ONTOLOGY_LIST_FILE=$OPTARG
           ;;
        # A file to record download errors
        e) DOWNLOAD_ERROR_FILE=$OPTARG
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
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${DOWNLOAD_DIRECTORY} || -z ${ONTOLOGY_LIST_FILE} || -z ${DOWNLOADED_ONTOLOGY_LIST_FILE} \
      || -z ${DOWNLOAD_ERROR_FILE} || -z ${STATUS_DIR} || -z ${MAVEN} || -z ${CODE_BASE_DIRECTORY} ]]; then
	echo "missing input arguments!!!!!"
	echo "code base directory: ${CODE_BASE_DIRECTORY}"
	echo "work directory: ${DOWNLOAD_DIRECTORY}"
	echo "ontology list file: ${ONTOLOGY_LIST_FILE}"
	echo "downloaded ontology list file: ${DOWNLOADED_ONTOLOGY_LIST_FILE}"
	echo "download error file: ${DOWNLOAD_ERROR_FILE}"
	echo "ontology status directory: ${STATUS_DIR}"
	echo "path to maven bin: ${MAVEN}"
    print_usage
    exit 1
fi

if ! [[ -e README.md ]]; then
    echo "Please run from the root of the project."
    exit 1
fi

IDs=( $(awk -F, '{print $1}' ${ONTOLOGY_LIST_FILE}) )
URLs=( $(awk -F, '{print $2}' ${ONTOLOGY_LIST_FILE}) )
> ${DOWNLOADED_ONTOLOGY_LIST_FILE}
> ${DOWNLOAD_ERROR_FILE}

### remove any trailing slash from the code base directory
case "${CODE_BASE_DIRECTORY}" in
    */)
    CODE_BASE_DIRECTORY=${CODE_BASE_DIRECTORY%?}
    ;;
esac

exit_code=0
for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  url=${URLs[$index]}
  # remove any duplicate forward slashes from the directory path
  dir=$(echo "${DOWNLOAD_DIRECTORY}/ontologies/${id}" | sed 's/\/\//\//g')
  echo "downloading ${url} into directory ${dir}"
  LOG_DIRECTORY=${STATUS_DIR}/log
  DOWNLOAD_LOG_FILE=${LOG_DIRECTORY}/${id}_dload.log
  > ${DOWNLOAD_LOG_FILE}
  ${CODE_BASE_DIRECTORY}/scripts/download/download.sh -g ${DOWNLOAD_LOG_FILE} -o ${dir} -i ${id} -u ${url}
  e=$?
  cp scripts/template.json ${STATUS_DIR}/${id}_dload.json
  # populate the template json with the ontology id
  sed -i '' 's/\"id\": null,/\"id\": \"'"${id}"'\",/' "${STATUS_DIR}/${id}_dload.json"
  # populate the template json with the path to the download log file
  pattern="[/]"
  escaped_log_file="${DOWNLOAD_LOG_FILE//$pattern/\/}"
  sed -i '' 's/\"dload_log\": null,/\"dload_log\": \"'"${escaped_log_file}"'\",/' "${STATUS_DIR}/${id}_dload.json"
  #sed -i '' 's/\"id\": null,/\"id\": \"'"${id}"'\",/' "${STATUS_DIR}/${id}_${REASONER_NAME}.json"
  if [ ${e} == 0 ]; then
    # we've download something. check to see that it's not an error message
    ont_file="${dir}/${id}.owl"
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
          echo "${id},${url}" >> ${DOWNLOADED_ONTOLOGY_LIST_FILE}
          sed -i '' 's/\"dload\": null,/\"dload\": true,/' "${STATUS_DIR}/${id}_dload.json"
          # log a successful download
          echo "" >> ${DOWNLOAD_LOG_FILE}
          echo "Download validation successful. Triple count = ${triple_count}" >> ${DOWNLOAD_LOG_FILE}
        else
          # download succeeded but the file contains no triples, so what was downloaded most likely wasn't an ontology
          echo "${id},${url}" >> ${DOWNLOAD_ERROR_FILE}
          sed -i '' 's/\"dload\": null,/\"dload\": false,/' "${STATUS_DIR}/${id}_dload.json"
          # add an error message to the download log file
          echo "" >> ${DOWNLOAD_LOG_FILE}
          echo "WARNING: Download completed successfully but no triples are observed. A portion of the downloaded file is shown below:" >> ${DOWNLOAD_LOG_FILE}
          echo "" >> ${DOWNLOAD_LOG_FILE}
          head -n 20 ${ont_file} >> ${DOWNLOAD_LOG_FILE}
        fi
      else
        # validation failed due to error
        echo "${id},${url}" >> ${DOWNLOAD_ERROR_FILE}
        sed -i '' 's/\"dload\": null,/\"dload\": false,/' "${STATUS_DIR}/${id}_dload.json"
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
       echo "${id},${url}" >> ${DOWNLOAD_ERROR_FILE}
       sed -i '' 's/\"dload\": null,/\"dload\": false,/' "${STATUS_DIR}/${id}_dload.json"
       # add an error message to the download log file
       echo "" >> ${DOWNLOAD_LOG_FILE}
       echo "WARNING: Error message detected in the downloaded file. Stale URL is likely cause." >> ${DOWNLOAD_LOG_FILE}
       echo "" >> ${DOWNLOAD_LOG_FILE}
       head -n 20 ${ont_file} >> ${DOWNLOAD_LOG_FILE}
    fi
  else
    # an error occurred during the download process
    echo "${id},${url}" >> ${DOWNLOAD_ERROR_FILE}
    sed -i '' 's/\"dload\": null,/\"dload\": false,/' "${STATUS_DIR}/${id}_dload.json"
    # log the error
    echo "" >> ${DOWNLOAD_LOG_FILE}
    echo "WARNING: Download failed due to error. See above." >> ${DOWNLOAD_LOG_FILE}
    echo "" >> ${DOWNLOAD_LOG_FILE}
  fi

done
