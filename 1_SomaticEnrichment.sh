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
    ./lib/bqsr.sh $seqId $sampleId $panel $vendorCaptureBed $padding
else
    echo "skipping base quality recalibration"
    cp "$seqId"_"$sampleId"_rmdup.bam "$seqId"_"$sampleId".bam
    cp "$seqId"_"$sampleId"_rmdup.bai "$seqId"_"$sampleId".bai
fi

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
    $minimumCoverage \
    $vendorCaptureBed \
    $padding \
    $minBQS \
    $minMQS

# pull all the qc data together
./lib/compileQcReport.sh $seqId $sampleId

# variant calling
./lib/mutect2.sh $seqId $sampleId $pipelineName $version $panel $padding $minBQS $minMQS $vendorCaptureBed

# variant filter
./lib/variant_filter.sh $seqId $sampleId $minBQS $minMQS

# annotation
./lib/annotation.sh $seqId $sampleId

# add samplename to run-level file if vcf detected
if [ -e /data/results/$seqId/$panel/$sampleId/"seqId"_"$sampleId".vcf.gz ]
then
    echo $sampleId >> /data/results/$seqId/$panel/sampleVCFs.txt
fi

## CNV ANALYSIS

echo "Running CNV Analysis"

# only run if all samples have completed
numberSamplesInVcf=$(cat ../sampleVCFs.txt | uniq | wc -l)
numberSamplesInProject=$(find ../ -maxdepth 2 -mindepth 2 | grep .variables | uniq | wc -l)

if [ $numberSamplesInVcf -eq $numberSamplesInProject ]
then

    echo "running CNVKit as $numberSamplesInVcf samples have completed SNV calling"
    # run cnv kit
    ./lib/cnvkit.sh $seqId $panel $vendorPrimaryBed

    # run gatk somatic CNV calling pipeline
    # bash GATK4_somaticCNV.sh $seqId $sampleId $panel $ROI
else
    echo "not all samples have been run yet!"
fi
