#!/usr/bin/env python
import commands
import sys
import time


# This script simply waits until the SLURM scheduler appears to be up and running.
# To make things simple, there are no input arguments. This script will check
# once a minute to see if jobs can be submitted.

def logMessage(msg, file):
    print msg
    file.write(msg + "\n")

def main():

    with open("/mnt/efsdata/job-logs/workflow.log", "a", 0) as logFile:
        logMessage("------ WaitForInstances Arguments ------", logFile)
        logMessage("========================================================================", logFile)
        logMessage("========== NO ARGS!!!!!!! ==========", logFile)
        logMessage("========================================================================", logFile)

    sys.exit(0)

main()
