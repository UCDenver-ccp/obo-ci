#!/bin/bash

# Create one r4.large instance that will drive the rest of the workflow
# May not want to use Spot for this one to make sure it doesn't get killed?
#CC -it r4.large
#CC -sp 0.08
#CC -tl 0:0:1
#CC -ni 1

#SBATCH -N 1

# Set the path to the shared filesystem where the data will be stored and persisted across runs
export SHARED_FS=/mnt/efsdata
export WORK_DIRECTORY=${SHARED_FS}/obo-ci-data
export CODE_BASE_DIRECTORY=${SHARED_FS}/obo-ci.git
export JOB_LOGS_DIRECTORY=${SHARED_FS}/job-logs
export S3_PATH=s3://cc.obo-ci
export LOG_FILE=${JOB_LOGS_DIRECTORY}/workflow.log

touch ${JOB_LOGS_DIRECTORY}/workflow_2_ran.txt

echo "PATH: "
echo $PATH

echo "PYTHON VERSION: "
python -V

echo "JAVA VERSION: "
java -version

