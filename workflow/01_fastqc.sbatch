#!/usr/bin/env bash
#SBATCH --job-name=fastqc
#SBATCH --cpus-per-task=10
#SBATCH --mem=50G
#SBATCH --time=04:00:00
#SBATCH --output=logs/fastqc_%A_%a.log
#SBATCH --error=logs/fastqc_%A_%a.err
#SBATCH --array=0-999

set -euo pipefail
mkdir -p logs

source workflow/config.env

[[ -n "${MOD_FASTQC}" ]] && module load "${MOD_FASTQC}" || true

SAMPLES="workflow/samples.tsv"
N=$(($(wc -l < "$SAMPLES") - 1))
if [[ "${SLURM_ARRAY_TASK_ID}" -ge "${N}" ]]; then exit 0; fi

LINE=$((SLURM_ARRAY_TASK_ID + 2))
sample=$(sed -n "${LINE}p" "$SAMPLES" | cut -f1)
fq1=$(sed -n "${LINE}p" "$SAMPLES" | cut -f2)
fq2=$(sed -n "${LINE}p" "$SAMPLES" | cut -f3)

mkdir -p "${OUTDIR}/qc/fastqc"
fastqc -t "${THREADS}" -o "${OUTDIR}/qc/fastqc" "${fq1}" "${fq2}"
