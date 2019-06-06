#!/bin/bash
set -euo pipefail

seqId=$1
sampleId=$2
referral=$3
worksheet=$4

source /home/transfer/miniconda3/bin/activate VirtualHood

    python /data/diagnostics/apps/VirtualHood/panCancer_report.py $seqId $sampleId $worksheet $referral 250x
    python /data/diagnostics/apps/VirtualHood/panCancer_report.py $seqId $sampleId $worksheet $referral 135x

source /home/transfer/miniconda3/bin/deactivate

