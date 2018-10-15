#!/bin/bash
set -euo pipefail

seqId=$1
panel=$2
sampleId=$3

sed 's/:/\t/g' /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_DepthOfCoverage | grep -v "^Locus" | sort -k1,1 -k2,2n | bgzip > "$seqId"_"$sampleId"_DepthOfCoverage_reformat.gz
/share/apps/htslib/tabix -b 2 -e 2 -s 1 "$seqId"_"$sampleId"_DepthOfCoverage_reformat.gz

#/share/apps/jre-distros/jre1.8.0_131/bin/java -jar /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-0.0.1/RochePanCancer/calculateCoverage.jar \
#    --bedfile $bedfile \
#    --depthfile $depthfile \
#    --

