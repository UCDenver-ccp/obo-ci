#!/bin/bash

# Create one r4.large instance that will drive the rest of the workflow
# May not want to use Spot for this one to make sure it doesn't get killed?
#CC -it r4.large
#CC -sp 0.08
#CC -tl 0:1:0
#CC -ni 1

#SBATCH -N 1

# Set the path to the shared filesystem where the data will be stored and persisted across runs
export SHARED_FS=/mnt/efsdata
export WORK_DIRECTORY=${SHARED_FS}/obo-ci-data
export CODE_BASE_DIRECTORY=${SHARED_FS}/obo-ci.git
export JOB_LOGS_DIRECTORY=${SHARED_FS}/job-logs
export S3_PATH=s3://cc.obo-ci
export LOG_FILE=${JOB_LOGS_DIRECTORY}/workflow.log

mkdir -p ${JOB_LOGS_DIRECTORY}

# clean the log file
> ${LOG_FILE}

## Since this is the next step in the workflow that starts the submission the
## large number of jobs, we will submit another CCQ job here that automatically
## scales up the number of running instances to the appropriate amount
## We may move this up to the first step so that the instances are being created
## while the setup scripts are running to minimize wait time?
#INSTANCE_JOB_ID=$(ccqsub -js scripts/cloudycluster/createInstances_download.sh)
#echo "INSTANCE_JOB_ID: ${INSTANCE_JOB_ID}"
#echo "INSTANCE_JOB_ID: ${INSTANCE_JOB_ID}" >> ${LOG_FILE}
#
### Run the setup script
##./scripts/0_setup.sh -d ${WORK_DIRECTORY} \
##             -m mvn \
##             -j jq \
##             -z ${CODE_BASE_DIRECTORY}
#
#
## ensure the instances come online before proceeding
#echo "Starting script to wait for compute instances to come online..." >> ${LOG_FILE}
#python scripts/cloudycluster/waitForInstancesUp.py ${INSTANCE_JOB_ID} ${LOG_FILE}
#echo "Compute instances should now be online." >> ${LOG_FILE}
#
#
## Run the download_ontologies script
#JOB_NAME_DOWNLOAD="obo-download"
#SLURM_LOG_DIRECTORY=${JOB_LOGS_DIRECTORY}/download
#mkdir -p ${SLURM_LOG_DIRECTORY}
#./scripts/1_download_ontologies.sh -d ${WORK_DIRECTORY} \
#                                   -m mvn \
#                                   -c md5sum \
#                                   -z ${CODE_BASE_DIRECTORY} \
#                                   -a ${CODE_BASE_DIRECTORY}/scripts/cloudycluster/headers/download.header.slurm \
#                                   -n ${JOB_NAME_DOWNLOAD} \
#                                   -e MY_EMAIL \
#                                   -y ${SLURM_LOG_DIRECTORY} \
#                                   -k sbatch
#
#echo "Download jobs have been submitted." >> ${LOG_FILE}
#echo "Compute instances are up. Starting script to wait for downloads to complete before shutting them down." >> ${LOG_FILE}
#WAIT_INTERVAL_IN_SEC=60
#python scripts/cloudycluster/shutdownInstances.py ${JOB_NAME_DOWNLOAD} ${WAIT_INTERVAL_IN_SEC} ${INSTANCE_JOB_ID} bill ${LOG_FILE}
#echo "Compute instances should now be shutting down." >> ${LOG_FILE}
#echo "Download phase complete." >> ${LOG_FILE}


## create the list of ontologies to process
#./scripts/2_modified_ontology_list_gen.sh -d ${WORK_DIRECTORY} \
#                                          -z ${CODE_BASE_DIRECTORY}
#
## Check to see if there are any ontologies to process, i.e. are there any ontologies
## that have changed since the previous download?
#MODIFIED_ONTOLOGY_LIST_FILE="${WORK_DIRECTORY}/ontologies.modified.list"
#if [ ! -s ${MODIFIED_ONTOLOGY_LIST_FILE} ]
#then
#    # file is empty, so there are no updated ontology files, thus no reason to proceed with further processing
#
#    ### Question: can we shut down the instances used by the download script here? Or do we just wait for the hour to elapse?
#
#    # Once the instances have been shutdown (if that's possible) then exit the script
#    exit 0
#fi
#

## Initiate compute instances for individual ontology classification

INSTANCE_JOB_ID=$(ccqsub -js scripts/cloudycluster/createInstances_classify.sh)
echo "INSTANCE_JOB_ID: ${INSTANCE_JOB_ID}"
echo "INSTANCE_JOB_ID: ${INSTANCE_JOB_ID}" >> ${LOG_FILE}

# ensure the instances come online before proceeding
echo "Starting script to wait for compute instances to come online..." >> ${LOG_FILE}
python scripts/cloudycluster/waitForInstancesUp.py ${INSTANCE_JOB_ID} ${LOG_FILE}
echo "Compute instances should now be online." >> ${LOG_FILE}

## Run reasoners over the individual ontologies
JOB_NAME="obo-classify"
SLURM_LOG_DIRECTORY=${JOB_LOGS_DIRECTORY}/classify
mkdir -p ${SLURM_LOG_DIRECTORY}
./scripts/3_classify_ontologies.sh -d ${WORK_DIRECTORY} \
                                   -m mvn \
                                   -z ${CODE_BASE_DIRECTORY} \
                                   -a ${CODE_BASE_DIRECTORY}/scripts/cloudycluster/headers/classify.header.slurm \
                                   -n ${JOB_NAME} \
                                   -e MY_EMAIL \
                                   -y ${SLURM_LOG_DIRECTORY} \
                                   -k sbatch


echo "Individual classification jobs have been submitted." >> ${LOG_FILE}
echo "Waiting for processes to complete before shutting compute instances down." >> ${LOG_FILE}
WAIT_INTERVAL_IN_SEC=60
python scripts/cloudycluster/shutdownInstances.py ${JOB_NAME} ${WAIT_INTERVAL_IN_SEC} ${INSTANCE_JOB_ID} bill ${LOG_FILE}
echo "Compute instances should now be shutting down." >> ${LOG_FILE}
echo "Classify phase complete." >> ${LOG_FILE}


## TODO: spin up classify-pairs instances

#
#
#### Question: can we also restart the 1 hour clock at this point?
#
#
## After all jobs finish run the 4th part of the workflow
#./scripts/4_classify_ontology_pairs.sh -d ${WORK_DIRECTORY} \
#                                       -m mvn \
#                                       -c md5sum \
#                                       -z ${CODE_BASE_DIRECTORY} \
#                                       -a ${CODE_BASE_DIRECTORY}/scripts/cloudycluster/headers/download.header.slurm \
#                                       -n obo-classify-pairs \
#                                       -y ${SHARED_FS}/job-logs \
#                                       -k sbatch
#
## Monitor the queue to determine when the jobs have completed
## TODO put monitoring code here may utilize ccautomaton
## custom workflow implementation here
#

## TODO: wait script
## TODO: spin up cycle detection instances


#### Question: can we also restart the 1 hour clock at this point?
#
## After all the jobs finish run the 5th part of the workflow
#./scripts/5_cycle_detection.sh  -d ${WORK_DIRECTORY} \
#                                -m mvn \
#                                -c md5sum \
#                                -z ${CODE_BASE_DIRECTORY} \
#                                -a ${CODE_BASE_DIRECTORY}/scripts/cloudycluster/headers/download.header.slurm \
#                                -n obo-classify \
#                                -y ${SHARED_FS}/job-logs \
#                                -k sbatch
#
#
## Monitor the queue to determine when the jobs have completed
## TODO put monitoring code here may utilize ccautomaton
## custom workflow implementation here
#

## TODO: wait script
## TODO: spin up cycle-detection pairs instances


#### Question: can we also restart the 1 hour clock at this point?
#
## After all the jobs finish run the 6th part of the workflow
#./scripts/6_cycle_detection_pairs.sh -d ${WORK_DIRECTORY} \
#                                     -m mvn \
#                                     -c md5sum \
#                                     -z ${CODE_BASE_DIRECTORY} \
#                                     -a ${CODE_BASE_DIRECTORY}/scripts/cloudycluster/headers/download.header.slurm \
#                                     -n obo-classify \
#                                     -y ${SHARED_FS}/job-logs \
#                                     -k sbatch

## TODO: wait script


#aws s3 sync ${SHARED_FS}/obo-ci-data/status ${S3_PATH}/