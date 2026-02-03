#!/usr/bin/env Rscript

# Mirrors the original "BayesianFirstAid Poisson test" idea:
# Aline <- c(generational_passages_treatment, generational_passages_control)
# A <- c(mutations_treatment, mutations_control)
# bayes.poisson.test(A, Aline)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  cat("Usage: Rscript R/01_bayesian_poisson_test.R results/mutation_counts.tsv\n")
  quit(status = 1)
}

infile <- args[1]
tab <- read.table(infile, header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Expect columns: group, mutations, passages
# Example rows:
# treatment 32 45
# control   25 50

if (!requireNamespace("BayesianFirstAid", quietly = TRUE)) {
  stop("Please install BayesianFirstAid (or load it via module/renv).")
}
library(BayesianFirstAid)

treat <- tab[tab$group == "treatment", ]
ctrl  <- tab[tab$group == "control", ]

A <- c(treat$mutations[1], ctrl$mutations[1])
Aline <- c(treat$passages[1], ctrl$passages[1])

res <- bayes.poisson.test(A, Aline)
print(res)

pdf("poisson_rate_ratio.pdf")
plot(res)
dev.off()
