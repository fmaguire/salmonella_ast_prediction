#!/usr/bin/Rscript

sir <- read.csv('ast_sir_labels.csv')
# drop the index column
sir <- sir[, !(names(sir) %in% "ID")]

pdf(file="upsetallast.pdf", onefile=FALSE)
UpSetR::upset(sir, nsets=12, order.by='freq',  point.size=3.5, line.size=2, mainbar.y.label = 'Set Frequency', sets.bar.color = "#56B4E9", mb.ratio = c(0.7, 0.3), sets.x.label = "Phenotypic AMR in all Serovars")

dev.off()
