#!/usr/bin/env python

import commands
import sys
import time


def logMessage(msg, file):
    print msg
    file.write(msg + "\n")

def main():

    with open("/mnt/efsdata/job-logs/workflow.log", "a") as logFile:
        logMessage("------ WaitForInstances Arguments 22222 ------", logFile)
        logMessage("========================================================================", logFile)
        logMessage("========== NO ARGS!!!!!!! ==========", logFile)
        logMessage("========================================================================", logFile)

    sys.exit(0)

main()
