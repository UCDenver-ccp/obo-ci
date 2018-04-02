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
    wait_interval = 60

    try:
        ccqJobSubmitOutput = sys.argv[1]
    except Exception:
        ccqJobSubmitOutput = ""

    try:
        logFilePath = sys.argv[2]
    except Exception:
        return {"status": "error"}

    try:
        ccqJobId = str(ccqJobSubmitOutput).split("job id is: ")[1].split(" ")[0]
    except Exception:
        return {"status": "error",
            "jobStatus": "The output passed into checkForCCQJobStatus was not in the appropriate format." + str(ccqJobSubmitOutput)}

    with open(logFilePath, "a", 0) as logFile:
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
                if ccqJobStatus == "CCQueued" or ccqJobStatus == "Completed" or ccqJobStatus == "deleted" or ccqJobStatus == "Error":
                    logMessage("The compute instances appear to be up and running. Wait-for-instance check complete.", logFile)
                    done = True

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
