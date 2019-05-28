#!/bin/bash
set -euo pipefail

# Christopher Medway AWMGS
# SNV/Indel calling using Mutect2

seqId=$1
sampleId=$2
pipeline=$3
version=$4
panel=$5
padding=$6
minBQS=$7
minMQS=$8
vendorCaptureBed=$9
gatk4=${10}

$gatk4 --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    Mutect2 \
    --reference /state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
    --input "$seqId"_"$sampleId".bam \
    --tumor $sampleId \
    --genotype-germline-sites true \
    --genotyping-mode DISCOVERY \
    --intervals $vendorCaptureBed \
    --interval-padding $padding \
    --max-population-af 0.5 \
    --output-mode EMIT_ALL_SITES \
    --germline-resource /data/diagnostics/pipelines/$pipeline/"$pipeline"-"$version"/$panel/gnomad.pancancer.r2.0.1.sites.biallelic.vcf.gz \
    --af-of-alleles-not-in-resource 0.0000025 \
    --output "$seqId"_"$sampleId".vcf.gz \
    --verbosity ERROR \
    --QUIET true
