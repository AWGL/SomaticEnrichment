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

