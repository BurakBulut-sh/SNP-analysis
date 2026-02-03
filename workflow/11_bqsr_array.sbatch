#!/usr/bin/env bash
#SBATCH --job-name=bqsr
#SBATCH --cpus-per-task=2
#SBATCH --mem=20G
#SBATCH --time=24:00:00
#SBATCH --output=logs/bqsr_%A_%a.log
#SBATCH --error=logs/bqsr_%A_%a.err
#SBATCH --array=0-999

set -euo pipefail
mkdir -p logs
source workflow/config.env

[[ -n "${MOD_GATK}" ]] && module load "${MOD_GATK}" || true
[[ -n "${MOD_SAMTOOLS}" ]] && module load "${MOD_SAMTOOLS}" || true
[[ -n "${MOD_PICARD}" ]] && module load "${MOD_PICARD}" || true

SAMPLES="workflow/samples.tsv"
N=$(($(wc -l < "$SAMPLES") - 1))
if [[ "${SLURM_ARRAY_TASK_ID}" -ge "${N}" ]]; then exit 0; fi
LINE=$((SLURM_ARRAY_TASK_ID + 2))
sample=$(sed -n "${LINE}p" "$SAMPLES" | cut -f1)

inbam="${OUTDIR}/bam/processed/${sample}/${sample}.marked_duplicates.sorted.bam"
[[ -f "${inbam}" ]] || { echo "Missing ${inbam}"; exit 1; }

# AddOrReplaceReadGroups (original step 34)
rg_bam="${OUTDIR}/bam/processed/${sample}/${sample}.rg.bam"
picard AddOrReplaceReadGroups \
  I="${inbam}" \
  O="${rg_bam}" \
  RGID=4 RGLB=lib1 RGPL=illumina RGPU=unit1 RGSM="${sample}"

samtools index "${rg_bam}"

# BaseRecalibrator / ApplyBQSR (original steps 36-37)
mkdir -p "${OUTDIR}/bqsr" "${OUTDIR}/bam/bqsr/${sample}"

recal="${OUTDIR}/bqsr/${sample}.recal.table"
gatk --java-options "-Xmx16g" BaseRecalibrator \
  -R "${REF_FASTA}" \
  -I "${rg_bam}" \
  --known-sites "${OUTDIR}/vcf/snps.PASS.vcf.gz" \
  --known-sites "${OUTDIR}/vcf/indels.PASS.vcf.gz" \
  -O "${recal}"

outbam="${OUTDIR}/bam/bqsr/${sample}/${sample}.abqsr.bam"
gatk --java-options "-Xmx16g" ApplyBQSR \
  -R "${REF_FASTA}" \
  -I "${rg_bam}" \
  --bqsr-recal-file "${recal}" \
  -O "${outbam}"

samtools index "${outbam}"

# Coverage after processing (original step 38)
mkdir -p "${OUTDIR}/qc/coverage_bqsr"
samtools depth "${outbam}" | awk '{print $3}' > "${OUTDIR}/qc/coverage_bqsr/${sample}.depth.txt"
