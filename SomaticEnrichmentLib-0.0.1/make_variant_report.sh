#!/bin/bash
set -euo pipefail

seqId=$1
panel=$2
    
source /home/transfer/miniconda3/bin/activate VirtualHood

    for i in /data/results/$seqId/$panel/*/; do

        sampleId=$(basename $i)

        if [ $sampleId == 'NTC' ]; then
            echo "skipping $sampleId worksheet"
        else
           
           # need to make sure CNV calling has completed (i.e. 2_cnvkit.sh has finished) before generating worksheet
           while [ ! -f  /data/results/$seqId/$panel/$sampleId/2_cnvkit.sh.* ]
           do
               sleep 2
           done

            . /data/results/$seqId/$panel/$sampleId/"$sampleId".variables
            python /data/diagnostics/apps/VirtualHood/panCancer_report.py $seqId $sampleId $worklistId $referral 250x
            python /data/diagnostics/apps/VirtualHood/panCancer_report.py $seqId $sampleId $worklistId $referral 135x
        fi
    done

source /home/transfer/miniconda3/bin/deactivate

