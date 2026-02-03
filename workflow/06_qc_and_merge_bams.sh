#!/usr/bin/env bash
set -euo pipefail
source workflow/config.env
[[ -n "${MOD_SAMTOOLS}" ]] && module load "${MOD_SAMTOOLS}" || true
[[ -n "${MOD_QUALIMAP}" ]] && module load "${MOD_QUALIMAP}" || true

sample="$1"

bam_dir="${OUTDIR}/bam/raw/${sample}"
mkdir -p "${OUTDIR}/qc/samtools" "${OUTDIR}/qc/qualimap/${sample}"

# Flagstat (original step 8)
for b in "${bam_dir}"/*.bam; do
  [[ -f "$b" ]] || continue
  samtools flagstat "$b" > "${OUTDIR}/qc/samtools/$(basename "$b").flagstat.txt"
done

# Merge assembled+unassembled if present (original step 9)
if [[ -f "${bam_dir}/${sample}_assembled_sorted.bam" && -f "${bam_dir}/${sample}_unassembled_sorted.bam" ]]; then
  samtools merge "${OUTDIR}/bam/raw/${sample}/${sample}_merged.bam" \
    "${bam_dir}/${sample}_assembled_sorted.bam" "${bam_dir}/${sample}_unassembled_sorted.bam"
fi

# Qualimap (original step 10) - run on direct-mapped bam
if [[ -f "${bam_dir}/${sample}.sort.bam" ]]; then
  qualimap bamqc -ip -outformat PDF -bam "${bam_dir}/${sample}.sort.bam" -outdir "${OUTDIR}/qc/qualimap/${sample}"
fi
