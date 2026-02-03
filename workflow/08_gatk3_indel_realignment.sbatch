#!/usr/bin/env bash
#SBATCH --job-name=gatk3realn
#SBATCH --cpus-per-task=2
#SBATCH --mem=30G
#SBATCH --time=24:00:00
#SBATCH --output=logs/gatk3_%A_%a.log
#SBATCH --error=logs/gatk3_%A_%a.err
#SBATCH --array=0-999

set -euo pipefail
mkdir -p logs
source workflow/config.env

SAMPLES="workflow/samples.tsv"
N=$(($(wc -l < "$SAMPLES") - 1))
if [[ "${SLURM_ARRAY_TASK_ID}" -ge "${N}" ]]; then exit 0; fi
LINE=$((SLURM_ARRAY_TASK_ID + 2))
sample=$(sed -n "${LINE}p" "$SAMPLES" | cut -f1)

inbam="${OUTDIR}/bam/processed/${sample}/${sample}.q20.properpair.bam"
[[ -f "${inbam}" ]] || { echo "Missing ${inbam}"; exit 1; }

mkdir -p "${OUTDIR}/bam/realigned/${sample}"

# 17) AddOrReplaceReadGroups + 18) index are in 07; here we follow your GATK3 steps 19-20
target_list="${OUTDIR}/bam/realigned/${sample}/${sample}.realign_targets.list"

"${JAVA_BIN}" -jar "${GATK3_JAR}" \
  -T RealignerTargetCreator \
  -R "${REF_FASTA}" \
  -I "${inbam}" \
  -o "${target_list}"

"${JAVA_BIN}" -jar "${GATK3_JAR}" \
  -T IndelRealigner \
  -R "${REF_FASTA}" \
  -I "${inbam}" \
  -targetIntervals "${target_list}" \
  -o "${OUTDIR}/bam/realigned/${sample}/${sample}.realigned.bam"
