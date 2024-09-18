#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//--------------------------------------------------------------------------
// Param Checking
//--------------------------------------------------------------------------

if(!params.fastaSubsetSize) {
  throw new Exception("Missing params.fastaSubsetSize")
}

if(params.inputFilePath) {
  seqs = Channel.fromPath( params.inputFilePath )
           .splitFasta( by:params.fastaSubsetSize, file:true  )
}
else {
  throw new Exception("Missing params.inputFilePath")
}

//--------------------------------------------------------------------------
// Main Workflow
//--------------------------------------------------------------------------

workflow {
  trf(seqs, params.args) | trf2bed | collectFile(storeDir: params.outputDir, name: params.outputFileName)
}


process trf {
  container = 'jbrestel/trf'

  input:
  path subsetFasta
  val args

  output:
  path "${subsetFasta}.dat"

  script:
  def outputSuffix = args.replace(" ", ".")
  def outputFile = subsetFasta + ".dat"
  """
  set +e
  trf $subsetFasta $args -d -h
  status=\$?
  set -e

  # annoying that trf returns a 1 exit code on success
  if [ \$status -eq 0 ] || [ \$status -eq 1 ]; then
    if grep -q "Done." .command.err ; then
      echo "Success.. Done string found" >&2
    else
      echo "Done String not found!" >&2
     exit 1
  fi

  # trf adds a header which must be removed
    cat ${subsetFasta}.${outputSuffix}.dat | \\
      perl -e '
        my \$start;
        while(<>) {
          \$start = 1 if(/Sequence:/);
          print if(\$start)
        }
      ' > $outputFile
  else
    exit \$status
  fi
  """
}


process trf2bed {
  container = 'bioperl/bioperl:stable'

  input:
  path trf

  output:
  path "trf_subset.bed"

  script:
  """
  trf2bed.pl $trf trf_subset.bed
  """
}
