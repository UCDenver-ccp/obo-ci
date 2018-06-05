import commands
import sys
import time


# This script simply waits until the SLURM scheduler appears to be up and running.
# To make things simple, there are no input arguments. This script will check
# once a minute to see if jobs can be submitted.

def logMessage(msg, file):
    print msg
    file.write(msg + "\n")

def getCCQJobStatus(ccqJobId):
    # Get the status of the job from CCQ
    status, output = commands.getstatusoutput("ccqstat -j " + str(ccqJobId))
    for line in output.split("\n"):
        # First line has JOBID in it and is a header so ignore it. Also can do a jobPrefixString here so you can check for certain job names as well
        if "Id            " not in line and "------------------" not in line and str(ccqJobId) in line:
            jobStatus = line.split(" ")
            jobStatus = jobStatus[len(jobStatus) - 1]
            return {"status": "success", "jobStatus": str(jobStatus)}
        elif "No jobs in queue" in line:
            # Assume that the job has been deleted and return deleted
            return {"status": "success", "jobStatus": "deleted"}

    return {"status": "error", "jobStatus": "ccqstat call did not return anything, the output was: " + str(output)}


def main():
    wait_interval = 10



    try:
        ccqJobSubmitOutput = sys.argv[1]
    except Exception:
        ccqJobSubmitOutput = ""

    try:
        logFilePath = sys.argv[2]
    except Exception:
        logFilePath = ""

    # when run in the pipeline, the ccqJobSubmitOutput will contain a sentence that has the job ID embedded, e.g.
    # "The job has successfully been submitted to the scheduler obocischeduler and is currently being processed. The job id is: 3756 you can use this id to look up the job status using the ccqstat utility."
    # So it will need to be extracted from the sentence.
    #
    # For convenience (and debugging), if "job id is: " is not observed then it is assumed that the input is just the job id itself
    try:
        if "job id is: " in ccqJobSubmitOutput:
            ccqJobId = str(ccqJobSubmitOutput).split("job id is: ")[1].split(" ")[0]
        else:
            ccqJobId = str(ccqJobSubmitOutput)
    except Exception:
        ccqJobId = ""

    with open(logFilePath, "a", 0) as logFile:
        logMessage("------ WaitForInstancesUp Arguments ------", logFile)
        logMessage("Argument 1: " + ccqJobSubmitOutput, logFile)
        logMessage("Argument 2: " + logFilePath, logFile)
        logMessage("ccqJobId: " + ccqJobId, logFile)
        logMessage("========================================================================", logFile)
        logMessage("========== Waiting for SLURM compute instances to come online ==========", logFile)
        logMessage("========================================================================", logFile)


        done = False
        while not done:
            logMessage("Checking to see if compute instances are online for job " + ccqJobId + "...", logFile)

            # Wait the specified amount of time before checking sinfo again
            time.sleep(wait_interval)

            response = getCCQJobStatus(ccqJobId)
            logMessage("CCQ status: " + str(response['status']), logFile)
            if str(response['status']) == "error":
                logMessage("There was an error when checking the CCQ Job State. Wait-for-instance check complete.", logFile)
                logMessage(str(response['jobStatus']), logFile)
                done = True
            else:
                ccqJobStatus = str(response['jobStatus'])
                logMessage("CCQ JOB status: " + str(response['jobStatus']), logFile)
                if ccqJobStatus == "CCQueued" or ccqJobStatus == "Completed" or ccqJobStatus == "deleted" or ccqJobStatus == "Error":
                    logMessage("The compute instances appear to be up and running. Wait-for-instance check complete. Waiting 2 minutes for good measure.", logFile)
                    done = True
                    time.sleep(120)
                    logMessage("Exiting waitForInstancesUp...", logFile)

    sys.exit(0)

    # done = False
    # while not done:
    #     print "Checking sinfo..."
    #     # call sinfo; if the job scheduler is ready, then sinfo will not return an error
    #     status, output = commands.getstatusoutput("sinfo")
    #     first_line = output.split("\n")[0]
    #     if "sinfo: error:" not in first_line:
    #         done = True
    #
    #     # Wait the specified amount of time before checking sinfo again
    #     time.sleep(wait_interval)
    #
    # print "The scheduler appears to be up and running. Wait-for-instance check complete."
    # sys.exit(0)

main()
