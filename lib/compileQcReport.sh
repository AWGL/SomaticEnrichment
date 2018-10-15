#!/bin/bash
set -euo pipefail

seqId=$1
sampleId=$2

if [ -e "$seqId"_"$sampleId"_qc.txt ]; then rm "$seqId"_"$sampleId"_qc.txt; fi

# gather metrics

# total reads
totalReads=$(head -n8 "$seqId"_"$sampleId"_HsMetrics.txt | tail -n1 | cut -s -f6)

# unique reads (non duplicates)
pctUniqueReads=$(head -n8 "$seqId"_"$sampleId"_HsMetrics.txt | tail -n 1 | cut -s -f10)

# reads aligned
pctAlignedReads=$(head -n8 "$seqId"_"$sampleId"_HsMetrics.txt | tail -n 1 | cut -s -f12)

# on target bases
pctSelectedBases=$(head -n8 "$seqId"_"$sampleId"_HsMetrics.txt | tail -n 1 | cut -s -f19)

# on + near bait bases / PF bases aligned
pctUsableBasesOnTarget=$(head -n8 "$seqId"_"$sampleId"_HsMetrics.txt | tail -n1 | cut -s -f27)

# meanTargetDepth
meanTargetDepth=$(head -n8 "$seqId"_"$sampleId"_HsMetrics.txt | tail -n1 | cut -s -f23)

# total number of usable bases
totalTargetedUsableBases=$(head -n2 "$seqId"_"$sampleId"_DepthOfCoverage.sample_summary | tail -n1 | cut -s -f2)

# avg usable coverage
meanOnTargetCoverage=$(head -n2 "$seqId"_"$sampleId"_DepthOfCoverage.sample_summary | tail -n1 | cut -s -f3)

# percentage panel covered with good enough data for variant detection
pctTargetBasesCt=$(head -n2 "$seqId"_"$sampleId"_DepthOfCoverage.sample_summary | tail -n1 | cut -s -f7)

# Insert Sizes
medInsertSize=$(head -n8 "$seqId"_"$sampleId"_InsertMetrics.txt | tail -n1 | cut -f1)

# check FASTQC output
#countQCFlagFails() {
#    #count how many core FASTQC tests failed
#    grep -E "Basic Statistics|Per base sequence quality|Per tile sequence quality|Per sequence quality scores|Per base N content" "$1" | \
#    grep -v ^PASS | \
#    grep -v ^WARN | \
#    wc -l | \
#    sed 's/^[[:space:]]*//g'
#}

rawSequenceQuality=FAIL
# check FASTQC output
#if [ $(countQCFlagFails "$seqId"_"$sampleId"_"$laneId"_R1_fastqc/fastqc_data.txt) -gt 0 ] || [ $(countQCFlagFails "$seqId"_"$sampleId"_"$laneId"_R2_fastqc/fastqc_data.txt) -gt 0 ]; then
#    rawSequenceQuality=FAIL
#fi

# print QC metrics
echo -e "SampleId\tTotalReads\tPctUniqueReads\tPctAlignedReads\tPctOnTarget\tTotalTargetUsableBases\tPctSelectedBases\tPctUsableBasesOnTarget\tPctTargetBasesCt\tMeanOnTargetCoverage\tMedianInsertSize" > "$seqId"_"$sampleId"_QC.txt
echo -e "$sampleId\t$totalReads\t$pctUniqueReads\t$pctAlignedReads\t$pctSelectedBases\t$totalTargetedUsableBases\t$pctSelectedBases\t$pctUsableBasesOnTarget\t$pctTargetBasesCt\t$meanOnTargetCoverage\t$medInsertSize" >> "$seqId"_"$sampleId"_QC.txt
