#!/bin/bash
set -euo pipefail

# Christopher Medway AWMGS
# generation of PICARD metrics for each sample 

seqId=$1
sampleId=$2
panel=$3
minimumCoverage=$4
vendorCaptureBed=$5
vendorPrimaryBed=$6
padding=$7
minBQS=$8
minMQS=$9

#Convert capture BED to interval_list for later
/share/apps/jre-distros/jre1.8.0_131/bin/java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx2g \
    -jar /share/apps/picard-tools-distros/picard-tools-2.18.5/picard.jar BedToIntervalList \
    I=$vendorCaptureBed \
    O="$panel"_capture.interval_list \
    SD=/state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.dict

#Convert primary BED to interval_list for later
/share/apps/jre-distros/jre1.8.0_131/bin/java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx2g \
    -jar /share/apps/picard-tools-distros/picard-tools-2.18.5/picard.jar BedToIntervalList \
    I=$vendorPrimaryBed \
    O="$panel"_primary.interval_list \
    SD=/state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.dict

#Alignment metrics: library sequence similarity
/share/apps/jre-distros/jre1.8.0_131/bin/java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx2g \
    -jar /share/apps/picard-tools-distros/picard-tools-2.18.5/picard.jar CollectAlignmentSummaryMetrics \
    R=/state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
    I="$seqId"_"$sampleId".bam \
    O="$seqId"_"$sampleId"_AlignmentSummaryMetrics.txt \
    MAX_RECORDS_IN_RAM=2000000 \
    TMP_DIR=/state/partition1/tmpdir

#Calculate insert size: fragmentation performance
/share/apps/jre-distros/jre1.8.0_131/bin/java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx2g \
    -jar /share/apps/picard-tools-distros/picard-tools-2.18.5/picard.jar CollectInsertSizeMetrics \
    I="$seqId"_"$sampleId".bam \
    O="$seqId"_"$sampleId"_InsertMetrics.txt \
    H="$seqId"_"$sampleId"_InsertMetrics.pdf \
    MAX_RECORDS_IN_RAM=2000000 \
    TMP_DIR=/state/partition1/tmpdir

#HsMetrics: capture & pooling performance
/share/apps/jre-distros/jre1.8.0_131/bin/java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx2g \
     -jar /share/apps/picard-tools-distros/picard-tools-2.18.5/picard.jar CollectHsMetrics \
     I="$seqId"_"$sampleId".bam \
     O="$seqId"_"$sampleId"_HsMetrics.txt \
     R=/state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
     BAIT_INTERVALS="$panel"_capture.interval_list \
     TARGET_INTERVALS="$panel"_primary.interval_list \
     MAX_RECORDS_IN_RAM=2000000 \
     TMP_DIR=/state/partition1/tmpdir \
     MINIMUM_MAPPING_QUALITY=$minMQS \
     MINIMUM_BASE_QUALITY=$minBQS \
     CLIP_OVERLAPPING_READS=false
