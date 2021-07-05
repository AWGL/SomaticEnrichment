import csv
import sys

'''
Filters 1p19q results and generates variant report

- Loads in segmetrics file from CNVKit, which contains CNV calls
- Filter to include only calls overlapping 1p/19q
- Output these calls as <sample>_1p19q.txt

- Load in <sample>_Glioma CNV calls
- Merge this file with the 1p19q results to make <sample>_Glioma_1p19q.txt
'''


# load in variables and make filepath
seq_id = sys.argv[1]
sample = sys.argv[2]
path = '/data/results/{}/RochePanCancer/{}'.format(seq_id, sample)

# path to input files
seg_file = '{}/CNVKit/{}.segmetrics.cns'.format(path, sample)
glioma_file = '{}/hotspot_cnvs/{}_Glioma'.format(path, sample)
tumour_file = '{}/hotspot_cnvs/{}_Tumour'.format(path, sample)

# path for output files
output_file_1p19q = '{}/hotspot_cnvs/{}_1p19q.txt'.format(path, sample)
output_file_1p19q_glioma = '{}/hotspot_cnvs/{}_Glioma_1p19q.txt'.format(path, sample)
output_file_1p19q_tumour = '{}/hotspot_cnvs/{}_Tumour_1p19q.txt'.format(path, sample)

# load dict of input files
seg_file_dict = csv.DictReader(open(seg_file), delimiter='\t')
glioma_file_dict = csv.DictReader(open(glioma_file), delimiter='\t')
tumour_file_dict = csv.DictReader(open(tumour_file), delimiter='\t')

# start and end co-ords of 1p and 19q
start_1p = 0
end_1p = 121535433

start_1q=124535435
end_1q=249250621

start_19p=0
end_19p=24681781

start_19q = 27681783
end_19q = 59128983

# filter seg_file to pull out regions overlapping with 1p or 19q
# can be either- regions starts within 1p/19q OR region ends within 1p/19q OR region completely overlaps with 1p/19q
combined = []
for row in seg_file_dict:
    
    if row['chromosome'] == '1':
        # check coords
        start = int(row['start'])
        end = int(row['end'])
        if ((start <= end_1p) and (end >= start_1q)):
            row['gene/region'] = '1p/1q'
            combined.append(row)
        elif ((start <= start_1p <= end) and (end < end_1p)) or ((start <= end_1p <= end) and (end < start_1q))  or (start_1p <= start and end_1p >= end):
            row['gene/region'] = '1p'
            combined.append(row)
        elif ((start <= start_1q <= end) and (start > end_1p)) or ((start <= end_1q <= end) and (start > end_1p)) or (start_1q <= start and end_1q >= end):
            row['gene/region'] = '1q'
            combined.append(row)

    elif row['chromosome'] == '19':
        # check coords
        start = int(row['start'])
        end = int(row['end'])
        if ((start<= end_19p) and (end >= start_19q)):
            row['gene/region'] = '19p/19q'
            combined.append(row)
        elif ((start <= start_19p <= end) and (end < end_19p)) or ((start <= end_19p <= end) and (end < start_19q))  or (start_19p <= start and end_19p >= end):
            row['gene/region'] = '19p'
            combined.append(row)
        elif ((start <= start_19q <= end) and (start > end_19p)) or ((start <= end_19q <= end) and (start > end_19p)) or (start_19q <= start and end_19q >= end):
            row['gene/region'] = '19q'
            combined.append(row)


# format dict for outputting data
# make empty list of lists to write to file
out_1p19q = []
out_1p19q_glioma = []
out_1p19q_tumour = []

# add headers to list
columns = ['gene/region', 'chromosome', 'start', 'end', 'log2', 'depth', 'weight', 'baf', 'ci_hi', 'ci_lo', 'n_bins', 'segment_weight', 'segment_probes']
out_1p19q.append(columns)
out_1p19q_glioma.append(columns)
out_1p19q_tumour.append(columns)

# format dict for outputting data and add them to output lists
# calls from original glioma file
for c in glioma_file_dict:
    # set missing values as N/A
    if 'baf' not in c.keys():
        c['baf'] = 'N/A'

    # pull out these values from the dict into the output list
    # gene/region is called gene in this dict
    key_list = ['gene', 'chromosome', 'start', 'end', 'log2', 'depth', 'weight', 'baf', 'ci_hi', 'ci_lo', 'n_bins', 'segment_weight', 'segment_probes']
    out_1p19q_glioma.append([c[k] for k in key_list])

# calls from original tumour file
for c in tumour_file_dict:
    # set missing values as N/A
    if 'baf' not in c.keys():
        c['baf'] = 'N/A'

    # pull out these values from the dict into the output list
    # gene/region is called gene in this dict
    key_list = ['gene', 'chromosome', 'start', 'end', 'log2', 'depth', 'weight', 'baf', 'ci_hi', 'ci_lo', 'n_bins', 'segment_weight', 'segment_probes']
    out_1p19q_tumour.append([c[k] for k in key_list])

# combine 1p19q calls with glioma/tumour calls
for c in combined:
    # set missing values as N/A
    c['n_bins'] = 'N/A'
    c['segment_weight'] = 'N/A'
    if 'baf' not in c.keys():
        c['baf'] = 'N/A'

    # pull out these values from the dict into the output list
    # segment_probes is called probes in this dict
    key_list = ['gene/region', 'chromosome', 'start', 'end', 'log2', 'depth', 'weight', 'baf', 'ci_hi', 'ci_lo', 'n_bins', 'segment_weight', 'probes']
    l = [c[k] for k in key_list]
    out_1p19q.append(l)
    out_1p19q_glioma.append(l)
    out_1p19q_tumour.append(l)


# write to file
with open(output_file_1p19q, 'w') as f:
    writer = csv.writer(f, delimiter='\t')
    writer.writerows(out_1p19q)

with open(output_file_1p19q_glioma, 'w') as f:
    writer = csv.writer(f, delimiter='\t')
    writer.writerows(out_1p19q_glioma)

with open(output_file_1p19q_tumour, 'w') as f:
    writer = csv.writer(f, delimiter='\t')
    writer.writerows(out_1p19q_tumour)
