#!/bin/sh

cpus="$1"
plan="${2:-1}"
script_name=$(readlink -f "$0")

case "$cpus" in
	''|*[!0-9]*)
		exit 1
		;;
esac

[ "$cpus" -eq 0 ] && exit 0
[ "$cpus" -gt 80 ] && exit 1

case "$plan" in
	1)
		seq 0 $((cpus - 1))
		;;
	2)
		if [ "$cpus" -le 10 ]; then
			seq 0 $((cpus - 1))
		elif [ "$cpus" -le 20 ]; then
			seq 0 9
			seq 20 $((cpus + 9))
		elif [ "$cpus" -le 30 ]; then
			seq 0 9
			seq 20 29
			seq 40 $((cpus + 19))
		elif [ "$cpus" -le 40 ]; then
			seq 0 9
			seq 20 29
			seq 40 49
			seq 60 $((cpus + 29))
		else
			seq 10 19
			seq 30 39
			seq 50 59
			seq 70 79
			"$script_name" $((cpus - 40)) 2
		fi
		;;
	3)
		packs=$((cpus / 4))
		rest=$((cpus % 4))

		seq "$packs" | while read -r node; do
			echo $((node - 1))
			echo $((node + 19))
			echo $((node + 39))
			echo $((node + 59))
		done

		seq "$rest" | while read -r node; do
			echo $((packs + (node - 1) * 20))
		done
		;;
	4)
		if [ "$cpus" -le 20 ]; then
			seq 0 $((cpus - 1))
		elif [ "$cpus" -le 40 ]; then
			seq 0 19
			seq 40 $((cpus + 19))
		else
			seq 20 39
			seq 60 79
			"$script_name" $((cpus - 40)) 4
		fi
		;;
	*)
		exit 1
		;;
esac
