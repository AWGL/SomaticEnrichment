#!/bin/bash
set -euo pipefail

# Christopher Medway AWMGS
# variant annotation with VEP

seqId=$1
sampleId=$2
panel=$3
gatk4=$4

perl /share/apps/vep-distros/ensembl-tools-release-86/scripts/variant_effect_predictor/variant_effect_predictor.pl \
    --input_file /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filteredStrLeftAligned.vcf \
    --format vcf \
    --output_file /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filteredStrLeftAligned_annotated.vcf \
    --vcf \
    --everything \
    --fork 12 \
    --assembly GRCh37 \
    --no_intergenic \
    --no_progress \
    --allele_number \
    --no_escape \
    --shift_hgvs 1 \
    --cache \
    --cache_version 86 \
    --force_overwrite \
    --no_stats \
    --offline \
    --dir /share/apps/vep-distros/ensembl-tools-release-86/scripts/variant_effect_predictor/annotations \
    --fasta /share/apps/vep-distros/ensembl-tools-release-86/scripts/variant_effect_predictor/annotations \
    --species homo_sapiens \
    --refseq \
    --custom /data/db/human/gnomad/gnomad.exomes.r2.0.1.sites.vcf.gz,GNOMAD,vcf,exact,0,AF \
    --custom /data/db/human/cosmic/b37/cosmic_78.b37.vcf.gz,COSMIC,vcf,exact,0

# index and validation
$gatk4 --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    IndexFeatureFile \
    -F /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filteredStrLeftAligned_annotated.vcf

rm /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_filteredStrLeftAligned.vcf
