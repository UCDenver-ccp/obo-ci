import commands
import sys
import time

# This script simply waits until the SLURM scheduler appears to be up and running.
# To make things simple, there are no input arguments. This script will check
# once a minute to see if jobs can be submitted.

def main():
    wait_interval = 60

    print "========================================================================"
    print "========== Waiting for SLURM compute instances to come online =========="
    print "========================================================================"

    done = False
    while not done:
        print "Checking sinfo..."
        # call sinfo; if the job scheduler is ready, then sinfo will not return an error
        status, output = commands.getstatusoutput("sinfo")
        first_line = output.split("\n")[0]
        if "sinfo: error:" not in first_line:
            done = True

        # Wait the specified amount of time before checking sinfo again
        time.sleep(wait_interval)

    print "The scheduler appears to be up and running. Wait-for-instance check complete."
    sys.exit(0)

main()