# SNP / gVCF workflow for Chironomus riparius (Slurm + Bash + R)

This repository contains a Slurm-based Bash workflow to run:
MD5 checks → (optional) gunzip → FastQC → Trimmomatic → (optional) PEAR merge
→ BWA-MEM mapping + sorting → SAMtools QC/merge/filter/depth
→ Qualimap → Picard (MarkDuplicates, SortSam, BuildBamIndex, ReadGroups)
→ (optional) GATK3 indel realignment
→ GATK HaplotypeCaller in GVCF mode (Slurm array)
→ CombineGVCFs / GenotypeGVCFs
→ SelectVariants (SNP/INDEL) + VariantFiltration + PASS extraction + bcftools stats
→ (optional) BQSR (BaseRecalibrator + ApplyBQSR)
→ (optional) accuMUlate + awk-based filtering
→ R: BayesianFirstAid Poisson test for rate ratios

## What is NOT in this repo
- Raw FASTQ/BAM/VCF files are not tracked (see .gitignore).
- Cluster-specific paths are provided via workflow/config.example.env.

## Quick start
1) Copy config:
   cp workflow/config.example.env workflow/config.env
   Edit workflow/config.env to match your HPC paths/modules.

2) Prepare sample sheet:
   Edit workflow/samples.tsv

3) Submit jobs in order:
   sbatch workflow/01_fastqc.sbatch
   sbatch workflow/02_trim_trimmomatic.sbatch
   sbatch workflow/03_pear_merge.sbatch        # optional
   sbatch workflow/05_bwa_map_and_sort.sbatch
   sbatch workflow/07_picard_and_filtering.sbatch
   sbatch workflow/08_gatk3_indel_realignment.sbatch  # optional
   sbatch workflow/09_haplotypecaller_gvcf_array.sbatch
   bash  workflow/10_combine_genotype_select_filter.sh
   sbatch workflow/11_bqsr_array.sbatch        # optional
   sbatch workflow/12_accumulate_and_filter.sbatch    # optional

4) Run R test (example):
   Rscript R/01_bayesian_poisson_test.R results/mutation_counts.tsv
