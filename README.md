# SomaticEnrichment
NGS pipeline for the detection of somatic variation (SNVs &amp; CNVs) and fusion genes

### CNV Calling

CNV calling is performed using [CNVKit](https://cnvkit.readthedocs.io/en/stable/).

The main CNV reports for each sample can be found in the *hotspot_cnvs* subdirectory. The text file in the directory have designed to i) combine the salient information from the larger repertoire of CNVKit output files (which can be found in the CNVKit directory) and, ii) only shows doasage changes for the relevant genes in each tissue. The output format is;

-  log2: the log2 ratio value of the segment covering the gene, i.e. weighted mean of all bins covered by the whole segment, not just this gene.
-  depth: weighted mean of un-normalized read depths across all this gene’s bins.
-  weight: sum of this gene’s bins’ weights.
-  nbins: the number of bins assigned to this gene.
-  seg_weight: the sum of the weights of the bins supporting the segment.
-  seg_probes: the number of probes supporting the segment.

### Evaluation of CNV Calls

The log2 thresholds for a single copy deletion / duplication will be dependent on tumor purity. If we have a sample which is 100% tumor, a single copy deletion will have a log2 < log2(1/2) = -1.00 and a single copy amplification will be > log2(3/2) = 0.58. These thresholds will move closer to 0 as tumor purity reduces. For example, with a tumor purity of 10% the thresholds will be;

```
2 x loss = log2(0.2*(0/2) + 0.8*(2/2)) = log2 < -0.32
1 x loss = log2(0.2*(1/2) + 0.8*(2/2)) = log2 < -0.15
1 x gain = log2(0.2*(3/2) + 0.8*(2/2)) = log2 >  0.14
2 x gain = log2(0.2*(4/2) + 0.8*(2/2)) = log2 >  0.26
3 x gain = log2(0.2*(4/2) + 0.8*(2/2)) = log2 >  0.38
4 x gain = log2(0.2*(4/2) + 0.8*(2/2)) = log2 >  0.49
```

The hotspot_cnv reports will report any gene dosage change down to 10% purity.

1. Any gene dosage changes with a log2 ratio > 0.58 or < -1.00 should be noted.
2. Loss of heterozygosity (BAF > 0.9 or < 0.1)
3. Number of bins
4. Confidence Interval of log2 Ratio

```
purity corrected log2 ratio

adjusted_cn = (ploidy * 2 ^ log2_ratio - ploidy * (1 - purity)) / purity
adjusted_log2 = log2(abs(adjusted_cn)/ploidy)
```


