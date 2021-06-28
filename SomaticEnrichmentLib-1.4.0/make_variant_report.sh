#!/bin/bash
set -euo pipefail

seqId=$1
panel=$2
version=$3
    
source /home/transfer/miniconda3/bin/activate VirtualHood

    for i in /data/results/$seqId/$panel/*/; do
        echo $i
        sampleId=$(basename $i)

        if [ $sampleId == 'NTC' ]; then
            echo "skipping $sampleId worksheet"
        else
            # load sample variables
            . /data/results/$seqId/$panel/$sampleId/"$sampleId".variables

            # check that referral is set, skip if not
            if [ -z "${referral:-}" ] || [ $referral == 'null' ]; then
                echo "$sampleId referral reason not set, skipping sample"
            else
                echo "$sampleId referral - $referral"
                python /data/diagnostics/apps/VirtualHood/VirtualHood-1.2.0/panCancer_report.py $seqId $sampleId $worklistId $referral

                # unset variable to make sure if doesn't carry over to next sample
                unset $referral
            fi
        fi
    done


    #make the cnv analysis sheet for samples with greater than or equal to 2million reads
    samples=$(cat /data/results/$seqId/$panel/CNVKit_samples.txt | grep -v "NTC")
    for i in ${samples[@]}; do
        echo $i
        sampleId=$(basename $i)

        if [ $sampleId == 'NTC' ]; then
            echo "skipping $sampleId worksheet"
        else
            # load sample variables
            . /data/results/$seqId/$panel/$sampleId/"$sampleId".variables
            
            #make the cnv analysis sheets
            python ./SomaticEnrichmentLib-"$version"/cnv_analysis_sheet.py --seqId $seqId --sampleid $sampleId --worksheetid $worklistId



          
        fi
    done

source /home/transfer/miniconda3/bin/deactivate

