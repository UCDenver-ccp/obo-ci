
if [[ -z ${HEADER_FILE} ]]; then
    HEADER="#!/bin/bash -e"
    echo ${HEADER} >> ${SCRIPT_FILE}
    echo "" >> ${SCRIPT_FILE}
else
    cat ${HEADER_FILE} > ${SCRIPT_FILE}
fi

### modify header file with replacement strings for job name, email, and job log directory (if they have been specified)
if [[ ! -z ${HEADER_JOB_NAME} ]]; then
    sed -i 's/JOB_NAME/'${HEADER_JOB_NAME}'/' ${SCRIPT_FILE}
fi
if [[ ! -z ${HEADER_EMAIL} ]]; then
    sed -i 's/YOUR_EMAIL/'${HEADER_EMAIL}'/' ${SCRIPT_FILE}
fi
if [[ ! -z ${HEADER_JOB_LOG_DIRECTORY} ]]; then
    ### remove any trailing slash from the directory, then escape any remaining slashes
    case "${HEADER_JOB_LOG_DIRECTORY}" in
        */)
        HEADER_JOB_LOG_DIRECTORY=${HEADER_JOB_LOG_DIRECTORY%?}
        ;;
    esac
    pattern="[/]"
    escaped_job_log_directory="${HEADER_JOB_LOG_DIRECTORY//$pattern/\/}"
    sed -i 's/JOB_LOG_DIRECTORY/'${escaped_job_log_directory}'/' ${SCRIPT_FILE}
fi