# Plotting

The general idea is to use `integration.py` to aggregate relevant data into one `plotting.csv` file and labeled them in an additional column called `method`, then use `violin_plot_*.r` to plot the data in the `plotting.csv` file according to the categories in `method`.

## Setup

You need to set up an R (and Python too, of course) environment through `conda` to run the codes. Follow the instructions [here](https://sites.wustl.edu/chpc/resources/software/r/) to set up the environment. The only package you need is `r-essentials` (so you can simply follow every steps in the webpage).

## The Python script

The `integration.py` script accepts one command line parameter, which is the path to a input text file. In this file, each line should contain the path to a `.csv` output file, and the category associated with it, separated by a single comma (without space). For example:

```bash
/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/prediction/avg_joint_proj_amp_fi_2500.csv,Averaged & Amplitude
/scratch/janine.bijsterbosch/WAPIAW_2/task_residuals/prediction/avg_joint_proj_fi_2500.csv,Average
...
```

The categories used are specified in the plotting R scripts `violin_plot_*.r` -- some examples are:

```R
c("Rest", "Residuals", "Amplitude", "Averaged", "Concatenated",
        "Rest & Amplitude", "Averaged & Amplitude", "Concatenated & Amplitude",
        "Concatenated & Amplitude & Phenotype Averaging",
        "Concatenated & Amplitude & Phenotype Averaging & Distribution Flattening")
```

You can also use other categories, but make sure to change them in the R script too. Another way is to change the display name of these categories in the `labels` option of the `factor` function, just one line below where you can find the above code.

The Python script will output a `plotting.csv` file in the same directory as the input text file.

## The R script

This script will read the `plotting.csv` file and plot a subfigure in one panel for each prediction target (fluid intelligence, neuroticism, age) it found. If you want it to only plot for one or two targets, you can either modify the code or simply don't select the data for the targets you don't want when you run the Python script.

Generally speaking, you need to specify the input `plotting.csv` file, the output filename (without file type extension) and it should be able to work well enough. You can also change the size of the output, the layout of the panels, the font size of labels and so on. Please look at the code for the detailed description of each parameter.
