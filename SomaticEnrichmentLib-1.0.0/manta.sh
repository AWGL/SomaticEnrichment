#!/bin/bash
set -euo pipefail

# Arthor: Christopjher Medway <christopher.medway@wales.nhs.uk>
# Description: Run MANTA over each sample for SV detection in tumor

seqId=$1
sampleId=$2
panel=$3
primaryBed=$4

if [ -d /data/results/$seqId/$panel/$sampleId/MANTA ]
then
    rm -r /data/results/$seqId/$panel/$sampleId/MANTA
fi


mkdir /data/results/$seqId/$panel/$sampleId/MANTA/

source /home/transfer/miniconda3/bin/activate manta

cat $primaryBed | bgzip > /data/results/$seqId/$panel/$sampleId/MANTA/callRegions.bed.gz
tabix -p bed  /data/results/$seqId/$panel/$sampleId/MANTA/callRegions.bed.gz

configManta.py \
    --tumorBam /data/results/$seqId/$panel/$sampleId/"$seqId"_"$sampleId".bam \
    --referenceFasta /data/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
    --runDir  /data/results/$seqId/$panel/$sampleId/MANTA/ \
    --exome \
    --callRegions /data/results/$seqId/$panel/$sampleId/MANTA/callRegions.bed.gz

/data/results/$seqId/$panel/$sampleId/MANTA/runWorkflow.py --quiet -m local

source /home/transfer/miniconda3/bin/deactivate
