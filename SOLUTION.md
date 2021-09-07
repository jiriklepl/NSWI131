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

```sh
while sleep 1; do lscpu; done | awk 'BEGIN { print "timestamp,CPU MHz" } /CPU MHz/ { print systime() "," $3 }'
```

```sh
awk '/^[^#]/ { printf $0 " " } END { print }' benchmarks.txt
```
