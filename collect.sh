#!/bin/sh

CPU_COUNT=${1:-1}

for strategy in $(seq 4); do
	DIR_NAME="data/$strategy"
	mkdir -p "$DIR_NAME"
	OUTPUT_CSV="$DIR_NAME/$CPU_COUNT.csv"
	echo "running: numactl --physcpubind=$(./cpuset.sh "$CPU_COUNT" "$strategy" | awk 'BEGIN { i = 0 } { if (i++ > 0) printf "," $1; else printf $1 } END { print "" }') ./run_script.sh"
	numactl --physcpubind=$(./cpuset.sh "$CPU_COUNT" "$strategy" | awk 'BEGIN { i = 0 } { if (i++ > 0) printf "," $1; else printf $1 } END { print "" }') ./run_script.sh
done
