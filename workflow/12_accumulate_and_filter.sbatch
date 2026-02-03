#!/usr/bin/env bash
#SBATCH --job-name=accuMUlate
#SBATCH --cpus-per-task=4
#SBATCH --mem=200G
#SBATCH --time=48:00:00
#SBATCH --output=logs/accum_%j.log
#SBATCH --error=logs/accum_%j.err

set -euo pipefail
mkdir -p logs
source workflow/config.env

# Inputs: a merged, sorted BAM + tmp directory of MAL outputs (as in your notes)
# You need to adapt these paths to your project layout.
MERGED_BAM="${OUTDIR}/accumulate/merged.sorted.bam"
TMP_DIR="${OUTDIR}/accumulate/tmp"
OUTTXT="${OUTDIR}/accumulate/unsorted.out.txt"
FILTTXT="${OUTDIR}/accumulate/filtered.out.txt"

mkdir -p "${OUTDIR}/accumulate"

# Merge + sort (original steps 39-40) - example: merge all bqsr bams if present
if [[ ! -f "${MERGED_BAM}" ]]; then
  mkdir -p "${OUTDIR}/accumulate"
  ls "${OUTDIR}/bam/bqsr/"*/"*.abqsr.bam" > "${OUTDIR}/accumulate/bams.list" || true
  if [[ -s "${OUTDIR}/accumulate/bams.list" ]]; then
    module load "${MOD_SAMTOOLS}" || true
    samtools merge -r "${OUTDIR}/accumulate/merged.bam" $(cat "${OUTDIR}/accumulate/bams.list")
    samtools sort -o "${MERGED_BAM}" "${OUTDIR}/accumulate/merged.bam"
    samtools index "${MERGED_BAM}"
  fi
fi

# accuMUlate parallel example (original step 41)
# Requires GNU parallel; if not available, replace with a simple loop.
parallel -j 60 \
  "accuMUlate -c ${ACCUMULATE_PARAMS_INI} -b ${MERGED_BAM} -r ${REF_FASTA} -i {}" \
  ::: "${TMP_DIR}"/* > "${OUTTXT}"

# awk filter (original step 42)
awk -F "\t" '{ if (($7 >= 0.90) && ($8 >= 0.90) && ($9 >= 0.90) && ($15 == 0) && ($16 <= 2.95) && ($18 >= 0.05)) { print} }' \
  "${OUTTXT}" > "${FILTTXT}"
