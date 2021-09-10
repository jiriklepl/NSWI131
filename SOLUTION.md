# SOLUTION

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

CPU clock-rate is 3900 MHz (max) and it idles at 800 MHz.

The cache configuration of the CPUs is as follows:

- **L1:** **TODO**
- **L2:** **TODO**
- **L3:** **TODO**

**RAM:**

The RAM memory size is 64 GiB, clocked at 2933MHz (0.3ns).

**Java:**

The environment is equipped with OpenJDK 11.0.11 implementation of Java Development Kit and OpenJDK 18.9 implementation of Java Runtime Environment (JRE) and Java Server Virtual Machine (JVM).

### Preparation

**Controlling CPU count:**

For limiting the number of CPU cores used in runtime, we can use the program `numactl`

**Renaissance Benchmark Suite:**

We will use the 0.12 MIT distribution of the [Renaissance Benchmark Suite](https://github.com/renaissance-benchmarks/renaissance/releases/download/v0.12.0/renaissance-mit-0.12.0.jar).

The list of all benchmarks retrieved by the `--raw-list` option in the Renaissance runtime is in the file [benchmarks.txt](benchmarks.txt). This file will be used during data collecting.

## Methodology

All measurements were performed on the aforementioned virtual machine with the same setup.

There were collected 2 batches of data ([data.tar.gz](data.tar.gz) and [data2.tar.gz](data2.tar.gz)), each consisting of 17 x 4 sets of measurement results: there were 17 different numbers of CPU cores and for each 4 different strategies of core assignments.

- The first strategy assigns the first N cores according to their numbering.
- The second strategy assigns the cores in batches of 10 maximizing hyper-threading. And for `N <= 20` all assigned cores share the same NUMA node.
- The third strategy assigns the cores from each of the 4 sets distincted by NUMA nodes and hyper-threading according to round robin and from the lowest indices.
- The fourth strategy assigns the cores consecutively according to their numbering avoiding the hyper-threading pairs (e.g. cores 0 and 20) as long as possible - this means that, for `N <= 40`, all the assigned cores are on the same NUMA node.

For more details on CPU core assignment strategies, see the [cpuset.sh](cpuset.sh) script.

The 17 x 4 sets where collected by the [collect.sh](collect.sh) script with a single argument being, for each consecutive call, *1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80*. This script then cycles through the 4 strategies.

## Results

### concurrency

- `akka-uct`: TODO - waiting for small

- `fj-kmeans`: this benchmark is, out of all measured benchmarks, the one that scales the best with more CPU cores. The benchmark is parametrized by the number of CPU cores (`@Parameter(name = "thread_count", defaultValue = "$cpu.count")`) and the architecture is build to run the algorithm in parallel efficiently on these cores. The algorithm scales almost perfectly until it reaches a point where the overhead of increase in parallelization is higher then the benefit. The speedup caps at `11.4`.

  The memory usage is very volatile, but, on average, it is almost `4` times better if it is being run on a single NUMA node.

- `reactors`: TODO - waiting for small

### database

- `db-shootout`: TODO - waiting for small

### functional

- `future-genetic`: TODO - waiting for small

- `mnemonics`, `par-mnemonics`: these two benchmarks solve the phone mnemonics using JDK streams (in `par-mnemonic`, parallel JDK streams). They are very simple benchmarks that encode a predefined phone number into a mnemonic using a specific dictionary.

  The nature of the benchmark should favor `par-mnemonics` in regards to scaling, but its performance seems independent on the number of cores. `mnemonics` benchmark does not utilize parallelism and thus its result is independent on the number of cores as well.

  There is one factor affecting performance of `par-mnemonics` and that is the number of utilized NUMA nodes. The benchmark gives consistent `5.5 x 10^9 ns` duration results independent on the number of cores if being run on both NUMA nodes, this is consistent with `mnemonics` results as well. And `4.5 x 10^9 ns` duration results if it is being run on a single NUMA node (and slightly decreasing with more cores). There is a notable exception to this behavior: performing the benchmark on a single core - this gives a result consistent with the results on both NUMA nodes. This suggests that it slightly benefits from parallelism, but this benefit is lost due to data transfers between NUMA nodes.

  The memory utilization results are too volatile to draw any meaningful conclusions, but for `mnemonics`, lower memory utilization was more consistent with fewer cores. This is quite surprising result as the performance results and the [code](https://github.com/renaissance-benchmarks/renaissance/blob/master/benchmarks/jdk-streams/src/main/java/org/renaissance/jdk/streams/MnemonicsCoderWithStream.java) (methods `translate` and `encode`) suggested that the benchmark doesn't utilize any parallelism. For `par-mnemonics`, the memory utilization is sometimes better, but overall the memory utilization is similar.

### scala

- `dotty`: TODO - waiting for small

- `philosophers`: this benchmark solves the problem of dining philosophers. This problem is used to illustrate process scheduling correctness. The complexity of the problem increases with the number of cores, so it makes sense that the performance decreases. The increase in benchmark duration linearly correlates with the number of cores (with very little variation), which is the expected result given the nature of the benchmark. The memory usage of the benchmark is very volatile, but the mean memory usage slightly increases with the number of cores, which is the expected result.

- `scala-doku`: TODO - waiting for small
- `scala-kmeans`: TODO - waiting for small

### web

- `finagle-chirper`: this benchmark does not scale well with more cores. Its performance actually decreases with more CPU cores. Memory usage of the benchmark is very volatile in the measured data, but it slightly increases with more cores.

  These results are quite surprising considering the technology used by the benchmark, Twitter Finagle, is advertized as being meant for "high-concurrency servers" by its [website](https://twitter.github.io/finagle/). On the other hand, the decrease in performance can be specific to the implementation of the benchmark as it, according to the documentation, heavily relies on atomics and probably is not meant to measure scalability.

  The memory usage increase can be explained by the overhead of thread-running and thread-safety measures performed by the framework.

- `finagle-http`: this benchmark does not scale well with more cores. Its performance steadily decreases with more CPU cores regardless of whether. Memory usage of the benchmark is very volatile in the measured data, but it clearly increases with more cores.

  The specific reasons for the decrease in performance and the increase in memory usage are the same as for `finagle-chirper` as they both use the same technology. This benchmark uses one more framework, Netty, which relies on asynchronous computing, but, in this benchmark with centralized architecture, falls victim to blocking.
