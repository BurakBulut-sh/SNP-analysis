# Workflow notes

All scripts read settings from:
- workflow/config.env
- workflow/samples.tsv

Conventions:
- samples.tsv contains sample_id and FASTQ paths (paired-end).
- Each Slurm job writes logs to logs/ (ignored by git).
- Intermediate and final outputs go to $OUTDIR (defined in config.env).

You can either:
A) Run PEAR merge then map assembled/unassembled (matches the original notes), or
B) Map paired reads directly (example included in 05_bwa_map_and_sort.sbatch).
