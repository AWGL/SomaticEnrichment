#!/bin/bash
set -euo pipefail

seqId=$1
sampleId=$2
minBQS=$3
minMQS=$4

gatk=/share/apps/GATK-distros/GATK_4.0.4.0/gatk

$gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    GetPileupSummaries \
    -V /data/db/human/gnomad/gnomad.exomes.r2.0.1.sites.common.bialleleic.vcf.gz \
    -I "$seqId"_"$sampleId".bam \
    -O getpileupsummaries.table    

$gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    CalculateContamination \
    -I getpileupsummaries.table \
    -O calculateContamination.table

$gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    FilterMutectCalls \
    --variant "$seqId"_"$sampleId".vcf.gz \
    --contamination-table calculateContamination.table \
    --min-base-quality-score $minBQS \
    --min-median-mapping-quality $minMQS \
    --output "$seqId"_"$sampleId"_filtered.vcf.gz \
    --verbosity ERROR \
    --QUIET true

$gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    CollectSequencingArtifactMetrics \
    -I "$seqId"_"$sampleId".bam \
    -O seqArtifacts \
    --FILE_EXTENSION ".txt" \
    -R /state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
    --VERBOSITY ERROR \
    --QUIET true

$gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    FilterByOrientationBias \
    -AM G/T \
    -AM C/T \
    -V "$seqId"_"$sampleId"_filtered.vcf.gz \
    -P seqArtifacts.pre_adapter_detail_metrics.txt \
    -O "$seqId"_"$sampleId"_filteredStr.vcf.gz \
    --verbosity ERROR \
    --QUIET true

# split multialleleic calls onto separate line and filter SNVs / Indels < 1%
/share/apps/bcftools-distros/bcftools-1.8/bin/bcftools norm -m - "$seqId"_"$sampleId"_filteredStr.vcf.gz |
    /share/apps/bcftools-distros/bcftools-1.8/bin/bcftools filter -e 'AF < 0.01' |
    /share/apps/bcftools-distros/bcftools-1.8/bin/bcftools view -e 'FILTER="multiallelic" ||
        FILTER="str_contraction"    ||
        FILTER="t_lod"              ||
        FILTER="base_quality"       ||
        FILTER="strand_artifact"    ||
        FILTER="read_position"      ||
        FILTER="orientation_bias"   ||
        FILTER="mapping_quality"    ||
        FILTER="fragment_length"    ||
        FILTER="artifact_in_normal" ||
        FILTER="contamination"      ||
        FILTER="duplicate_evidence" ||
        FILTER="panel_of_normals"' \
        190313_NB551415_0011_AH57W5AFXY_14M07220_filteredStr.vcf.gz > "$seqId"_"$sampleId"_filteredStrLeftAligned.vcf.gz
