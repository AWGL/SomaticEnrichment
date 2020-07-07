import sys

# make filpaths for results folder and sampleVCFs file (which contains a list of all samples)
run_id = sys.argv[1]
panel = sys.argv[2]
run_folder = '/data/results/{}/{}'.format(run_id, panel)
samplevcfs_filepath = '{}/sampleVCFs.txt'.format(run_folder)


# get list of all samples from sampleVCFs file - dont add NTC, this is skipped in the pipeline
all_samples = []
with open(samplevcfs_filepath) as samples_file:
    for line in samples_file:
        sample = line.rstrip()
        if sample != 'NTC':
            all_samples.append(sample)


# loop through all samples, removing one each time and saving list to file
for query_sample in all_samples:

    # make a copy of the samples list with the query sample removed
    list_removed_sample = [ sample for sample in all_samples if sample != query_sample ]
    
    # make a string out of the list with file ending after the sample name
    target_str = '.targetcoverage.cnn '.join(list_removed_sample) + '.targetcoverage.cnn'
    antitarget_str = '.antitargetcoverage.cnn '.join(list_removed_sample) + '.antitargetcoverage.cnn'

    # write the strings to a file
    target_output_filepath = '{}/{}/CNVKit/tc.array'.format(run_folder, query_sample)
    with open(target_output_filepath, 'w') as f:
        f.write(target_str)

    antitarget_output_filepath = '{}/{}/CNVKit/atc.array'.format(run_folder, query_sample)
    with open(antitarget_output_filepath, 'w') as f:
        f.write(antitarget_str)
