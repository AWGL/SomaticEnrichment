#!/bin/bash
set -euo pipefail

seqId=$1
panel=$2
    
source /home/transfer/miniconda3/bin/activate VirtualHood

    for i in /data/results/$seqId/$panel/*/; do
        echo $i
        sampleId=$(basename $i)

        if [ $sampleId == 'NTC' ]; then
            echo "skipping $sampleId worksheet"
        else
           # need to make sure CNV calling has completed (i.e. 2_cnvkit.sh has finished) before generating worksheet
           while [ ! -f  /data/results/$seqId/$panel/$sampleId/2_cnvkit.sh.o* ]
           do
               sleep 2
           done

           . /data/results/$seqId/$panel/$sampleId/"$sampleId".variables

           # check that referral is set, skip if not
           if [ -z "${referral:-}" ] || [ $referral == 'null' ]; then
               echo "$sampleId referral reason not set, skipping sample"
           else
               echo "$sampleId referral - $referral"
               python /data/diagnostics/apps/VirtualHood/VirtualHood-1.1.0/panCancer_report.py $seqId $sampleId $worklistId $referral
           fi
        fi
    done

source /home/transfer/miniconda3/bin/deactivate

