#!/usr/bin/env bash
#SBATCH --job-name=bwa
#SBATCH --cpus-per-task=10
#SBATCH --mem=40G
#SBATCH --time=12:00:00
#SBATCH --output=logs/bwa_%A_%a.log
#SBATCH --error=logs/bwa_%A_%a.err
#SBATCH --array=0-999

set -euo pipefail
mkdir -p logs
source workflow/config.env

[[ -n "${MOD_BWA}" ]] && module load "${MOD_BWA}" || true
[[ -n "${MOD_SAMTOOLS}" ]] && module load "${MOD_SAMTOOLS}" || true

SAMPLES="workflow/samples.tsv"
N=$(($(wc -l < "$SAMPLES") - 1))
if [[ "${SLURM_ARRAY_TASK_ID}" -ge "${N}" ]]; then exit 0; fi

LINE=$((SLURM_ARRAY_TASK_ID + 2))
sample=$(sed -n "${LINE}p" "$SAMPLES" | cut -f1)

mkdir -p "${OUTDIR}/bam/raw/${sample}"

# Mode A (matches original notes): map PEAR assembled reads, and optionally unassembled reads separately
assembled="${OUTDIR}/pear/${sample}/${sample}_merged_reads.assembled.fastq"
if [[ -f "${assembled}" ]]; then
  bwa mem -t "${THREADS}" -k 30 "${REF_FASTA}" "${assembled}" | \
    samtools sort -l 9 -O BAM -o "${OUTDIR}/bam/raw/${sample}/${sample}_assembled_sorted.bam"
fi

# Mode B (direct paired-end mapping example, similar to your "perfect parallel" snippet)
r1="${OUTDIR}/trim/${sample}/${sample}_1P.fq.gz"
r2="${OUTDIR}/trim/${sample}/${sample}_2P.fq.gz"
bwa mem -M -t "${THREADS}" "${REF_FASTA}" "${r1}" "${r2}" | \
  samtools sort -l 9 -O BAM -o "${OUTDIR}/bam/raw/${sample}/${sample}.sort.bam"
