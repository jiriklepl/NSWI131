#!/usr/bin/env Rscript

library('tidyverse')

get_data <- function(data_dir) (
	list.files(path=data_dir, recursive=TRUE, pattern="*.csv", full.names=TRUE) %>%
		map(function(x) (read_csv(x, show_col_types=FALSE) %>%
			mutate(cores=as.integer(substr(x, str_length(data_dir) + 4, str_length(x) - 4)), strategy=as.integer(substr(x, str_length(data_dir) + 2, str_length(data_dir) + 2))))) %>%
		bind_rows)

data1 <- get_data("data")
data2 <- get_data("data2")
data3 <- get_data("data3")

data <- bind_rows(data1, data2)

(data %>% group_by(benchmark, strategy) %>% do(plots=ggplot(data=.) + aes(x=factor(cores), y=duration_ns) + geom_violin(trim=TRUE, draw_quantiles=c(.25,.5,.75)) + stat_summary(data = . %>% group_by(cores) %>% summarize(dur=mean(duration_ns)), aes(x=factor(cores), y=dur, group=1, color=1), fun.y=sum, geom="line") + ggtitle(unique(paste(.$benchmark, .$strategy, "duration", sep="-"))) + theme(legend.position = "none")))$plots
(data %>% group_by(benchmark, strategy) %>% do(plots=ggplot(data=.) + aes(x=factor(cores), y=heap_size_after-heap_size_before) + geom_violin(trim=TRUE, draw_quantiles=c(.25,.5,.75)) + stat_summary(data = . %>% group_by(cores) %>% summarize(dur=mean(heap_size_after-heap_size_before)), aes(x=factor(cores), y=dur, group=1, color=1), fun.y=sum, geom="line") + ggtitle(unique(paste(.$benchmark, .$strategy, "heap_usage", sep="-"))) + theme(legend.position = "none")))$plots

(data3 %>% group_by(benchmark, strategy) %>% do(plots=ggplot(data=.) + aes(x=factor(cores), y=duration_ns) + geom_violin(trim=TRUE, draw_quantiles=c(.25,.5,.75)) + stat_summary(data = . %>% group_by(cores) %>% summarize(dur=mean(duration_ns)), aes(x=factor(cores), y=dur, group=1, color=1), fun.y=sum, geom="line") + ggtitle(unique(paste(.$benchmark, .$strategy, "duration", "small", sep="-"))) + theme(legend.position = "none")))$plots
(data3 %>% group_by(benchmark, strategy) %>% do(plots=ggplot(data=.) + aes(x=factor(cores), y=heap_size_after-heap_size_before) + geom_violin(trim=TRUE, draw_quantiles=c(.25,.5,.75)) + stat_summary(data = . %>% group_by(cores) %>% summarize(dur=mean(heap_size_after-heap_size_before)), aes(x=factor(cores), y=dur, group=1, color=1), fun.y=sum, geom="line") + ggtitle(unique(paste(.$benchmark, .$strategy, "heap_usage", "small", sep="-"))) + theme(legend.position = "none")))$plots
