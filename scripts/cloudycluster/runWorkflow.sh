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


echo "Calling NoArgs" >> ${LOG_FILE}
/mnt/efsdata/obo-ci.git/scripts/cloudycluster/scripts/cloudycluster/noArgs.py
echo "NoArgs Done." >> ${LOG_FILE}

# Change directory to the Shared Filesystem specified before
#cd ${SHARED_FS}

## Check if the repo already exists, if it does pull and get the latest updates.
## If not then clone the repo to the shared filesystem
#if [ -d ${CODE_BASE_DIRECTORY} ]; then
#  cd ${CODE_BASE_DIRECTORY}
#  git pull https://github.com/UCDenver-ccp/obo-ci.git
#else
#  git clone https://github.com/UCDenver-ccp/obo-ci.git ${CODE_BASE_DIRECTORY}
#  cd ${CODE_BASE_DIRECTORY}
#fi

# Since this is the next step in the workflow that starts the submission the
# large number of jobs, we will submit another CCQ job here that automatically
# scales up the number of running instances to the appropriate amount
# We may move this up to the first step so that the instances are being created
# while the setup scripts are running to minimize wait time?
INSTANCE_JOB_ID=$(ccqsub -js scripts/cloudycluster/createInstances_download.sh)
echo "INSTANCE_JOB_ID: ${INSTANCE_JOB_ID}"
echo "INSTANCE_JOB_ID: ${INSTANCE_JOB_ID}" >> ${LOG_FILE}

# Run the setup script
# I think we said that this doesn't need to be submitted to the Scheduler but can be run just as a script?
# ~~~ANSWER~~~: correct, 0_setup.sh can run either with or without the scheduler
#./scripts/0_setup.sh -d ${WORK_DIRECTORY} \
#             -m mvn \
#             -j jq \
#             -z ${CODE_BASE_DIRECTORY}


# Run the download_ontologies script
# I think we said that this doesn't need to be submitted to the Scheduler but can be run just as a script?
# ~~~ANSWER~~~: This one does need the scheduler as it will kick off ~180 separate jobs (1 for each download process)
#            So I've moved the createInstancesForWorkFlow.sh script to be just above this.
JOB_NAME_DOWNLOAD="obo-download"
SLURM_LOG_DIRECTORY=${JOB_LOGS_DIRECTORY}/download
mkdir -p ${SLURM_LOG_DIRECTORY}
./scripts/1_download_ontologies.sh -d ${WORK_DIRECTORY} \
                                   -m mvn \
                                   -c md5sum \
                                   -z ${CODE_BASE_DIRECTORY} \
                                   -a ${CODE_BASE_DIRECTORY}/scripts/cloudycluster/headers/download.header.slurm \
                                   -n ${JOB_NAME_DOWNLOAD} \
                                   -e MY_EMAIL \
                                   -y ${SLURM_LOG_DIRECTORY} \
                                   -k sbatch



# ensure the instances came online before we try to shut them down
echo "Download jobs have been submitted." >> ${LOG_FILE}
echo "Starting script to wait for compute instances to come online..." >> ${LOG_FILE}
a=$(python scripts/cloudycluster/waitForInstances.py ${INSTANCE_JOB_ID} ${LOG_FILE})
echo "Output of python waitForInstances: ${a}" >> ${LOG_FILE}
echo "Compute instances should now be online." >> ${LOG_FILE}

echo "Compute instances are up. Starting script to wait for downloads to complete before shutting them down." >> ${LOG_FILE}
WAIT_INTERVAL_IN_SEC=60
b=$(python scripts/cloudycluster/shutdownInstances.py ${JOB_NAME_DOWNLOAD} ${WAIT_INTERVAL_IN_SEC} ${INSTANCE_JOB_ID} bill ${LOG_FILE})
echo "Output of python shutdownInstances: ${b}" >> ${LOG_FILE}
echo "Compute instances should now be shutting down." >> ${LOG_FILE}
echo "Download phase complete." >> ${LOG_FILE}


## TODO: spin up classify instances
echo "Sleeping for 20 minutes." >> ${LOG_FILE}
date >> ${LOG_FILE}
sleep 1200


## Run the second part of the workflow (I don't think this submits jobs?)
## ~~~ANSWER~~~: correct, this one does not submit jobs
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
#### Question: would it be possible to restart the 1 hour clock on the instances at this point?
#
## Run the 3rd stage of the workflow that submits jobs to the scheduler
## Instances will be launching while the job is running and the jobs will
## start as soon as the instances are available
#./scripts/3_classify_ontologies.sh -d ${WORK_DIRECTORY} \
#                                   -m mvn \
#                                   -c md5sum \
#                                   -z ${CODE_BASE_DIRECTORY} \
#                                   -a ${CODE_BASE_DIRECTORY}/scripts/cloudycluster/headers/download.header.slurm \
#                                   -n obo-classify \
#                                   -y ${SHARED_FS}/job-logs \
#                                   -k sbatch
#
## Monitor the queue to determine when the jobs have completed
## TODO put monitoring code here may utilize ccautomaton
## custom workflow implementation here

## TODO: wait script
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