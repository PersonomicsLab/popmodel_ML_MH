#!/bin/bash

#SBATCH --job-name=averaged_joint_proj
#SBATCH --output=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/log/job_%j.out
#SBATCH --error=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/log/job_%j.err
#SBATCH --time=23:55:00
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=500MB

sub_list=/scratch/janine.bijsterbosch/WAPIAW_2/subj_lists/sub_list_N12_bal.csv
data_file=/scratch/janine.bijsterbosch/WAPIAW_2/imaging/averaged_joint_proj.npy
output=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/prediction/avg_joint_proj_age_N12_bal.csv
n_split=10
target=21003-2.0  # "20016-2.0" for fluid intelligence, "20127-0.0" for neuroticism, and "21003-2.0" for age

script_loc=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/prediction_with_imaging.py
pheno=/scratch/janine.bijsterbosch/WAPIAW_2/phenotypes/age.tsv  # Change it to .... age.tsv for age prediction

module load python
export OMP_NUM_THREADS=16
python ${script_loc} -l ${sub_list} -d ${data_file} -p ${pheno} -t ${target} -o ${output} -s ${n_split}  # Note: imaging data list is set as default