#!/bin/bash

# Author: Ruiqi Chen
# version: 01/12/2022


############################## Documentation #############################

Help()
{
    echo
    echo "Write scripts to run the processing program and submit them to Slurm."
    echo
    echo "Usage: launch_job.sh [-h] [-s <sub_list>] [-n <n_sub>] [-a <array_size>] [-j <job_size>] [-l <log_dir_prefix>] [-p <program>] [-i <input_dir>] [-o <output_dir>] [-f <ica_file>]"
    echo
    echo "-h                   Print this help message and exit."
    echo "-s <sub_list>        Set the file containing a list of all folders to process."
    echo "-n <n_sub>           Processs the first <n_sub> folders in subject list file."
    echo "-a <array_size>      Set the number of jobs to run in parallel in a job array."
    echo "-j <job_size>        Set the number of subjects to process (serially) in a job."
    echo "-l <log_dir_prefix>  Set the log directory as \"\${log_dir_prefix}-xxx\" (from 001 to 999, increasing after each launch)"
    echo "-p <program>         Name and path of the processing script."
    echo "-i <input_dir>       Set the input directory containing all subject's data."
    echo "-o <output_dir>      Set output directory."
    echo "-f <ica_file>        Set group ICA file."
    echo
    echo "Inputs:"
    echo
    echo "This script will load the subject list in <sub_list> and process the first <n_sub> of them (or all of them, if <n_sub> is larger than the number of subjects in the list)."
    echo
    echo "If <sub_list> does not exist, it will be created with a list of all folders entitled \"sub-*\" under <input_dir>. The first <n_sub> (or all if <n_sub> is larger) of them will be processed."
    echo
    echo "Outputs:"
    echo
    echo "A log directory \"\${log_dir_prefix}-xxx\" (xxx is the smallest available integer from 001 to 999) will be created, with several pairs of configuration files and scripts (one for each job array)."
    echo
    echo "The bash script for each job array is named \"array-xxxxx.sh\" (xxxxx from 00001 to 99999). The corresponding configuration file is \"array-xxxxx.cfg\", which contains a list of folder names to process for each job in each line."
    echo
    echo "Note:"
    echo
    echo "This script will not wait for the jobs to finish. You may want to check whether they're successful and update the <sub_list> after finishing the jobs."
    echo
}


########################### Default Parameters ###########################

# Subjects
sub_list="./testing/sub_list.txt"  # The list of the to-be-processed subjects
n_sub=7  # Number of the subjects to be processed in this whole script
array_size=2  # Number of jobs to run in an array in each launch
job_size=2  # Number of subjects to be processed in each job, will be reduced if job_size array_size > n_sub

# Log directory
log_dir_prefix="testing/launch"  # Default log directory name ("launch-001" to "launch-999")

# Program
my_program="./convert_res.sh"
my_input="/ceph/biobank/derivatives/feat"
my_output="./testing"
my_ica="./rfMRI_ICA_d100.nii.gz" 

# Computation
wall_time="23:59:59"
mail_user="chen.ruiqi@wustl.edu"


####################### Command line input #########################

while getopts ":hs:n:a:j:l:p:i:o:f:" opt
do
    case "${opt}" in
        "h") Help; exit;;
        "s") sub_list="${OPTARG}";;
        "n") n_sub=${OPTARG};;
        "a") array_size=${OPTARG};;
        "j") job_size=${OPTARG};;
        "l") log_dir_prefix="${OPTARG}";;
        "p") my_program="${OPTARG}";;
        "i") my_input="${OPTARG}";;
        "o") my_output="${OPTARG}";;
        "f") my_ica="${OPTARG}";;
        ":") echo "Missing argument for option -${OPTARG}"; exit 1;;
        "?") echo "Unknown option -${OPTARG}"; exit 1;;
        *) echo "Unknown error while parsing arguments"; exit 1;;
    esac
done


###################### Generate subject list ###########################

echo "Loading subject list..."
if [ ! -f "${sub_list}" ]  # Generate subject list if file doesn't exist
then
    echo "WARNING: subject list file doesn't exist, using all \"sub-*\" folders in input directory as subject list!"
    curr_dir="`pwd`"
    cd "${my_input}" || { echo "Unable to open ${my_input}!"; exit 1; }
    all_sub=(sub-*)
    cd "${curr_dir}" || { echo "Unable to open current directory ${curr_dir}!"; exit 1; }

    sub_list_dir="`dirname \"${sub_list}\"`"
    mkdir -p "${sub_list_dir}" || { echo "Error creating the directory for subject list file!"; exit 1; }
    for curr in ${all_sub[@]}
    do
        echo ${curr} >> "${sub_list}" || { echo "Error writting into subject list file!"; exit 1; }
    done
else  # Load subject list
    all_sub=(`head -n ${n_sub} "${sub_list}"`)
    if [ ${#all_sub[@]} -eq 0 ]
    then
        echo "No subject found in ${sub_list}! Please check whether error occurs."
        exit
    fi
fi

# Check whether n_sub is larger than the number of available subjects
if [ ${#all_sub[@]} -lt ${n_sub} ]
then
    n_sub=${#all_sub[@]}
else
    all_sub=(${all_sub[@]::${n_sub}})
fi


####################### Prepare the launch log ######################

# Total number of jobs
if [ `expr ${n_sub} % ${job_size}` -eq 0 ]
then
    n_job=`expr ${n_sub} / ${job_size}`
else
    n_job=`expr ${n_sub} / ${job_size} + 1`
fi

# Total number of job arrays
if [ `expr ${n_job} % ${array_size}` -eq 0 ]
then
    n_array=`expr ${n_job} / ${array_size}`
else
    n_array=`expr ${n_job} / ${array_size} + 1`
fi

echo "Total number of subjects: ${n_sub}"
echo "Total number of jobs: ${n_job}"
echo "Total number of job arrays: ${n_array}"

# Create log directory
launchID=1
while [ ${launchID} -lt 1000 ]
do
    log_dir="`printf \"%s-%03d\" \"${log_dir_prefix}\" ${launchID}`"
    if [ ! -d "${log_dir}" ]
    then
        if mkdir -p "${log_dir}"  # Successfully create log directory
        then
            echo "Creating log directory ${log_dir}"
            break
        else
            echo "Error creating log directory ${log_dir}"
            exit 1
        fi
    fi
    launchID=`expr ${launchID} + 1`
done
if [ "${launchID}" -eq 1000 ]; then echo "Cannot create log directory."; exit 1; fi


########################## Write the input and the script #########################

start_ind=0  # Starting subject index for current job
for arrayID in `seq ${n_array}`  # Array index starting from 1
do
    # Number of jobs in this array
    if [ ${arrayID} -eq ${n_array} -a `expr ${n_job} % ${array_size}` -ne 0 ]
    then
        n_job_in_array=`expr ${n_job} % ${array_size}`
    else
        n_job_in_array=${array_size}
    fi

    # Create input file
    curr_input_file="`printf \"%s/array-%05d.cfg\" \"${log_dir}\" ${arrayID}`"
    for jobID in `seq ${n_job_in_array}`
    do
        sub_in_job=(${all_sub[@]:${start_ind}:${job_size}})
        echo "${sub_in_job[@]}" >> "${curr_input_file}"
        start_ind=`expr ${start_ind} + ${#sub_in_job[@]}`
    done

    # Create scripts
    curr_script_file="`printf \"%s/array-%05d.sh\" \"${log_dir}\" ${arrayID}`"
    curr_output_file="`printf \"%s/array-%05d_%%a.out\" \"${log_dir}\" ${arrayID}`"
    echo "\
\
#!/bin/bash

#SBATCH -J cvt_res                  ###        Job name         ###
#SBATCH -o \"${curr_output_file}\"  ###       Output file       ###
#SBATCH -N 1                        ### Number of cluster nodes ###
#SBATCH -n 1                        ### Number of CPU per node  ###
#SBATCH --mem 4G                    ###     Memory per node     ###
#SBATCH -t ${wall_time}             ###        Wall time        ###
#SBATCH --mail-type END
#SBATCH --mail-user ${mail_user}
#SBATCH --array 1-${n_job_in_array}

module load fsl
subjects=\"\`head -n \$SLURM_ARRAY_TASK_ID \\\"${curr_input_file}\\\" | tail -n 1\`\"
srun \"${my_program}\" -i \"${my_input}\" -o \"${my_output}\" -f \"${my_ica}\" -s \"\$subjects\"\
\
" > "${curr_script_file}"  # Overwritting

    # Make script executable
    chmod +x "${curr_script_file}" || { echo "Error changing the script permission!"; exit 1; }

    # Submit scripts
    sbatch "${curr_script_file}" || { echo "Error submitting jobs!"; exit 1; }
done