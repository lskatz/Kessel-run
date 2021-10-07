#!/usr/bin/env nextflow

params.database = "missing.chewbbaca"
params.outdir   = "chewbbaca.out"
//params.asm      = "missing.fasta"
params.fastq    = "missing_1.fastq.gz missing_2.fastq.gz"
params.chunk    = 5
params.genomesize = "5M"

// resolve the database path right away
in_db = file("${params.database}")

// resolve the output directory the right way
outdir = file("${params.outdir}")

// Turn the assemblies into a list and then a channel
//asm_list = file(params.asm)
//asmChannel    = Channel.fromPath(asm_list).buffer(size:params.chunk)

// Fastq channel from --fastq
Channel
  .fromPath(params.fastq)
  .ifEmpty{
    println("No fastq files were given")
    exit 1
    }
  .map { file -> tuple(file.baseName.replaceAll(/(_[12])?(.fq|.fastq)?(.gz)?$/,""), file) }
  //.view {"now they are mapped: $it"}
  .groupTuple(by:0, sort:true, size:2)
  //.view {"all the grouped files: $it"}
  .set {fastqChannel}

// Assemble with shovill/spades
process assembly {

  input:
  set val(samplename), file(fastqs) from fastqChannel

  output:
  file("${samplename}.fa") into asmChannel

  shell:
  '''
  gbMemory=$(echo "!{task.memory}" | sed 's/[A-Za-z]//')
  depth=100 # can change for debugging purposes. Default:100
  # ensure R1 and R2 are correct
  R1="!{fastqs[0]}"
  R2="!{fastqs[1]}"
  export TMPDIR=$PWD/tmp
  if [ -e /scratch ]; then
      export TMPDIR=/scratch/$USER/scratch
  fi
  mkdir -pv $TMPDIR

  shovilltemp=$TMPDIR/!{samplename}.shovill.tmp
  outdir=$TMPDIR/!{samplename}.shovill.out

  echo "TMPDIR is $TMPDIR"

  shovill --check
  echo =====
  shovill --depth $depth --tmpdir $shovilltemp --outdir $outdir --R1 $R1 --R2 $R2 --assembler spades --ram $gbMemory --cpus !{task.cpus} --force --gsize !{params.genomesize}
  cp -v $outdir/contigs.fa ./!{samplename}.fa
  '''
}

process prepDatabase {

  input:
  path(in_db)

  output:
  path("mlst.db") into dbChannel

  shell:
  '''
  # Get a fresh copy of the database
  cd !{in_db}
  git status
  git tag -l | grep v1
  cd -
  # Clone into a temporary target
  git clone --branch v1 !{in_db} mlst.db.tmp
  # ... and then when it is 100% complete, rename it
  mv mlst.db.tmp mlst.db
  '''
}

process callAlleles {

  input:
  file(fasta) from asmChannel //.buffer(size:params.chunk)
  path("mlst.db") from dbChannel

  output:
  file("chewie.out/*/results_alleles.tsv") into alleleCalls
  path("mlst.modified.db") into modifiedDbChannel

  shell:
  println "Calling alleles on "
  println "     $fasta"
  '''
  # Copy all the assemblies over to an input folder
  mkdir -v chewie.in
  cp -nvL !{fasta} chewie.in
  # Check env
  which blastn
  which chewBBACA.py
  python3 --version
  which python3

  # Grab the database into a tmp folder
  cp -rL mlst.db mlst.modified.db.tmp
  # Allele calling on the tmp folder
  chewBBACA.py AlleleCall -i chewie.in --schema-directory mlst.modified.db.tmp -o chewie.out --cpu !{task.cpus} --force-reset
  # When the directory is all good and allele calling is all right, name it properly.
  # Only name it properly when we are complete in this process.
  mv mlst.modified.db.tmp mlst.modified.db
  '''
}

// Mark which alleles are new and save them as fasta
process markNewAlleles {
  input:
  path("mlst.modified.db") from modifiedDbChannel

  output:
  stdout into newAllelesChannel

  shell:
  '''
  (cd mlst.modified.db && git diff)
  '''
}

// Aggregate all calls to an output directory
process saveCalls {

  publishDir "${outdir}", mode:'copy'

  input:
  file(alleles) from alleleCalls.collectFile(name:"results_alleles.tsv", newLine:true)

  output:
  file("results_alleles.tsv") into results_alleles

  shell:
  '''
  pwd
  '''
}

