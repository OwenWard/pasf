#!/bin/sh
#
# Simple Matlab submit script to run the examples using Slurm
# This example runs the demo's on the cluster. Not sure where
# the output is stored though, or how to access the animations yet.
#
#
#
#SBATCH -A stats
#SBATCH -J MimicSim
#SBATCH -t 30:00
#SBATCH --mem-per-cpu=2gb

module load matlab

echo "Lauching the Matlab run"
date

#matlab-nojvm

matlab -nosplash -nodisplay -nodesktop -r 'extract_dynamics' > output

echo "Finished"
date

# End of script 
