#!/bin/bash

# Author: Ruiqi Chen
# Version: 01/25/2022
#
# Update (01/26/2020): Now convert_res will created an placeholder when it skips a subject, and
# this script will find out these placeholders, delete the folder and remove the subjects from
# the list. (to be implemented)
#
# This script has two functionality:
#
# 1. Check the output directory and update the list of subjects to process.
# 
# The script will scan throught the subject list and look for the corresponding output folder
# in the output directory. A subject is considered successfully processed if and only if:
#
#   a) The output folder has been created.
#   b) There is only one file in the folder, which is the final output, and it's not empty.
#
# Subjects that are successfully processed will be removed from the subject list.
#
# Similarly, if a) is true but b) is false, this subject's processing is considered failed.
# In this case:
#
#   a) The list of failed subjects will be appended to a file `failed_subs.txt`.
#   b) The output folders will be deleted.
#   c) Their names will not be removed from the subject list, so `launch_job.sh` will try
#      to handle them the next time.
# 
# You can view the log the see if a subject's name repeatedly appears, which indicates some
# essential error.
#
# 2. Launch new jobs.


########################## Constants ###########################

# Update subject list
sub_list="./output/sub_list.txt"
output_dir="./output"
skip_list="./output/skipped_subs.txt"
fail_list="./output/failed_subs.txt"

# Launch new jobs
n_sub=4000
array_size=50
job_size=80
launch_script="./launch_job.sh"
log_dir_prefix="./output/launch"
processing_script="./convert_res.sh"
input_dir="/ceph/biobank/derivatives/feat"
ica_file="./rfMRI_ICA_d100.nii.gz"


########################## Update list ###########################

echo "Searching for output folders in ${output_dir}..."
all_sub=(`cat "${sub_list}"`)
max_ind=`expr ${#all_sub[@]} - 1`
n_skipped=0
n_success=0
n_failure=0
for i in `seq 0 ${max_ind}`
do
    curr_sub=${all_sub[$i]}
    curr_dir="${output_dir}/${curr_sub}"
    if [ ! -d "${curr_dir}" ]; then continue; fi  # Not processed yet
    if [ -f "${curr_dir}/skipped" ]  # Skipped
    then
        n_skipped=`expr ${n_skipped} + 1`
        all_sub[$i]=""
        echo ${curr_sub} >> "${skip_list}"
        echo "Subject ${curr_sub} was skipped. Removing the output folder..."
        rm -r "${curr_dir}"
        continue
    fi
    curr_files=(`ls "${curr_dir}"`)
    curr_output="${curr_dir}/${curr_sub}_res_d100_dr_stage1.txt"
    if [ ${#curr_files[@]} -eq 1 -a -s "${curr_output}" ]  # Success
    then
        n_success=`expr ${n_success} + 1`
        all_sub[$i]=""
    else  # Failure
        n_failure=`expr ${n_failure} + 1`
        echo ${curr_sub} >> "${fail_list}"
        echo "Processing of subject ${curr_sub} failed. Removing the output folder..."
        rm -r "${curr_dir}"
    fi
done
echo "" >> "${fail_list}"

# Update subject list
rm "${sub_list}"
n_remain=0
for curr_sub in ${all_sub[@]}  # Automatically leave out blank (deleted) elements
do
    echo ${curr_sub} >> "${sub_list}"
    n_remain=`expr ${n_remain} + 1`
done

echo
echo "Number of successfully processed subjects: ${n_success}. Skipped: ${n_skipped}. Failed: ${n_failure}."
echo "Number of remaining subjects: ${n_remain}."


########################## Launch jobs ###########################

# echo
# echo "Launching new jobs..."
# "${launch_script}" -s "${sub_list}" -n ${n_sub} -a ${array_size} -j ${job_size} -l "${log_dir_prefix}" -p "${processing_script}" -i "${input_dir}" -o "${output_dir}" -f "${ica_file}"
