#!/usr/bin/env Rscript

library('tidyverse')

get_data <- function(data_dir) (
	list.files(path=data_dir, recursive=TRUE, pattern="*.csv", full.names=TRUE) %>%
		map(function(x) (read_csv(x, show_col_types=FALSE) %>%
			mutate(cores=as.integer(substr(x, str_length(data_dir) + 4, str_length(x) - 4)), strategy=as.integer(substr(x, str_length(data_dir) + 2, str_length(data_dir) + 2))))) %>%
		bind_rows)

data1 <- get_data("data")
data2 <- get_data("data2")

data <- bind_rows(data1, data2)

last <- (data %>% filter(benchmark == "fj-kmeans") %>% filter(cores == 80) %>% summarize(dur=mean(duration_ns)))$dur[1]
first <- (data %>% filter(benchmark == "fj-kmeans") %>% filter(cores == 1) %>% summarize(dur=mean(duration_ns)))$dur[1]


message(paste("speadup:", first / last))