#!/bin/bash
#PBS -l walltime=48:00:00
#PBS -l ncpus=12
set -euo pipefail

PBS_O_WORKDIR=(`echo $PBS_O_WORKDIR | sed "s/^\/state\/partition1//"`)
cd $PBS_O_WORKDIR

# Description: Somatic Enrichment Pipeline. Requires fastq file split by lane
# Author:      Christopher Medway, All Wales Medical Genetics Service. Includes code from GermlineEnrichment-2.5.2
# Mode:        BY_SAMPLE
# Use:         bash within sample directory

version="1.3.0"

# load sample variables
. *.variables

# copy script library
cp -r /data/diagnostics/pipelines/"$pipelineName"/"$pipelineName"-"$pipelineVersion"/SomaticEnrichmentLib-"$version" /data/results/"$seqId"/"$panel"/"$sampleId"/

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
    ./SomaticEnrichmentLib-"$version"/cutadapt.sh \
        $seqId \
        $sampleId \
        $laneId \
        $read1Fastq \
        $read2Fastq \
        $read1Adapter \
        $read2Adapter

    # fastqc
    ./SomaticEnrichmentLib-"$version"/fastqc.sh $seqId $sampleId $laneId

     # fastq to ubam
    ./SomaticEnrichmentLib-"$version"/fastq_to_ubam.sh \
        $seqId \
        $sampleId \
        $laneId \
        $worklistId \
        $panel \
        $expectedInsertSize

    # bwa
    ./SomaticEnrichmentLib-"$version"/bwa.sh $seqId $sampleId $laneId
    
done

# merge & mark duplicate reads
./SomaticEnrichmentLib-"$version"/mark_duplicates.sh $seqId $sampleId 

# basequality recalibration
# >100^6 on target bases required for this to be effective
if [ "$includeBQSR = true" ] ; then
    ./SomaticEnrichmentLib-"$version"/bqsr.sh $seqId $sampleId $panel $vendorCaptureBed $padding $gatk4
else
    echo "skipping base quality recalibration"
    cp "$seqId"_"$sampleId"_rmdup.bam "$seqId"_"$sampleId".bam
    cp "$seqId"_"$sampleId"_rmdup.bai "$seqId"_"$sampleId".bai
fi

rm "$seqId"_"$sampleId"_rmdup.bam "$seqId"_"$sampleId"_rmdup.bai

# post-alignment QC
./SomaticEnrichmentLib-"$version"/post_alignment_qc.sh \
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
./SomaticEnrichmentLib-"$version"/hotspot_coverage.sh \
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

# variant calling
./SomaticEnrichmentLib-"$version"/mutect2.sh $seqId $sampleId $pipelineName $version $panel $padding $minBQS $minMQS $vendorCaptureBed $gatk4

# variant filter
./SomaticEnrichmentLib-"$version"/variant_filter.sh $seqId $sampleId $panel $minBQS $minMQS $gatk4

# annotation
# check that there are called variants to annotate
if [ $(grep -v "#" "$seqId"_"$sampleId"_filteredStrLeftAligned.vcf | grep -v '^ ' | wc -l) -ne 0 ]; then
    ./SomaticEnrichmentLib-"$version"/annotation.sh $seqId $sampleId $panel $gatk4
else
    mv "$seqId"_"$sampleId"_filteredStrLeftAligned.vcf "$seqId"_"$sampleId"_filteredStrLeftAligned_annotated.vcf
fi

# generate variant reports
./SomaticEnrichmentLib-"$version"/hotspot_variants.sh $seqId $sampleId $panel $pipelineName $pipelineVersion

# run manta for all samples except NTC
if [ $sampleId != 'NTC' ]; then 
    ./SomaticEnrichmentLib-"$version"/manta.sh $seqId $sampleId $panel $vendorPrimaryBed
fi

# add samplename to run-level file if vcf detected
if [ -e /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filteredStrLeftAligned_annotated.vcf ]
then
    echo $sampleId >> /data/results/$seqId/$panel/sampleVCFs.txt
fi

# tidy up
rm /data/results/$seqId/$panel/$sampleId/*.interval_list
rm /data/results/$seqId/$panel/$sampleId/seqArtifacts.*
rm /data/results/$seqId/$panel/$sampleId/getpileupsummaries.table
rm /data/results/$seqId/$panel/$sampleId/calculateContamination.table


# ---------------------------------------------------------------------------------------------------------
#  RUN LEVEL ANALYSES
# ---------------------------------------------------------------------------------------------------------

numberSamplesInVcf=$(cat ../sampleVCFs.txt | uniq | wc -l)
numberSamplesInProject=$(find ../ -maxdepth 2 -mindepth 2 | grep .variables | uniq | wc -l)

# only the last sample to complete SNV calling will run the following
if [ $numberSamplesInVcf -eq $numberSamplesInProject ]
then

    # run cnv kit
    echo "running CNVKit as $numberSamplesInVcf samples have completed SNV calling"
    ./SomaticEnrichmentLib-"$version"/cnvkit.sh $seqId $panel $vendorPrimaryBed $version

    # generate worksheets
    ./SomaticEnrichmentLib-"$version"/make_variant_report.sh $seqId $panel
    
    # pull all the qc data together and generate combinedQC.txt
    ./SomaticEnrichmentLib-"$version"/compileQcReport.sh $seqId $panel
    
    # tidy up
    rm /data/results/$seqId/$panel/*.cnn
    rm /data/results/$seqId/$panel/*.bed

else
    echo "not all samples have completed running. Finishing process for this sample."
fi
