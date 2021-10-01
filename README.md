# kessel-run
Run ChewBBACA allele calling in nextflow

# Running

This is a basic nextflow command to run this workflow.
Note that the value for `--fastq` is in quotes so that
nextflow can evaluate it instead of shell.
The output directory will be created for you and should
not exist before running this workflow.

    nextflow main.nf -resume \
      --database MLST.db/Salmonella_enterica.chewbbaca 
      --outdir chewbbaca.Salm.out
      --fastq 'illumina/Salm/*.fastq.gz'


# Installation

    make all

# Etymology

Since Chewie can make the Kessel Run in less than twelve parsecs,
I believe I can at least match that imaginary speed with allele calling.

