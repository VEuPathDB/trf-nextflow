# trf-nextflow

A Nextflow pipeline that identifies tandem repeats in genomic sequences using Tandem Repeats Finder (TRF).

## Overview

This pipeline runs [Tandem Repeats Finder](https://github.com/Benson-Genomics-Lab/TRF) over an input genome assembly to locate tandemly repeated DNA sequences, then converts the results into a sorted, indexed BED file. It is used within VEuPathDB's genome annotation workflows to generate tandem repeat feature tracks. The input FASTA is split into subsets for parallel processing, `trf` is run with the `-d -h` flags (`.dat`-format output, no HTML report), its raw `.dat` output is converted to BED format, and the combined results are sorted, compressed with `bgzip`, and indexed with `tabix` for efficient downstream access.

## Requirements

- [Nextflow](https://www.nextflow.io/) (DSL2)
- Docker (a `docker.config` profile is included and applied by default; `singularity` and `lsf` config files are also provided)

The pipeline uses three container images: `veupathdb/trf:1.0.0` (Tandem Repeats Finder), `bioperl/bioperl:stable` (BED conversion), and `biocontainers/tabix:v1.9-11-deb_cv1` (sorting/indexing).

## Usage

```
nextflow run VEuPathDB/trf-nextflow \
  -r main \
  --inputFilePath /path/to/genome.fa \
  --outputDir /path/to/output \
  --outputFileName tandemRepeats.bed \
  --fastaSubsetSize 25 \
  --args "2 7 7 80 10 50 500" \
  -profile docker \
  -resume
```

The pipeline has a single, unnamed workflow entry point that runs the full process: splitting the input FASTA, running `trf`, converting to BED, and indexing the result.

## Key Parameters

| Parameter | Description |
| --- | --- |
| `params.inputFilePath` | Path to the input FASTA file of genomic sequences to scan for tandem repeats. |
| `params.args` | Command-line arguments passed to `trf` (match, mismatch, indel penalties, match probability, indel probability, minimum score, and max period size). Defaults to `"2 7 7 80 10 50 500"`. |
| `params.fastaSubsetSize` | Number of sequences per FASTA subset sent to a single `trf` process; controls the degree of parallelism. |
| `params.outputFileName` | File name for the final BED output (default: `tandemRepeats.bed`). |
| `params.outputDir` | Directory where the final `.bed.gz` and `.tbi` index are published. |

## Output

A `bgzip`-compressed, `tabix`-indexed BED file (`<outputFileName>.gz` and its `.tbi` index) listing every tandem repeat found across the input sequences, sorted by sequence and start coordinate.
