#!/usr/bin/env bash
#SBATCH --job-name=picard
#SBATCH --cpus-per-task=2
#SBATCH --mem=40G
#SBATCH --time=12:00:00
#SBATCH --output=logs/picard_%A_%a.log
#SBATCH --error=logs/picard_%A_%a.err
#SBATCH --array=0-999

set -euo pipefail
mkdir -p logs
source workflow/config.env

[[ -n "${MOD_PICARD}" ]] && module load "${MOD_PICARD}" || true
[[ -n "${MOD_SAMTOOLS}" ]] && module load "${MOD_SAMTOOLS}" || true

SAMPLES="workflow/samples.tsv"
N=$(($(wc -l < "$SAMPLES") - 1))
if [[ "${SLURM_ARRAY_TASK_ID}" -ge "${N}" ]]; then exit 0; fi
LINE=$((SLURM_ARRAY_TASK_ID + 2))
sample=$(sed -n "${LINE}p" "$SAMPLES" | cut -f1)

inbam="${OUTDIR}/bam/raw/${sample}/${sample}.sort.bam"
[[ -f "${inbam}" ]] || { echo "Missing ${inbam}"; exit 1; }

mkdir -p "${OUTDIR}/bam/processed/${sample}"

# MarkDuplicates (original step 11)
picard MarkDuplicates \
  I="${inbam}" \
  O="${OUTDIR}/bam/processed/${sample}/${sample}.marked_duplicates.bam" \
  M="${OUTDIR}/bam/processed/${sample}/${sample}.marked_duplicates.metrics.txt" \
  VALIDATION_STRINGENCY=SILENT \
  REMOVE_DUPLICATES=true

# SortSam (original step 12)
picard SortSam \
  I="${OUTDIR}/bam/processed/${sample}/${sample}.marked_duplicates.bam" \
  O="${OUTDIR}/bam/processed/${sample}/${sample}.marked_duplicates.sorted.bam" \
  SORT_ORDER=coordinate \
  VALIDATION_STRINGENCY=SILENT

# BuildBamIndex (original step 13)
picard BuildBamIndex I="${OUTDIR}/bam/processed/${sample}/${sample}.marked_duplicates.sorted.bam"

# Samtools filter low quality (original step 15)
samtools view -q 20 -f 0x0002 -F 0x0004 -F 0x0008 -b \
  "${OUTDIR}/bam/processed/${sample}/${sample}.marked_duplicates.sorted.bam" \
  > "${OUTDIR}/bam/processed/${sample}/${sample}.q20.properpair.bam"

samtools index "${OUTDIR}/bam/processed/${sample}/${sample}.q20.properpair.bam"

# Coverage depth (original step 16)
mkdir -p "${OUTDIR}/qc/coverage"
samtools depth "${OUTDIR}/bam/processed/${sample}/${sample}.q20.properpair.bam" | awk '{print $3}' \
  > "${OUTDIR}/qc/coverage/${sample}.coverage.txt"
