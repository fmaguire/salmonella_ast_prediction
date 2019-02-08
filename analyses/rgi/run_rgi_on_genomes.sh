#!/bin/bash

for genome in ../data/genomes/*.fasta
do
	rgi main -i $genome -o $(basename $genome)_rgi -t contig -a DIAMOND -n 8 && echo "$genome success" >> rgi_run.log || echo "$genome failed" >> rgi_run.log
done
