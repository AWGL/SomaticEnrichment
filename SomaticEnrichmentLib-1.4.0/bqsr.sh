#!/bin/bash
set -euo pipefail

# Christopher Medway AWMGS
# base quality score recalibration

echo "performing base quality recalibraton"

seqId=$1
sampleId=$2
panel=$3
vendorCaptureBed=$4
padding=$5
gatk4=$6

$gatk4 --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    BaseRecalibrator \
    --reference /state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
    --known-sites /state/partition1/db/human/gatk/2.8/b37/dbsnp_138.b37.vcf \
    --known-sites /state/partition1/db/human/gatk/2.8/b37/1000G_phase1.indels.b37.vcf \
    --known-sites /state/partition1/db/human/gatk/2.8/b37/Mills_and_1000G_gold_standard.indels.b37.vcf \
    --input "$seqId"_"$sampleId"_rmdup.bam \
    --intervals $vendorCaptureBed \
    --interval-padding $padding \
    --output "$seqId"_"$sampleId"_recal_data.table \
    --verbosity ERROR \
    --QUIET true

$gatk4 --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    ApplyBQSR \
    --reference /state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
    --bqsr-recal-file "$seqId"_"$sampleId"_recal_data.table \
    --input "$seqId"_"$sampleId"_rmdup.bam \
    --output "$seqId"_"$sampleId".bam \
    --QUIET true \
    --verbosity ERROR

$gatk4 --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    BaseRecalibrator \
    --reference /state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
    --known-sites /state/partition1/db/human/gatk/2.8/b37/dbsnp_138.b37.vcf \
    --known-sites /state/partition1/db/human/gatk/2.8/b37/1000G_phase1.indels.b37.vcf \
    --known-sites /state/partition1/db/human/gatk/2.8/b37/Mills_and_1000G_gold_standard.indels.b37.vcf \
    --input "$seqId"_"$sampleId".bam \
    --intervals $vendorCaptureBed \
    --interval-padding $padding \
    --output "$seqId"_"$sampleId"_post_recal_data.table \
    --verbosity ERROR \
    --QUIET true

$gatk4 --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    AnalyzeCovariates \
    -before "$seqId"_"$sampleId"_recal_data.table \
    -after "$seqId"_"$sampleId"_post_recal_data.table \
    -plots "$seqId"_"$sampleId"_BQSR.pdf

rm *post_recal_data.table
rm *recal_data.table
