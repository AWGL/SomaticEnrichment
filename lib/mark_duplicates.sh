#!/bin/bash
set -euo pipefail

# Christopher Medway AWMGS
# marks duplicated for all BAM files that have been generated for a sample
# merges across lanes

echo "removing duplicates and merging lanes"

seqId=$1
sampleId=$2

/share/apps/jre-distros/jre1.8.0_131/bin/java \
    -XX:GCTimeLimit=50 \
    -XX:GCHeapFreeLimit=10 \
    -Djava.io.tmpdir=/state/partition1/tmpdir \
    -Xmx2g \
    -jar /share/apps/picard-tools-distros/picard-tools-2.18.5/picard.jar \
    MarkDuplicates \
    $(ls "$seqId"_"$sampleId"_*_aligned.bam | \sed 's/^/I=/' | tr '\n' ' ') \
    OUTPUT="$seqId"_"$sampleId"_rmdup.bam \
    METRICS_FILE="$seqId"_"$sampleId"_markDuplicatesMetrics.txt \
    CREATE_INDEX=true \
    MAX_RECORDS_IN_RAM=2000000 \
    VALIDATION_STRINGENCY=SILENT \
    TMP_DIR=/state/partition1/tmpdir \
    QUIET=true \
    VERBOSITY=ERROR

rm "$seqId"_"$sampleId"_*_aligned.bam
rm "$seqId"_"$sampleId"_*_aligned.bai
