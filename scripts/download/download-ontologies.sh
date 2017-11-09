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
    echo "  [-m <maven>]: MUST BE ABSOLUTE PATH. The path to the mvn command."
}

while getopts "d:l:o:e:m:h" OPTION; do
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
        # The path to the Apache Maven command
        m) MAVEN=$OPTARG
           ;;
        # HELP!
        h) print_usage; exit 0
           ;;
    esac
done

if [[ -z ${DOWNLOAD_DIRECTORY} || -z ${ONTOLOGY_LIST_FILE} || -z ${DOWNLOADED_ONTOLOGY_LIST_FILE} || -z ${DOWNLOAD_ERROR_FILE} || -z ${MAVEN} ]]; then
	echo "missing input arguments!!!!!"
	echo "work directory: ${DOWNLOAD_DIRECTORY}"
	echo "ontology list file: ${ONTOLOGY_LIST_FILE}"
	echo "downloaded ontology list file: ${DOWNLOADED_ONTOLOGY_LIST_FILE}"
	echo "download error file: ${DOWNLOAD_ERROR_FILE}"
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
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
> ${DOWNLOADED_ONTOLOGY_LIST_FILE}
> ${DOWNLOAD_ERROR_FILE}

exit_code=0
for index in ${!IDs[*]}; do
  id=${IDs[$index]}
  url=${URLs[$index]}
  # remove any duplicate forward slashes from the directory path
  dir=$(echo "${DOWNLOAD_DIRECTORY}/ontologies/${id}" | sed 's/\/\//\//g')
  log_file="${dir}/${id}.log"
  echo "downloading ${url} into directory ${dir}"

  ${CURRENT_DIR}/download.sh -l ${log_file} -o ${dir} -i ${id} -u ${url}
  e=$?
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
      ${CURRENT_DIR}/validate.sh -i ${ont_file} -o ${output_file} -m ${MAVEN}
      if [ $? == 0 ]; then
        # the validation process didn't fail due to error, so we count the number of triples in the generated output_file
        triple_count=$(cat ${output_file} | wc -l)
        triple_count=$(($triple_count + 0))

        if [ ${triple_count} != 0 ]; then
          echo "${id},${url}" >> ${DOWNLOADED_ONTOLOGY_LIST_FILE}
        else
          echo "${id},${url}" >> ${DOWNLOAD_ERROR_FILE}
          mv ${dir} "${dir}_VALIDATION_ERROR"
        fi
      else
        # validation failed due to error
        echo "${id},${url}" >> ${DOWNLOAD_ERROR_FILE}
        mv ${dir} "${dir}_VALIDATION_FAILURE"
      fi
      # delete the n-triples output file if it was created
      if [ -e ${output_file} ]; then
        rm ${output_file}
      fi
    else
       # an error message was detected
       echo "${id},${url}" >> ${DOWNLOAD_ERROR_FILE}
       mv ${dir} "${dir}_UNAVAILABLE"
    fi
  else
    # an error occurred during the download process
    echo "${id},${url}" >> ${DOWNLOAD_ERROR_FILE}
    mv ${dir} "${dir}_UNAVAILABLE"
  fi




done
