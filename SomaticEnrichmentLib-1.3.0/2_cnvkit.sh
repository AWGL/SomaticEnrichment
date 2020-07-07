#!/bin/bash
#PBS -l walltime=20:00:00
#PBS -l ncpus=12
set -euo pipefail
PBS_O_WORKDIR=(`echo $PBS_O_WORKDIR | sed "s/^\/state\/partition1//"`)
cd $PBS_O_WORKDIR

cnvkit=$1
seqId=$2
panel=$3
test_sample=$4
version=$5

FASTA=/data/db/human/gatk/2.8/b37/human_g1k_v37.fasta


odir=/data/results/$seqId/$panel/$test_sample/CNVKit/ 

echo "generating references"

$cnvkit reference $(cat $odir/tc.array) $(cat $odir/atc.array) --fasta $FASTA  -o "$odir"/"$test_sample".reference.cnn

echo "fixing ratios"
$cnvkit fix "$test_sample".targetcoverage.cnn "$test_sample".antitargetcoverage.cnn "$odir"/"$test_sample".reference.cnn -o "$odir"/"$test_sample".cnr

echo "selecting common germline variants for CNV backbone"
/share/apps/GATK-distros/GATK_4.0.4.0/gatk \
    --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Djava.io.tmpdir=/state/partition1/tmpdir -Xmx4g" \
    SelectVariants \
    -R /data/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
    -V /data/results/$seqId/$panel/$test_sample/"$seqId"_"$test_sample"_filteredStr.vcf.gz \
    --select-type-to-include SNP \
    -O "$odir"/"$test_sample"_common.vcf \
    --restrict-alleles-to BIALLELIC \
    --selectExpressions 'POP_AF > 0.01' \
    --selectExpressions 'POP_AF < 0.99'

echo "segmentation"
$cnvkit segment "$odir"/"$test_sample".cnr -m cbs -o "$odir"/"$test_sample".cns --vcf "$odir"/"$test_sample"_common.vcf --drop-low-coverage
$cnvkit segmetrics -s "$odir"/"$test_sample".cn{s,r} -o "$odir"/"$test_sample".segmetrics.cns --ci

$cnvkit call "$odir"/"$test_sample".segmetrics.cns -o "$odir"/"$test_sample".call.cns --vcf "$odir"/"$test_sample"_common.vcf -m threshold -t=-0.32,-0.15,0.14,0.26 --filter ci --center

$cnvkit metrics "$test_sample".targetcoverage.cnn "$test_sample".antitargetcoverage.cnn "$odir"/"$test_sample".cnr -s "$odir"/"$test_sample".call.cns > "$odir"/"$test_sample".metrics
$cnvkit scatter "$odir"/"$test_sample".cnr -s "$odir"/"$test_sample".call.cns -v "$odir"/"$test_sample"_common.vcf -o "$odir"/"$test_sample"-scatter.pdf
$cnvkit breaks "$odir"/"$test_sample".cnr "$odir"/"$test_sample".call.cns > "$odir"/"$test_sample".breaks
$cnvkit genemetrics "$odir"/"$test_sample".cnr -s "$odir"/"$test_sample".segmetrics.cns -m 3 -t 0.13 > "$odir"/"$test_sample".genemetrics
$cnvkit genemetrics "$odir"/"$test_sample".cnr -m 3 -t 0.13 > "$odir"/"$test_sample".unsegmented.genemetrics
$cnvkit sex "$odir"/"$test_sample".*.cnn "$odir"/"$test_sample".cnr "$odir"/"$test_sample".call.cns > "$odir"/"$test_sample".sex

# generate CNV report for each panel

mkdir -p /data/results/$seqId/$panel/$test_sample/hotspot_cnvs


for cnvfile in /data/diagnostics/pipelines/SomaticEnrichment/SomaticEnrichment-"$version"/RochePanCancer/hotspot_cnvs/*;do
    
    name=$(basename $cnvfile)
    echo $name

    if [ $name == '1p19q' ]; then

        $cnvkit scatter "$odir"/"$test_sample".cnr \
            -s "$odir"/"$test_sample".cns \
            -v "$odir"/"$test_sample"_common.vcf \
            -c 1:0-249250621 \
            -g '' \
            -o /data/results/$seqId/$panel/$test_sample/hotspot_cnvs/"$test_sample"_chromosome1-scatter.pdf

        $cnvkit scatter "$odir"/"$test_sample".cnr \
            -s "$odir"/"$test_sample".cns \
            -v "$odir"/"$test_sample"_common.vcf \
            -c 19:0-59128983 \
            -g '' \
            -o /data/results/$seqId/$panel/$test_sample/hotspot_cnvs/"$test_sample"_chromosome19-scatter.pdf

    else

        if [ -f /data/results/$seqId/$panel/$test_sample/hotspot_cnvs/"$test_sample"_"$name" ]; then
            rm /data/results/$seqId/$panel/$test_sample/hotspot_cnvs/"$test_sample"_"$name"
        fi

        # prepare output files
        head -n 1 "$odir"/"$test_sample".genemetrics >> /data/results/$seqId/$panel/$test_sample/hotspot_cnvs/"$test_sample"_"$name"

        while read gene; do
            echo $gene

            # check that gene contains an entry in genemetrics file
            if grep -qw $gene "$odir"/"$test_sample".genemetrics; then
                grep -w $gene "$odir"/"$test_sample".genemetrics >> /data/results/$seqId/$panel/$test_sample/hotspot_cnvs/"$test_sample"_"$name"
            fi
            
            $cnvkit scatter "$odir"/"$test_sample".cnr \
                -s "$odir"/"$test_sample".cns \
                -v "$odir"/"$test_sample"_common.vcf \
                -g $gene \
                -o /data/results/$seqId/$panel/$test_sample/hotspot_cnvs/"$test_sample"_"$gene"-scatter.pdf

        done <$cnvfile

    fi

done

echo $test_sample >> /data/results/$seqId/$panel/samplesCNVKit_script2.txt
