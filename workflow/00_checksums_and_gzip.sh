#!/usr/bin/env bash
set -euo pipefail

# This script mirrors the original "MD5 check" and "(un)zip" notes.
# It does not submit Slurm jobs.

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 workflow/samples.tsv"
  exit 1
fi

SAMPLES_TSV="$1"

tail -n +2 "$SAMPLES_TSV" | while IFS=$'\t' read -r sample fq1 fq2; do
  echo "== $sample =="
  echo "MD5:"
  md5sum "$fq1" "$fq2" || true

  # Optional: decompress if you truly need uncompressed fastq
  # gunzip -k "$fq1"
  # gunzip -k "$fq2"
done
