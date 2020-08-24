#!/bin/bash
set -euo pipefail

# Description: wrapper script to two further CNVKit scripts (1_cnvkit.sh and 2_cnvkit.sh)
# Author:      Christopher Medway  
# Mode:        run once by the final sample to be processed
# Use:         called by 1_SomaticEnrichment.sh

seqId=$1
panel=$2
vendorCaptureBed=$3
version=$4

# resources
FASTA=/data/db/human/gatk/2.8/b37/human_g1k_v37.fasta
cnvkit=/share/apps/anaconda2/bin/cnvkit.py

# navigate to run directory
cd /data/results/$seqId/$panel/

samples=$(cat /data/results/$seqId/$panel/sampleVCFs.txt | grep -v "NTC")
bams=$(for s in $samples; do echo /data/results/$seqId/$panel/$s/"$seqId"_"$s".bam ;done)


# 1. RUN FOR ALL SAMPLES IN RUN
$cnvkit autobin $bams -t $vendorCaptureBed -g /data/db/human/cnvkit/access-excludes.hg19.bed --annotate /data/db/human/cnvkit/refFlat.txt 


# ---------------------------------------------------------------------------------------------------------
#  CNVKit 1
# ---------------------------------------------------------------------------------------------------------

# initialise file to keep track of which samples have already been processed with CNVKit script 1 - wipe file clean if it already exists
> /data/results/$seqId/$panel/samplesCNVKit_script1.txt

# schedule each sample to be processed with 1_cnvkit.sh
for i in ${samples[@]}
do
    sample=$(basename $i)
    echo $sample

    # queue 1_cnvkit
    qsub -o ./$i/ -e ./$i/  /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/SomaticEnrichmentLib-"$version"/1_cnvkit.sh -F "$cnvkit $seqId $panel $sample"

    # make cnvkit directory - needed for make_cnvkit_arrays python script downstream
    mkdir -p /data/results/$seqId/$panel/$sample/CNVKit/
done

# check that cnvkit script 1 have all finished before next step
numberOfProcessedCnvFiles=0
numberOfInputFiles=$(cat /data/results/$seqId/$panel/sampleVCFs.txt | grep -v 'NTC' | wc -l)

until [ $numberOfProcessedCnvFiles -eq $numberOfInputFiles ]
do
    echo "checking if CNVs are processed"
    sleep 2m
    numberOfProcessedCnvFiles=$(wc -l < /data/results/$seqId/$panel/samplesCNVKit_script1.txt)
done


# ---------------------------------------------------------------------------------------------------------
#  CNVKit 2
# ---------------------------------------------------------------------------------------------------------

# initialise file to keep track of which samples have already been processed with CNVKit script 2 - wipe file clean if it already exists
> /data/results/$seqId/$panel/samplesCNVKit_script2.txt

# make tc and atc array for all samples
/home/transfer/miniconda3/bin/python3 /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/SomaticEnrichmentLib-"$version"/make_cnvkit_arrays.py $seqId $panel

# launch cnvkit script 2
for i in ${samples[@]}
do
    test_sample=$i
    normal_samples=${samples[@]}

    cp /data/results/$seqId/$panel/"$test_sample".targetcoverage.cnn /data/results/$seqId/$panel/$test_sample/CNVKit/
    cp /data/results/$seqId/$panel/"$test_sample".antitargetcoverage.cnn /data/results/$seqId/$panel/$test_sample/CNVKit/
    cp /data/results/$seqId/$panel/*.target.bed /data/results/$seqId/$panel/$test_sample/CNVKit/
    cp /data/results/$seqId/$panel/*.antitarget.bed /data/results/$seqId/$panel/$test_sample/CNVKit/

    qsub -o ./$i/ -e ./$i/ /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/SomaticEnrichmentLib-"$version"/2_cnvkit.sh  -F "$cnvkit $seqId $panel $test_sample $version"

done

# check that cnvkit script 2 have all finished before next step
numberOfProcessedCnvFiles_script2=0
numberOfInputFiles=$(cat /data/results/$seqId/$panel/sampleVCFs.txt | grep -v 'NTC' | wc -l)

until [ $numberOfProcessedCnvFiles_script2 -eq $numberOfInputFiles ]
do
    echo "checking if hotspot CNVs are processed"
    sleep 2m
    numberOfProcessedCnvFiles_script2=$(wc -l < /data/results/$seqId/$panel/samplesCNVKit_script2.txt)
done


# ---------------------------------------------------------------------------------------------------------
#  Postprocessing
# ---------------------------------------------------------------------------------------------------------

# combine CNV calls with 1p19q calls for glioma and tumour panels
for sample in $(cat /data/results/$seqId/$panel/sampleVCFs.txt | grep -v 'NTC')
do
    /home/transfer/miniconda3/bin/python3 /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/SomaticEnrichmentLib-"$version"/combine_1p19q.py $seqId $sample
done
