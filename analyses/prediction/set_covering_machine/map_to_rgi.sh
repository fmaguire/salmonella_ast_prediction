for i in */model_rule_1_equiv.fasta;
do 
    bwa mem rgi_hits_dna.fasta $i > $(dirname $i).sam
done
