#!/bin/bash

#SBATCH --job-name=cat_amp_fi
#SBATCH --output=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/log/job_%j.out
#SBATCH --error=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/log/job_%j.err
#SBATCH --time=167:55:00
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=1G

sub_list=/scratch/janine.bijsterbosch/WAPIAW_2/subj_lists/sub_list.csv
data_file=/scratch/janine.bijsterbosch/WAPIAW_2/imaging/joint_proj_concat.npy
output=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/prediction/joint_proj_cat_amp_fi_all.csv
n_split=50
target=20016-2.0  # "20016-2.0" or "20016_Mean" for fluid intelligence, "20127-0.0" for neuroticism, and "21003-2.0" for age
extra_feature="/scratch/janine.bijsterbosch/WAPIAW_2/imaging/amplitudes_dr_stage1.txt /scratch/janine.bijsterbosch/WAPIAW_2/imaging/amplitudes_res_dr_stage1.txt"  # Extra features

script_loc=/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/prediction_with_imaging.py
pheno=/scratch/janine.bijsterbosch/WAPIAW_2/phenotypes/WAPIAW2_clean_appended.tsv  # Change it to .... age.tsv for age prediction

module load python
export OMP_NUM_THREADS=16
python ${script_loc} -l ${sub_list} -d ${data_file} -p ${pheno} -t ${target} -o ${output} -s ${n_split} -e "${extra_feature}" # Note: imaging data list is set as default
