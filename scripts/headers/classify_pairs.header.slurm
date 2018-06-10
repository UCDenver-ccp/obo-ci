#!/bin/bash
#SBATCH -p short
#SBATCH --job-name=JOB_NAME
#SBATCH --mail-type=FAIL               # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=YOUR_EMAIL
#SBATCH --nodes=1                    # Only use a single node
#SBATCH --ntasks=1                    # Run on a single CPU
#SBATCH --mem=18gb                   # Memory limit
#SBATCH --time=00:15:00               # Time limit hrs:min:sec
#SBATCH --output=JOB_LOG_DIRECTORY/JOB_NAME_%j.out   # Standard output and error log
#SBATCH --error=JOB_LOG_DIRECTORY/JOB_NAME_%j.err   # %j inserts job number

