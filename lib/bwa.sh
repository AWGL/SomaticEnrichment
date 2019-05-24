#!/bin/bash
set -euo pipefail

# Christopher Medway AWMGS
# runs BWA-mem over given sample: input unaligned BAM output aligned BAM

echo "extracting reads from to ubam and passing to BWA for alignment"

seqId=$1
sampleId=$2
laneId=$3

/share/apps/jre-distros/jre1.8.0_131/bin/java \
    -XX:GCTimeLimit=50 \
    -XX:GCHeapFreeLimit=10 \
    -Djava.io.tmpdir=/state/partition1/tmpdir \
    -Xmx2g \
    -jar /share/apps/picard-tools-distros/picard-tools-2.18.5/picard.jar \
    SamToFastq \
    I="$seqId"_"$sampleId"_"$laneId"_unaligned.bam \
    FASTQ=/dev/stdout \
    INTERLEAVE=true \
    NON_PF=true \
    MAX_RECORDS_IN_RAM=2000000 \
    TMP_DIR=/state/partition1/tmpdir \
    COMPRESSION_LEVEL=0 \
    QUIET=true \
    VERBOSITY=ERROR \
    | \
    # pipe fastq reads to bwa
   /share/apps/bwa-distros/bwa-0.7.17/bwa mem \
    -M \
    -t 12 \
    -p \
    -v 1 \
    /state/partition1/db/human/mappers/b37/bwa/human_g1k_v37.fasta \
    /dev/stdin \
    | \
    # pipe bam file to merge bam alignment
    /share/apps/jre-distros/jre1.8.0_131/bin/java \
    -XX:GCTimeLimit=50 \
    -XX:GCHeapFreeLimit=10 \
    -Djava.io.tmpdir=/state/partition1/tmpdir \
    -Xmx4g \
    -jar /share/apps/picard-tools-distros/picard-tools-2.18.5/picard.jar \
    MergeBamAlignment \
    EXPECTED_ORIENTATIONS=FR \
    ALIGNED_BAM=/dev/stdin \
    UNMAPPED_BAM="$seqId"_"$sampleId"_"$laneId"_unaligned.bam \
    OUTPUT="$seqId"_"$sampleId"_"$laneId"_aligned.bam \
    REFERENCE_SEQUENCE=/state/partition1/db/human/mappers/b37/bwa/human_g1k_v37.fasta \
    PAIRED_RUN=true \
    SORT_ORDER="coordinate" \
    CLIP_ADAPTERS=false \
    MAX_RECORDS_IN_RAM=2000000 \
    MAX_INSERTIONS_OR_DELETIONS=-1 \
    PRIMARY_ALIGNMENT_STRATEGY=MostDistant \
    CREATE_INDEX=true \
    QUIET=true \
    VERBOSITY=ERROR \
    TMP_DIR=/state/partition1/tmpdir
        

# clean
rm "$seqId"_"$sampleId"_"$laneId"_unaligned.bam
