for i in */model_rule_1_equiv.fasta;
do 
    bwa mem all_genes_clustered $i > $(dirname $i)_all_genes.sam
done
