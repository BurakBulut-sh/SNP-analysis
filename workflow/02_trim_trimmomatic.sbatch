#!/usr/bin/env bash
#SBATCH --job-name=trim
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH --time=08:00:00
#SBATCH --output=logs/trim_%A_%a.log
#SBATCH --error=logs/trim_%A_%a.err
#SBATCH --array=0-999

set -euo pipefail
mkdir -p logs

source workflow/config.env

[[ -n "${MOD_TRIMMOMATIC}" ]] && module load "${MOD_TRIMMOMATIC}" || true

SAMPLES="workflow/samples.tsv"
N=$(($(wc -l < "$SAMPLES") - 1))
if [[ "${SLURM_ARRAY_TASK_ID}" -ge "${N}" ]]; then exit 0; fi

LINE=$((SLURM_ARRAY_TASK_ID + 2))
sample=$(sed -n "${LINE}p" "$SAMPLES" | cut -f1)
fq1=$(sed -n "${LINE}p" "$SAMPLES" | cut -f2)
fq2=$(sed -n "${LINE}p" "$SAMPLES" | cut -f3)

mkdir -p "${OUTDIR}/trim/${sample}"

# Output names match the original style: P/U reads
out1p="${OUTDIR}/trim/${sample}/${sample}_1P.fq.gz"
out1u="${OUTDIR}/trim/${sample}/${sample}_1U.fq.gz"
out2p="${OUTDIR}/trim/${sample}/${sample}_2P.fq.gz"
out2u="${OUTDIR}/trim/${sample}/${sample}_2U.fq.gz"

trimmomatic PE -threads 8 -phred33 \
  "${fq1}" "${fq2}" \
  "${out1p}" "${out1u}" "${out2p}" "${out2u}" \
  "ILLUMINACLIP:${ADAPTERS}:2:30:10:8:true" \
  "SLIDINGWINDOW:4:20" \
  "MINLEN:100" \
  "TOPHRED33"
