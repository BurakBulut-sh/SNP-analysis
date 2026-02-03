#!/usr/bin/env bash
set -euo pipefail
source workflow/config.env

[[ -n "${MOD_GATK}" ]] && module load "${MOD_GATK}" || true
[[ -n "${MOD_BCFTOOLS}" ]] && module load "${MOD_BCFTOOLS}" || true

mkdir -p "${OUTDIR}/vcf" "${OUTDIR}/qc/bcftools"

# Build a list of gvcfs from samples.tsv (mirrors your huge explicit --variant list)
gvcf_list="${OUTDIR}/vcf/gvcfs.list"
: > "${gvcf_list}"
tail -n +2 workflow/samples.tsv | cut -f1 | while read -r sample; do
  echo "${OUTDIR}/gvcf/${sample}.g.vcf.gz" >> "${gvcf_list}"
done

combined="${OUTDIR}/vcf/combined.g.vcf.gz"
gatk CombineGVCFs -R "${REF_FASTA}" $(awk '{print "--variant " $0}' "${gvcf_list}") -O "${combined}"

genotyped="${OUTDIR}/vcf/genotyped.vcf.gz"
gatk GenotypeGVCFs -R "${REF_FASTA}" -V "${combined}" -O "${genotyped}"

# SNPs
snps="${OUTDIR}/vcf/snps.vcf.gz"
gatk SelectVariants -V "${genotyped}" --select-type-to-include SNP -O "${snps}"
bcftools stats "${snps}" > "${OUTDIR}/qc/bcftools/snps.stats.txt"

snps_filt="${OUTDIR}/vcf/snps.filtered.vcf.gz"
gatk VariantFiltration -R "${REF_FASTA}" -V "${snps}" -O "${snps_filt}" \
  --filter-expression "QD < 2.0" --filter-name "QD2" \
  --filter-expression "MQ < 50.0" --filter-name "MQ50" \
  --filter-expression "MQRankSum < -2.5" --filter-name "MQRankSum-2.5" \
  --filter-expression "ReadPosRankSum < -1.0" --filter-name "ReadPosRankSum-1" \
  --filter-expression "FS > 80.0" --filter-name "FS80" \
  --filter-expression "SOR > 3.00" --filter-name "SOR3" \
  --filter-expression "QUAL < 10.0" --filter-name "QUAL10"

# PASS extraction (your original used grep; we provide both)
bcftools view -f PASS "${snps_filt}" -Oz -o "${OUTDIR}/vcf/snps.PASS.vcf.gz"
bcftools index -t "${OUTDIR}/vcf/snps.PASS.vcf.gz"
bcftools stats "${OUTDIR}/vcf/snps.PASS.vcf.gz" > "${OUTDIR}/qc/bcftools/snps.PASS.stats.txt"

# INDELs
indels="${OUTDIR}/vcf/indels.vcf.gz"
gatk SelectVariants -V "${genotyped}" --select-type-to-include INDEL -O "${indels}"
bcftools stats "${indels}" > "${OUTDIR}/qc/bcftools/indels.stats.txt"

indels_filt="${OUTDIR}/vcf/indels.filtered.vcf.gz"
gatk VariantFiltration -R "${REF_FASTA}" -V "${indels}" -O "${indels_filt}" \
  --filter-expression "QD < 2.0" --filter-name "QD2" \
  --filter-expression "MQ < 50.0" --filter-name "MQ50" \
  --filter-expression "MQRankSum < -2.5" --filter-name "MQRankSum-2.5" \
  --filter-expression "ReadPosRankSum < -1.0" --filter-name "ReadPosRankSum-1" \
  --filter-expression "FS > 80.0" --filter-name "FS80" \
  --filter-expression "SOR > 3.00" --filter-name "SOR3" \
  --filter-expression "QUAL < 10.0" --filter-name "QUAL10"

bcftools view -f PASS "${indels_filt}" -Oz -o "${OUTDIR}/vcf/indels.PASS.vcf.gz"
bcftools index -t "${OUTDIR}/vcf/indels.PASS.vcf.gz"
bcftools stats "${OUTDIR}/vcf/indels.PASS.vcf.gz" > "${OUTDIR}/qc/bcftools/indels.PASS.stats.txt"
