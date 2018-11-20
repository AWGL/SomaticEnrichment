#!/bin/bash
set -euo pipefail

# Description: generate custom variant report given bedfile and vcffile
# Author: Christopher Medway, AWMGL

seqId=$1
sampleId=$2
panel=$3
version=$4

source /home/transfer/miniconda3/bin/activate vcf_parse

if [ -d /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/"$panel"/hotspot_variants ]; then
    
    mkdir hotspot_variants

    for bedFile in /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/"$panel"/hotspot_variants/*.bed;
    do

        target=$(basename "$bedFile" | sed 's/\.bed//g')

        echo $target
        
        python /data/diagnostics/apps/vcf_parse/vcf_parse-0.1.0/vcf_parse.py \
            --transcripts /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/$panel/"$panel"_PreferredTranscripts.txt \
            --transcript_strictness low \
            --config /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/$panel/"$panel"_config.txt \
            --bed $bedFile \
            --output /data/results/$seqId/$panel/$sampleId/hotspot_variants/ \
            /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filteredStr_annotated.vcf

        mv /data/results/$seqId/$panel/$sampleId/hotspot_variants/$sampleId_VariantReport.txt /data/results/$seqId/$panel/$sampleId/hotspot_variants/"$sampleId"_"$target"_VariantReport.txt
    done
fi

        
source /home/transfer/miniconda3/bin/deactivate
