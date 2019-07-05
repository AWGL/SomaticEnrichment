# SomaticEnrichment

NGS pipeline for the detection of somatic variation (SNVs, Indels and CNVs) from capture-based libraries. Version 1.0.0 is not validated for CNV or Fusion Detection. The validation documentation and SOP can be found on QPulse:

`LP-GEN-PanCanAnlyss`

Useage:

```
qsub 1_SomaticEnrichment.sh
```

command must be issues inside sample directory; which contains:
`{samplename}.variables` file

`SomaticEnrichmentLib-{version}` library

`{sample}.fastq.gz` files

The no template control must be named "NTC" in the SampleSheet.csv.


