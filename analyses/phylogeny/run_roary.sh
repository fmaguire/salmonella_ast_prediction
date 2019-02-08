#!/bin/bash
roary -p 2 -o clusters -e -qc ../genome_annotations/*.gff 
snp-sites -v -p -m -o pangenome_snps core_gene_alignment.aln
