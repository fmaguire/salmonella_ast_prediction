#!/bin/bash

sistr -m --qc --novel-alleles novel-alleles.fasta --cgmlst-profiles cgmlst-profiles.csv -f tab -o sistr-output.tab -i ../../genomes/*.fasta
