#!/bin/bash

#SBATCH --job-name=joint_proj_cat
#SBATCH --output=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/log/job_%j.out
#SBATCH --error=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/log/job_%j.err
#SBATCH --time=23:55:00
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=500MB

sub_list=/scratch/janine.bijsterbosch/WAPIAW_2/subj_lists/sub_list_N12_bal.csv
data_file=/scratch/janine.bijsterbosch/WAPIAW_2/imaging/joint_proj_concat.npy
output=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/prediction/joint_proj_cat_age_N12_bal.csv
n_split=20
target=21003-2.0

script_loc=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/prediction_with_imaging.py
pheno=/scratch/janine.bijsterbosch/WAPIAW_2/phenotypes/age.tsv

module load python
export OMP_NUM_THREADS=16
python ${script_loc} -l ${sub_list} -d ${data_file} -p ${pheno} -t ${target} -o ${output} -s ${n_split}