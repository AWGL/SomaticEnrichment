#!/bin/bash
set -euo pipefail

echo "running fastqc"

seqId=$1
sampleId=$2
laneId=$3

# consider adding --adapter to command
/share/apps/fastqc-distros/fastqc_v0.11.7/fastqc \
    --dir /state/partition1/tmpdir \
    --threads 12 \
    --extract \
    --quiet \
    "$seqId"_"$sampleId"_"$laneId"_R1.fastq \
    "$seqId"_"$sampleId"_"$laneId"_R2.fastq

mv "$seqId"_"$sampleId"_"$laneId"_R1_fastqc/summary.txt "$seqId"_"$sampleId"_"$laneId"_R1_fastqc.txt
mv "$seqId"_"$sampleId"_"$laneId"_R2_fastqc/summary.txt	"$seqId"_"$sampleId"_"$laneId"_R2_fastqc.txt
