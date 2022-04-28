#!/bin/bash

#SBATCH -J tan_projection
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --mem 256G
#SBATCH -t 01:00:00
#SBATCH --mail-type END

module load python
source activate NiLearn
python ./tan_projection.py
conda deactivate