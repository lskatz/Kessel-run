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

1. Download the chewbbaca and shovill containers

    mkdir bin
    singularity build bin/shovill-v1.1.0.cif docker://staphb/shovill:1.1.0
    singularity build bin/chewbbaca-v2.8.4-1.cif ummidock/chewbbaca:2.8.4-1
   
2. Configure `nextflow.config` to match those paths using your favorite editor

3. Download the databases in ChewBBACA format.
These commands should help create filenames like `MLST.db/Salmonella_enterica.chewbbaca`.

    mkdir MLST.db
    cd MLST.db
    for i in `seq 1 10`; do wget -O species$i.zip https://chewbbaca.online/NS/api/species/$i/schemas/1/zip?request_type=download; done
    for i in `seq 1 10`; do mkdir $i.chewbbaca; mv species$i.zip $i.chewbbaca/; (cd $i.chewbbaca; unzip species$i.zip); done;
    for i in *.chewbbaca; do trn=$(\ls $i/*.trn); b=$(basename $trn .trn); target=$b.chewbbaca; mv $i $target -nv; done;
    cd -

# Etymology

Since Chewie can make the Kessel Run in less than twelve parsecs,
I believe I can at least match that imaginary speed with allele calling.

