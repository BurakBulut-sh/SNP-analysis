#!/usr/bin/env bash
set -euo pipefail
source workflow/config.env
[[ -n "${MOD_BWA}" ]] && module load "${MOD_BWA}" || true
bwa index "${REF_FASTA}"
