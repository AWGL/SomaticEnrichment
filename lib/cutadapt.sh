#!/bin/bash
set -euo pipefail

echo "running cutadapt"

seqId=$1
sampleId=$2
laneId=$3
read1Fastq=$4
read2Fastq=$5
read1Adapter=$6
read2Adapter=$7

# -m is the minumun read length
/share/apps/anaconda2/bin/cutadapt \
    -a "$read1Adapter" \
    -A "$read2Adapter" \
    -m 50 \
    -o "$seqId"_"$sampleId"_"$laneId"_R1.fastq \
    -p "$seqId"_"$sampleId"_"$laneId"_R2.fastq \
    "$read1Fastq" \
    "$read2Fastq"
