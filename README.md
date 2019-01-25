# SomaticEnrichment
NGS pipeline for the detection of somatic variation (SNVs &amp; CNVs) and fusion genes


### CNV Calling

CNV calling is performed using [CNVKit](https://cnvkit.readthedocs.io/en/stable/).

The main CNV reports for each sample can be found in the *hotspot_cnvs* subdirectory. The text file in the directory are subsets of the larger genemetrics file; each file only shows doasage changes for the relevant genes in each tissue. The output format is;

-  log2: the log2 ratio value of the segment covering the gene, i.e. weighted mean of all bins covered by the whole segment, not just this gene.
-  depth: weighted mean of un-normalized read depths across all this gene’s bins.
-  weight: sum of this gene’s bins’ weights.
-  nbins: the number of bins assigned to this gene.
-  seg_weight: the sum of the weights of the bins supporting the segment.
-  seg_probes: the number of probes supporting the segment.

The log2 thresholds for a single copy deletion / duplication will be dependent on tumor purity. If we have a sample which is 100% tumor, a single copy deletion will have a log2 < log2(1/2) = -1.00 and a single dopy amplification will be > log2(3/2) = 0.58. These thresholds will move closer to 0 as tumor purity reduces. For example, with a tumor purity of 10% the thresholds will be;

```
2 x loss = log2(0.2*(0/2) + 0.8*(2/2)) = log2 < -0.32
1 x loss = log2(0.2*(1/2) + 0.8*(2/2)) = log2 < -0.15
1 x gain = log2(0.2*(3/2) + 0.8*(2/2)) = log2 > 0.14
```
