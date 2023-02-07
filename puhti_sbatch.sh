#!/bin/bash
#SBATCH --job-name=example
#SBATCH --account=project_2004160
#SBATCH --partition=small
#SBATCH --reservation=training
#SBATCH --time=00:05:00
#SBATCH --ntasks=4

srun my_mpi_exe