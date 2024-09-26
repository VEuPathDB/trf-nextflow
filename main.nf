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
  trfResults = trf(seqs, params.args)
  bedFiles = trf2bed(trfResults)
  indexed = indexResults(bedFiles.collectFile(), params.outputFileName)
}


process trf {
  container = 'veupathdb/trf'

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

  # annoying that trf returns a non zero exit code on success
  # the exit status seems to be the number of sequences processed
  if [ \$status -eq 0 ] || [ \$status -eq \$(grep '>' $subsetFasta | wc -l) ]; then
    if grep -q "Done." .command.err ; then
      echo "Success.. Done string found" >&2
    else
    echo "Unexpected Error: Exit status \$status" >&2
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


process indexResults {
  container = 'biocontainers/tabix:v1.9-11-deb_cv1'

  publishDir params.outputDir, mode: 'copy'

  input:
    path bed
    val outputFileName

  output:
    path '*.bed.gz'
    path '*.tbi'

  script:
  """
  sort -k1,1 -k2,2n $bed > ${outputFileName}
  bgzip ${outputFileName}
  tabix -p bed ${outputFileName}.gz
  """
}
