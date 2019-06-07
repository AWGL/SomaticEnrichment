# SomaticEnrichment

NGS pipeline for the detection of somatic variation (SNVs, Indels and CNVs) from capture-based libraries.

Useage:

```
qsub 1_SomaticEnrichment.sh
```

command must be issues inside sample directory; which contains:
1. {sample}.variables file
2. SomaticEnrichmentLib-{version} library
3. sample fastq files

The no template control must be names NTC
