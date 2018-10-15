#!/bin/bash

set -euo pipefail

seqId=$1
sampleId=$2
panel=$3
minimumCoverage=$4
vendorCaptureBed=$5
padding=$6
minBQS=$7
minMQS=$8
worklistId=$9

# gatk3=/share/apps/GATK-distros/GATK_3.8.0/GenomeAnalysisTK.jar

version=0.0.1

# calculate gene percentage coverage
/share/apps/jre-distros/jre1.8.0_101/bin/java -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx8g -jar /data/diagnostics/apps/CoverageCalculator-2.0.2/CoverageCalculator-2.0.2.jar \
"$seqId"_"$sampleId"_DepthOfCoverage \
/data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/"$panel"/"$panel"_genes.txt \
/state/partition1/db/human/refseq/ref_GRCh37.p13_top_level.gff3 \
-p5 \
-d"$minimumCoverage" \
> "$seqId"_"$sampleId"_PercentageCoverage.txt

#Gather QC metrics
totalReads=$(head -n8 "$seqId"_"$sampleId"_HsMetrics.txt | tail -n1 | cut -s -f6) #The total number of reads in the SAM or BAM file examine.
pctSelectedBases=$(head -n8 "$seqId"_"$sampleId"_HsMetrics.txt | tail -n1 | cut -s -f19) #On+Near Bait Bases / PF Bases Aligned.
totalTargetedUsableBases=$(head -n2 $seqId"_"$sampleId"_DepthOfCoverage".sample_summary | tail -n1 | cut -s -f2) #total number of usable bases.
meanOnTargetCoverage=$(head -n2 $seqId"_"$sampleId"_DepthOfCoverage".sample_summary | tail -n1 | cut -s -f3) #avg usable coverage
pctTargetBasesCt=$(head -n2 $seqId"_"$sampleId"_DepthOfCoverage".sample_summary | tail -n1 | cut -s -f7) #percentage panel covered with good enough data for variant detection


#Add VCF meta data to final VCF
grep '^##' "$seqId"_"$sampleId"_PASS.vcf > "$seqId"_"$sampleId"_PASS_meta.vcf
echo \#\#SAMPLE\=\<ID\="$sampleId",Tissue\=Somatic,WorklistId\="$worklistId",SeqId\="$seqId",Assay\="$panel",PipelineName\=SomaticEnrichment,PipelineVersion\="$version",TotalReads\="$totalReads",PctSelectedBases\="$pctSelectedBases",MeanOnTargetCoverage\="$meanOnTargetCoverage",PctTargetBasesCt\="$pctTargetBasesCt",TotalTargetedUsableBases\="$totalTargetedUsableBases",RemoteVcfFilePath\=$(find $PWD -type f -name "$seqId"_"$sampleId"_filtered_meta.vcf),RemoteBamFilePath\=$(find $PWD -type f -name "$seqId"_"$sampleId".bam)\> >> "$seqId"_"$sampleId"_PASS_meta.vcf
grep -v '^##' "$seqId"_"$sampleId"_PASS.vcf >> "$seqId"_"$sampleId"_PASS_meta.vcf

echo "parse VCF"

#write full dataset to table
/share/apps/jre-distros/jre1.8.0_101/bin/java -Djava.io.tmpdir=/state/partition1/tmpdir -jar /data/diagnostics/apps/VCFParse/VCFParse-1.0.0/VCFParse.jar \
-V "$seqId"_"$sampleId"_PASS_meta.vcf \
-T /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/"$panel"/"$panel"_PreferredTranscripts.txt \
-C /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/"$panel"/"$panel"_KnownVariants.vcf \
-K
