#!/usr/bin/env nextflow

params.database = "missing.chewbbaca"
params.outdir   = "chewbbaca.out"
params.asm      = "missing.fasta"
params.chunk    = 5

// resolve the database path right away
in_db = file("${params.database}")

// resolve the output directory the right way
outdir = file("${params.outdir}")

// Turn the assemblies into a list and then a channel
asm_list = file(params.asm)
asmChannel    = Channel.fromPath(asm_list).buffer(size:params.chunk)

process prepDatabase {

  input:
  path(in_db)
  file(fasta) from asmChannel

  output:
  file("chewie.out/*/results_alleles.tsv") into alleleCalls
  //stdout into dbPrepped

  shell:
  '''
  # Check env
  which blastn
  which chewBBACA.py

  # Get a fresh copy of the database
  cd !{in_db}
  git status
  git tag -l | grep v1
  cd -
  git clone --branch v1 !{in_db} mlst.db

  # Copy all the assemblies over to an input folder
  mkdir -v chewie.in
  cp -nvL !{fasta} chewie.in

  # Run chewie
  chewBBACA.py AlleleCall -i chewie.in --schema-directory mlst.db -o chewie.out --cpu !{task.cpus}
  '''
}

// Aggregate allele calls into CombinedAlleleCalls channel
//Channel
//  .from(alleleCalls)
//  .collectFile(name:"results_alleles.tsv", newLine:true)
//  .set { CombinedAlleleCalls }

process saveCalls {

  publishDir "${outdir}"

  input:
  file(alleles) from alleleCalls.collectFile(name:"results_alleles.tsv", newLine:true)

  output:
  file("results_alleles.tsv") into results_alleles

  shell:
  '''
  pwd
  '''
}

