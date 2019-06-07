#!/bin/bash
set -euo pipefail

seqId=$1
panel=$2
    
source /home/transfer/miniconda3/bin/activate VirtualHood

    for i in /data/results/$seqId/$panel/*/; do

        sampleId=$(basename $i)

        . /data/results/$seqId/$panel/$sampleId/"$sampleId".variables
        
        python /data/diagnostics/apps/VirtualHood/panCancer_report.py $seqId $sampleId $worklistId $referral 250x
        python /data/diagnostics/apps/VirtualHood/panCancer_report.py $seqId $sampleId $worklistId $referral 135x

    done

source /home/transfer/miniconda3/bin/deactivate
