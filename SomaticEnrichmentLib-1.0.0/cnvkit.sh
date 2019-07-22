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

# samples that are not exceptable to use as part of a pooled reference
#low_depth_sample=$(for i in /data/results/$seqId/$panel/*/*HsMetrics.txt; do 
#    if [ $(cat $i | head -n 8 | cut -f 23 | tail -1 | cut -d . -f 1) -lt 100 ]; then echo $i | cut -d/ -f6; fi; 
#done


#  the access function has been pre-run
#  only rerun this if using new annotations
# $cnvkit access \
#    $FASTA \
#    -x ./resources/wgEncodeDacMapabilityConsensusExcludable.bed \
#    -o ./resources/access-excludes.hg19.bed

# 1. RUN FOR ALL SAMPLES IN RUN
$cnvkit autobin $bams -t $vendorCaptureBed -g /data/db/human/cnvkit/access-excludes.hg19.bed --annotate /data/db/human/cnvkit/refFlat.txt 

# keeps track of which samples have already been processed with CNVKit
if [ -e /data/results/$seqId/$panel/samplesCNVKit.txt ]
then
    rm /data/results/$seqId/$panel/samplesCNVKit.txt
fi

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
    numberOfProcessedCnvFiles=$(wc -l < /data/results/$seqId/$panel/samplesCNVKit.txt)
done


for i in ${samples[@]}
do
    test_sample=$i
    normal_samples=( ${samples[@]/$i} )

    mkdir -p /data/results/$seqId/$panel/$test_sample/CNVKit/

    echo "${normal_samples[@]/%/.targetcoverage.cnn}" > /data/results/$seqId/$panel/$test_sample/CNVKit/tc.array
    echo "${normal_samples[@]/%/.antitargetcoverage.cnn}" > /data/results/$seqId/$panel/$test_sample/CNVKit/atc.array

    qsub -o ./$i/ -e ./$i/ /data/results/$seqId/$panel/$i/SomaticEnrichmentLib-"$version"/2_cnvkit.sh  -F "$cnvkit $seqId $panel $test_sample"

    cp /data/results/$seqId/$panel/"$test_sample".targetcoverage.cnn /data/results/$seqId/$panel/$test_sample/CNVKit/
    cp /data/results/$seqId/$panel/"$test_sample".antitargetcoverage.cnn /data/results/$seqId/$panel/$test_sample/CNVKit/
    cp /data/results/$seqId/$panel/*.target.bed /data/results/$seqId/$panel/$test_sample/CNVKit/
    cp /data/results/$seqId/$panel/*.antitarget.bed /data/results/$seqId/$panel/$test_sample/CNVKit/

done
