#!/bin/bash
set -euo pipefail

# script should be run once - when last sample in run has been processed
seqId=$1
panel=$2
vendorCaptureBed=$3

FASTA=/data/db/human/gatk/2.8/b37/human_g1k_v37.fasta

# navigate to run directory
cd /data/results/$seqId/$panel/

cnvkit=/share/apps/anaconda2/bin/cnvkit.py
samples=$(cat /data/results/$seqId/$panel/sampleVCFs.txt | grep -v "NTC")
bams=$(for s in $samples; do echo /data/results/$seqId/$panel/$s/"$seqId"_"$s".bam ;done)

#  the access function has been pre-run
#  only rerun this if using new annotations
# $cnvkit access \
#    $FASTA \
#    -x ./resources/wgEncodeDacMapabilityConsensusExcludable.bed \
#    -o ./resources/access-excludes.hg19.bed

# 1. RUN FOR ALL SAMPLES IN RUN
$cnvkit autobin $bams -t $vendorCaptureBed -g /data/db/human/cnvkit/access-excludes.hg19.bed --annotate /data/db/human/cnvkit/refFlat.txt 

if [ -e /data/results/$seqId/$panel/samplesCNVKit.txt ]
then
    rm /data/results/$seqId/$panel/samplesCNVKit.txt
fi


for i in ${samples[@]}
do
    sample=$(basename $i)
    echo $sample

    qsub -o ./$i/ -e ./$i/  /data/results/$seqId/$panel/$i/lib/1_cnvkit.sh -F "$cnvkit $seqId $panel $sample"
done


numberOfProcessedCnvFiles=0
numberOfInputFiles=$(wc -l < /data/results/$seqId/$panel/sampleVCFs.txt)

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


    qsub -o ./$i/ -e ./$i/ /data/results/$seqId/$panel/$i/lib/2_cnvkit.sh  -F "$cnvkit $seqId $panel $test_sample $normal_samples"

    cp /data/results/$seqId/$panel/"$i".targetcoverage.cnn /data/results/$seqId/$panel/$test_sample/CNVKit/
    cp /data/results/$seqId/$panel/"$i".antitargetcoverage.cnn /data/results/$seqId/$panel/$test_sample/CNVKit/
    cp /data/results/$seqId/$panel/*.target.bed /data/results/$seqId/$panel/$i/CNVKit/
    cp /data/results/$seqId/$panel/*.antitarget.bed /data/results/$seqId/$panel/$i/CNVKit/

done
