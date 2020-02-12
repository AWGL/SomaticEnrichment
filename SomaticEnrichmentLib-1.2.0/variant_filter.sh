#!/bin/bash
set -euo pipefail

# Christopher Medway AWMGS
# Applies filter flags to variant calls.
# Hard filters rare variants (<1%) and only keeps variants
# with PASS, germline_risk and/or clustered_event in FILTER column

seqId=$1
sampleId=$2
panel=$3
minBQS=$4
minMQS=$5
gatk4=$6

$gatk4 --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    GetPileupSummaries \
    -V /data/db/human/gnomad/gnomad.exomes.r2.0.1.sites.common.bialleleic.vcf.gz \
    -I /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId".bam \
    -O /data/results/$seqId/$panel/$sampleId/getpileupsummaries.table    

$gatk4 --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    CalculateContamination \
    -I /data/results/$seqId/$panel/$sampleId/getpileupsummaries.table \
    -O /data/results/$seqId/$panel/$sampleId/calculateContamination.table

$gatk4 --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    FilterMutectCalls \
    --variant /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId".vcf.gz \
    --contamination-table /data/results/$seqId/$panel/$sampleId/calculateContamination.table \
    --min-base-quality-score $minBQS \
    --min-median-mapping-quality $minMQS \
    --tumor-lod 4.7 \
    --output /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filtered.vcf.gz \
    --verbosity ERROR \
    --QUIET true

$gatk4 --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    CollectSequencingArtifactMetrics \
    -I /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId".bam \
    -O seqArtifacts \
    --FILE_EXTENSION ".txt" \
    -R /state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
    --VERBOSITY ERROR \
    --QUIET true

$gatk4 --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    FilterByOrientationBias \
    -AM G/T \
    -AM C/T \
    -V /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filtered.vcf.gz \
    -P /data/results/$seqId/$panel/$sampleId/seqArtifacts.pre_adapter_detail_metrics.txt \
    -O /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filteredStr.vcf.gz \
    --verbosity ERROR \
    --QUIET true

# split multialleleic calls onto separate line and filter SNVs / Indels < 1%
/share/apps/bcftools-distros/bcftools-1.8/bin/bcftools norm -m - /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filteredStr.vcf.gz |
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
        FILTER="panel_of_normals"' > "$seqId"_"$sampleId"_filteredStrLeftAligned.vcf

rm /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filtered.vcf.gz
rm /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId".vcf.gz
rm /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filtered.vcf.gz.tbi
rm /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId".vcf.gz.tbi
