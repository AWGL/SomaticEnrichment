#!/bin/bash
set -euo pipefail

# see pipeline details here: https://software.broadinstitute.org/gatk/documentation/article?id=11682

seqId=$1
sampleId=$2
panel=$3
ROI=$4

mkdir -p gatk_cnv_plots
mkdir -p gatk_cnv_segments

gatk=/share/apps/GATK-distros/GATK_4.0.4.0/gatk

# loop of each sample in run and generate counts file
for i in ./TEST/"$panel"/*M*/;
    do

    sample=`basename $i`
    echo $sample

#Convert BED to interval_list for later
    /share/apps/jre-distros/jre1.8.0_131/bin/java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx2g \
        -jar /share/apps/picard-tools-distros/picard-tools-2.18.5/picard.jar BedToIntervalList \
        I=$ROI \
        O="$sample"_ROI.interval_list \
        SD=/state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.dict

    $gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
        PreprocessIntervals \
        -L "$sample"_ROI.interval_list \
        -R /state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
        --bin-length 0 \
        --interval-merging-rule OVERLAPPING_ONLY \
        --padding 250 \
        -O "$sample"_ROI_preprocessed.interval.list

    $gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
        CollectReadCounts \
        -I ./TEST/"$panel"/"$sample"/"$seqId"_"$sample".bam \
        -L "$sample"_ROI_preprocessed.interval.list \
        --interval-merging-rule OVERLAPPING_ONLY \
        -O "$sample".counts.hdf5
done


# second loop over all samples to perform remainder of analysis
for i in ./TEST/"$panel"/*M*/;
    do
    sample=`basename $i`

    # create panel of normals (all samples in run minus query sample)
    normals=`for f in *.hdf5; do echo "-I $f"; done | grep -v "$sample"`

    $gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
        CreateReadCountPanelOfNormals \
        $normals \
        --minimum-interval-median-percentile 5.0 \
        -O "$sample"_PON.hdf5

    $gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
        DenoiseReadCounts \
        -I "$sample".counts.hdf5 \
        --count-panel-of-normals "$sample"_PON.hdf5 \
        --standardized-copy-ratios "$sample".standardised.tsv \
        --denoised-copy-ratios "$sample".denoised.tsv

#    $gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
#        PlotDenoisedCopyRatios \
#        --standardized-copy-ratios "$sample".standardised.tsv \
#        --denoised-copy-ratios "$sample".denoised.tsv \
#        --sequence-dictionary /data/db/human/gatk/2.8/b37/human_g1k_v37.dict \
#        --minimum-contig-length 46709983 \
#        --output gatk_cnv_plots \
#        --output-prefix $sample

    $gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
        CollectAllelicCounts \
        -L /data/db/human/gnomad/gnomad.exomes.r2.0.1.sites.common.bialleleic.vcf.gz \
        -I ./TEST/"$panel"/"$sample"/"$seqId"_"$sample".bam \
        -R /state/partition1/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
        -O "$sample"_alleleic_counts.tsv

    $gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
        ModelSegments \
        --denoised-copy-ratios "$sample".denoised.tsv \
        --allelic-counts "$sample"_alleleic_counts.tsv \
        --output gatk_cnv_segments \
        --output-prefix $sample

    $gatk --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
        CallCopyRatioSegments \
        --input ./gatk_cnv_segments/"$sample".cr.seg \
        --output ./gatk_cnv_segments/"$sample".called.seg


done
