#!/bin/bash
#SBATCH -J bstrapCCA                		###        Job name         ###
#SBATCH -e /scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity/log/bstrapCCA_tst.err  		###       Error file        ###
#SBATCH -o /scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity/log/bstrapCCA_tst.out  		###       Output file       ###
#SBATCH -N 1                        		### Number of cluster nodes ###
#SBATCH -n 1                        		### Number of CPU per node  ###
#SBATCH --mem 50G                    		###     Memory per node     ###
#SBATCH --time=167:55:00                 	###        Wall time        ###

module load matlab
# run IQ:
# matlab -nodisplay -nojvm -batch "bootstrap_CCA('sub_list','x20016_2_0','resting_state_separate_proj',100)"
# run neuroticism:
matlab -nodisplay -nojvm -batch "bootstrap_CCA('sub_list_tiny','x20127_0_0','resting_state_separate_proj',100)"
