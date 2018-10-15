#!/bin/bash
set -euo pipefail

gatk=/share/apps/GATK-distros/GATK_4.0.4.0/gatk

seqId=$1
sampleId=$2

perl /share/apps/vep-distros/ensembl-tools-release-86/scripts/variant_effect_predictor/variant_effect_predictor.pl \
    --input_file "$seqId"_"$sampleId"_filteredStr.vcf.gz \
    --format vcf \
    --output_file "$seqId"_"$sampleId"_filteredStr_annotated.vcf \
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
$gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    IndexFeatureFile \
    -F "$seqId"_"$sampleId"_filteredStr_annotated.vcf

# extract variants PASSING filter
$gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    SelectVariants \
    -R /state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
    -V "$seqId"_"$sampleId"_filteredStr_annotated.vcf \
    -O "$seqId"_"$sampleId"_PASS.vcf \
    --exclude-filtered
