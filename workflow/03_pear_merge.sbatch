#!/usr/bin/env bash
#SBATCH --job-name=pear
#SBATCH --cpus-per-task=4
#SBATCH --mem=20G
#SBATCH --time=04:00:00
#SBATCH --output=logs/pear_%A_%a.log
#SBATCH --error=logs/pear_%A_%a.err
#SBATCH --array=0-999

set -euo pipefail
mkdir -p logs
source workflow/config.env

[[ -n "${MOD_PEAR}" ]] && module load "${MOD_PEAR}" || true

SAMPLES="workflow/samples.tsv"
N=$(($(wc -l < "$SAMPLES") - 1))
if [[ "${SLURM_ARRAY_TASK_ID}" -ge "${N}" ]]; then exit 0; fi

LINE=$((SLURM_ARRAY_TASK_ID + 2))
sample=$(sed -n "${LINE}p" "$SAMPLES" | cut -f1)

# Use trimmed paired reads
r1="${OUTDIR}/trim/${sample}/${sample}_1P.fq.gz"
r2="${OUTDIR}/trim/${sample}/${sample}_2P.fq.gz"

mkdir -p "${OUTDIR}/pear/${sample}"
pear -f "${r1}" -r "${r2}" -o "${OUTDIR}/pear/${sample}/${sample}_merged_reads"
