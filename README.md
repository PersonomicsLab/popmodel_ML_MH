# Population Modeling and Mental Health Prediction: Replication Paper Code and Results 

This repository aggregates the code and results data for the forthcoming paper:

"Population modeling with machine learning can enhance measures of mental health - Open-Data Replication" (2022). Ty Easley, Ruiqi Chen, Kayla Hannon, Rosie Dutt, Janine Bijsterbosch.


## Data Sharing and Privacy

This study was conducted with publicly-available data from the UK Biobank (UKB) 20k release. Only prediction output data is aggregated in this repository: no individual-specific inputs or subject ID numbers are included. 


## Results Data and Code Replication

Results can be replicated using the code in the "prediction" directory on UKB data; usage examples are available in "prediction/scripts." Prediction outputs for all data are given in "prediction/outputs."

Minimal functions for this paper's data manipulations (biotyping, task residuals, and phenotype averaging) are included in "manipulations."

Prediction outputs are included to allow for the re-plotting and examination of figures. See "figures" directory for more details and instructions on running figure-generating code.

Finally, the file "comp_r2_stats.py" checks whether data manipulations produce statistically significant increases in mean R^2 when compared to our replication of Dadi et al's results on the UKB 20k release or Dadi's results on the 10k release.

## License

[MIT](https://choosealicense.com/licenses/mit/)


### Acknowledgments

This research was performed under UK Biobank application number 47267.
This research was supported by the NIH (1 R34 NS118618-01) and the McDonnell Center for Systems Neuroscience.
