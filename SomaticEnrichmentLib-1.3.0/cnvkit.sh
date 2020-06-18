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

# keep track of which samples have already been processed with CNVKit - wipe file clean if it already exists
> /data/results/$seqId/$panel/samplesCNVKit_script1.txt

# schedule each sample to be processed with 1_cnvkit.sh
for i in ${samples[@]}
do
    sample=$(basename $i)
    echo $sample

    qsub -o ./$i/ -e ./$i/  /data/results/$seqId/$panel/$i/SomaticEnrichmentLib-"$version"/1_cnvkit.sh -F "$cnvkit $seqId $panel $sample"
done


numberOfProcessedCnvFiles=0
numberOfInputFiles=$(cat /data/results/$seqId/$panel/sampleVCFs.txt | grep -v 'NTC' | wc -l)

until [ $numberOfProcessedCnvFiles -eq $numberOfInputFiles ]
do
    echo "checking if CNVs are processed"
    sleep 2m
    numberOfProcessedCnvFiles=$(wc -l < /data/results/$seqId/$panel/samplesCNVKit_script1.txt)
done


for i in ${samples[@]}
do
    test_sample=$i
    normal_samples=${samples[@]}

    mkdir -p /data/results/$seqId/$panel/$test_sample/CNVKit/

    echo "${normal_samples[@]/%/.targetcoverage.cnn}" > /data/results/$seqId/$panel/$test_sample/CNVKit/tc_preliminary.array
    sed 's/$i\s//g' /data/results/$seqId/$panel/$test_sample/CNVKit/tc_preliminary.array >>/data/results/$seqId/$panel/$test_sample/CNVKit/tc.array
    echo "${normal_samples[@]/%/.antitargetcoverage.cnn}" > /data/results/$seqId/$panel/$test_sample/CNVKit/atc_preliminary.array
    sed 's/$i\s//g' /data/results/$seqId/$panel/$test_sample/CNVKit/atc_preliminary.array >>/data/results/$seqId/$panel/$test_sample/CNVKit/atc.array

    qsub -o ./$i/ -e ./$i/ /data/results/$seqId/$panel/$i/SomaticEnrichmentLib-"$version"/2_cnvkit.sh  -F "$cnvkit $seqId $panel $test_sample $version"

    cp /data/results/$seqId/$panel/"$test_sample".targetcoverage.cnn /data/results/$seqId/$panel/$test_sample/CNVKit/
    cp /data/results/$seqId/$panel/"$test_sample".antitargetcoverage.cnn /data/results/$seqId/$panel/$test_sample/CNVKit/
    cp /data/results/$seqId/$panel/*.target.bed /data/results/$seqId/$panel/$test_sample/CNVKit/
    cp /data/results/$seqId/$panel/*.antitarget.bed /data/results/$seqId/$panel/$test_sample/CNVKit/

done


# check that cnvkit script 2 have all finished
> /data/results/$seqId/$panel/samplesCNVKit_script2.txt

numberOfProcessedCnvFiles_script2=0
numberOfInputFiles=$(cat /data/results/$seqId/$panel/sampleVCFs.txt | grep -v 'NTC' | wc -l)

until [ $numberOfProcessedCnvFiles_script2 -eq $numberOfInputFiles ]
do
    echo "checking if hotspot CNVs are processed"
    sleep 2m
    numberOfProcessedCnvFiles_script2=$(wc -l < /data/results/$seqId/$panel/samplesCNVKit_script2.txt)
done

