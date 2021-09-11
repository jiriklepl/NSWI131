# SOLUTION

This study analyzes the performance of the benchmarks of the [Renaissance Suite](https://renaissance.dev/). It measures the duration of the runtime of each benchmark by itself. There is a [plugin](heap-measure.tar.gz) made for this study that measures the heap usage of each iteration of each benchmark.

## Research

### Environment

The environment is a virtual Linux machine with Fedora user space.

**Installed packages:**

- numactl, numactl-devel
- git
- R-devel, libxml2-devel, openssl-devel, libcurl-devel
  - packages: tidyverse
- less, vim
- wget
- java-11-openjdk-devel
- mc, tmux
- ShellCheck, aspell, aspell-en

**CPU:**

The CPU of the environment is *Intel(R) Xeon(R) Gold 6230*. It has access to 80 CPU threads (including hyper-threading). The CPU nodes 0-19, 40-59 are on NUMA node 0, the rest (20-39, 60-79) is on NUMA node 1. CPU nodes *n* and *n+40* always share the same physical core.

CPU clock-rate is 2100 MHz and maximum CPU clock-rate is 3900 MHz, and it idles at 800 MHz.

There are two such CPUs, each representing one NUMA node.

The cache configuration of the CPUs is as follows:

- **L1:** 1.3 MiB data and 1.3 MiB instruction cache
- **L2:** 40 MiB
- **L3:** 55 MiB

**RAM:**

The RAM memory size is 64 GiB, clocked at 2933MHz (0.3ns).

**Java:**

The environment is equipped with OpenJDK 11.0.11 implementation of Java Development Kit and OpenJDK 18.9 implementation of Java Runtime Environment (JRE) and Java Server Virtual Machine (JVM).

### Preparation

**Controlling CPU count:**

To limit the number of CPU cores used in runtime, we will use the program `numactl`.

**Renaissance Benchmark Suite:**

We will use the 0.12 MIT distribution of the [Renaissance Benchmark Suite](https://github.com/renaissance-benchmarks/renaissance/releases/download/v0.12.0/renaissance-mit-0.12.0.jar).

The list of all benchmarks retrieved by the `--raw-list` option in the Renaissance runtime is in the file [benchmarks.txt](benchmarks.txt). This file will be used during data collecting.

## Methodology

All measurements were performed on the aforementioned virtual machine with the same setup.

There were 2 batches of data ([data.tar.gz](data.tar.gz) and [data2.tar.gz](data2.tar.gz)) collected, each consisting of 17 x 4 sets of measurement results for each benchmark and its default repetitions: there were 17 different numbers of CPU cores and, for each, 4 different strategies of core assignments. This is so that we can analyze the effects of memory sharing between NUMA nodes and the effects of hyper-threading, if there are any such effects in the analyzed benchmarks.

- The first strategy assigns the first N cores according to their numbering.
- The second strategy assigns the cores in batches of 10 maximizing hyper-threading. And for `N <= 20` all assigned cores share the same NUMA node.
- The third strategy assigns the cores from each of the 4 sets distincted by NUMA nodes and hyper-threading according to round robin and from the lowest indices.
- The fourth strategy assigns the cores consecutively according to their numbering avoiding the hyper-threading pairs (e.g. cores 0 and 20) for as long as possible - this means that, for `N <= 40`, all the assigned cores are on the same NUMA node.

For more details on CPU core assignment strategies, see the [cpuset.sh](cpuset.sh) script.

The 17 x 4 sets where collected by the [collect.sh](collect.sh) script with a single argument being, for each consecutive call, *1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80*, specifying the number of cores being assigned. This script then cycles through the 4 strategies.

This was performed twice and the results of this make up the *original combined dataset*.

Then the R script [script.R](script.R) was used to generate 8 plots for each benchmark, 4 for the performance and 4 for memory usage.

Then there were collected more data for certain benchmarks, those that appeared to behave differently when run on a low number of CPU cores. These benchmarks are those that are not commented out in [benchmarks-small.txt](benchmarks-small.txt). This new dataset, the *small dataset*, was collected by the [collect.sh](collect.sh) script with two arguments, first being in each call one of *1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16*, consecutively, specifying the number of cores being assigned, and the second one being 3, specifying the number of strategies of cores assignment.

## Results

Here, we will go through conclusions from the data collected from the benchmarks. The number of CPU cores in the plots will be referred to as `N`.

All the results are plotted out in the [Rplots.pdf](Rplots.pdf) document. Their respective names match the names in this document with added number specifying which CPU assignment strategy was used and `duration` or `heap-usage` specifying whether the plot shows results for performance or memory usage, respectively. The names of the results collected in the small dataset end with `small`.

I used violin plots because the data are very volatile and the two main collecting runs gave slightly different results (one dataset consistently showed that the benchmarks performed better). Violin plots make it easy to see whether it affects the final results and to easily filter this out.

In addition to the violin plots there is a line plot showing the mean values for each *benchmark x core count x strategy* trio. This conveniently shows the trends of changes in performance and memory usage.

### concurrency

- `akka-uct`: (including the small dataset) this benchmark performs consistently better on multiple CPU cores compared to single-threaded runtime. However, not considering this special case, the performance decreases with higher number of cores, especially when they do not share the same NUMA node. Considering the [documentation](https://akka.io/docs/), this seems to be due to frequent data transfers between actors.

  The memory usage of the benchmark is too volatile to draw any conclusions on the lower numbers of CPU cores (`N <= 16`). On higher numbers, it consistently slowly increases with the number of cores.

- `fj-kmeans`: this benchmark is, out of all measured benchmarks, the one that scales the best with more CPU cores. The benchmark is parametrized by the number of CPU cores (`@Parameter(name = "thread_count", defaultValue = "$cpu.count")`) and the architecture is built to run the algorithm in parallel efficiently on these cores. The algorithm scales almost perfectly until it reaches a point where the overhead of increase in parallelization is higher than the benefit. The speedup caps at `11.4`.

  The memory usage is very volatile, but, on average, it is almost `4` times better when being run on a single NUMA node.

- `reactors`: (including the small dataset) this benchmark performs best on 4 CPU cores if they share the same NUMA node, very similar result is obtained on 3 cores (within 10% difference in median and mean). The scaling from 1 core to 3 cores roughly copies the scaling of a well-parallelizable algorithm, the 4 core case is the last case of performance improvement with higher number of cores.

  The third set for this benchmark in the original combined dataset shows that this benchmark is very negatively affected by the cores being present on different NUMA nodes. This is further confirmed by the small dataset. In other cases (strategies I, II and IV, still in the small dataset), the performance exhibits very little volatility.

  The original dataset shows that the performance of the benchmark is very volatile in higher core numbers regardless of the cores sharing the same NUMA node, however, the mean performance appears to be independent on the concrete number of the cores.

  The memory usage is very volatile, but in the small dataset it appears to be independent on the actual number of the cores and whether they share the same NUMA node. On higher numbers of cores, `N > 30`, the mean memory usage is double the memory usage in other cases, disregarding results for 50, 55 and 60 cores in the fourth set of the results in the original combined dataset.

### database

- `db-shootout`: (including the small dataset) this benchmark performs better with a higher number of CPU cores and this increase in performance continues up until 15 cores (sooner if they do not share the same NUMA node), then the performance slowly decreases with a higher number of cores.

  The memory utilization slowly increases with more CPU cores. This is visible in the original combined dataset.

### functional

- `future-genetic`: (including the small dataset) this benchmark is sped up by assigning 2 CPU cores from the same NUMA node and it increases drastically more with 3 CPU cores. From that point on the benchmark's performance seems independent on the actual number of cores.

  The memory usage is very volatile, but it seems to be independent on the number of CPU cores.

- `mnemonics`, `par-mnemonics`: these two benchmarks solve the phone mnemonics using JDK streams (in `par-mnemonic`, parallel JDK streams). They are very simple benchmarks that encode a predefined phone number into a mnemonic using a specific dictionary.

  The nature of the benchmark should favor `par-mnemonics` in regards to scaling, but its performance seems independent on the number of cores. `mnemonics` benchmark does not utilize parallelism and thus its result is independent on the number of cores as well.

  There is one factor affecting performance of `par-mnemonics` and that is the number of utilized NUMA nodes. The benchmark gives consistent `5.5 x 10^9 ns` duration results independent on the number of cores when being run on both NUMA nodes, this is consistent with `mnemonics` results as well. And `4.5 x 10^9 ns` duration results when it is being run on a single NUMA node (and slightly decreasing with more cores). There is a notable exception to this behavior: performing the benchmark on a single core - this gives a result consistent with the results on both NUMA nodes. This suggests that it slightly benefits from parallelism, but this benefit is lost due to data transfers between NUMA nodes.

  The memory utilization results are too volatile to draw any meaningful conclusions, but for `mnemonics`, lower memory utilization was more consistent with fewer cores. This is quite surprising result as the performance results and the [code](https://github.com/renaissance-benchmarks/renaissance/blob/master/benchmarks/jdk-streams/src/main/java/org/renaissance/jdk/streams/MnemonicsCoderWithStream.java) (methods `translate` and `encode`) suggested that the benchmark doesn't utilize any parallelism. For `par-mnemonics`, the memory utilization is sometimes better, but overall the memory utilization is similar.

### scala

- `dotty`: (including the small dataset) the performance of this benchmark is very consistent and independent on the actual number of CPU cores, with a notable exception of the case with just 1 core.

  The small dataset shows that the benchmark's performance increases slightly with each added core from 1 core up until 4 cores (if they share the same NUMA core).
  
  The third set of results for this benchmark in the small dataset shows that assigning cores on different NUMA cores significantly hinders the performance. This is further confirmed by the third set in the original combined dataset.

  The memory usage slowly increases with the number of CPU cores, however, the increase is almost negligible in the original combined dataset. In the small dataset, this increase is very fast if the cores do not share the same NUMA core as can be seen in the third set of the small dataset.

- `philosophers`: this benchmark solves the problem of dining philosophers. This problem is used to illustrate process scheduling correctness. The complexity of the problem increases with the number of cores, so it makes sense that the performance decreases. The increase in benchmark duration linearly correlates with the number of cores (with very little variation), which is the expected result, given the nature of the benchmark. The memory usage of the benchmark is very volatile, but the mean memory usage slightly increases with the number of cores, which is the expected result.

- `scala-doku`: (including the small dataset) this benchmark's performance is very volatile in its dependence on external influences, but very consistent in subsequent runtime instances - this can be best seen when comparing sets 1 and 2 in the small dataset, the assigned CPU cores are the same up until 10, but the two sets contain very different results for these cases.

  Taking into account the previous conclusion, the benchmark's performance seems independent on the number of CPU cores as evidenced by the original combined dataset. This applies to the memory usage as well. However, in the memory usage sets, there is consistently a difference between the case with just one core and the other cases. This could be accounted to some internal mechanism that prepares the framework for multi-threaded runtime which the benchmark then does not utilize.

  The overall conclusion is that the number of assigned cores (and NUMA nodes) does not affect the performance nor it affects the memory usage.

- `scala-kmeans`: (including the small dataset) all the sets for this benchmark show that the number of CPU cores does not affect the performance of the benchmark. The small dataset exhibits few outlying subsequent measurements, but this is probably caused by external influences as there is very significant difference between the runtime durations collected in the first big dataset and the second big dataset (this can be seen in the plots for the original combined dataset as all the 'violins' have two 'heads' - each for one of the two datasets).

  The memory usage dependence on the number of number of CPU cores in very surprising as the memory usage seems independent on the number of cores with the exceptions of `2 <= N <= 15` which are consistently significantly lower. This can be probably explained by some internal Java interpreter behavior.

### web

- `finagle-chirper`: this benchmark does not scale well with more cores. Its performance actually decreases with more CPU cores. Memory usage of the benchmark is very volatile in the measured data, but it slightly increases with more cores.

  These results are quite surprising considering the technology used by the benchmark, Twitter Finagle, is advertized as being meant for "high-concurrency servers" on its [website](https://twitter.github.io/finagle/). On the other hand, the decrease in performance can be specific to the implementation of the benchmark as it, according to the documentation, heavily relies on atomics and probably is not meant to measure scalability.

  The memory usage increase can be explained by the overhead of thread-running and thread-safety measures performed by the framework.

- `finagle-http`: this benchmark does not scale well with more cores. Its performance steadily decreases with more CPU cores regardless of whether. Memory usage of the benchmark is very volatile in the measured data, but it clearly increases with more cores.

  The specific reasons for the decrease in performance and the increase in memory usage are the same as for `finagle-chirper` as they both use the same technology. This benchmark uses one more framework, Netty, which relies on asynchronous computing, but, in this benchmark with centralized architecture, it falls victim to blocking.
