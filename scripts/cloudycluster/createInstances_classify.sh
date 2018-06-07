#!/bin/bash

#CC -it r4.large
#CC -sp 0.08

# Here we will create a Spot Fleet to help us obtain our desired number of 
# instances
#CC -sf
#CC -ft diversified

# I don't think we decided on the exact number of instances that we wanted to use yet
# So this is sort of a place holder for how many nodes we want to spin up to run the jobs
#CC -sw 1
#CC -fs 44

# Specify that this job is a placeholder job that will only create instances and
# allow them to run for the specified timelimit. In this case 1 hour.
#CC -si yes
#CC -cp
#CC -tl 0:12:0

#SBATCH -N 1

# This script will create 100 EC2 r4.large instances with a Spot Bid price of 
# $0.08 and these instances will run and process jobs submitted to the scheduler
# for 1 hour.

echo "Placeholder script"
sleep 100