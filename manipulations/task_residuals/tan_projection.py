"""tan_projection.py - Estimating covariance matrix and projecting onto the tangent space

Author: Ruiqi Chen
Version: 02/08/2022

Usage: tan_projection.py <residual_dir> <rsfMRI_dir> <good_ic_file> <n_sub> <output_file>

- residual_dir: output of convert_res.sh, with one folder for each subject
- rsfMRI_dir: all resting state IC time series (no subfolders)
- good_ic_file: file containing the indices of good ICs
- n_sub: The script will process the first <n_sub> subjects' data who have both residual and rsfMRI data
- cov_file: output file for the covariances, with the following contains:
    - task_residuals: The task residuals projected onto its own tangent space. It's an 
        (n_sub, n_feature) numpy array, where n_feature should be 55*27=1485.
    - resting_state: Similar to the one above, but for resting state data.
    - concat_data: (n_sub, n_feature) numpy array, computed from the concatenated timeseries,
        where the data will be z-scored within each IC before concatenation and covariance estimation.
- proj_file: output file for the tangent space projections, with the following contains:
    - task_residuals: The task residuals projected onto its own tangent space. It's an 
        (n_sub, n_feature) numpy array, where n_feature should be 55*27=1485.
    - resting_state: Similar to the one above, but for resting state data.
    - transformed_together: a set containing both task residuals and resting state data,
        projected onto a common tangent space, with the following fields:
        - task_residuals: (n_sub, n_feature) numpy array
        - resting_state: same as above, but for resting state data
    - concat_data: (n_sub, n_feature) numpy array, computed from the concatenated timeseries,
        where the data will be z-scored within each IC before concatenation and covariance estimation.

"""

import sys, warnings
from os import path
from glob import glob
import numpy as np
from matplotlib import pyplot as plt
from nilearn.connectome import ConnectivityMeasure

def zscore(x, axis=None):
    """Calculate the z score of data along certain dimension(s)

    Input:
        - x: numpy array
        - axis: the dimension (or iterative of dimensions) to calculate the mean and std, by default will use global mean and std
    Output:
        - y: numpy array, z score of x
    """
    return (x - np.mean(x, axis=axis, keepdims=True)) / np.std(x, axis=axis, keepdims=True)

# Arguments
if len(sys.argv) == 1:
    task_dir = './output'
    rs_dir = './rsfMRI'
    ic_file = './rfMRI_GoodComponents_d100_v1.txt'
    n_sub = 20000
    cov_file = './no_proj.npz'
    proj_file = './tan_proj.npz'
else:
    assert (len(sys.argv) >= 7), 'Missing parameter!'
    task_dir, rs_dir, ic_file, n_sub, cov_file, proj_file = sys.argv[1:7]
    if len(sys.argv) > 6:
        warnings.warn("Warning: Extra arguments were ignored!")

# Find subjects
task_sub = [path.split(curr)[1].replace('_res_d100_dr_stage1.txt', '')
    for curr in glob(task_dir + '/sub-*/sub-*_res_d100_dr_stage1.txt')]
task_sub.sort()
rs_sub = [path.split(curr)[1].replace('_d100_dr_stage1.txt', '')
    for curr in glob(rs_dir + '/sub-*')]
rs_sub.sort()

# Find common subjects
i1, i2, sub_list = 0, 0, []
while len(sub_list) < n_sub and i1 < len(task_sub) and i2 < len(rs_sub):
    if task_sub[i1] == rs_sub[i2]:
        sub_list.append(task_sub[i1])
        i1 += 1
        i2 += 1
    elif task_sub[i1] < rs_sub[i2]:
        i1 += 1
    else:
        i2 += 1
n_sub = len(sub_list)
print('Found', n_sub, 'common subjects.')

sub_ind = [int(curr.replace('sub-', '')) for curr in  sub_list]
np.savetxt('sub_list.csv', np.array(sub_ind, dtype=np.int32), delimiter=',', fmt='%d')

# Load data
goodIC = np.loadtxt(ic_file, dtype=int) - 1  # Pick these components
taskDat, rsDat, catDat = [], [], []
for currSub in sub_list:
    currTask = np.loadtxt(task_dir + '/' + currSub + '/' + currSub + '_res_d100_dr_stage1.txt')
    currRs = np.loadtxt(rs_dir + '/' + currSub + '_d100_dr_stage1.txt')
    currCat = np.vstack([zscore(currTask, axis=0), zscore(currRs, axis=0)])  # Centered for each IC
    taskDat.append(currTask[np.ix_(range(currTask.shape[0]), goodIC)])
    rsDat.append(currRs[np.ix_(range(currRs.shape[0]), goodIC)])
    catDat.append(currCat[np.ix_(range(currRs.shape[0]), goodIC)])


# ----------------------------- No Projection ------------------------------ #

# Estimation
estimator = ConnectivityMeasure(kind='covariance', vectorize=True, discard_diagonal=True)
taskMat = estimator.fit_transform(taskDat)
rsMat = estimator.fit_transform(rsDat)
catMat = estimator.fit_transform(catDat)

# Save data
np.savez(cov_file, task_residuals=taskMat, resting_state=rsMat, concat_data=catMat)
print('Covariance data saved in', cov_file)


# --------------------------- Tangent space Projection --------------------- #

# Estimation
estimator = ConnectivityMeasure(kind='tangent', vectorize=True, discard_diagonal=True)
taskMat = estimator.fit_transform(taskDat)
rsMat = estimator.fit_transform(rsDat)
allMat = estimator.fit_transform(taskDat + rsDat)
catMat = estimator.fit_transform(catDat)

# Save data
np.savez(proj_file, task_residuals=taskMat, resting_state=rsMat, concat_data=catMat,
    transformed_together={'task_residuals': allMat[:n_sub, :], 'resting_state': allMat[n_sub:, :]})
print('Tangent space projections saved in', proj_file)