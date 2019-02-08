for genome in ../data/genomes/*.fasta;
do 
    prokka --usegenus --outdir $(basename $genome) --genus Salmonella --species enterica --gram neg --cpus 2 $genome
    echo $genome
done
