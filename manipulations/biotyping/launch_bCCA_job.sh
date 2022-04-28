#!/bin/bash

array_size=10  # Number of jobs to run in an array in each launch
job_size=10 # Number of boostraps to run in each job

script_dir="/scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity"

# Log directory
log_dir="/scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity/log"  # Default log directory name ("launch-001" to "launch-999")




########################## Write the input and the script #########################

for n_job in `seq 100`
do
    # Create scripts
    curr_script_file="`printf %s/do_bootstrap_CCA.sh \"${script_dir}\"`"
    curr_output_file="`printf %s/bstrapCCA \"${log_dir}\"`"
    curr_error_file="`printf %s/bstrapCCA \"${log_dir}\"`"
    echo "\
\
#!/bin/bash
#SBATCH -J bstrapCCA                		###        Job name         ###
#SBATCH -e ${curr_error_file}.err  		###       Error file        ###
#SBATCH -o ${curr_output_file}.out  		###       Output file       ###
#SBATCH -N 1                        		### Number of cluster nodes ###
#SBATCH -n 1                        		### Number of CPU per node  ###
#SBATCH --mem 50G                    		###     Memory per node     ###
#SBATCH --time=167:55:00                 	###        Wall time        ###

module load matlab
# run IQ:
# matlab -nodisplay -nojvm -batch \"bootstrap_CCA('sub_list','x20016_2_0','resting_state_separate_proj',${n_job})\"
# run neuroticism:
matlab -nodisplay -nojvm -batch \"bootstrap_CCA('sub_list','x20127_0_0','resting_state_separate_proj',${n_job})\"
\
" > "${curr_script_file}"  # Overwritting

    # Make script executable
    chmod +x "${curr_script_file}" || { echo "Error changing the script permission!"; exit 1; }

    # Submit scripts
    sbatch "${curr_script_file}" || { echo "Error submitting jobs!"; exit 1; }
done



