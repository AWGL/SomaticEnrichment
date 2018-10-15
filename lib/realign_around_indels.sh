#!/bin/bash
set -euo pipefail

# DEPRECATED - NO LONGER RECOMMENDED AS PART OF GATK PIPELINE

echo "realigning around duplicates"

seqId=$1
sampleId=$2
pipeline=$3
version=$4
panel=$5

gatk=/share/apps/GATK-distros/GATK_4.0.4.0/gatk

# identify candidate realignment regions
$gatk \
-T RealignerTargetCreator \
-R /state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
-known /state/partition1/db/human/gatk/2.8/b37/1000G_phast1.indels.b37.vcf \
-known /state/partition1/db/human/gatk/2.8/b37/Mills_and_1000G_gold_standard.indels.b37.vcf \
-I "$seqId"_"$sampleId"_rmdup.bam \
-o "$seqId"_"$sampleId"_realign.intervals \
-L /home/cm/"$pipeline"/"$pipeline"-"$version"/"$panel"/"$panel"_ROI_b37.bed \
-ip 100 \
-dt NONE
