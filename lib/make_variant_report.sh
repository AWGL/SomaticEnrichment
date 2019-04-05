#!/bin/bash
set -euo pipefail

seqId=$1
sampleId=$2
referral=$3
worksheet=$4

source /home/transfer/miniconda/bin/activate VirtualHood

    python virtualhood.py $seqId $sampleId $worksheet $referral

source /home/transfer/miniconda/bin/deactivate

