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

gatk3=/share/apps/GATK-distros/GATK_3.8.0/GenomeAnalysisTK.jar
calculateCoverage=/data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-0.0.1/RochePanCancer/calculateCoverage.jar

# Generate per-base coverage: variant detection sensitivity
/share/apps/jre-distros/jre1.8.0_131/bin/java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g -jar $gatk3 \
    -T DepthOfCoverage \
    -R /state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
    -I "$seqId"_"$sampleId".bam \
    -L $vendorCaptureBed \
    -o "$seqId"_"$sampleId"_DepthOfCoverage \
    --countType COUNT_FRAGMENTS \
    --minMappingQuality $minMQS \
    --minBaseQuality $minBQS \
    -ct $minimumCoverage \
    --omitLocusTable \
    -rf MappingQualityUnavailable \
    -dt NONE


# tabix index depth of coverage file
sed 's/:/\t/g' /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_DepthOfCoverage | grep -v "^Locus" | sort -k1,1 -k2,2n | /share/apps/htslib-distros/htslib-1.4.1/bgzip > /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_DepthOfCoverage.gz
/share/apps/htslib-distros/htslib-1.4.1/tabix -b 2 -e 2 -s 1 /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_DepthOfCoverage.gz

# gene gaps
/share/apps/jre-distros/jre1.8.0_131/bin/java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g -jar $calculateCoverage \
    -B /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-0.0.1/RochePanCancer/180702_HG19_PanCancer_EZ_primary_targets_genes.bed \
    -D /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_DepthOfCoverage.gz \
    --depth $minimumCoverage \
    --padding $padding \
    --outdir /data/results/$seqId/$panel/$sampleId \
    --outname "$seqId"_"$sampleId"_geneGaps.txt

# hotspot gaps
/share/apps/jre-distros/jre1.8.0_131/bin/java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g -jar $calculateCoverage \
    -B /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-0.0.1/RochePanCancer/180702_HG19_PanCancer_EZ_primary_targets_hotspots.bed \
    -D /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_DepthOfCoverage.gz \
    --depth $minimumCoverage \
    --padding $padding \
    --outdir /data/results/$seqId/$panel/$sampleId \
    --outname "$seqId"_"$sampleId"


# loop over panels to create hotspot_coverage data
for file in /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-0.0.1/RochePanCancer/hotspot_coverage/*.bed
do

    name=$(echo $(basename $file) | cut -d"." -f1)
    echo $name
    mkdir -p /data/results/$seqId/$panel/$sampleId/hotspot_coverage/$name
    
    # gene gaps
    /share/apps/jre-distros/jre1.8.0_131/bin/java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g -jar $calculateCoverage \
        -B $file \
        -D /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId"_DepthOfCoverage.gz \
        --depth $minimumCoverage \
        --padding $padding \
        --outdir /data/results/$seqId/$panel/$sampleId/hotspot_coverage/$name \
        --outname "$seqId"_"$sampleId"_"$name"
done
