#!/bin/bash

# Author: Ruiqi Chen
# Version: 01/09/2021
# Update (01/26/2022): Use sub-xxxxxxx_feat.feat/tfMRI.feat as the input directory if it exists


########################### Document ############################

Help()
{
    echo
    echo "Convert the residual of task fMRI data into IC activations"
    echo
    echo "Usage: convert_res.sh [-h] [-i <all_input_dir>] [-o <all_output_dir>] [-f <ica_file>] [-s <all_subjects>]"
    echo
    echo "-h                   Print this help message."
    echo "-i <all_input_dir>   Set the input directory containing all subjects' data."
    echo "-o <all_output_dir>  Set the output directory. Must NOT contain spaces!"
    echo "-f <ica_file>        Set the ICA component file."
    echo "-s <all_subjects>    Set the list of subjects to be processed (default is all 'sub-*' folders in the input directory)"
    echo
    echo "Inputs:"
    echo
    echo "In <all_input_dir>, there should be one folder entitled 'sub-xxxxxxx' (e.g., 'sub-1111908') for each subject. In each of these folder should be the FEAT directory for this subject called 'sub-xxxxxxx_feat.feat'."
    echo
    echo "The <ica_file> should be the 100-component one from UKBB."
    echo
    echo "The <all_subjects> should be a string of subject folder names seperated by space (e.g. \"sub-xxxxxxx sub-yyyyyyy\") ."
    echo
    echo "Outputs:"
    echo
    echo "In <all_output_dir>, there will be one folder entitled 'sub-xxxxxxx' for each subject, which contains dual_regression stage 1 output file 'sub-xxxxxxx_res_d100_dr_stage1.txt'. If this file already exists, it will be overwritten."
    echo
    echo "If there is no data for the current subject, the output folder will still be created containing an empty file called \"skipped\"."
}

####################### Default parameters #######################

all_input_dir="/ceph/biobank/derivatives/feat"  # Directory containing all subjects' input data
all_output_dir="res_converted"  # Directory for all subjects' output
ica_file="rfMRI_ICA_d100.nii.gz"  # Resting state group ICA components
all_subjects=()  # The subjects to be processed (empty list indicates all)


########################### Filenames and Paths ############################

# GLM
glm_dat="filtered_func_data.nii.gz"  # GLM input data (in FEAT directory, same for the several ones below)
glm_design="design.mat"  # GLM design matrix

# Add back the mean
mean_file="mean_func.nii.gz"  # Mean over time

# Registration
warp_file="reg/example_func2standard_warp.nii.gz"  # Warp field
ref_file="${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz"  # Standard space (absolute path as specified in "design.fsf")

# Dual regression (stage 1)
ref_mask_file="${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz"  # Standard space mask

# Temporaray output
temp_folder="myStats"  # default name of temp folder under each subject's output directory
res_file="res4d.nii.gz"  # the residual (in temp folder)
reg_out="res_in_standard.nii.gz"  # Residual in MNI space (in temp folder)


##################### Command line inputs #######################

while getopts ":hi:o:f:s:" opt
do
    case "${opt}" in
        "h") Help; exit;;
        "i") all_input_dir="${OPTARG}";;
        "o") all_output_dir="${OPTARG}";;
        "f") ica_file="${OPTARG}";;
        "s")
            if [ -n "${OPTARG}" ]
            then
                all_subjects=(${OPTARG})  # Seperated by spaces
            else  # No subject, probably due to error in previous steps
                echo "${0}: No subject to process!"
                exit
            fi;;
        ":") echo "Missing argument for option -${OPTARG}"; exit 1;;
        "?") echo "Unknown option -${OPTARG}"; exit 1;;
        *) echo "Unknown error while parsing arguments"; exit 1;;
    esac
done

# Check directories
if [ ! -d "${all_input_dir}" ]; then echo "${all_input_dir} is not a valid directory!"; exit 1; fi
if [ ! -f "${ica_file}" ]; then echo "${ica_file} is not a valid IC file!"; exit 1; fi
if [ `expr index "${all_output_dir}" " "` -ne 0 ]; then echo "Output dir cannot contain spaces!"; exit 1; fi

# Check subject list
if [ ${#all_subjects[@]} -eq 0 ]
then  # Create default list (all subjects)
    curr_dir="`pwd`"
    cd "${all_input_dir}" || { echo "Unable to open ${all_input_dir}!"; exit 1; }
    all_subjects=(sub-*)
    cd "${curr_dir}" || { echo "Unable to open current directory ${curr_dir}!"; exit 1; }
else  # Check provided list
    for subject in ${all_subjects[@]}
    do
        if [ ! -d "${all_input_dir}/${subject}" ]
        then
            echo "${all_input_dir}/${subject} not found!"
            exit 1
        fi
    done
fi
echo
echo "Number of subjects: ${#all_subjects[@]}"

# Create output path
if [ ! -d "${all_output_dir}" ]
then
    echo
    echo "Creating output directory ${all_output_dir}..."
    mkdir -p "${all_output_dir}" || { echo "Error while creating ${all_output_dir}."; exit 1; }
fi


############################ Processing ##############################

for subject in ${all_subjects[@]}
do
    input_dir="${all_input_dir}/${subject}/${subject}_feat.feat"
    output_dir="${all_output_dir}/${subject}"
    tmp_path="${output_dir}/${temp_folder}"  # Default temp folder
    dr_out="${output_dir}/${subject}_res_d100_dr_stage1.txt"  # Final output

    echo
    echo "Processing subject ${subject}'s data..."

    # Check whether the output directory already exists
    if [ -d "${output_dir}" ]
    then
        echo
        echo "WARNING: output directory ${output_dir} already exists!"

        # Add a plus sign to the temporary path if a folder already exists
        while [ -d "${tmp_path}" ]
        do
            echo "Temp folder ${tmp_path} already exists."
            tmp_path="${tmp_path}+"
        done        
        echo
        echo "Using temp folder ${tmp_path}."

        # Remove output file if it already exists
        if [ -f "${dr_out}" ]
        then
            echo
            echo "WARNING: output file ${dr_out} already exists and will be replaced!"
            rm "${dr_out}"
        fi
    else
        echo
        echo "Creating subject output directory ${output_dir}..."
        mkdir "${output_dir}"
    fi

    if [ ! -d "${input_dir}" ]  # No data
    then
        echo
        echo "WARNING: feat directory ${input_dir} not found!"
        echo "Skipping subject ${subject}. Creating placeholder ${output_dir}/skipped"
        echo > "${output_dir}/skipped" || { echo "Failed to create placeholder!"; exit 1; }
        continue
    fi

    if [ -d "${input_dir}/tfMRI.feat" ]  # Handle a bug in the inputs
    then
        echo
        echo "WARNING: tfMRI.feat sub-folder found and will be used as the input directory!"
        input_dir="${input_dir}/tfMRI.feat"
    fi

    # GLM
    echo
    echo "Calculating the GLM..."
    ${FSLDIR}/bin/film_gls --in="${input_dir}/${glm_dat}" --rn="${tmp_path}" --pd="${input_dir}/${glm_design}" --thr=1000.0 --sa --ms=5

    # Add back the mean
    echo
    echo "Adding back the mean..."
    ${FSLDIR}/bin/fslmaths "${tmp_path}/${res_file}" -add "${input_dir}/${mean_file}" "${tmp_path}/${res_file}"

    # Registration
    echo
    echo "Registrating the residual..."
    ${FSLDIR}/bin/applywarp --ref=${ref_file} --in="${tmp_path}/${res_file}" --out="${tmp_path}/${reg_out}" --warp="${input_dir}/${warp_file}"

    # Dual regression
    echo
    echo "Calculating dual regression..."
    ${FSLDIR}/bin/fsl_glm -i "${tmp_path}/${reg_out}" -d "${ica_file}" -o "${dr_out}" --demean -m ${ref_mask_file}

    ###### CAUTION: rm -rf below! ######
    # Remove stat folder
    echo
    echo "Remove temp folder ${tmp_path}"
    rm -rf "${tmp_path}"
    ####################################

    echo
    echo "Output for subject ${subject}: ${dr_out}"
done
