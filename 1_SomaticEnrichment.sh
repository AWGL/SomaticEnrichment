#!/bin/bash
#PBS -l walltime=20:00:00
#PBS -l ncpus=12
set -euo pipefail

PBS_O_WORKDIR=(`echo $PBS_O_WORKDIR | sed "s/^\/state\/partition1//"`)
cd $PBS_O_WORKDIR

# Description: Somatic Enrichment Pipeline. Requires fastq file split by lane
# Author:      Christopher Medway, All Wales Medical Genetics Service. Includes code from GermlineEnrichment-2.5.2
# Mode:        BY_SAMPLE
# Use:         bash within sample directory

version="0.0.1"

# load sample variables
. *.variables

# copy script library
cp -r /data/diagnostics/pipelines/"$pipelineName"/"$pipelineName"-"$pipelineVersion"/lib /data/results/"$seqId"/"$panel"/"$sampleId"/

# load pipeline variables
. /data/diagnostics/pipelines/"$pipelineName"/"$pipelineName"-"$pipelineVersion"/"$panel"/"$panel".variables

# path to panel capture bed file
vendorCaptureBed=/data/diagnostics/pipelines/"$pipelineName"/"$pipelineName"-"$pipelineVersion"/"$panel"/180702_HG19_PanCancer_EZ_capture_targets.bed
vendorPrimaryBed=/data/diagnostics/pipelines/"$pipelineName"/"$pipelineName"-"$pipelineVersion"/"$panel"/180702_HG19_PanCancer_EZ_primary_targets.bed

# path go GATK versions
gatk4=/share/apps/GATK-distros/GATK_4.0.4.0/gatk
gatk3=/share/apps/GATK-distros/GATK_3.8.0/GenomeAnalysisTK.jar

# define fastq variables
for fastqPair in $(ls "$sampleId"_S*.fastq.gz | cut -d_ -f1-3 | sort | uniq)
do
    
    laneId=$(echo "$fastqPair" | cut -d_ -f3)
    read1Fastq=$(ls "$fastqPair"_R1_*fastq.gz)
    read2Fastq=$(ls "$fastqPair"_R2_*fastq.gz)

    # cutadapt
    ./lib/cutadapt.sh \
        $seqId \
        $sampleId \
        $laneId \
        $read1Fastq \
        $read2Fastq \
        $read1Adapter \
        $read2Adapter

    # fastqc
    ./lib/fastqc.sh $seqId $sampleId $laneId

     # fastq to ubam
    ./lib/fastq_to_ubam.sh \
        $seqId \
        $sampleId \
        $laneId \
        $worklistId \
        $panel \
        $expectedInsertSize

    # bwa
    ./lib/bwa.sh $seqId $sampleId $laneId
    
done

# merge & mark duplicate reads
./lib/mark_duplicates.sh $seqId $sampleId 

# basequality recalibration
# >100^6 on target bases required for this to be effective
if [ "$includeBQSR = true" ] ; then
    ./lib/bqsr.sh $seqId $sampleId $panel $vendorCaptureBed $padding $gatk4
else
    echo "skipping base quality recalibration"
    cp "$seqId"_"$sampleId"_rmdup.bam "$seqId"_"$sampleId".bam
    cp "$seqId"_"$sampleId"_rmdup.bai "$seqId"_"$sampleId".bai
fi

rm "$seqId"_"$sampleId"_rmdup.bam "$seqId"_"$sampleId"_rmdup.bai

# post-alignment QC
./lib/post_alignment_qc.sh \
    $seqId \
    $sampleId \
    $panel \
    $minimumCoverage \
    $vendorCaptureBed \
    $vendorPrimaryBed \
    $padding \
    $minBQS \
    $minMQS

# coverage calculations
./lib/hotspot_coverage.sh \
    $seqId \
    $sampleId \
    $panel \
    $pipelineName \
    $pipelineVersion \
    $minimumCoverage \
    $vendorCaptureBed \
    $padding \
    $minBQS \
    $minMQS \
    $gatk3

# pull all the qc data together
./lib/compileQcReport.sh $seqId $sampleId $panel

# variant calling
./lib/mutect2.sh $seqId $sampleId $pipelineName $version $panel $padding $minBQS $minMQS $vendorCaptureBed $gatk4

# variant filter
./lib/variant_filter.sh $seqId $sampleId $panel $minBQS $minMQS $gatk4

# annotation
./lib/annotation.sh $seqId $sampleId $panel $gatk4

# generate variant reports
./lib/hotspot_variants.sh $seqId $sampleId $panel $pipelineName $pipelineVersion

# add samplename to run-level file if vcf detected
if [ -e /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId".vcf.gz ]
then
    echo $sampleId >> /data/results/$seqId/$panel/sampleVCFs.txt
fi

# generate excel reports using virtual Hood
./lib/make_variant_report.sh $seqId $sampleId $referral $worklistId


## CNV ANALYSIS

# only run cnv calling if all samples have completed this far
numberSamplesInVcf=$(cat ../sampleVCFs.txt | uniq | wc -l)
numberSamplesInProject=$(find ../ -maxdepth 2 -mindepth 2 | grep .variables | uniq | wc -l)

if [ $numberSamplesInVcf -eq $numberSamplesInProject ]
then

    echo "running CNVKit as $numberSamplesInVcf samples have completed SNV calling"
    # run cnv kit
    ./lib/cnvkit.sh $seqId $panel $vendorPrimaryBed
else
    echo "not all samples have been run yet!"
fi

rm /data/results/$seqId/$panel/*.cnn
rm /data/results/$seqId/$panel/*.bed
rm /data/results/$seqId/$panel/*.interval_list
rm /data/results/$seqId/$panel/seqArtifacts.*
rm /data/results/$seqId/$panel/getpileupsummaries.table
rm /data/results/$seqId/$panel/calculateContamination.table
