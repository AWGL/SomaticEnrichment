#!/bin/bash
set -euo pipefail

# Christopher Medway AWMGS
# compiles a file of useful QC metrics from the multitude of PICARD metrics

seqId=$1
panel=$2


# loop through each sample and make QC file
for sampleId in $(cat ../sampleVCFs.txt); do

    dir=/data/results/$seqId/$panel/$sampleId

    if [ -e $dir/"$seqId"_"$sampleId"_qc.txt ]; then rm $dir/"$seqId"_"$sampleId"_qc.txt; fi

    #Gather QC metrics
    meanInsertSize=$(head -n8 $dir/"$seqId"_"$sampleId"_InsertMetrics.txt | tail -n1 | cut -s -f6) #mean insert size
    sdInsertSize=$(head -n8 $dir/"$seqId"_"$sampleId"_InsertMetrics.txt | tail -n1 | cut -s -f7) #insert size standard deviation
    duplicationRate=$(head -n8 $dir/"$seqId"_"$sampleId"_markDuplicatesMetrics.txt | tail -n1 | cut -s -f9) #The percentage of mapped sequence that is marked as duplicate.
    totalReads=$(head -n8 $dir/"$seqId"_"$sampleId"_HsMetrics.txt | tail -n1 | cut -s -f6) #The total number of reads in the SAM or BAM file examine.
    pctSelectedBases=$(head -n8 $dir/"$seqId"_"$sampleId"_HsMetrics.txt | tail -n1 | cut -s -f19) #On+Near Bait Bases / PF Bases Aligned.
    totalTargetedUsableBases=$(head -n2 $dir/$seqId"_"$sampleId"_DepthOfCoverage".sample_summary | tail -n1 | cut -s -f2) #total number of usable bases. NB BQSR requires >= 100M, ideally >= 1B
    percentUseableBasesOnTarget=$(head -n8 $dir/"$seqId"_"$sampleId"_HsMetrics.txt | tail -n1 | cut -s -f27)
    meanOnTargetCoverage=$(head -n2 $dir/$seqId"_"$sampleId"_DepthOfCoverage".sample_summary | tail -n1 | cut -s -f3) #avg usable coverage
    pctTargetBasesCt=$(head -n2 $dir/$seqId"_"$sampleId"_DepthOfCoverage".sample_summary | tail -n1 | cut -s -f7) #percentage panel covered with good enough data for variant detection

    #freemix=$(tail -n1 $dir/"$seqId"_"$sampleId"_Contamination.selfSM | cut -s -f7) #percentage DNA contamination. Should be <= 0.02
    pctPfReadsAligned=$(grep ^PAIR $dir/"$seqId"_"$sampleId"_AlignmentSummaryMetrics.txt | awk '{print $7*100}') #Percentage mapped reads
    atDropout=$(head -n8 $dir/"$seqId"_"$sampleId"_HsMetrics.txt | tail -n1 | cut -s -f51) #A measure of how undercovered <= 50% GC regions are relative to the mean
    gcDropout=$(head -n8 $dir/"$seqId"_"$sampleId"_HsMetrics.txt | tail -n1 | cut -s -f52) #A measure of how undercovered >= 50% GC regions are relative to the mean

    # check FASTQC output
    countQCFlagFails() {
        #count how many core FASTQC tests failed
        grep -E "Basic Statistics|Per base sequence quality|Per tile sequence quality|Per sequence quality scores|Per base N content" "$1" | \
        grep -v ^PASS | \
        grep -v ^WARN | \
        wc -l | \
        sed 's/^[[:space:]]*//g'
    }

    rawSequenceQuality=PASS
    for report in $dir/FASTQC/"$seqId"_"$sampleId"_*_fastqc.txt;
    do
        if [ $(countQCFlagFails $report) -gt 0 ]; then
            rawSequenceQuality=FAIL
        fi
    done

    # Sex check removed as it was unstable. 
    # sex check
    # this file will not be avilable for NTC
    #if [ $sampleId == "NTC" ]; then
    #    ObsSex='Null'
    #elif [ ! -e /data/results/$seqId/$panel/$sampleId/CNVKit/*.sex ]; then
    #    ObsSex='Unknown'
    #else
    #    ObsSex=$(cat /data/results/$seqId/$panel/$sampleId/CNVKit/*.sex | grep .cnr | cut -f2)
    #fi

    # keeping placeholder sex variable in report
    ObsSex='Unknown'

    #Print QC metrics
    echo -e "TotalReads\tRawSequenceQuality\tGender\tTotalTargetUsableBases\tPercentTargetUseableBases\tDuplicationRate\tPctSelectedBases\tPctTargetBasesCt\tMeanOnTargetCoverage\tMeanInsertSize\tSDInsertSize\tPercentMapped\tAtDropout\tGcDropout" > $dir/"$seqId"_"$sampleId"_QC.txt
    echo -e "$totalReads\t$rawSequenceQuality\t$ObsSex\t$totalTargetedUsableBases\t$percentUseableBasesOnTarget\t$duplicationRate\t$pctSelectedBases\t$pctTargetBasesCt\t$meanOnTargetCoverage\t$meanInsertSize\t$sdInsertSize\t$pctPfReadsAligned\t$atDropout\t$gcDropout" >> $dir/"$seqId"_"$sampleId"_QC.txt

done


# generate combinedQC.txt
python /data/diagnostics/scripts/merge_qc_files.py /data/results/$seqId/$panel/
