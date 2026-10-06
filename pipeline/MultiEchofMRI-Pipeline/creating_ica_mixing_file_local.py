import pandas as pd
import numpy as np
import sys

sub = sys.argv[1:][0]
class_file = '/data' + str(sub) + '/func/rest/session_1/run_1/Tedana+ManualComponentClassification/desc-tedana_metrics.tsv'
classification_metrics = pd.read_csv(class_file, sep='\t')
accepted_components = []
for index,row in classification_metrics.iterrows():
	if row['classification'] == 'accepted':
		accepted_components.append((row['Component']))

ica_file = '/data/' + str(sub) + '/func/rest/session_1/run_1/Tedana+ManualComponentClassification/desc-ICAOrth_mixing.tsv'
ica_components_mixing = pd.read_csv(ica_file, sep='\t')

renamed_columns = {}
for col in ica_components_mixing:
	col_name = ica_components_mixing[col].name
	num = col_name.replace('ica_', '')
	col_name = "ICA_" + str(num)
	if col_name in accepted_components:
		#print(col_name)
		ica_components_mixing = ica_components_mixing.drop(columns = col)
	else:
		renamed_columns[col] = col_name
ica_components_mixing = ica_components_mixing.rename(columns=renamed_columns)


print(ica_components_mixing)
file_string = "sub-" + str(sub) + '_ses-baseline_task-rest_dir-AP_desc-confounds_timeseries.tsv'
ica_components_mixing.to_csv(file_string, sep='\t')
