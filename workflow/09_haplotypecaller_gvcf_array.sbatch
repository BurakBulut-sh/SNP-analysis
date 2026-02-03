#!/usr/bin/env bash
#SBATCH --job-name=hc_gvcf
#SBATCH --cpus-per-task=4
#SBATCH --mem=20G
#SBATCH --time=48:00:00
#SBATCH --output=logs/hc_%A_%a.log
#SBATCH --error=logs/hc_%A_%a.err
#SBATCH --array=0-999

set -euo pipefail
mkdir -p logs
source workflow/config.env

[[ -n "${MOD_GATK}" ]] && module load "${MOD_GATK}" || true

SAMPLES="workflow/samples.tsv"
N=$(($(wc -l < "$SAMPLES") - 1))
if [[ "${SLURM_ARRAY_TASK_ID}" -ge "${N}" ]]; then exit 0; fi
LINE=$((SLURM_ARRAY_TASK_ID + 2))
sample=$(sed -n "${LINE}p" "$SAMPLES" | cut -f1)

# Prefer realigned BAM if you ran GATK3 step, else use processed BAM
bam1="${OUTDIR}/bam/realigned/${sample}/${sample}.realigned.bam"
bam2="${OUTDIR}/bam/processed/${sample}/${sample}.q20.properpair.bam"
inbam="${bam2}"
[[ -f "${bam1}" ]] && inbam="${bam1}"

mkdir -p "${OUTDIR}/gvcf"
gatk --java-options "-Xmx16g" HaplotypeCaller \
  -R "${REF_FASTA}" \
  -I "${inbam}" \
  -O "${OUTDIR}/gvcf/${sample}.g.vcf.gz" \
  -ERC GVCF
