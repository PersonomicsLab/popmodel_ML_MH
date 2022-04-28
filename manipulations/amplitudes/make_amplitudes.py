import os
import numpy as np

sub_list_loc = "/scratch/janine.bijsterbosch/WAPIAW_2/subj_lists/sub_list.csv"  # filename of list of subject IDs
read_dir = "/scratch/janine.bijsterbosch/Ruiqi/rsfMRI"                          # resting state data directory
savedir = "/scratch/janine.bijsterbosch/WAPIAW_2/imaging"                       # output directory

fsuffix = "_d100_dr_stage1.txt"                                                 # filename suffix
sub_list = ['sub-' + str(int(i)) for i in np.genfromtxt(sub_list_loc)]          # subject list

good_comps_loc = "/scratch/janine.bijsterbosch/Ruiqi/rfMRI_GoodComponents_d100_v1.txt"  # list of good rfMRI 100d ICA components (UKB data)
good_comps = np.genfromtxt(good_comps_loc)-1                                    # change to python indexing (0-start)
good_comps = [int(i) for i in good_comps]                                       # change datatype

all_amps=[]
for i in sub_list:
    alldata_i_loc = os.path.join(read_dir, i+fsuffix)           # resting state data filename
    alldata_i = np.genfromtxt(alldata_i_loc)                    # resting state ICA timeseries data
    data_i = alldata_i[:,good_comps]                            # non-noise ICA components of data
    amps_i = np.std(data_i,axis=0)                              # compute amplitude (standard deviation) of signal
    all_amps.append(amps_i)                                     # amplitudes list

saveloc = os.path.join(savedir,"dr_stage1_amplitudes.txt")      # output filename
np.savetxt(saveloc, all_amps)                                   # save amplitudes to output
