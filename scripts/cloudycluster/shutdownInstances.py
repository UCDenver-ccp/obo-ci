import commands
import sys
import time

def logMessage(msg, file):
    print msg
    file.write(msg + "\n")

def checkExperimentJobCompletion(jobPrefixString, logFile):
    # Get the output from the squeue command that will show all the jobs that are currently running or waiting to run in the system
    status, output = commands.getstatusoutput("squeue")
    stillRunning = 0
    lineNum = 0
    # Cycle through the lines of the output and see if there are any jobs still running
    for line in output.split("\n"):
        lineNum += 1
        # First line has JOBID in it and is a header so ignore it. Also can do a jobPrefixString here so you can check for certain job names as well
        if "JOBID" not in line and str(jobPrefixString) in line:
            stillRunning += 1
    
    if stillRunning == 1:
        logMessage("There is " + str(stillRunning) + " job still running.", logFile)
    else:
        logMessage("There are " + str(stillRunning) + " job(s) still running.", logFile)

    # Return True if jobs are still running and False if they are not
    if stillRunning == 0:
        return {"status": "success", "payload": True}
    else:
        return {"status": "success", "payload": False}

def checkForCCQJobStatus(ccqJobId):

    # Get the status of the job from CCQ
    status, output = commands.getstatusoutput("ccqstat -j " + str(ccqJobId))
    for line in output.split("\n"):
        # First line has JOBID in it and is a header so ignore it. Also can do a jobPrefixString here so you can check for certain job names as well
        if "Id            " not in line and "------------------" not in line and str(ccqJobId) in line:
            jobStatus = line.split(" ")
            jobStatus = jobStatus[len(jobStatus)-1]
            return {"status": "success", "jobStatus": str(jobStatus)}
        elif "No jobs in queue" in line:
            # Assume that the job has been deleted and return deleted
            return {"status": "success", "jobStatus": "deleted"}

    return {"status": "error", "jobStatus": "ccqstat call did not return anything, the output was: " + str(output)}

def main():
    # Get the prefix string from the command line, if there isn't one set it to an empty string
    try:
        prefixString = sys.argv[1]
    except Exception:
        prefixString = ""

    # Get the time to wait from the command line, if not specified default to 20 seconds
    try:
        timeToWait = int(sys.argv[2])
    except IndexError:
        timeToWait = 20
    except Exception:
        print "Invalid time to wait specified, it must be an integer."
        sys.exit(0)

    # Get the CCQ Job submission output to monitor the CCQ job to see if it completes or hits the timelimit.
    # If the CCQ Job hits the timelimit, this script will cancel all the remaining jobs in the queue
    # May not be exactly what we want but I think this is what we discussed?
    try:
        ccqJobId = sys.argv[3]
    except Exception:
        ccqJobId = ""

    # In order to be able to cancel the jobs we will need to know the userId under which the jobs will be running
    # This will be the CloudyCluster username
    try:
        jobUsername = sys.argv[4]
    except Exception:
        jobUsername = ""


    try:
        logFilePath = sys.argv[5]
    except Exception:
        logFilePath = ""


    with open(logFilePath, "a", 0) as logFile:


        logMessage("------ ShutdownInstances Arguments ------", logFile)
        logMessage("Argument 1: " + prefixString, logFile)
        logMessage("Argument 2: " + ccqJobId, logFile)
        logMessage("Argument 3: " + jobUsername, logFile)
        logMessage("Argument 4: " + logFilePath, logFile)

        logMessage("=======================================================================================", logFile)
        logMessage("========== Compute instance shutdown will proceed when all jobs are complete ==========", logFile)
        logMessage("=======================================================================================", logFile)
        logMessage("=== Job name prefix: " + prefixString, logFile)
        logMessage("=== User: " + jobUsername, logFile)
        logMessage("=== Wait interval (s): " + str(timeToWait), logFile)
        logMessage("=== Instance job ID: " + ccqJobId, logFile)
        logMessage("=======================================================================================", logFile)

        done = False
        while not done:
            logMessage( "Checking " + prefixString + " job status...", logFile)
            # Check and make sure that the CCQ job has not entered the Completed or Error state
            response = checkForCCQJobStatus(ccqJobId)
            logMessage( "CCQ status: " + str(response['status']), logFile)
            if str(response['status']) == "error":
                logMessage("There was an error when checking the CCQ Job State.", logFile)
                logMessage(str(response['jobStatus']), logFile)
            else:
                ccqJobStatus = str(response['jobStatus'])
                if ccqJobStatus == "Completed" or ccqJobStatus == "deleted" or ccqJobStatus == "Error":
                    logMessage("All jobs have completed (or errored). Canceling remaining jobs...", logFile)
                    # The CCQ job is no longer running so we should cancel all of the jobs and then exit
                    status, output = commands.getstatusoutput("scancel -u " + str(jobUsername))
                    break

            # Wait the specified amount of time before checking the number of jobs running
            time.sleep(timeToWait)
            # Call the function to check if the jobs have completed
            results = checkExperimentJobCompletion(prefixString, logFile)

            # Set the variable done to the return of the checkExperimentJobCompletion function
            done = results['payload']

        logMessage("There are no more jobs in the queue. Shutting down all compute instances.", logFile)
        status, output = commands.getstatusoutput("ccqdel -j " + ccqJobId)
        logMessage("ccqdel response: " + output, logFile)
        sys.exit(0)

main()