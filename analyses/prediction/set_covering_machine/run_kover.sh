name=$(basename $1 | cut -d '_' -f 1)
./kover/bin/kover dataset create from-contigs --genomic-data genome_metadata.tsv --phenotype-name $name --phenotype-metadata $1 --output ${name}_dataset -x --n-cpu 1 --temp-dir tmp
./kover/bin/kover dataset split --folds 10 --dataset ${name}_dataset --id 10CV --train-size 0.75
./kover/bin/kover learn --model-type conjunction disjunction --p 0.1 0.178 0.316 0.562 1.0 1.778 3.162 5.623 10.0 999999.0 --hp-choice cv --output-dir ${name}_model --split 10CV --dataset ${name}_dataset --n-cpu 1 -x
