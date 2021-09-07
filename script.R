#!/usr/bin/env Rscript

library('tidyverse')

# TODO: add cpu set strategy
data <- list.files(path="data", recursive=TRUE, pattern="*.csv", full.names=TRUE) %>% map((function(x) (read_csv(x, show_col_types=FALSE) %>% mutate(cores=as.integer(substr(x, 8, str_length(x) - 4)))))) %>% bind_rows

data %>% group_by(benchmark, cores) %>% summarize(duration=mean(duration_ns), std_dev=sd(duration_ns))
