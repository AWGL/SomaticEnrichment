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
    -V /data/results/$seqId/$panel/$test_sample/"$seqId"_"$test_sample".vcf.gz \
    --select-type-to-include SNP \
    -O "$odir"/"$test_sample"_common.vcf \
    --restrict-alleles-to BIALLELIC \
    --selectExpressions 'POP_AF > 0.05' \
    --selectExpressions 'POP_AF < 0.95'

echo "seqgmentation"
$cnvkit segment "$odir"/"$test_sample".cnr -m cbs -o "$odir"/"$test_sample".cns --vcf "$odir"/"$test_sample"_common.vcf

echo "CNV calling"
$cnvkit call "$odir"/"$test_sample".cns -o "$odir"/"$test_sample".call.cns --vcf "$odir"/"$test_sample"_common.vcf

$cnvkit metrics "$test_sample".targetcoverage.cnn "$test_sample".antitargetcoverage.cnn "$odir"/"$test_sample".cnr -s "$odir"/"$test_sample".cns > "$odir"/"$test_sample".metrics
$cnvkit scatter "$odir"/"$test_sample".cnr -s "$odir"/"$test_sample".cns -v "$odir"/"$test_sample"_common.vcf -o "$odir"/"$test_sample"-scatter.pdf
$cnvkit breaks "$odir"/"$test_sample".cnr "$odir"/"$test_sample".cns > "$odir"/"$test_sample".breaks
$cnvkit genemetrics "$odir"/"$test_sample".cnr -s "$odir"/"$test_sample".cns > "$odir"/"$test_sample".genemetrics
$cnvkit sex "$odir"/"$test_sample".*.cnn "$odir"/"$test_sample".cnr "$odir"/"$test_sample".cns > "$odir"/"$test_sample".sex
$cnvkit segmetrics "$odir"/"$test_sample".cnr -s "$odir"/"$test_sample".cns --ci --pi
