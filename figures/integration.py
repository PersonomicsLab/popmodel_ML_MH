"""integration.py

Integrate multiple output .csv files to one big file for plotting, and add one column entitled "method" to indicate the improve methods used, which will become the labels of the figure.

You should call this script with a name of a text (or csv) file. The file should contain N lines of a filename (with path) and the value you want to put in "method" for this file, separated by a comma (no space after comma!).

The output file will be saved in the same directory as the input file, with name "plotting.csv".

Note: the code with also replace the "Mean fluid intelligence" and "Mean neuroticism" with "Fluid intelligence" and "Neuroticism" in the "target" column, otherwise they will be plotted as a different panel. You can turn it off by setting "correct_target_names" as False in the code.
"""

from matplotlib import lines
import pandas as pd
import sys
from os import path

correct_target_names = True

input_file = '/scratch/janine.bijsterbosch/WAPIAW_2/figure_plotting/data_list.txt' if not (
    len(sys.argv) > 1 and path.isfile(sys.argv[1])) else sys.argv[1]
output_file = path.join(path.dirname(input_file), 'plotting.csv')

with open(input_file, 'r') as f:
    lines = f.read().splitlines()
for i, curr_line in enumerate(lines):
    tokens = curr_line.split(sep=',')
    df = pd.read_csv(tokens[0]).assign(method=tokens[1])
    if correct_target_names:
        df = df.replace({'target': 'Mean fluid intelligence'}, 'Fluid intelligence')
        df = df.replace({'target': 'Mean neuroticism'}, 'Neuroticism')
    all_df = df if i == 0 else pd.concat([all_df, df])  # may want .reset_index() too

all_df.to_csv(output_file)

