import csv
import sys
import numpy as np
import pandas as pd
from scipy import stats


## Tests for significantly higher mean validation R^2 after adding data manipulations when compared to (a) the results of Dadi et al. in the 
## 10k UKB release and (b) our replication of those results in the 20k UKB release.
def sig_testing(dlist_name):
    with open(dlist_name,newline='') as fin:
        data_list = list(csv.reader(fin))

    dadi_flist = [i[0] for i in data_list if 'Dadi'==i[1]]      # list of Dadi data files
    rep_flist = [i[0] for i in data_list if 'Rest'==i[1]]       # list of replication data files
    null_hyp_datalist = dadi_flist + rep_flist                  # list of files that will serve as comparison distribution in T-test

    test_hyp_datalist = [i[0] for i in data_list if i[0] not in null_hyp_datalist]
    # test_hyp_datalist = [i for i in data_list if 'Dadi'!=i[1]]
    # test_hyp_datalist = [i[0] for i in test_hyp_datalist if 'Rest'!=i[1]]

    for i in null_hyp_datalist:
        print(i.split('/')[-1].split('.')[0])
        null_r2val = single_summ(i, print_summ=False)

        if 'nc' in i:
            sublist = [k for k in test_hyp_datalist if 'nc' in k]
            other_null = [k for k in null_hyp_datalist if 'nc' in k 
                    and k!=i]
            sublist = other_null+sublist

        if 'fi' in i:
            sublist = [k for k in test_hyp_datalist if 'fi' in k]
            other_null = [k for k in null_hyp_datalist if 'fi' in k 
                    and k!=i]
            sublist = other_null+sublist

        for j in sublist:
            print(j.split('/')[-1].split('.')[0])
            test_r2val = single_summ(j, print_summ=False)
            stat,p = stats.ttest_ind(null_r2val, test_r2val, equal_var=False, alternative='less')
            print(p)

        print("")


def single_summ(fname, print_summ=True):

    with open(fname, newline='') as fin:
        scores_list = list(csv.reader(fin))

    all_scores = pd.DataFrame(data = scores_list[1:], columns = scores_list[0])
    val_scores = all_scores[all_scores["model_testing"] == "validation"]
    gen_scores = all_scores[all_scores["model_testing"] == "generalization"]
    r2_val = [float(i) for i in val_scores.loc[:,"r2_score"]]
    r2_gen = [float(i) for i in gen_scores.loc[:,"r2_score"]]
    if print_summ:
        summarize(r2_val,fname,'validation')
        summarize(r2_gen,fname,'generalization')

    return r2_gen


def summarize(r2,fname,model_testing):
    stderr = np.std(r2)/np.sqrt(len(r2))
    meanval = np.mean(r2)
    conf_int = [meanval - 2*stderr, meanval + 2*stderr]
    print("Summarizing R2 results in " + fname + " ("+model_testing+")")
    print("Mean: " + str(meanval))
    print("Std. Err: " + str(stderr))
    print("95% Confidence interval: " + str(conf_int))
    print("")

    return meanval,stderr


if __name__=="__main__":
    fname = sys.argv[1]
    if '.csv' in fname:
        single_summ(fname)
    if '.txt' in fname:
        sig_testing(fname)
